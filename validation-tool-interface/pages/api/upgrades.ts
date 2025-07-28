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

    const actualNetwork = (network as string).toLowerCase() as 'mainnet' | 'sepolia' | 'test';
    const ACCEPTED_NETWORKS = ['mainnet', 'sepolia', 'test'];

    if (!ACCEPTED_NETWORKS.includes(actualNetwork)) {
      return res
        .status(400)
        .json({ error: 'Invalid network parameter. Must be "mainnet", "sepolia", or "test"' });
    }
    const upgrades = getUpgradeOptions(actualNetwork);
    res.status(200).json(upgrades);
  } catch (error) {
    console.error('Error fetching upgrades:', error);
    res.status(500).json({ error: 'Failed to fetch upgrades' });
  }
}
