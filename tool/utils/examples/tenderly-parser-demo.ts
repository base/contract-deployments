#!/usr/bin/env node

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { TenderlyClient } from '../tenderly.js';
import { ExtractedData, TenderlySimulationResponse } from '../types/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Concise test for Tenderly parsing methods
 */
async function testParsing() {
  console.log('🧪 Testing Tenderly Parsing Methods\n');

  const client = new TenderlyClient('dummy-key');
  const runDir = path.join(__dirname, 'run');

  // Test both methods in sequence
  await testStateOverrides(client, runDir);
  await testStateChanges(client, runDir);

  console.log('\n✅ Tests completed!');
}

/**
 * Test parseStateOverrides with real data
 */
async function testStateOverrides(client: TenderlyClient, runDir: string) {
  console.log('🔧 Testing parseStateOverrides');

  const extractedData = loadJsonFile<ExtractedData>(runDir, 'test-script-output-extracted.json');
  if (!extractedData?.simulationLink) {
    console.log('❌ No simulation link found');
    return;
  }

  const overrides = client.parseStateOverrides(extractedData.simulationLink);
}

/**
 * Test parseStateChanges with real Tenderly response
 */
async function testStateChanges(client: TenderlyClient, runDir: string) {
  console.log('\n🔍 Testing parseStateChanges');

  const apiResults = loadJsonFile<TenderlySimulationResponse>(runDir, 'tenderly-api-results.json');
  if (!apiResults) return;

  const changes = client.parseStateChanges(apiResults);
}

/**
 * Generic JSON file loader with error handling
 */
function loadJsonFile<T>(dir: string, filename: string): T | null {
  const filepath = path.join(dir, filename);

  if (!fs.existsSync(filepath)) {
    console.log(`❌ ${filename} not found`);
    return null;
  }

  try {
    return JSON.parse(fs.readFileSync(filepath, 'utf8'));
  } catch (error) {
    console.log(`❌ Failed to parse ${filename}:`, error);
    return null;
  }
}

// Run the test
if (import.meta.url === `file://${process.argv[1]}`) {
  testParsing().catch(console.error);
}
