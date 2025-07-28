import { exec, spawn } from 'child_process';
import path from 'path';
import { promisify } from 'util';
import {
  ExtractedStateDiffOptions,
  StateChange,
  StateDiffResult,
  StateOverride,
} from './types/index';

const execAsync = promisify(exec);

export class StateDiffClient {
  private binaryPath: string;

  constructor(binaryPath?: string) {
    // Default to go-simulator directory relative to tool
    this.binaryPath = binaryPath || path.join(process.cwd(), '..', 'go-simulator');
    console.log(`🔧 StateDiffClient initialized with binary path: ${this.binaryPath}`);
  }

  /**
   * Simulate using pre-extracted data (new method)
   */
  async simulateWithExtractedData(options: ExtractedStateDiffOptions): Promise<{
    result: StateDiffResult;
    output: string;
  }> {
    const { rpcUrl, extractedData } = options;

    if (!extractedData.signingData || !extractedData.simulationLink) {
      throw new Error('Extracted data must contain signingData and simulationLink');
    }

    const args = [
      'run',
      '.',
      '--rpc',
      rpcUrl,
      '--format',
      'json',
      '--use-extracted',
      '--signing-data',
      extractedData.signingData.dataToSign,
      '--sender',
      extractedData.simulationLink.from,
    ];

    // Add optional parameters from parsed SimulationLink
    if (extractedData.simulationLink.network) {
      args.push('--network', extractedData.simulationLink.network);
    }
    if (extractedData.simulationLink.contractAddress) {
      args.push('--contract', extractedData.simulationLink.contractAddress);
    }
    if (extractedData.simulationLink.stateOverrides) {
      args.push('--state-overrides', extractedData.simulationLink.stateOverrides);
    }
    if (extractedData.simulationLink.rawFunctionInput) {
      args.push('--raw-input', extractedData.simulationLink.rawFunctionInput);
    }
    // Optionally include the full URL for reference/logging in Go
    if (extractedData.simulationLink.url) {
      args.push('--tenderly-link', extractedData.simulationLink.url);
    }

    console.log(`🔧 Executing state-diff with extracted data using spawn`);
    console.log(`📁 Working directory: ${this.binaryPath}`);
    console.log(`🔧 Command: go ${args.join(' ')}`);

    return new Promise((resolve, reject) => {
      const child = spawn('go', args, {
        cwd: this.binaryPath,
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      let stdout = '';
      let stderr = '';

      child.stdout.on('data', data => {
        stdout += data.toString();
      });

      child.stderr.on('data', data => {
        stderr += data.toString();
      });

      const timeout = setTimeout(() => {
        child.kill();
        reject(new Error('State-diff simulation timed out after 2 minutes'));
      }, 120000);

      child.on('close', code => {
        clearTimeout(timeout);

        if (code !== 0) {
          console.error('❌ State-diff simulation failed with exit code:', code);
          console.error('Stdout:', stdout);
          console.error('Stderr:', stderr);
          reject(new Error(`Command failed with exit code ${code}: ${stderr}`));
          return;
        }

        if (stderr) {
          // Don't throw on stderr, as Go might output logs there
          console.warn('⚠️ State-diff stderr:', stderr);
        }

        console.log(`✅ State-diff simulation completed with extracted data`);

        // Parse JSON output
        let result: StateDiffResult;
        try {
          result = JSON.parse(stdout);
        } catch (parseError) {
          console.error('❌ Failed to parse JSON output:', parseError);
          console.error('Raw output:', stdout);
          reject(new Error(`Failed to parse state-diff JSON output: ${parseError}`));
          return;
        }

        resolve({
          result,
          output: stdout,
        });
      });

      child.on('error', error => {
        clearTimeout(timeout);
        console.error('❌ State-diff process error:', error);
        reject(new Error(`State-diff simulation failed: ${error.message}`));
      });
    });
  }

  // Convert Go JSON format to TypeScript types (should already match)
  parseStateChanges(result: StateDiffResult): StateChange[] {
    return result.state_changes.map(change => ({
      name: change.name,
      address: change.address,
      changes: change.changes.map(c => ({
        key: c.key,
        before: c.before,
        after: c.after,
        description: c.description,
      })),
    }));
  }

  parseStateOverrides(result: StateDiffResult): StateOverride[] {
    return result.state_overrides.map(override => ({
      name: override.name,
      address: override.address,
      overrides: override.overrides.map(o => ({
        key: o.key,
        value: o.value,
        description: o.description,
      })),
    }));
  }

  /**
   * Get domain and message hashes from the result
   */
  getDomainAndMessageHashes(result: StateDiffResult): {
    address: string;
    domain_hash: string;
    message_hash: string;
  } {
    return {
      address: result.target_safe,
      domain_hash: result.domain_hash,
      message_hash: result.message_hash,
    };
  }

  /**
   * Check if the state-diff binary is available
   */
  async checkAvailability(): Promise<boolean> {
    try {
      const { stderr } = await execAsync('go version', {
        cwd: this.binaryPath,
        timeout: 5000,
      });
      return true;
    } catch (error) {
      console.warn('⚠️ Go not available or state-diff binary path incorrect');
      return false;
    }
  }
}
