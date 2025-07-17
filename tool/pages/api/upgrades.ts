import type { NextApiRequest, NextApiResponse } from 'next';
import { getUpgradeOptions, type DeploymentInfo } from '../../utils/deployments';

export default function handler(
  req: NextApiRequest,
  res: NextApiResponse<DeploymentInfo[] | { error: string }>
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { network } = req.query;

    if (
      !network ||
      (network !== 'mainnet' &&
        network !== 'Mainnet' &&
        network !== 'sepolia' &&
        network !== 'Sepolia' &&
        network !== 'test' &&
        network !== 'Test')
    ) {
      return res
        .status(400)
        .json({ error: 'Invalid network parameter. Must be "mainnet", "sepolia", or "test"' });
    }

    // Map frontend network names to directory names
    const networkMapping: Record<string, 'mainnet' | 'sepolia' | 'test'> = {
      mainnet: 'mainnet',
      Mainnet: 'mainnet',
      sepolia: 'sepolia',
      Sepolia: 'sepolia',
      test: 'test',
      Test: 'test',
    };

    const actualNetwork = networkMapping[network as string];
    const upgrades = getUpgradeOptions(actualNetwork);
    res.status(200).json(upgrades);
  } catch (error) {
    console.error('Error fetching upgrades:', error);
    res.status(500).json({ error: 'Failed to fetch upgrades' });
  }
}
