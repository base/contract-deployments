export interface Transaction {
  blockNumber: string;
  timeStamp: string;
  hash: string;
  nonce: string;
  blockHash: string;
  transactionIndex: string;
  from: string;
  to: string;
  value: string;
  gas: string;
  gasPrice: string;
  isError: string;
  txreceipt_status: string;
  input: string;
  contractAddress: string;
  cumulativeGasUsed: string;
  gasUsed: string;
  confirmations: string;
  methodId: string;
  functionName: string;
}

export interface ChainConfig {
  chainId: number;
  name: string;
  startBlock: number;
  endBlock: number;
}

export interface AddressResult {
  address: string;
  totalWei: string;
  category: 'CEX' | 'NOT_CEX' | 'NORMAL' | 'NAUGHTY';
  addressType: 'EOA' | 'CONTRACT';
  name?: string;
}

// Format expected by Solidity scripts (matches normal.json format)
export interface SolidityAddressInfo {
  address: string;
  totalWei: string;
  category: string;
  addressType: string;
}

export interface SolidityRecoveryFile {
  addresses: SolidityAddressInfo[];
} 