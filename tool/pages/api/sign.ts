import { NextApiRequest, NextApiResponse } from 'next';
import { LedgerSigner, LedgerSigningOptions } from '../../utils/ledger-signing';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { action, domainHash, messageHash, ledgerAccount, eip712signPath } = req.body as {
      action: 'get-address' | 'sign';
      domainHash?: string;
      messageHash?: string;
      ledgerAccount?: number;
      eip712signPath?: string;
    };

    // Validate required fields
    if (!action) {
      return res.status(400).json({
        error: 'Missing required field: action'
      });
    }

    console.log(`🔐 Starting Ledger ${action} operation`);

    // Initialize Ledger signer
    const ledgerSigner = new LedgerSigner(eip712signPath);

    // Check if eip712sign is available
    const isAvailable = await ledgerSigner.checkAvailability();
    if (!isAvailable) {
      return res.status(500).json({
        success: false,
        error: 'eip712sign binary not found. Please ensure it is installed and in your PATH or GOPATH/bin.'
      });
    }

    if (action === 'get-address') {
      // Get address from Ledger device
      const result = await ledgerSigner.getAddress(ledgerAccount || 0);

      if (result.success) {
        console.log(`✅ Successfully retrieved Ledger address: ${result.address}`);
        res.status(200).json({
          success: true,
          address: result.address
        });
      } else {
        console.error('❌ Failed to get Ledger address:', result.error);
        res.status(500).json({
          success: false,
          error: result.error
        });
      }
    } else if (action === 'sign') {
      // Validate signing parameters
      if (!domainHash || !messageHash) {
        return res.status(400).json({
          error: 'Missing required fields for signing: domainHash, messageHash'
        });
      }

      const signingOptions: LedgerSigningOptions = {
        domainHash,
        messageHash,
        ledgerAccount: ledgerAccount || 0
      };

      // Sign with Ledger device
      const result = await ledgerSigner.signDomainAndMessageHash(signingOptions);

      if (result.success) {
        console.log(`✅ Successfully signed with Ledger. Signer: ${result.signerAddress}`);
        res.status(200).json({
          success: true,
          signature: result.signature,
          signerAddress: result.signerAddress
        });
      } else {
        console.error('❌ Failed to sign with Ledger:', result.error);
        res.status(500).json({
          success: false,
          error: result.error
        });
      }
    } else {
      return res.status(400).json({
        error: 'Invalid action. Must be "get-address" or "sign"'
      });
    }

  } catch (error) {
    console.error('❌ Ledger signing API error:', error);

    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error occurred'
    });
  }
}

// Increase timeout for Ledger operations
export const config = {
  api: {
    externalResolver: true,
    responseLimit: false,
  },
};
