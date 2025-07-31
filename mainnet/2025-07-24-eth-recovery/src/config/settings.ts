import { ChainConfig } from '../types/index.js';

// ========== ETHERSCAN API CONFIGURATION ==========
export const ETHERSCAN_API = {
  BASE_URL: 'https://api.etherscan.io/api',
  PAGE_SIZE: 10000,
  RATE_LIMIT_DELAY: 200, // ms between requests (5 RPS)
  BATCH_SIZE: 5, // Process 5 addresses per batch
  DELAY_BETWEEN_BATCHES_MS: 1000, // 1 second = 5 calls per second
  MAX_RETRIES: 3,
  TIMEOUT: 30000 // 30 seconds
} as const;

// ========== NAUGHTY-LIST API CONFIGURATION ==========
export const NAUGHTY_LIST_API = {
  PRODUCTION_URL: 'https://naughty-list-query.cbhq.net:3000',
  DEVELOPMENT_URL: 'https://naughty-list-query-dev.cbhq.net:3000',
  ENDPOINT: '/entities',
  MAX_RETRIES: 3,
  TIMEOUT: 10000, // 10 seconds
  // 20 RPS rate limiting
  RATE_LIMIT_DELAY: 50, // ms between requests (20 RPS: 1000ms / 20 = 50ms) 
  BATCH_SIZE: 10 // Process addresses in batches for 20 RPS
} as const;

// ========== SUPPORTED BLOCKCHAIN NETWORKS ==========
export const SUPPORTED_CHAINS: Record<number, ChainConfig> = {
  42161: {
    chainId: 42161,
    name: 'Arbitrum One',
    startBlock: 111048844,
    endBlock: 337674580
  },
  10: {
    chainId: 10,
    name: 'Optimism',
    startBlock: 106836897,
    endBlock: 134080874
  },
  8453: {
    chainId: 8453,
    name: 'Base',
    startBlock: 1261624, 
    endBlock: 32988909
  }
};

// ========== DEFAULT VALUES ==========
export const DEFAULTS = {
  TARGET_ADDRESS: '0x49048044D57e1C92A77f79988d21Fa8fAF74E97e',
  CHAIN_ID: 42161
} as const;

// ========== HELPER FUNCTIONS ==========
export function getChainConfig(chainId: number): ChainConfig {
  const config = SUPPORTED_CHAINS[chainId];
  if (!config) {
    throw new Error(`Unsupported chain ID: ${chainId}. Supported chains: ${Object.keys(SUPPORTED_CHAINS).join(', ')}`);
  }
  return config;
}

export function getSupportedChainIds(): number[] {
  return Object.keys(SUPPORTED_CHAINS).map(Number);
}

export function getChainDefaults(chainId: number): { startBlock: number; endBlock: number } {
  const config = getChainConfig(chainId);
  return {
    startBlock: config.startBlock,
    endBlock: config.endBlock
  };
}

// Helper function to get chain directory name for output
export function getChainDirName(chainId: number): string {
  const config = getChainConfig(chainId);
  switch (chainId) {
    case 42161:
      return 'output/arbitrum';
    case 10:
      return 'output/optimism';
    case 8453:
      return 'output/base';
    default:
      return `output/${config.name.toLowerCase().replace(/\s+/g, '-')}`;
  }
} 