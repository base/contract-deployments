import { ExtractedData, ScriptRunnerOptions, SimulationLink } from './types/index';

import { execSync } from 'child_process';
import fs from 'fs';

/**
 * Run a Foundry script and extract structured data from its output
 */
export async function runAndExtract(options: ScriptRunnerOptions): Promise<ExtractedData> {
  const {
    scriptPath,
    rpcUrl,
    scriptName,
    signature,
    args = [],
    sender,
    saveOutput,
    extractOnly = false,
  } = options;

  console.log('🔧 Foundry Script Runner & Data Extractor\n');

  let scriptOutput: string;
  const originalCwd = process.cwd();

  if (extractOnly && saveOutput && fs.existsSync(saveOutput)) {
    console.log(`📁 Reading existing output from: ${saveOutput}`);
    scriptOutput = fs.readFileSync(saveOutput, 'utf8');
  } else {
    // Build and run the forge command
    const forgeCommand = buildForgeCommand({ rpcUrl, scriptName, signature, args, sender });

    console.log(`📍 Working directory: ${scriptPath}`);
    console.log(`🚀 Running: ${forgeCommand}\n`);

    try {
      if (!fs.existsSync(scriptPath)) {
        throw new Error(`Script directory does not exist: ${scriptPath}`);
      }

      process.chdir(scriptPath);
      scriptOutput = execSync(forgeCommand, {
        encoding: 'utf8',
        stdio: 'pipe',
        maxBuffer: 10 * 1024 * 1024, // 10MB buffer
      });
      process.chdir(originalCwd);

      console.log('✅ Script executed successfully!\n');

      // Optionally save output to file
      if (saveOutput) {
        fs.writeFileSync(saveOutput, scriptOutput);
        console.log(`💾 Output saved to: ${saveOutput}\n`);
      }
    } catch (error: any) {
      process.chdir(originalCwd);
      console.error('❌ Script execution failed:');
      if (error.stdout) console.error('STDOUT:', error.stdout.toString());
      if (error.stderr) console.error('STDERR:', error.stderr.toString());
      console.error('Error:', error.message);

      // Throw error instead of exiting the process
      const errorMessage = error.stderr ? error.stderr.toString() : error.message;
      throw new Error(`Script execution failed: ${errorMessage}`);
    }
  }

  // Extract and display results
  console.log('🔍 Extracting structured data...\n');

  try {
    const extractedData = extractFromOutput(scriptOutput);
    displayResults(extractedData);

    // Optionally save extracted data as JSON
    if (saveOutput) {
      const jsonFile = saveOutput.replace(/\.[^/.]+$/, '') + '-extracted.json';
      fs.writeFileSync(jsonFile, JSON.stringify(extractedData, null, 2));
      console.log(`📄 Extracted data saved to: ${jsonFile}\n`);
    }

    return extractedData;
  } catch (error) {
    console.error('❌ Failed to extract data:', error);
    console.log('\n📝 Raw script output:');
    console.log('-'.repeat(50));
    console.log(scriptOutput);

    // Throw error instead of exiting the process
    throw new Error(
      `Data extraction failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Extract structured data from Foundry script output
 */
function extractFromOutput(output: string): ExtractedData {
  // Regex patterns for extraction (single matches only, except nested hashes)
  const PATTERNS = {
    nestedHash: /Nested hash for safe (0x[a-fA-F0-9]{40}):\s*(0x[a-fA-F0-9]{64})/g,
    simulationLink: /https:\/\/dashboard\.tenderly\.co\/[^\s]+/,
    approvalHash:
      /call Safe\.approveHash on (0x[a-fA-F0-9]{40}) with the following hash:\s*(0x[a-fA-F0-9]{64})/,
    signingData: /Data to sign:\s*vvvvvvvv\s*(0x[a-fA-F0-9]+)\s*\^\^\^\^\^\^\^\^/,
    rawInputData: /Insert the following hex into the 'Raw input data' field:\s*(0x[a-fA-F0-9]+)/,
  } as const;

  const simulationMatch = output.match(PATTERNS.simulationLink);
  const approvalHashMatch = output.match(PATTERNS.approvalHash);
  const signingDataMatch = output.match(PATTERNS.signingData);
  const rawInputDataMatch = output.match(PATTERNS.rawInputData);

  // Extract multiple nested hashes
  const nestedHashes = [];
  let nestedHashMatch;
  while ((nestedHashMatch = PATTERNS.nestedHash.exec(output)) !== null) {
    nestedHashes.push({
      safeAddress: nestedHashMatch[1],
      hash: nestedHashMatch[2],
    });
  }

  // Other data types only contain one match each
  const simulationLink = simulationMatch
    ? parseSimulationUrl(simulationMatch[0], rawInputDataMatch ? rawInputDataMatch[1] : undefined)
    : null;

  const approvalHash = approvalHashMatch
    ? {
        safeAddress: approvalHashMatch[1],
        hash: approvalHashMatch[2],
      }
    : null;

  const signingData = signingDataMatch
    ? {
        dataToSign: signingDataMatch[1],
      }
    : null;

  return {
    nestedHashes,
    simulationLink: simulationLink ?? undefined,
    approvalHash: approvalHash ?? undefined,
    signingData: signingData ?? undefined,
  };
}

/**
 * Parse simulation URL and extract parameters
 */
function parseSimulationUrl(url: string, separateRawInput?: string): SimulationLink {
  try {
    const urlObj = new URL(url);
    const params = urlObj.searchParams;

    return {
      url,
      network: params.get('network') || 'unknown',
      contractAddress:
        params.get('contractAddress') || '0x0000000000000000000000000000000000000000',
      from: params.get('from') || '0x0000000000000000000000000000000000000000',
      stateOverrides: params.get('stateOverrides') || undefined,
      // Use separate raw input if available, otherwise use URL parameter
      rawFunctionInput: separateRawInput || params.get('rawFunctionInput') || undefined,
    };
  } catch {
    return {
      url,
      network: 'unknown',
      contractAddress: '0x0000000000000000000000000000000000000000',
      from: '0x0000000000000000000000000000000000000000',
      rawFunctionInput: separateRawInput || undefined,
    };
  }
}

/**
 * Build the forge script command
 */
function buildForgeCommand(options: {
  rpcUrl: string;
  scriptName: string;
  signature?: string;
  args?: string[];
  sender?: string;
}): string {
  const { rpcUrl, scriptName, signature, args = [], sender } = options;

  let command = `forge script --rpc-url ${rpcUrl} ${scriptName}`;

  if (signature) {
    const argsString = args.length > 0 ? ` ${args.join(' ')}` : '';
    command += ` --sig "${signature}"${argsString}`;
  }

  if (sender) {
    command += ` --sender ${sender}`;
  }

  return command;
}

/**
 * Utils: Display extracted results
 */
function displayResults(data: ExtractedData) {
  // Display detailed data
  if (data.nestedHashes.length > 0) {
    console.log('🔗 NESTED HASHES:');
    console.log('='.repeat(50));
    data.nestedHashes.forEach((hash, i) => {
      console.log(`${i + 1}. Safe: ${hash.safeAddress}`);
      console.log(`   Hash: ${hash.hash}`);
    });
    console.log('');
  }

  if (data.simulationLink) {
    console.log('🌐 SIMULATION LINK:');
    console.log('='.repeat(50));
    console.log(`URL: ${data.simulationLink.url}`);
    console.log('');
    console.log('URL Breakdown:');
    console.log('='.repeat(50));
    console.log(`• Network: ${data.simulationLink.network}`);
    console.log(`• Contract: ${data.simulationLink.contractAddress}`);
    console.log(`• From: ${data.simulationLink.from}`);

    // Display break down of URL components
    if (data.simulationLink.stateOverrides) {
      try {
        // Decode URL-encoded JSON and parse it
        const decodedStateOverrides = decodeURIComponent(data.simulationLink.stateOverrides);
        const parsedOverrides = JSON.parse(decodedStateOverrides);

        console.log(`• State Overrides:`);
        parsedOverrides.forEach((override: any, index: number) => {
          console.log(`  ${index + 1}. Contract: `);
          console.log(`     Name: (empty)`); // Leave empty as requested
          console.log(`     Address: ${override.contractAddress}`);
          console.log(`     Storage Overrides:`);
          override.storage?.forEach((storage: any, storageIndex: number) => {
            console.log(`       ${storageIndex + 1}. Key: ${storage.key}`);
            console.log(`          Value: ${storage.value}`);
          });
        });
      } catch (error) {
        // If parsing fails, show raw data
        console.log(`• State Overrides (raw): ${data.simulationLink.stateOverrides}`);
      }
    }
    if (data.simulationLink.rawFunctionInput) {
      console.log(`• Raw Function Input:`);
      console.log(`  ${data.simulationLink.rawFunctionInput}`);
    }
    console.log('');
  }

  if (data.approvalHash) {
    console.log('✅ APPROVAL HASH:');
    console.log('='.repeat(50));
    console.log(`Safe: ${data.approvalHash.safeAddress}`);
    console.log(`Hash: ${data.approvalHash.hash}`);
    console.log('');
  }

  if (data.signingData) {
    console.log('✏️  SIGNING DATA:');
    console.log('='.repeat(50));
    console.log(`Data to Sign: ${data.signingData.dataToSign}`);
    console.log('');
  }
}
