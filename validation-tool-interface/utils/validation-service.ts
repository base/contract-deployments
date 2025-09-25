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
  rpcUrl: string;
  tenderlyApiKey?: string;
  simulationMethod?: 'tenderly' | 'state-diff';
  stateDiffBinaryPath?: string; // Path to state-diff binary
  userLedgerAddress: string; // User's Ledger address to use as sender
}

export class ValidationService {
  private tenderlyClient?: TenderlyClient;
  private stateDiffClient?: StateDiffClient;

  constructor(tenderlyApiKey?: string, stateDiffBinaryPath?: string) {
    const apiKey = tenderlyApiKey || process.env.TENDERLY_ACCESS;

    if (apiKey) {
      this.tenderlyClient = new TenderlyClient(apiKey);
      console.log(
        `🔑 Tenderly client initialized with ${tenderlyApiKey ? 'provided' : 'environment'} API key`
      );
    } else {
      console.warn('⚠️ No Tenderly API key found in parameters or environment variables');
    }

    this.stateDiffClient = new StateDiffClient(stateDiffBinaryPath);
  }



  /**
   * Parse validation config file and return both ValidationOptions and parsed config
   */
  private async getConfigData(baseOptions: {
    upgradeId: string;
    network: string;
    userType: string;
    tenderlyApiKey?: string;
    simulationMethod?: 'tenderly' | 'state-diff';
    stateDiffBinaryPath?: string;
    userLedgerAddress: string;
  }): Promise<{
    options: ValidationOptions;
    parsedConfig: any;
  }> {
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    
    // Handle test network specially - load from validation-tool-interface/test-upgrade instead of root/test
    const upgradePath = baseOptions.network === 'test'
      ? path.join(process.cwd(), 'test-upgrade', baseOptions.upgradeId)
      : path.join(contractDeploymentsPath, baseOptions.network, baseOptions.upgradeId);

    // Look for validation config files based on user type in validations subdirectory
    const configFileName = this.getConfigFileName(baseOptions.userType);
    const configPath = path.join(upgradePath, 'validations', configFileName);

    if (!fs.existsSync(configPath)) {
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

      console.log(`✅ Loaded config data from ${configFileName}`);
      
      // Return complete ValidationOptions with rpcUrl from config and the parsed config
      return {
        options: {
          upgradeId: baseOptions.upgradeId,
          network: baseOptions.network as 'mainnet' | 'sepolia' | 'test',
          userType: baseOptions.userType as 'Base SC' | 'Coinbase' | 'OP',
          rpcUrl: parsedConfig.config.rpc_url,
          tenderlyApiKey: baseOptions.tenderlyApiKey,
          simulationMethod: baseOptions.simulationMethod,
          stateDiffBinaryPath: baseOptions.stateDiffBinaryPath,
          userLedgerAddress: baseOptions.userLedgerAddress,
        },
        parsedConfig: parsedConfig.config
      };
    } catch (error) {
      console.error(`❌ Error reading config file: ${error}`);
      throw error;
    }
  }

  /**
   * Main validation flow that orchestrates script extraction, simulation, and config parsing
   */
  async validateUpgrade(baseOptions: {
    upgradeId: string;
    network: string;
    userType: string;
    tenderlyApiKey?: string;
    simulationMethod?: 'tenderly' | 'state-diff';
    stateDiffBinaryPath?: string;
    userLedgerAddress: string;
  }): Promise<ValidationData> {
    console.log(`🚀 Starting validation for ${baseOptions.upgradeId} on ${baseOptions.network}`);
    console.log(`🎯 Using simulation method: ${baseOptions.simulationMethod || 'auto-detect'}`);

    // 1. Get complete config data including rpcUrl from validation file
    const { options, parsedConfig } = await this.getConfigData(baseOptions);

    // 2. Get expected data from parsed config (no need to parse again)
    const expected = this.getExpectedData(parsedConfig);

    // 3. Get actual data by running scripts and simulation  
    const actual = await this.getActualData(options, expected.scriptParams);

    // 4. Sort state overrides and changes for consistent comparison
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

  
  private getExpectedData(parsedConfig: any): {
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
    domainAndMessageHashes?: {
      address: string;
      domain_hash: string;
      message_hash: string;
    };
    ledgerId: number;
    scriptParams: {
      scriptName: string;
      signature: string;
      args: string;
    };
  } {
    return {
      stateOverrides: parsedConfig.state_overrides,
      stateChanges: parsedConfig.state_changes,
      domainAndMessageHashes: parsedConfig.expected_domain_and_message_hashes,
      ledgerId: parsedConfig["ledger-id"],
      scriptParams: {
        scriptName: parsedConfig.script_name,
        signature: parsedConfig.signature,
        args: parsedConfig.args,
      },
    };
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
    // If user explicitly specified a method, validate it's available
    if (options.simulationMethod) {
      console.log(`🎯 Using user-specified simulation method: ${options.simulationMethod}`);
      
      if (options.simulationMethod === 'tenderly' && !this.tenderlyClient) {
        throw new Error(
          'Tenderly simulation method specified but no Tenderly API key available. ' +
          'Set TENDERLY_ACCESS in .env file or provide via API request.'
        );
      }
      
      if (options.simulationMethod === 'state-diff' && !(await this.stateDiffClient?.checkAvailability())) {
        throw new Error(
          'State-diff simulation method specified but Go binary is not available. ' +
          'Ensure Go is installed and the go-simulator directory exists.'
        );
      }
      
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
      throw new Error(
        'No simulation method available. Either:\n' +
        '1. Set TENDERLY_ACCESS in .env file or provide Tenderly API key, OR\n' +
        '2. Ensure Go is installed and the go-simulator directory exists.\n' +
        'At least one simulation method must be available to proceed.'
      );
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

      // Use the RPC URL from options
      const rpcUrl = options.rpcUrl;

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
    if (!this.tenderlyClient) {
      throw new Error(
        'Tenderly simulation requested but no Tenderly API key available. ' +
        'Set TENDERLY_ACCESS in .env file or provide via API request.'
      );
    }

    let tenderlyResponse: TenderlySimulationResponse | undefined;
    let stateOverrides: StateOverride[] = [];
    let stateChanges: StateChange[] = [];

    try {
      tenderlyResponse = await this.tenderlyClient.simulateFromExtractedData(extractedData);

      // Parse state overrides and changes from Tenderly response
      stateOverrides = this.tenderlyClient.parseStateOverrides(extractedData.simulationLink!);
      stateChanges = this.tenderlyClient.parseStateChanges(tenderlyResponse);

      console.log(`✅ Tenderly simulation completed: ${stateChanges.length} state changes found`);
    } catch (error) {
      console.error('❌ Tenderly simulation failed:', error);
      throw error;
    }

    return {
      data: { stateOverrides, stateChanges },
      extractedData,
      tenderlyResponse,
    };
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

    // Use the RPC URL from options
    const rpcUrl = options.rpcUrl;

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
  async cleanup(options: {
    upgradeId: string;
    network: string;
  }): Promise<void> {
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
