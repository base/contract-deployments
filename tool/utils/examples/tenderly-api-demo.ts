#!/usr/bin/env node

import 'dotenv/config'; // Load .env file
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { TenderlyClient } from '../tenderly.js';
import { ExtractedData } from '../types/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Demo showing real Tenderly API integration
 */
async function apiDemo() {
  console.log('🚀 Tenderly API Integration Demo\n');

  // Load test data
  const testDataPath = path.join(__dirname, 'run', 'test-script-output-extracted.json');
  if (!fs.existsSync(testDataPath)) {
    console.error('❌ Test data file not found. Please ensure test-script-output-extracted.json exists.');
    return;
  }

  // Load extracted data from the test script output (Ideally we should not have a seperate output file but this is for testing purposes)
  // We only need the Tenderly Link from extracted data
  const extractedData: ExtractedData = JSON.parse(fs.readFileSync(testDataPath, 'utf8'));

  if (!extractedData.simulationLink) {
    console.log('⚠️  No simulation link found in test data');
    return;
  }

  const simulationLink = extractedData.simulationLink;

  // Show basic simulation info
  console.log(`📤 Simulation Preview:`);
  console.log(`  Network: ${simulationLink.network}`);
  console.log(`  Contract: ${simulationLink.contractAddress}`);
  console.log(`  From: ${simulationLink.from}`);
  console.log(`  Raw Input Length: ${simulationLink.rawFunctionInput?.length || 0} characters`);
  console.log('');

  // Show state overrides summary
  if (simulationLink.stateOverrides) {
    const stateOverrides = JSON.parse(simulationLink.stateOverrides);
    console.log(`  State Overrides: ${stateOverrides.length} contracts`);
    stateOverrides.forEach((override: any, i: number) => {
      console.log(`    ${i + 1}. ${override.contractAddress} (${override.storage?.length || 0} storage slots)`);
    });
    console.log('');
  }

  const apiKey = process.env.TENDERLY_ACCESS;
  if (!apiKey) {
    console.log('⚠️  No Tenderly API key found');
    console.log('\n🔧 To run with real API calls:');
    console.log('1. Get your API key from: Tenderly');
    console.log('2. Set TENDERLY_ACCESS environment variable');
    console.log('\n💡 Example usage with API key:');
    console.log('TENDERLY_ACCESS=your_key npx tsx src/examples/tenderly-api-demo.ts');
    return;
  }

  try {
    const client = new TenderlyClient(apiKey);
    const result = await client.simulateFromExtractedData(extractedData);

    console.log(`\nSimulation:`);
    console.log(`  ID: ${result.simulation.id}`);
    console.log(`  Status: ${result.simulation.status ? '✅ Success' : '❌ Failed'}`);
    console.log(`  Gas Used: ${result.simulation.gas_used.toLocaleString()}`);
    console.log(`  Block Number: ${result.simulation.block_number}`);
    console.log('');

    if (result.simulation.error_message) {
      console.log(`  Error: ${result.simulation.error_message}`);
    }

    // Parse state overrides and state changes (just for testing purposes)
    const parsedStateOverrides = client.parseStateOverrides(simulationLink);
    const stateChanges = client.parseStateChanges(result);

    // Save results
    const resultsFile = path.join(__dirname, 'run', 'tenderly-api-results.json');
    fs.writeFileSync(resultsFile, JSON.stringify(result, null, 2));
    console.log(`\n💾 Results saved to: ${resultsFile}`);

  } catch (error) {
    console.error('❌ API call failed:', error instanceof Error ? error.message : String(error));

    if (error instanceof Error && error.message.includes('401')) {
      console.log('\n🔑 This looks like an authentication error. Please check your API key.');
    } else if (error instanceof Error && error.message.includes('400')) {
      console.log('\n📝 This looks like a request format error. The API request might need adjustment.');
    }
  }
}

// Run the demo
if (import.meta.url === `file://${process.argv[1]}`) {
  apiDemo().catch(console.error);
}
