import * as dotenv from 'dotenv';
import * as fs from 'fs';
import { Transaction, AddressResult, SolidityRecoveryFile, SolidityAddressInfo } from './types/index.js';
import { SUPPORTED_CHAINS, DEFAULTS, getChainConfig, NAUGHTY_LIST_API, ETHERSCAN_API, getChainDirName } from './config/settings.js';

dotenv.config();

async function fetchTransactions(chainId: number, targetAddress: string): Promise<Transaction[]> {
  const chain = SUPPORTED_CHAINS[chainId];
  if (!chain) throw new Error(`Unsupported chain: ${chainId}`);

  const apiKey = process.env.ETHERSCAN_API_KEY;
  if (!apiKey) throw new Error('Missing ETHERSCAN_API_KEY');

  const params = new URLSearchParams({
    chainid: chainId.toString(),
    module: 'account',
    action: 'txlist',
    address: targetAddress,
    startblock: chain.startBlock.toString(),
    endblock: chain.endBlock.toString(),
    page: '1',
    offset: '10000',
    sort: 'desc',
    apikey: apiKey
  });
  
  console.log(`\n📊 FETCHING TRANSACTIONS`);
  console.log(`   Block range: ${chain.startBlock} - ${chain.endBlock}`);

  const response = await fetch(`https://api.etherscan.io/v2/api?${params}`);
  const data = await response.json() as any;
  
  console.log(`   API Response: ${data.status === '1' ? '✅' : '❌'} ${data.message}`);
  console.log(`   Raw transactions found: ${data.result?.length || 0}`);
  
  if (data.status !== '1') {
    console.error('API Error:', data);
  }
  
  return data.result || [];
}

function loadKnownWallets() {
  const cex = JSON.parse(fs.readFileSync('src/config/cex-wallets.json', 'utf8')).wallets;
  const cexMap = new Map(cex.map((w: any) => [w.address.toLowerCase(), w.name]));
  
  return { cexMap };
}

async function checkNaughtyList(addresses: string[]): Promise<Set<string>> {
  const naughtyAddresses = new Set<string>();
  
  const apiKey = process.env.NAUGHTY_LIST_API_KEY;
  if (!apiKey) {
    console.warn('NAUGHTY_LIST_API_KEY not provided, skipping naughty-list check');
    return naughtyAddresses;
  }

  const isDevelopment = process.env.NODE_ENV === 'development';
  const baseUrl = isDevelopment ? NAUGHTY_LIST_API.DEVELOPMENT_URL : NAUGHTY_LIST_API.PRODUCTION_URL;
  const apiUrl = `${baseUrl}${NAUGHTY_LIST_API.ENDPOINT}`;
  
  const batchSize = NAUGHTY_LIST_API.BATCH_SIZE;
  const delay = NAUGHTY_LIST_API.RATE_LIMIT_DELAY;
  
  console.log(`\n🚨 CHECKING NAUGHTY-LIST`);
  console.log(`   Addresses to check: ${addresses.length}`);
  console.log(`   Endpoint: ${isDevelopment ? '🛠️  Development' : '🏭 Production'} (${baseUrl})`);
  console.log(`   Rate limit: ${Math.round(1000 / delay)} calls/second`);
  let shouldAbort = false;
  
  for (let i = 0; i < addresses.length && !shouldAbort; i += batchSize) {
    const batch = addresses.slice(i, i + batchSize);
    const batchNumber = Math.floor(i / batchSize) + 1;
    const totalBatches = Math.ceil(addresses.length / batchSize);
    
    console.log(`   📦 Batch ${batchNumber}/${totalBatches} (${batch.length} addresses)`);
    
    const promises = batch.map(async (address) => {
      for (let retry = 0; retry < NAUGHTY_LIST_API.MAX_RETRIES; retry++) {
        try {
          const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey
            },
            body: JSON.stringify({ address }),
            signal: AbortSignal.timeout(NAUGHTY_LIST_API.TIMEOUT)
          });
          
          if (response.status === 200) {
            const data = await response.json();
            if (Array.isArray(data) && data.length > 0) {
              naughtyAddresses.add(address.toLowerCase());
              console.log(`      ⚠️  NAUGHTY: ${address}`);
            }
            return;
          } else if (response.status === 404) {
            return;
          } else {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
          }
        } catch (error) {
          const isLastRetry = retry === NAUGHTY_LIST_API.MAX_RETRIES - 1;
          console.error(`      ❌ ${address} (attempt ${retry + 1}/${NAUGHTY_LIST_API.MAX_RETRIES}): ${error instanceof Error ? error.message : error}`);
            
          if (isLastRetry) {
            console.error(`      🚫 ABORTING: ${address} failed after ${NAUGHTY_LIST_API.MAX_RETRIES} attempts`);
            shouldAbort = true;
            return;
          } else {
            await new Promise(resolve => setTimeout(resolve, delay * (retry + 1)));
          }
        }
      }
    });
    
    await Promise.all(promises);
    
    if (shouldAbort) {
      console.warn(`   🛑 Aborted: Continuing with ${naughtyAddresses.size} addresses already checked`);
      break;
    }
    
    if (i + batchSize < addresses.length) {
      console.log(`   ⏱️  Waiting ${delay}ms before next batch...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  if (!shouldAbort) {
    console.log(`   ✅ Complete: ${naughtyAddresses.size}/${addresses.length} addresses flagged`);
  }
  return naughtyAddresses;
}

async function checkAddressType(address: string, chainId: number): Promise<'EOA' | 'CONTRACT'> {
  const chain = SUPPORTED_CHAINS[chainId];
  if (!chain) return 'EOA';
  
  const apiKey = process.env.ETHERSCAN_API_KEY;
  if (!apiKey) return 'EOA';
  
  try {
    const url = `https://api.etherscan.io/v2/api?chainid=${chainId}&module=proxy&action=eth_getCode&address=${address}&tag=latest&apikey=${apiKey}`;
    
    const response = await fetch(url);
    const data = await response.json() as any;
    
    if (data.result !== undefined) {
      return data.result === '0x' || data.result === '' ? 'EOA' : 'CONTRACT';
    }
  } catch (error) {
    console.error(`Error checking address type for ${address}:`, error);
  }
  
  return 'EOA';
}

async function checkAddressTypes(addresses: string[], chainId: number): Promise<Map<string, 'EOA' | 'CONTRACT'>> {
  const addressTypeMap = new Map<string, 'EOA' | 'CONTRACT'>();
  
  console.log(`\n🔍 CHECKING ADDRESS TYPES`);
  console.log(`   Addresses to check: ${addresses.length}`);
  console.log(`   Rate limit: 5 calls/second (Etherscan API limits)`);
  
  const batchSize = ETHERSCAN_API.BATCH_SIZE;
  const delayBetweenBatches = ETHERSCAN_API.DELAY_BETWEEN_BATCHES_MS;
  
  for (let i = 0; i < addresses.length; i += batchSize) {
    const batch = addresses.slice(i, i + batchSize);
    const batchNumber = Math.floor(i / batchSize) + 1;
    const totalBatches = Math.ceil(addresses.length / batchSize);
    
    console.log(`   📦 Batch ${batchNumber}/${totalBatches} (${batch.length} addresses)`);
    
    const promises = batch.map(async (address) => {
      const type = await checkAddressType(address, chainId);
      addressTypeMap.set(address.toLowerCase(), type);
    });
    
    await Promise.all(promises);
    
    if (i + batchSize < addresses.length) {
      console.log(`   ⏱️  Waiting ${delayBetweenBatches}ms before next batch...`);
      await new Promise(resolve => setTimeout(resolve, delayBetweenBatches));
    }
  }
  
  const eoaCount = Array.from(addressTypeMap.values()).filter(type => type === 'EOA').length;
  const contractCount = Array.from(addressTypeMap.values()).filter(type => type === 'CONTRACT').length;
  console.log(`   ✅ Complete: ${eoaCount} EOAs, ${contractCount} Contracts`);
  
  return addressTypeMap;
}

async function processTransactions(transactions: Transaction[], targetAddress: string, chainId: number): Promise<AddressResult[]> {
  const { cexMap } = loadKnownWallets();
  const senderMap = new Map<string, { totalValue: bigint; txCount: number }>();

  for (const tx of transactions) {
    if (tx.value === '0') continue;
    if (tx.isError !== '0') continue;
    if (tx.to.toLowerCase() !== targetAddress.toLowerCase()) continue;
    
    const sender = tx.from.toLowerCase();
    const value = BigInt(tx.value);
    
    if (senderMap.has(sender)) {
      const existing = senderMap.get(sender)!;
      existing.totalValue += value;
      existing.txCount++;
    } else {
      senderMap.set(sender, { totalValue: value, txCount: 1 });
    }
  }

  const allAddresses = Array.from(senderMap.keys());
  const addressTypeMap = await checkAddressTypes(allAddresses, chainId);

  const results: AddressResult[] = [];
  for (const [address, data] of senderMap) {
    const totalWei = data.totalValue.toString();
    
    let category: 'CEX' | 'NOT_CEX' = 'NOT_CEX';
    let name: string | undefined;
    
    if (cexMap.has(address)) {
      category = 'CEX';
      name = cexMap.get(address) as string;
    }
    
    const addressType = addressTypeMap.get(address) || 'EOA';
    
    const result: AddressResult = { address, totalWei, category, addressType };
    if (name) result.name = name;
    results.push(result);
  }

  const sortedResults = results.sort((a, b) => {
    const aWei = BigInt(a.totalWei);
    const bWei = BigInt(b.totalWei);
    if (aWei > bWei) return -1;
    if (aWei < bWei) return 1;
    return 0;
  });
  
  const notCexResults = sortedResults.filter(r => r.category === 'NOT_CEX');
  const notCexAddresses = notCexResults.map(r => r.address);
  const naughtyAddresses = await checkNaughtyList(notCexAddresses);
  
  for (const result of sortedResults) {
    if (result.category === 'NOT_CEX') {
      if (naughtyAddresses.has(result.address.toLowerCase())) {
        result.category = 'NAUGHTY';
      } else {
        result.category = 'NORMAL';
      }
    }
  }

  return sortedResults;
}

async function saveResults(results: AddressResult[], chainId: number) {
  const chainDirName = getChainDirName(chainId);
  const chain = getChainConfig(chainId);
  
  // Filter to only include NORMAL addresses (exclude CEX and NAUGHTY)
  const normalAddresses = results.filter(r => r.category === 'NORMAL');
  
  // Convert to Solidity format
  const solidityAddresses: SolidityAddressInfo[] = normalAddresses.map(addr => ({
    refund_address: addr.address,
    category: addr.category,
    total_eth: addr.totalWei // Keep as wei string
  }));
  
  const recoveryFile: SolidityRecoveryFile = {
    addresses: solidityAddresses
  };
  
  // Save to chain-specific directory
  const outputPath = `${chainDirName}/recovery_addresses.json`;
  fs.writeFileSync(outputPath, JSON.stringify(recoveryFile, null, 2));
  
  // Calculate totals
  const totalWeiNormal = normalAddresses.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthNormal = (Number(totalWeiNormal) / 1e18).toFixed(6);
  
  const cexCount = results.filter(r => r.category === 'CEX').length;
  const naughtyCount = results.filter(r => r.category === 'NAUGHTY').length;
  
  console.log(`\n💾 RESULTS SAVED`);
  console.log(`   📁 Location: ${outputPath}`);
  console.log(`   📊 Summary for ${chain.name}:`);
  console.log(`      • Total analyzed: ${results.length} addresses`);
  console.log(`      • 🏛️  CEX (excluded): ${cexCount} addresses`);
  console.log(`      • ⚠️  Naughty (excluded): ${naughtyCount} addresses`);
  console.log(`      • ✅ Normal (included): ${normalAddresses.length} addresses`);
  console.log(`      • 💰 ETH to recover: ${totalEthNormal} ETH`);
}

async function main() {
  const args = process.argv.slice(2);
  
  if (args.length !== 1) {
    console.log('Usage:');
    console.log('  npx tsx src/analyze.ts <chainId>');
    console.log('');
    console.log('Supported chains:');
    Object.entries(SUPPORTED_CHAINS).forEach(([id, chain]) => {
      console.log(`  ${id}: ${chain.name}`);
    });
    process.exit(1);
  }
  
  const chainId = parseInt(args[0]);
  const targetAddress = DEFAULTS.TARGET_ADDRESS;
  
  if (!SUPPORTED_CHAINS[chainId]) {
    console.error(`Invalid chain ID: ${chainId}`);
    console.log('Supported chains:');
    Object.entries(SUPPORTED_CHAINS).forEach(([id, chain]) => {
      console.log(`  ${id}: ${chain.name}`);
    });
    process.exit(1);
  }
  
  if (!targetAddress.startsWith('0x') || targetAddress.length !== 42) {
    console.error(`Invalid target address format: ${targetAddress}`);
    process.exit(1);
  }
  
  try {
    console.log(`\n🚀 STARTING ANALYSIS`);
    console.log(`   🎯 Target Address: ${targetAddress}`);
    console.log(`   ⛓️  Chain: ${SUPPORTED_CHAINS[chainId].name} (${chainId})`);
    
    const transactions = await fetchTransactions(chainId, targetAddress);
    console.log(`   📋 Filtered transactions: ${transactions.length}`);
    
    if (transactions.length === 0) {
      console.log(`   ⏭️  No transactions found, creating empty recovery file...`);
      const chainDirName = getChainDirName(chainId);
      const recoveryFile: SolidityRecoveryFile = { addresses: [] };
      fs.writeFileSync(`${chainDirName}/recovery_addresses.json`, JSON.stringify(recoveryFile, null, 2));
      return;
    }
    
    const results = await processTransactions(transactions, targetAddress, chainId);
    await saveResults(results, chainId);
    
    console.log(`\n✅ ANALYSIS COMPLETE`);
    
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
} 