// Simple standalone demo for testing the improved state-diff approach
// This demonstrates the new clean architecture without URL parsing in Go

import { spawn } from 'child_process';
import { ExtractedData } from '../types';

async function testStateDiffWithExtractedData() {
  console.log('🚀 Testing State Diff Simulation with Pre-extracted Data\n');

  // Sample extracted data that would come from script-extractor
  const extractedData: ExtractedData = {
    nestedHashes: [
      {
        safeAddress: '0x847B5c174615B1B7fDF770882256e2D3E95b9D92',
        hash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      }
    ],
    simulationLink: {
      url: 'https://dashboard.tenderly.co/shared/simulation/some-simulation-id',
      network: '1',
      contractAddress: '0x847B5c174615B1B7fDF770882256e2D3E95b9D92',
      from: '0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A',
      stateOverrides: JSON.stringify({
        '0x847B5c174615B1B7fDF770882256e2D3E95b9D92': {
          stateDiff: {
            '0x0000000000000000000000000000000000000000000000000000000000000004': '0x0000000000000000000000000000000000000000000000000000000000000001'
          }
        }
      }),
      rawFunctionInput: '0xa0e67e2b000000000000000000000000542ba1902374a1aa1a7b1d6b1b89ce59d6d37ad100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000240481dec80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a000000000000000000000000542ba1902374a1aa1a7b1d6b1b89ce59d6d37a010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
    },
    signingData: {
      dataToSign: '0x1901477ce1b7e4c150558616ee49c9d7e71a98983476ab2090be6e4c53b6ce29b0e66bff2d47604090e1d7c2ad3b6a8bef9b4675e1e4c74e8e8e8e8e8e8e8e8e8e00'
    }
  };

  console.log('📊 Testing the actual Go implementation...\n');

  // Build the Go command arguments
  const args = [
          'run', '.',
    '--rpc', 'https://eth-mainnet.public.blastapi.io', // Use a working public RPC
    '--format', 'json',
    '--use-extracted',
    '--signing-data', extractedData.signingData!.dataToSign,
    '--sender', extractedData.simulationLink!.from
  ];

  // Add optional parameters
  if (extractedData.simulationLink!.network) {
    args.push('--network', extractedData.simulationLink!.network);
  }
  if (extractedData.simulationLink!.contractAddress) {
    args.push('--contract', extractedData.simulationLink!.contractAddress);
  }
  if (extractedData.simulationLink!.stateOverrides) {
    args.push('--state-overrides', extractedData.simulationLink!.stateOverrides);
  }
  if (extractedData.simulationLink!.rawFunctionInput) {
    args.push('--raw-input', extractedData.simulationLink!.rawFunctionInput);
  }
  if (extractedData.simulationLink!.url) {
    args.push('--tenderly-link', extractedData.simulationLink!.url);
  }

  console.log('🔧 Executing Go command:');
  console.log(`   go ${args.join(' ')}`);
  console.log('');

  // Actually run the Go command
  const goSimulatorPath = '../../../go-simulator';

  return new Promise((resolve, reject) => {
    const child = spawn('go', args, {
      cwd: goSimulatorPath,
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    const timeout = setTimeout(() => {
      child.kill();
      reject(new Error('Command timed out after 60 seconds'));
    }, 60000);

    child.on('close', (code) => {
      clearTimeout(timeout);

      console.log(`📋 Command completed with exit code: ${code}`);

      if (stdout) {
        console.log('📤 STDOUT:');
        console.log(stdout);
      }

      if (stderr) {
        console.log('⚠️ STDERR:');
        console.log(stderr);
      }

      if (code === 0) {
        console.log('✅ SUCCESS: Go command executed successfully!');

        // Try to parse JSON output
        try {
          const result = JSON.parse(stdout);
          console.log('📊 Parsed JSON result:');
          console.log(JSON.stringify(result, null, 2));
        } catch (parseError) {
          console.log('⚠️ Could not parse output as JSON, but command succeeded');
        }
      } else {
        console.log(`❌ FAILED: Go command failed with exit code ${code}`);
      }

      resolve(code);
    });

    child.on('error', (error) => {
      clearTimeout(timeout);
      console.error('❌ Process error:', error);
      reject(error);
    });
  });
}

// Run the actual test
testStateDiffWithExtractedData()
  .then((exitCode) => {
    console.log('\n🎯 Test completed!');
    console.log(`   Exit code: ${exitCode}`);
    if (exitCode === 0) {
      console.log('✅ Our improved implementation works!');
    } else {
      console.log('❌ Implementation needs debugging');
    }
  })
  .catch((error) => {
    console.error('❌ Test failed:', error);
    console.log('\n🔧 Troubleshooting steps:');
    console.log('1. Make sure go-simulator is built: cd ../../../go-simulator && make build');
    console.log('2. Verify Go is installed and in PATH');
    console.log('3. Check that the RPC URL is accessible');
    console.log('4. Ensure the signing data format is correct');
  });
