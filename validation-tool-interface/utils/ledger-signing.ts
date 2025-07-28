import { spawn } from 'child_process';
import os from 'os';
import path from 'path';

export interface LedgerSigningOptions {
  domainHash: string;
  messageHash: string;
  hdPath?: string;
  ledgerAccount?: number;
}

export interface LedgerSigningResult {
  success: boolean;
  signature?: string;
  signerAddress?: string;
  error?: string;
}

export interface LedgerAddressResult {
  success: boolean;
  address?: string;
  error?: string;
}

export class LedgerSigner {
  private eip712signPath: string;

  constructor(eip712signPath?: string) {
    if (eip712signPath) {
      this.eip712signPath = eip712signPath;
    } else {
      // Try to find eip712sign in common locations
      const homeDir = os.homedir();
      const possiblePaths = [
        path.join(homeDir, 'go', 'bin', 'eip712sign'),
        '/usr/local/go/bin/eip712sign',
        '/usr/local/bin/eip712sign',
        'eip712sign' // fallback to PATH
      ];

      this.eip712signPath = possiblePaths[0]; // Default to ~/go/bin/eip712sign
    }
  }

  /**
   * Get the Ethereum address for a given HD path from Ledger device
   */
  async getAddress(ledgerAccount: number = 0): Promise<LedgerAddressResult> {
    const hdPath = `m/44'/60'/${ledgerAccount}'/0/0`;

    try {
      // Use the --address flag to get the address
      const result = await this.runEip712signCommand([
        '--ledger',
        '--hd-paths', hdPath,
        '--address'
      ]);

      if (result.success && result.output) {
        // The --address flag should output just the address
        const addressMatch = result.output.match(/(0x[a-fA-F0-9]{40})/);
        if (addressMatch) {
          return {
            success: true,
            address: addressMatch[1]
          };
        }

        // If no regex match, try to extract from any output containing an address
        const lines = result.output.split('\n');
        for (const line of lines) {
          const match = line.match(/(0x[a-fA-F0-9]{40})/);
          if (match) {
            return {
              success: true,
              address: match[1]
            };
          }
        }
      }

      // Handle specific error cases
      if (result.error) {
        let errorMessage = result.error;

        if (result.error.includes('reply lacks public key entry')) {
          errorMessage = 'Please unlock your Ledger device and open the Ethereum app';
        } else if (result.error.includes('no such file or directory')) {
          errorMessage = 'eip712sign binary not found. Please ensure it is installed and in your PATH or GOPATH/bin.';
        }

        return {
          success: false,
          error: errorMessage
        };
      }

      return {
        success: false,
        error: 'Could not extract address from Ledger device output'
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error getting Ledger address'
      };
    }
  }

  /**
   * Sign domain and message hash using Ledger device
   */
  async signDomainAndMessageHash(options: LedgerSigningOptions): Promise<LedgerSigningResult> {
    const { domainHash, messageHash, ledgerAccount = 0 } = options;
    const hdPath = options.hdPath || `m/44'/60'/${ledgerAccount}'/0/0`;

    try {
      // Validate input format
      if (!domainHash.startsWith('0x') || domainHash.length !== 66) {
        throw new Error('Invalid domain hash format');
      }
      if (!messageHash.startsWith('0x') || messageHash.length !== 66) {
        throw new Error('Invalid message hash format');
      }

      // Create EIP-712 formatted data to sign: 0x1901 + domain hash + message hash
      const dataToSign = `0x1901${domainHash.slice(2)}${messageHash.slice(2)}`;

      // Use eip712sign with --data flag to sign the data directly
      const result = await this.runEip712signCommand([
        '--ledger',
        '--hd-paths', hdPath,
        '--data', dataToSign
      ]);

      if (result.success && result.output) {
        // Parse the output to extract signature and signer address
        const signatureMatch = result.output.match(/Signature:\s*([a-fA-F0-9]+)/);
        const signerMatch = result.output.match(/Signer:\s*(0x[a-fA-F0-9]{40})/);

        if (signatureMatch && signerMatch) {
          return {
            success: true,
            signature: `0x${signatureMatch[1]}`,
            signerAddress: signerMatch[1]
          };
        }

        // Alternative parsing - look for any hex string that looks like a signature (130 chars)
        const altSignatureMatch = result.output.match(/(0x[a-fA-F0-9]{130})/);
        const altSignerMatch = result.output.match(/(0x[a-fA-F0-9]{40})/);

        if (altSignatureMatch && altSignerMatch) {
          return {
            success: true,
            signature: altSignatureMatch[1],
            signerAddress: altSignerMatch[1]
          };
        }
      }

      // Handle specific error cases
      if (result.error) {
        let errorMessage = result.error;

        if (result.error.includes('reply lacks public key entry')) {
          errorMessage = 'Please unlock your Ledger device and open the Ethereum app';
        } else if (result.error.includes('no such file or directory')) {
          errorMessage = 'eip712sign binary not found. Please ensure it is installed and in your PATH or GOPATH/bin.';
        } else if (result.error.includes('user denied')) {
          errorMessage = 'Transaction was denied on the Ledger device';
        }

        return {
          success: false,
          error: errorMessage
        };
      }

      return {
        success: false,
        error: `Could not extract signature from eip712sign output. Output was: ${result.output}`
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error during Ledger signing'
      };
    }
  }

  /**
   * Run eip712sign command with given arguments
   */
  private async runEip712signCommand(args: string[]): Promise<{
    success: boolean;
    output?: string;
    error?: string;
  }> {
    return new Promise((resolve) => {
      console.log(`Running: ${this.eip712signPath} ${args.join(' ')}`);

      const process = spawn(this.eip712signPath, args, {
        stdio: ['inherit', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', (code) => {
        console.log(`eip712sign exited with code ${code}`);
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);

        if (code === 0) {
          resolve({
            success: true,
            output: stdout
          });
        } else {
          resolve({
            success: false,
            error: stderr || `Process exited with code ${code}`
          });
        }
      });

      process.on('error', (error) => {
        console.error(`eip712sign process error:`, error);
        resolve({
          success: false,
          error: error.message
        });
      });
    });
  }

  /**
   * Check if eip712sign binary is available
   */
  async checkAvailability(): Promise<boolean> {
    try {
      console.log(`Checking eip712sign availability at: ${this.eip712signPath}`);
      const result = await this.runEip712signCommand(['--help']);
      console.log(`eip712sign availability check result: ${result.success}`);
      return result.success;
    } catch (error) {
      console.error(`eip712sign availability check failed:`, error);
      return false;
    }
  }
}
