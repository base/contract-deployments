import fs from 'fs';
import path from 'path';
import { ConfigParser } from './parser';
import { runAndExtract } from './script-extractor';
import { StateDiffClient } from './state-diff';
import { TenderlyClient } from './tenderly';
import {
  ExtractedData,
  StateChange,
  StateOverride,
  TenderlySimulationResponse,
  ValidationData,
} from './types/index';

// Re-export ValidationData for external use
export type { ValidationData };

export interface ValidationOptions {
  upgradeId: string; // e.g., "2025-06-04-upgrade-system-config"
  network: 'mainnet' | 'sepolia' | 'test';
  userType: 'Base SC' | 'Coinbase' | 'OP';
  rpcUrl?: string;
  tenderlyApiKey?: string;
  simulationMethod?: 'tenderly' | 'state-diff'; // New option for choosing simulation method
  stateDiffBinaryPath?: string; // Path to state-diff binary
  userLedgerAddress: string; // User's Ledger address to use as sender
}

export class ValidationService {
  private tenderlyClient?: TenderlyClient;
  private stateDiffClient?: StateDiffClient;

  constructor(tenderlyApiKey?: string, stateDiffBinaryPath?: string) {
    // Check for API key: parameter first, then environment variable
    const apiKey = tenderlyApiKey || process.env.TENDERLY_ACCESS;

    if (apiKey) {
      this.tenderlyClient = new TenderlyClient(apiKey);
      console.log(
        `🔑 Tenderly client initialized with ${tenderlyApiKey ? 'provided' : 'environment'} API key`
      );
    } else {
      console.warn('⚠️ No Tenderly API key found in parameters or environment variables');
    }

    // Initialize state-diff client
    this.stateDiffClient = new StateDiffClient(stateDiffBinaryPath);
  }

  /**
   * Main validation flow that orchestrates script extraction, simulation, and config parsing
   */
  async validateUpgrade(options: ValidationOptions): Promise<ValidationData> {
    console.log(`🚀 Starting validation for ${options.upgradeId} on ${options.network}`);
    console.log(`🎯 Using simulation method: ${options.simulationMethod || 'auto-detect'}`);

    // 1. Get expected data from validation config files
    const expected = await this.getExpectedData(options);

    // 2. Get actual data by running scripts and simulation
    const actual = await this.getActualData(options, expected.scriptParams);

    // 3. Sort state overrides and changes for consistent comparison
    const sortedExpectedData = this.sortValidationData({
      stateOverrides: expected.stateOverrides,
      stateChanges: expected.stateChanges,
    });
    const sortedActualData = this.sortValidationData(actual.data);

    const sortedExpected = {
      ...sortedExpectedData,
      domainAndMessageHashes: expected.domainAndMessageHashes,
    };
    const sortedActual = sortedActualData;

    console.log(
      `📊 Sorted data for comparison: ${sortedExpected.stateChanges.length} state changes, ${sortedExpected.stateOverrides.length} state overrides`
    );

    return {
      expected: sortedExpected,
      actual: sortedActual,
      extractedData: actual.extractedData,
      tenderlyResponse: actual.tenderlyResponse,
      stateDiffOutput: actual.stateDiffOutput,
    };
  }

  /**
   * Sort validation data for consistent comparison
   * Sorts by contract address first, then by storage slot (key)
   */
  private sortValidationData(data: {
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
  }): {
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
  } {
    // Sort state overrides by address only (storage slots sorted within each contract)
    const sortedStateOverrides = [...data.stateOverrides]
      .sort((a, b) => {
        // Sort by contract address (case-insensitive)
        return a.address.toLowerCase().localeCompare(b.address.toLowerCase());
      })
      .map(stateOverride => ({
        ...stateOverride,
        // Sort overrides within each contract by storage slot (key)
        overrides: [...stateOverride.overrides].sort((a, b) =>
          a.key.toLowerCase().localeCompare(b.key.toLowerCase())
        ),
      }));

    // Sort state changes by address only (storage slots sorted within each contract)
    const sortedStateChanges = [...data.stateChanges]
      .sort((a, b) => {
        // Sort by contract address (case-insensitive)
        return a.address.toLowerCase().localeCompare(b.address.toLowerCase());
      })
      .map(stateChange => ({
        ...stateChange,
        // Sort changes within each contract by storage slot (key)
        changes: [...stateChange.changes].sort((a, b) =>
          a.key.toLowerCase().localeCompare(b.key.toLowerCase())
        ),
      }));

    return {
      stateOverrides: sortedStateOverrides,
      stateChanges: sortedStateChanges,
    };
  }

  /**
   * Get expected state changes and overrides from validation config files
   */
  private async getExpectedData(options: ValidationOptions): Promise<{
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
    domainAndMessageHashes?: {
      address: string;
      domain_hash: string;
      message_hash: string;
    };
    ledgerId: number; // Required field (no longer optional)
    scriptParams: {
      scriptName: string;
      signature: string;
      args: string;
    };
  }> {
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    
    // Handle test network specially - load from validation-tool-interface/test-upgrade instead of root/test
    const upgradePath = options.network === 'test'
      ? path.join(process.cwd(), 'test-upgrade', options.upgradeId)
      : path.join(contractDeploymentsPath, options.network, options.upgradeId);

    // Look for validation config files based on user type in validations subdirectory
    const configFileName = this.getConfigFileName(options.userType);
    const configPath = path.join(upgradePath, 'validations', configFileName);

    if (!fs.existsSync(configPath)) {
      console.warn(`⚠️ Config file not found: ${configPath}`);
      throw new Error(`Config file not found: ${configPath}`);
    }

    try {
      const configContent = fs.readFileSync(configPath, 'utf-8');
      const parsedConfig = ConfigParser.parseFromString(configContent);

      if (!parsedConfig.result.success) {
        console.error(
          '❌ Failed to parse config:',
          ConfigParser.getValidationSummary(parsedConfig.result)
        );
        throw new Error('Failed to parse config file');
      }

      console.log(`✅ Loaded expected data from ${configFileName}`);
      return {
        stateOverrides: parsedConfig.config.state_overrides,
        stateChanges: parsedConfig.config.state_changes,
        domainAndMessageHashes: parsedConfig.config.expected_domain_and_message_hashes,
        ledgerId: parsedConfig.config["ledger-id"], // Required field
        scriptParams: {
          scriptName: parsedConfig.config.script_name,
          signature: parsedConfig.config.signature,
          args: parsedConfig.config.args,
        },
      };
    } catch (error) {
      console.error(`❌ Error reading config file: ${error}`);
      throw error;
    }
  }

  /**
   * Get actual state changes and overrides by running scripts and simulation
   */
  private async getActualData(
    options: ValidationOptions,
    scriptParams: {
      scriptName: string;
      signature: string;
      args: string;
    }
  ): Promise<{
    data: {
      stateOverrides: StateOverride[];
      stateChanges: StateChange[];
    };
    extractedData?: ExtractedData;
    tenderlyResponse?: TenderlySimulationResponse;
    stateDiffOutput?: string;
  }> {
    // 1. Run script extraction (handle only script extraction errors)
    let extractedData: ExtractedData;
    try {
      extractedData = await this.runScriptExtraction(options, scriptParams);
    } catch (error) {
      console.error('❌ Script extraction failed:', error);
      throw new Error(
        `Script extraction failed: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }

    if (!extractedData.simulationLink) {
      console.warn('⚠️ No simulation link found in script output');
      throw new Error(
        'No simulation link found in script output. Please check the script configuration.'
      );
    }

    // 2. Choose simulation method
    const simulationMethod = await this.selectSimulationMethod(options);

    // 3. Run simulation (let simulation errors propagate to UI for retry)
    if (simulationMethod === 'state-diff') {
      return await this.runStateDiffSimulation(options, extractedData);
    } else {
      return await this.runTenderlySimulation(extractedData);
    }
  }

  /**
   * Select the appropriate simulation method based on availability and user preference
   */
  private async selectSimulationMethod(
    options: ValidationOptions
  ): Promise<'tenderly' | 'state-diff'> {
    // If user explicitly specified a method, use it
    if (options.simulationMethod) {
      console.log(`🎯 Using user-specified simulation method: ${options.simulationMethod}`);
      return options.simulationMethod;
    }

    // Auto-detect: prefer Tenderly if available, fallback to state-diff
    if (this.tenderlyClient) {
      console.log(`🎯 Auto-detected: Using Tenderly simulation (API key available)`);
      return 'tenderly';
    } else if (await this.stateDiffClient?.checkAvailability()) {
      console.log(`🎯 Auto-detected: Using state-diff simulation (Go binary available)`);
      return 'state-diff';
    } else {
      console.warn(
        `⚠️ Neither Tenderly API key nor state-diff binary available, defaulting to Tenderly`
      );
      return 'tenderly';
    }
  }

  /**
   * Run simulation using state-diff tool
   */
  private async runStateDiffSimulation(
    options: ValidationOptions,
    extractedData: ExtractedData
  ): Promise<{
    data: {
      stateOverrides: StateOverride[];
      stateChanges: StateChange[];
    };
    extractedData?: ExtractedData;
    stateDiffOutput?: string;
  }> {
    if (!this.stateDiffClient) {
      throw new Error('StateDiffClient not initialized.');
    }

    try {
      console.log('🔧 Running state-diff simulation with extracted data...');

      // Get RPC URL
      let rpcUrl = options.rpcUrl || this.getRpcUrl(options.network);

      // Use the new simulateWithExtractedData method
      const stateDiffResult = await this.stateDiffClient.simulateWithExtractedData({
        rpcUrl,
        extractedData,
      });

      // Parse both state overrides and state changes from state-diff output
      const stateOverrides = this.stateDiffClient.parseStateOverrides(stateDiffResult.result);
      const stateChanges = this.stateDiffClient.parseStateChanges(stateDiffResult.result);

      console.log(
        `✅ State-diff simulation completed: ${stateOverrides.length} state overrides, ${stateChanges.length} state changes found`
      );

      return {
        data: { stateOverrides, stateChanges },
        extractedData,
        stateDiffOutput: stateDiffResult.output,
      };
    } catch (error) {
      console.error('❌ State-diff simulation failed:', error);
      throw error;
    }
  }

  /**
   * Run simulation using Tenderly API (existing functionality)
   */
  private async runTenderlySimulation(extractedData: ExtractedData): Promise<{
    data: {
      stateOverrides: StateOverride[];
      stateChanges: StateChange[];
    };
    extractedData?: ExtractedData;
    tenderlyResponse?: TenderlySimulationResponse;
  }> {
    let tenderlyResponse: TenderlySimulationResponse | undefined;
    let stateOverrides: StateOverride[] = [];
    let stateChanges: StateChange[] = [];

    if (this.tenderlyClient) {
      try {
        tenderlyResponse = await this.tenderlyClient.simulateFromExtractedData(extractedData);

        // Parse state overrides and changes from Tenderly response
        stateOverrides = this.tenderlyClient.parseStateOverrides(extractedData.simulationLink!);
        stateChanges = this.tenderlyClient.parseStateChanges(tenderlyResponse);

        console.log(`✅ Tenderly simulation completed: ${stateChanges.length} state changes found`);
      } catch (error) {
        console.error('❌ Tenderly simulation failed:', error);
      }
    } else {
      console.warn('⚠️ No Tenderly API key available, skipping simulation');
      console.warn(
        '💡 To enable Tenderly simulation: add TENDERLY_ACCESS to .env file or provide via UI'
      );
      // Still parse state overrides from the simulation link
      if (extractedData.simulationLink) {
        stateOverrides = this.parseStateOverridesFromLink(extractedData.simulationLink);
      }
    }

    return {
      data: { stateOverrides, stateChanges },
      extractedData,
      tenderlyResponse,
    };
  }

  /**
   * Get RPC URL with fallbacks
   */
  private getRpcUrl(network: 'mainnet' | 'sepolia' | 'test'): string {
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    const networkPath = path.join(contractDeploymentsPath, network);
    const envPath = path.join(networkPath, '.env');

    if (fs.existsSync(envPath)) {
      try {
        const envContent = fs.readFileSync(envPath, 'utf-8');
        const match = envContent.match(/^L1_RPC_URL=(.*)$/m);
        if (match && match[1]) {
          const rpcUrl = match[1].trim().replace(/^["']|["']$/g, '');
          console.log(`📡 Using RPC URL from ${network}/.env file: ${rpcUrl}`);
          return rpcUrl;
        }
      } catch (error) {
        console.warn(`⚠️ Failed to read .env file: ${error}`);
      }
    }

    // Fall back to default RPC URLs
    const defaultRpcUrls = {
      mainnet: 'https://mainnet.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul',
      sepolia: 'https://sepolia.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul',
      test: 'https://virtual.mainnet.rpc.tenderly.co/3a94c397-9711-4592-aadf-a66a31c6747f',
    };

    const rpcUrl = defaultRpcUrls[network];
    console.log(`📡 Using default RPC URL: ${rpcUrl}`);
    return rpcUrl;
  }

  /**
   * Run Foundry script extraction
   */
  private async runScriptExtraction(
    options: ValidationOptions,
    scriptParams: {
      scriptName: string;
      signature: string;
      args: string;
    }
  ): Promise<ExtractedData> {
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    
    // Handle test network specially - load from validation-tool-interface/test-upgrade instead of root/test
    const scriptPath = options.network === 'test'
      ? path.join(process.cwd(), 'test-upgrade', options.upgradeId)
      : path.join(contractDeploymentsPath, options.network, options.upgradeId);

    // Try to read RPC URL from .env file in the network folder
    let rpcUrl = options.rpcUrl;

    if (!rpcUrl) {
      const networkPath = path.join(contractDeploymentsPath, options.network);
      const envPath = path.join(networkPath, '.env');
      if (fs.existsSync(envPath)) {
        try {
          const envContent = fs.readFileSync(envPath, 'utf-8');
          const match = envContent.match(/^L1_RPC_URL=(.*)$/m);
          if (match && match[1]) {
            // Remove quotes if present and trim whitespace
            rpcUrl = match[1].trim().replace(/^["']|["']$/g, '');
            console.log(`📡 Using RPC URL from ${options.network}/.env file: ${rpcUrl}`);
          }
        } catch (error) {
          console.warn(`⚠️ Failed to read .env file: ${error}`);
        }
      }
    }

    // Fall back to default RPC URLs if not found
    if (!rpcUrl) {
      const defaultRpcUrls = {
        mainnet: 'https://mainnet.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul',
        sepolia: 'https://sepolia.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul',
        test: 'https://virtual.mainnet.rpc.tenderly.co/3a94c397-9711-4592-aadf-a66a31c6747f',
      };
      rpcUrl = defaultRpcUrls[options.network];
      console.log(`📡 Using default RPC URL: ${rpcUrl}`);
    }

    // Use the user's Ledger address as the sender instead of default
    const senderAddress = options.userLedgerAddress;
    console.log(`👤 Using user's Ledger address as sender: ${senderAddress}`);

    const extractorOptions = {
      scriptPath,
      rpcUrl,
      scriptName: scriptParams.scriptName,
      signature: scriptParams.signature,
      args: scriptParams.args ? [scriptParams.args] : [], // Handle empty args
      sender: senderAddress,
      saveOutput: path.join(scriptPath, 'temp-script-output.txt'),
    };

    console.log(`🔧 Running script extraction with options:`, extractorOptions);

    return await runAndExtract(extractorOptions);
  }

  /**
   * Get config file name based on user type (now supports dynamic user types)
   */
  private getConfigFileName(userType: string): string {
    // Convert display name back to filename
    // "Base Sc" → "base-sc.json"
    // "Op" → "op.json"
    // "Coinbase" → "coinbase.json"
    const fileName = userType.toLowerCase().replace(/\s+/g, '-') + '.json';
    console.log(`🗂️ Mapping user type "${userType}" to config file: ${fileName}`);
    return fileName;
  }

  /**
   * Parse state overrides from simulation link when Tenderly is not available
   */
  private parseStateOverridesFromLink(simulationLink: any): StateOverride[] {
    if (!simulationLink.stateOverrides) {
      return [];
    }

    try {
      const stateOverrides = JSON.parse(simulationLink.stateOverrides);
      return stateOverrides.map((override: any, index: number) => ({
        name: `Contract ${index + 1}`,
        address: override.contractAddress,
        overrides:
          override.storage?.map((storage: any) => ({
            key: storage.key,
            value: storage.value,
            description: 'State override from script',
          })) || [],
      }));
    } catch (error) {
      console.error('Failed to parse state overrides:', error);
      return [];
    }
  }

  /**
   * Clean up temporary files
   */
  async cleanup(options: ValidationOptions): Promise<void> {
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    
    // Handle test network specially - load from validation-tool-interface/test-upgrade instead of root/test
    const scriptPath = options.network === 'test'
      ? path.join(process.cwd(), 'test-upgrade', options.upgradeId)
      : path.join(contractDeploymentsPath, options.network, options.upgradeId);
    const tempFile = path.join(scriptPath, 'temp-script-output.txt');
    const extractedFile = path.join(scriptPath, 'temp-script-output-extracted.json');

    try {
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile);
      }
      if (fs.existsSync(extractedFile)) {
        fs.unlinkSync(extractedFile);
      }
    } catch (error) {
      console.warn('Warning: Failed to clean up temporary files:', error);
    }
  }
}
