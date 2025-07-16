import { Change, ExtractedData, SimulationLink, StateChange, StateOverride, TenderlySimulationRequest, TenderlySimulationResponse } from './types/index.js';

export class TenderlyClient {
  private apiKey: string;
  private baseUrl: string = 'https://api.tenderly.co/api/v1';
  private accountSlug: string;
  private projectSlug: string;

  constructor(apiKey: string, accountSlug: string = 'thanhtrinh', projectSlug: string = 'project') {
    this.apiKey = apiKey;
    this.accountSlug = accountSlug;
    this.projectSlug = projectSlug;

    if (!this.apiKey) {
      throw new Error('Tenderly API key is required. Set TENDERLY_ACCESS in .env file or pass it directly.');
    }
  }

  /**
   * Send simulation request to Tenderly API using extracted data
   */
  async simulateFromExtractedData(extractedData: ExtractedData): Promise<TenderlySimulationResponse> {
    const simulationLink = extractedData.simulationLink;

    if (!simulationLink) {
      throw new Error('No simulation link found in extracted data');
    }

    try {
      console.log(`🌐 Sending simulation request for: ${simulationLink.contractAddress}`);

      const simulationRequest = this.buildSimulationRequest(simulationLink);
      const response = await this.sendSimulationRequest(simulationRequest);

      console.log(`✅ Simulation completed successfully for: ${simulationLink.contractAddress}`);
      return response;
    } catch (error) {
      console.error(`❌ Simulation failed for ${simulationLink.contractAddress}:`, error);
      throw error;
    }
  }

  /**
   * Build Tenderly simulation request from simulation link data
   */
  private buildSimulationRequest(simulationLink: SimulationLink): TenderlySimulationRequest {
    const request: TenderlySimulationRequest = {
      network_id: simulationLink.network,
      from: simulationLink.from,
      to: simulationLink.contractAddress,
      input: simulationLink.rawFunctionInput || '0x',
      gas: 648318, // Default gas limit
      value: '0',
      save: true,
      save_if_fails: true,
      simulation_type: 'quick'
    };

    // Parse and add state objects if available
    if (simulationLink.stateOverrides) {
      try {
        const stateOverrides = JSON.parse(simulationLink.stateOverrides);
        const stateObjects: { [contractAddress: string]: any } = {};

                stateOverrides.forEach((override: any) => {
          const storage: any = {};
          override.storage?.forEach((storageItem: any) => {
            // Ensure storage key is properly formatted (32 bytes)
            const key = storageItem.key.startsWith('0x') ? storageItem.key : `0x${storageItem.key}`;
            const value = storageItem.value.startsWith('0x') ? storageItem.value : `0x${storageItem.value}`;
            storage[key] = value;
          });

          // Use the storage format directly as shown in the example
          stateObjects[override.contractAddress.toLowerCase()] = {
            storage
          };
        });

        request.state_objects = stateObjects;
      } catch (error) {
        console.warn('Failed to parse state overrides:', error);
      }
    }

    return request;
  }

  /**
   * Send simulation request to Tenderly API
   */
  private async sendSimulationRequest(request: TenderlySimulationRequest, timeout: number = 30000): Promise<TenderlySimulationResponse> {
    const url = `${this.baseUrl}/account/${this.accountSlug}/project/${this.projectSlug}/simulate`;

    // Setup timeout using AbortController
    const controller = new AbortController();
    const { signal } = controller;
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Access-Key': this.apiKey,
        },
        body: JSON.stringify(request),
        signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Tenderly API error (${response.status}): ${errorText}`);
      }

      return await response.json();
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error(`Tenderly API request timed out after ${timeout}ms`);
      }

      throw error;
    }
  }

  /**
   * Parse Tenderly simulation results into our StateChange format - optimized
   */
  parseStateChanges(simulationResponse: TenderlySimulationResponse): StateChange[] {
    // Try both possible property names (dashes and underscores)
    const stateDiff = simulationResponse?.transaction?.['transaction-info']?.call_trace?.state_diff ||
                     (simulationResponse?.transaction as any)?.transaction_info?.call_trace?.state_diff;

    if (!stateDiff?.length) {
      console.log('⚠️  No state changes found');
      return [];
    }

    console.log(`📊 Processing ${stateDiff.length} state changes...`);

    // Group changes by address efficiently
    const changesByAddress = new Map<string, Change[]>();

    for (const change of stateDiff) {
      const address = change.address.toLowerCase();
      const changeData: Change = {
        key: change.raw?.[0]?.key || change.soltype?.index || 'unknown',
        before: change.original || change.raw?.[0]?.original || '0x0',
        after: change.dirty || change.raw?.[0]?.dirty || '0x0',
        description: change.soltype?.name
          ? `${change.soltype.name} (${change.soltype.type}) changed`
          : 'Storage slot changed'
      };

      if (!changesByAddress.has(address)) {
        changesByAddress.set(address, []);
      }
      changesByAddress.get(address)!.push(changeData);
    }

    // Convert to StateChange format
    const result = Array.from(changesByAddress.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([address, changes]) => ({
        name: '',
        address,
        changes: changes.sort((a, b) => (a.key || '').localeCompare(b.key || ''))
      }));

    console.log(`✅ Parsed ${result.length} contracts with state changes`);

    // Log in StateChange format
    result.forEach((stateChange, index) => {
      console.log(`📦 StateChange[${index}]:`);
      console.log(`   name: "${stateChange.name}"`);
      console.log(`   address: "${stateChange.address}"`);
      console.log(`   changes: [`);

      stateChange.changes.forEach((change, changeIndex) => {
        console.log(`     {`);
        console.log(`       key: "${change.key}"`);
        console.log(`       before: "${change.before}"`);
        console.log(`       after: "${change.after}"`);
        console.log(`       description: "${change.description}"`);
        console.log(`     }${changeIndex < stateChange.changes.length - 1 ? ',' : ''}`);
      });

      console.log(`   ]`);
      console.log(`}`);
      console.log('');
    });

    return result;
  }

  /**
   * Parse state overrides from simulation link - optimized
   */
  parseStateOverrides(simulationLink: SimulationLink): StateOverride[] {
    if (!simulationLink.stateOverrides) return [];

    try {
      const overrides = JSON.parse(simulationLink.stateOverrides);

      console.log(`📊 Processing ${overrides.length} state override contracts...`);

      const result = overrides.map((override: any) => {
        const overrideItems = override.storage?.map((storage: any) => {
          return {
            key: storage.key,
            value: storage.value,
            description: `Storage override for slot ${storage.key}`
          };
        }) || [];

        return {
          name: '',
          address: override.contractAddress,
          overrides: overrideItems
        };
      });

      console.log(`✅ Parsed ${result.length} contracts with state overrides`);

      // Log in StateOverride format
      result.forEach((stateOverride: StateOverride, index: number) => {
        console.log(`📦 StateOverride[${index}]:`);
        console.log(`   name: "${stateOverride.name}"`);
        console.log(`   address: "${stateOverride.address}"`);
        console.log(`   overrides: [`);

        stateOverride.overrides.forEach((override: any, overrideIndex: number) => {
          console.log(`     {`);
          console.log(`       key: "${override.key}"`);
          console.log(`       value: "${override.value}"`);
          console.log(`       description: "${override.description}"`);
          console.log(`     }${overrideIndex < stateOverride.overrides.length - 1 ? ',' : ''}`);
        });

        console.log(`   ]`);
        console.log(`}`);
        console.log('');
      });

      return result;
    } catch (error) {
      console.warn('Failed to parse state overrides:', error);
      return [];
    }
  }
}
