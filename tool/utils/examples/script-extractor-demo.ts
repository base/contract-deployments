#!/usr/bin/env node

import path from 'path';
import { fileURLToPath } from 'url';
import { runAndExtract } from '../script-extractor.js';

// Get the directory name of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Test the script runner with your actual command
 */
async function testScriptRunner() {
  console.log('🧪 Testing Foundry Script Runner\n');

  // Your actual command parameters
  const options = {
    scriptPath: path.resolve(
      __dirname,
      '../../../sepolia/2025-06-04-upgrade-system-config'
    ),
    rpcUrl: 'https://sepolia.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul',
    scriptName: 'UpgradeSystemConfigScript',
    signature: 'sign(address[])',
    args: [
      '["0x6AF0674791925f767060Dd52f7fB20984E8639d8","0x646132A1667ca7aD00d36616AFBA1A28116C770A"]',
    ],
    sender: '0xb2d9a52e76841279EF0372c534C539a4f68f8C0B',
    saveOutput: path.join(__dirname, 'run', 'test-script-output.txt'), // Save in examples/run/
  };

  try {
    console.log('📋 Running with options:');
    console.log(JSON.stringify(options, null, 2));
    console.log('');

    const extractedData = await runAndExtract(options);

    console.log('🎉 Script completed successfully!');
    console.log('📊 Summary:');
    console.log(`• Found ${extractedData.nestedHashes.length} nested hashes`);
    console.log(`• Found ${extractedData.simulationLink ? '1' : '0'} simulation link`);
    console.log(`• Found ${extractedData.approvalHash ? '1' : '0'} approval hash`);
    console.log(`• Found ${extractedData.signingData ? '1' : '0'} signing data entry`);
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
}

// Test with extract-only mode using existing output
async function testExtractOnly() {
  console.log('🧪 Testing Extract-Only Mode\n');

  // Create some sample output to test with
  const sampleOutput = `
== Logs ==
Nested hash for safe 0x6AF0674791925f767060Dd52f7fB20984E8639d8:
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

Nested hash for safe 0x646132A1667ca7aD00d36616AFBA1A28116C770A:
  0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890

Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=11155111&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

If submitting onchain, call Safe.approveHash on 0x6AF0674791925f767060Dd52f7fB20984E8639d8 with the following hash:
  0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba

Data to sign:
  vvvvvvvv
  0xdeadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef
  ^^^^^^^^
  `;

  // Save sample output to file
  const fs = await import('fs');
  const sampleOutputPath = path.join(__dirname, 'run', 'sample-output.txt');
  fs.writeFileSync(sampleOutputPath, sampleOutput);

  const options = {
    scriptPath: '', // Not needed for extract-only
    rpcUrl: '', // Not needed for extract-only
    scriptName: '', // Not needed for extract-only
    saveOutput: sampleOutputPath,
    extractOnly: true,
  };

  try {
    console.log('📋 Testing extract-only mode with sample data...\n');
    await runAndExtract(options);
    console.log('🎉 Extract-only test completed successfully!');
  } catch (error) {
    console.error('❌ Extract-only test failed:', error);
    process.exit(1);
  } finally {
    // Clean up
    fs.unlinkSync(sampleOutputPath);
    const extractedPath = sampleOutputPath.replace(/\.[^/.]+$/, '') + '-extracted.json';
    if (fs.existsSync(extractedPath)) {
      fs.unlinkSync(extractedPath);
    }
  }
}

// Run the appropriate test based on command line args
async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--extract-only')) {
    await testExtractOnly();
  } else if (args.includes('--help')) {
    console.log(`
🧪 Test Script Runner

Usage:
  npx tsx test-script-runner.ts [options]

Options:
  --extract-only    Test extract-only mode with sample data
  --help           Show this help message

Examples:
  # Test full script execution (requires valid script path)
  npx tsx test-script-runner.ts

  # Test extract-only mode with sample data
  npx tsx test-script-runner.ts --extract-only
`);
  } else {
    await testScriptRunner();
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
