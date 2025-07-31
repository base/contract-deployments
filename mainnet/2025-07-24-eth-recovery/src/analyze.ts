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

async function saveResults(results: AddressResult[], chainId: number, targetAddress: string) {
  const chainDirName = getChainDirName(chainId);
  const chain = getChainConfig(chainId);
  
  // Calculate totals for all results
  const totalWeiAll = results.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthAll = (Number(totalWeiAll) / 1e18).toFixed(6);
  
  // Filter results by category
  const cex = results.filter(r => r.category === 'CEX');
  const notCex = results.filter(r => r.category === 'NOT_CEX' || r.category === 'NORMAL' || r.category === 'NAUGHTY');
  const normal = results.filter(r => r.category === 'NORMAL');
  const naughty = results.filter(r => r.category === 'NAUGHTY');
  
  // Calculate totals for each category
  const totalWeiCex = cex.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthCex = (Number(totalWeiCex) / 1e18).toFixed(6);
  const totalWeiNotCex = notCex.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthNotCex = (Number(totalWeiNotCex) / 1e18).toFixed(6);
  const totalWeiNormal = normal.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthNormal = (Number(totalWeiNormal) / 1e18).toFixed(6);
  const totalWeiNaughty = naughty.reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
  const totalEthNaughty = (Number(totalWeiNaughty) / 1e18).toFixed(6);
  
  // Calculate address type statistics
  const getAddressTypeStats = (addresses: AddressResult[]) => {
    const eoaCount = addresses.filter(r => r.addressType === 'EOA').length;
    const contractCount = addresses.filter(r => r.addressType === 'CONTRACT').length;
    const eoaWei = addresses.filter(r => r.addressType === 'EOA').reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
    const contractWei = addresses.filter(r => r.addressType === 'CONTRACT').reduce((sum, r) => sum + BigInt(r.totalWei), BigInt(0));
    return { eoaCount, contractCount, eoaWei, contractWei };
  };
  
  // Create output with summary including address type stats
  const createOutput = (category: string, addresses: AddressResult[], totalEth: string) => {
    const typeStats = getAddressTypeStats(addresses);
    return {
      summary: {
        targetAddress,
        chain: chain.name,
        chainId,
        category,
        totalWallets: addresses.length,
        totalEthReceived: totalEth,
        addressTypes: {
          eoa: {
            count: typeStats.eoaCount,
            totalEth: (Number(typeStats.eoaWei) / 1e18).toFixed(6)
          },
          contract: {
            count: typeStats.contractCount,
            totalEth: (Number(typeStats.contractWei) / 1e18).toFixed(6)
          }
        },
        generatedAt: new Date().toISOString()
      },
      addresses
    };
  };
  
  // Save main category results
  fs.writeFileSync(`${chainDirName}/cex.json`, 
    JSON.stringify(createOutput('CEX', cex, totalEthCex), null, 2));
    
  fs.writeFileSync(`${chainDirName}/not-cex.json`, 
    JSON.stringify(createOutput('Not CEX', notCex, totalEthNotCex), null, 2));
  
  // Save filtered results
  fs.writeFileSync(`${chainDirName}/normal.json`, 
    JSON.stringify(createOutput('Normal', normal, totalEthNormal), null, 2));
    
  fs.writeFileSync(`${chainDirName}/naughty.json`, 
    JSON.stringify(createOutput('Naughty', naughty, totalEthNaughty), null, 2));
  
  // Create Solidity-compatible recovery file (only normal addresses)
  const solidityAddresses: SolidityAddressInfo[] = normal.map(addr => ({
    address: addr.address,
    totalWei: addr.totalWei, // Keep as wei string
    category: addr.category,
    addressType: addr.addressType
  }));
  
  const recoveryFile: SolidityRecoveryFile = {
    addresses: solidityAddresses
  };
  
  fs.writeFileSync(`${chainDirName}/recovery_addresses.json`, 
    JSON.stringify(recoveryFile, null, 2));
  
  // Enhanced console output with address type breakdown
  const allStats = getAddressTypeStats(results);
  const cexStats = getAddressTypeStats(cex);
  const normalStats = getAddressTypeStats(normal);
  const naughtyStats = getAddressTypeStats(naughty);
  
  console.log(`\n💾 RESULTS SAVED`);
  console.log(`   📁 Location: ${chainDirName}/`);
  console.log(`   📊 Summary for ${chain.name}:`);
  console.log(`      • Total: ${results.length} addresses (${allStats.eoaCount} EOAs, ${allStats.contractCount} Contracts)`);
  console.log(`      • Total ETH: ${totalEthAll} ETH`);
  console.log(`      • 🏛️  CEX: ${cex.length} addresses (${totalEthCex} ETH)`);
  console.log(`      • 👥 Normal: ${normal.length} addresses (${totalEthNormal} ETH)`);
  console.log(`      • ⚠️  Naughty: ${naughty.length} addresses (${totalEthNaughty} ETH)`);
  console.log(`   📁 Files created:`);
  console.log(`      • cex.json - CEX addresses (excluded from recovery)`);
  console.log(`      • not-cex.json - All non-CEX addresses`);
  console.log(`      • normal.json - Normal addresses (analysis format)`);
  console.log(`      • naughty.json - Flagged addresses (excluded from recovery)`);
  console.log(`      • recovery_addresses.json - Solidity-compatible format for execution`);
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
    await saveResults(results, chainId, targetAddress);
    
    console.log(`\n✅ ANALYSIS COMPLETE`);
    
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
} 