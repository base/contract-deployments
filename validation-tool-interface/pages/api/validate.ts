import { NextApiRequest, NextApiResponse } from 'next';
import { ValidationService } from '../../utils/validation-service';
import fs from 'fs';
import path from 'path';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  try {
    const { upgradeId, network, userType, simulationMethod, userLedgerAddress } =
      req.body;

    if (!upgradeId || !network || !userType) {
      return res.status(400).json({
        message: 'Missing required parameters: upgradeId, network, and userType are required',
      });
    }

    if (!userLedgerAddress) {
      return res.status(400).json({
        message: 'Missing userLedgerAddress parameter',
      });
    }

    const actualNetwork = network.toLowerCase();

    console.log(
      `🔍 Starting validation for ${upgradeId} on ${actualNetwork} for ${userType} using ${simulationMethod} with ledger address ${userLedgerAddress}`
    );

    // Initialize ValidationService
    const validationService = new ValidationService();

    // Getting config info to get rpcType
    const configInfo = await validationService.getConfigInfo({
      upgradeId,
      network: actualNetwork,
      userType,
    });

    const rpcUrl = getRpcUrl(actualNetwork, configInfo.rpcType);

    // Run validation with the RPC URL
    const validationResult = await validationService.validateUpgrade({
      upgradeId,
      network: actualNetwork,
      userType,
      simulationMethod,
      userLedgerAddress,
      rpcUrl, // Now we pass the RPC URL
    });

    // Clean up temp files
    await validationService.cleanup({
      upgradeId,
      network: actualNetwork,
      userType,
      simulationMethod,
      userLedgerAddress,
      rpcUrl, // Add rpcUrl to cleanup too
    });

    res.status(200).json({
      success: true,
      data: validationResult,
    });
  } catch (error) {
    console.error('Validation failed:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Validation failed',
    });
  }
}

/**
 * Read RPC URL from network-specific .env file
 */
function getRpcUrl(network: string, rpcType: string): string {
  let envPath: string;
  let envLocation: string;

  if (network === 'test') {
    // Handle test network specially - read from validation-tool-interface/test-upgrade/.env
    envPath = path.join(process.cwd(), 'test-upgrade', '.env');
    envLocation = 'test-upgrade';
  } else {
    // For mainnet/sepolia - read from ../network/.env
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    envPath = path.join(contractDeploymentsPath, network, '.env');
    envLocation = network;
  }

  if (!fs.existsSync(envPath)) {
    throw new Error(`❌ .env file not found: ${envPath}`);
  }

  try {
    const envContent = fs.readFileSync(envPath, 'utf-8');
    const match = envContent.match(new RegExp(`^${rpcType}=(.*)$`, 'm'));
    if (match && match[1]) {
      const rpcUrl = match[1].trim().replace(/^["']|["']$/g, '');
      console.log(`📡 Using ${rpcType} from ${envLocation}/.env file: ${rpcUrl}`);
      return rpcUrl;
    }
  } catch (error) {
    throw new Error(`❌ Failed to read .env file: ${error}`);
  }

  throw new Error(`❌ RPC URL '${rpcType}' not found in ${envLocation}/.env file`);
}

// Increase timeout for script execution and Tenderly calls
export const config = {
  api: {
    externalResolver: true,
    responseLimit: false,
  },
};
