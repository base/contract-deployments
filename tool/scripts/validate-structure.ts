#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { ConfigParser } from '../utils/parser';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Available config files for each upgrade (at least one required)
const REQUIRED_CONFIG_FILES = [
  'base-nested.json',
  'base-sc.json',
  'op.json'
] as const;

// Upgrade folder pattern: YYYY-MM-DD-description
const UPGRADE_FOLDER_PATTERN = /^\d{4}-\d{2}-\d{2}-/;

interface ValidationError {
  folder: string;
  message: string;
}

interface ValidationWarning {
  folder: string;
  message: string;
}

interface InvalidFile {
  file: string;
  errors: Array<{ message: string }>;
}

export class StructureValidator {
  private errors: ValidationError[] = [];
  private warnings: ValidationWarning[] = [];
  private checkedFolders: Set<string> = new Set();

  /**
   * Main validation entry point
   */
  validate(inputs: string[]): boolean {
    console.log('🔍 Starting structure validation...');
    console.log(`📁 Processing ${inputs.length} input(s)\n`);

    // Extract unique upgrade folders from inputs (can be files or folders)
    const upgradeFolders = this.extractUpgradeFolders(inputs);

    if (upgradeFolders.length === 0) {
      console.log('✅ No upgrade folders detected in changes');
      return true;
    }

    console.log(`🎯 Found ${upgradeFolders.length} upgrade folders to validate:`);
    upgradeFolders.forEach(folder => console.log(`   - ${folder}`));
    console.log();

    // Validate each upgrade folder
    for (const folder of upgradeFolders) {
      this.validateUpgradeFolder(folder);
    }

    // Report results
    return this.reportResults();
  }

    /**
   * Extract unique upgrade folders from changed file paths or direct folder paths
   */
  private extractUpgradeFolders(inputs: string[]): string[] {
    const folders = new Set<string>();

    for (const input of inputs) {
      // Check if input is a direct folder path (e.g., "mainnet/2025-06-25-safe-swap-owner")
      // This should NOT contain any slashes after the upgrade folder name
      const directFolderMatch = input.match(/^(mainnet|sepolia)\/(\d{4}-\d{2}-\d{2}-[^/]+)$/);
      if (directFolderMatch) {
        folders.add(input);
        continue;
      }

      // Check if input is a file path (e.g., "mainnet/2025-06-25-safe-swap-owner/validations/base-nested.json")
      const filePathMatch = input.match(/^(mainnet|sepolia)\/(\d{4}-\d{2}-\d{2}-.+?)\//);
      if (filePathMatch) {
        const [, network, upgradeFolder] = filePathMatch;
        const fullPath = `${network}/${upgradeFolder}`;
        folders.add(fullPath);
      }
    }

    return Array.from(folders);
  }

  /**
   * Validate a single upgrade folder
   */
  private validateUpgradeFolder(folderPath: string): void {
    console.log(`🔎 Validating: ${folderPath}`);
    this.checkedFolders.add(folderPath);

    const absolutePath = path.join(__dirname, '../../', folderPath);

    // Check if folder exists
    if (!fs.existsSync(absolutePath)) {
      this.addError(folderPath, 'Upgrade folder does not exist');
      return;
    }

    // Check if validations subdirectory exists
    const validationsPath = path.join(absolutePath, 'validations');
    if (!fs.existsSync(validationsPath)) {
      this.addError(folderPath, 'Missing validations/ subdirectory');
      return;
    }

    // Check for required config files
    this.validateConfigFiles(folderPath, validationsPath);

    console.log(`   ✓ Structure validated\n`);
  }

    /**
   * Validate that at least one config file exists and all existing files are valid JSON
   */
  private validateConfigFiles(folderPath: string, validationsPath: string): void {
    const existingFiles: string[] = [];
    const missingFiles: string[] = [];
    const invalidFiles: InvalidFile[] = [];

    // Check which files exist
    for (const configFile of REQUIRED_CONFIG_FILES) {
      const filePath = path.join(validationsPath, configFile);

      if (fs.existsSync(filePath)) {
        existingFiles.push(configFile);
      } else {
        missingFiles.push(configFile);
      }
    }

    // Require at least one config file
    if (existingFiles.length === 0) {
      this.addError(
        folderPath,
        `No validation config files found. At least one of these files is required: ${REQUIRED_CONFIG_FILES.join(', ')}`
      );
      return;
    }

    // Validate existing files
    for (const configFile of existingFiles) {
      const filePath = path.join(validationsPath, configFile);

      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const result = ConfigParser.parseFromString(content);

        if (!result.result.success) {
          invalidFiles.push({
            file: configFile,
            errors: result.result.zodError?.issues?.map(issue => ({
              message: issue.path.length > 0
                ? `${issue.path.join('.')}: ${issue.message}`
                : issue.message
            })) || []
          });
        } else {
          console.log(`   ✓ ${configFile} - valid`);
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        invalidFiles.push({
          file: configFile,
          errors: [{ message: `Failed to read file: ${errorMessage}` }]
        });
      }
    }

    // Show info about missing files (as info, not error)
    if (missingFiles.length > 0) {
      console.log(`   ℹ️  Optional files not present: ${missingFiles.join(', ')}`);
    }

    // Report invalid files
    for (const invalid of invalidFiles) {
      const errorSummary = invalid.errors
        .map(e => e.message)
        .join('; ');
      this.addError(
        folderPath,
        `Invalid ${invalid.file}: ${errorSummary}`
      );
    }
  }

  /**
   * Add validation error
   */
  private addError(folder: string, message: string): void {
    this.errors.push({ folder, message });
    console.log(`   ❌ ${message}`);
  }

  /**
   * Add validation warning
   */
  private addWarning(folder: string, message: string): void {
    this.warnings.push({ folder, message });
    console.log(`   ⚠️  ${message}`);
  }

  /**
   * Report final validation results
   */
  private reportResults(): boolean {
    console.log('📊 VALIDATION RESULTS');
    console.log('='.repeat(50));

    console.log(`📁 Folders checked: ${this.checkedFolders.size}`);
    console.log(`❌ Errors found: ${this.errors.length}`);
    console.log(`⚠️  Warnings: ${this.warnings.length}`);

    if (this.errors.length > 0) {
      console.log('\n🚨 ERRORS:');
      for (const error of this.errors) {
        console.log(`   ${error.folder}: ${error.message}`);
      }
    }

    if (this.warnings.length > 0) {
      console.log('\n⚠️  WARNINGS:');
      for (const warning of this.warnings) {
        console.log(`   ${warning.folder}: ${warning.message}`);
      }
    }

    const success = this.errors.length === 0;
    console.log(`\n${success ? '✅ VALIDATION PASSED' : '❌ VALIDATION FAILED'}`);

    return success;
  }
}

// Main execution
function main(): void {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('❌ No input provided');
    console.error('Usage:');
    console.error('  Validate specific folder: tsx scripts/validate-structure.ts "mainnet/2025-06-25-safe-swap-owner"');
    console.error('  Validate multiple folders: tsx scripts/validate-structure.ts "mainnet/upgrade1 sepolia/upgrade2"');
    console.error('  Validate from file paths: tsx scripts/validate-structure.ts "file1 file2 file3"');
    process.exit(1);
  }

  // Parse inputs (can be folder paths or file paths, space-separated string)
  const inputs = args[0].split(' ').filter(input => input.trim());

  const validator = new StructureValidator();
  const success = validator.validate(inputs);

  process.exit(success ? 0 : 1);
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
