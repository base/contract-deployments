import { NextApiRequest, NextApiResponse } from 'next';
import { ValidationService } from '../../utils/validation-service';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  try {
    const { upgradeId, network, userType, simulationMethod, tenderlyApiKey, userLedgerAddress } =
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
    const validationService = new ValidationService(tenderlyApiKey);

    // Run validation
    const validationResult = await validationService.validateUpgrade({
      upgradeId,
      network: actualNetwork,
      userType,
      simulationMethod,
      tenderlyApiKey,
      userLedgerAddress,
    });

    // Clean up temp files
    await validationService.cleanup({
      upgradeId,
      network: actualNetwork,
      userType,
      simulationMethod,
      tenderlyApiKey,
      userLedgerAddress,
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

// Increase timeout for script execution and Tenderly calls
export const config = {
  api: {
    externalResolver: true,
    responseLimit: false,
  },
};
