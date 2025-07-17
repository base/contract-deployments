import { jest } from '@jest/globals';
import { execSync } from 'child_process';
import { runAndExtract } from '../../utils/script-extractor';

// Mock dependencies with explicit module mocking
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
  writeFileSync: jest.fn(),
  default: {
    existsSync: jest.fn(),
    readFileSync: jest.fn(),
    writeFileSync: jest.fn(),
  }
}));

jest.mock('child_process', () => ({
  execSync: jest.fn(),
}));

describe('script-extractor', () => {
  let mockedFs: any;
  let mockedExecSync: jest.MockedFunction<typeof execSync>;

  beforeEach(async () => {
    // Import mocked modules inside async beforeEach
    const fs = await import('fs');
    mockedFs = {
      existsSync: fs.default.existsSync as jest.MockedFunction<typeof fs.default.existsSync>,
      readFileSync: fs.default.readFileSync as jest.MockedFunction<typeof fs.default.readFileSync>,
      writeFileSync: fs.default.writeFileSync as jest.MockedFunction<typeof fs.default.writeFileSync>,
    };

    mockedExecSync = execSync as jest.MockedFunction<typeof execSync>;

    // Reset mocks
    jest.clearAllMocks();

    // Mock console methods to avoid cluttering test output
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Mock process.chdir and process.cwd
    jest.spyOn(process, 'chdir').mockImplementation(() => {});
    jest.spyOn(process, 'cwd').mockReturnValue('/mock/cwd');

    // Mock process.exit
    jest.spyOn(process, 'exit').mockImplementation(() => undefined as never);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('extractFromOutput', () => {
    it('should extract multiple nested hashes', async () => {
      const sampleOutput = `
== Logs ==
Nested hash for safe 0x6AF0674791925f767060Dd52f7fB20984E8639d8: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

Nested hash for safe 0x646132A1667ca7aD00d36616AFBA1A28116C770A: 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890

Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=11155111&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

If submitting onchain, call Safe.approveHash on 0x6AF0674791925f767060Dd52f7fB20984E8639d8 with the following hash: 0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba

Data to sign:
  vvvvvvvv
  0xdeadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef
  ^^^^^^^^
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.nestedHashes).toHaveLength(2);
      expect(result.nestedHashes[0]).toEqual({
        safeAddress: '0x6AF0674791925f767060Dd52f7fB20984E8639d8',
        hash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      });
      expect(result.nestedHashes[1]).toEqual({
        safeAddress: '0x646132A1667ca7aD00d36616AFBA1A28116C770A',
        hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      expect(link.network).toBe('11155111');
      expect(link.contractAddress).toBe('0xcA11bde05977b3631167028862bE2a173976CA11');
      expect(link.from).toBe('0xb2d9a52e76841279EF0372c534C539a4f68f8C0B');

      expect(result.approvalHash).toBeTruthy();
      expect(result.approvalHash).toEqual({
        safeAddress: '0x6AF0674791925f767060Dd52f7fB20984E8639d8',
        hash: '0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba',
      });

      expect(result.signingData).toBeTruthy();
      expect(result.signingData).toEqual({
        dataToSign: '0xdeadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef',
      });
    });

    it('should extract simulation link with state overrides and raw function input', async () => {
      const stateOverrides = encodeURIComponent(JSON.stringify([
        {
          contractAddress: '0x1234567890123456789012345678901234567890',
          storage: [
            { key: '0x0000000000000000000000000000000000000000000000000000000000000000', value: '0x0000000000000000000000000000000000000000000000000000000000000001' }
          ]
        }
      ]));

      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=base-mainnet&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B&stateOverrides=${stateOverrides}&rawFunctionInput=0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      expect(link.network).toBe('base-mainnet');
      expect(link.stateOverrides).toBeTruthy();
      expect(link.rawFunctionInput).toBe('0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020');
    });

    it('should handle separated raw input data (edge case)', async () => {
      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=base-mainnet&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

Insert the following hex into the 'Raw input data' field:
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000014536667cd30e52c0b458baaccb9fada7046e056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000e246a761202000000000000000000000000ca11bde05977b3631167028862be2a173976ca11
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      expect(link.network).toBe('base-mainnet');
      expect(link.rawFunctionInput).toBe('0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000014536667cd30e52c0b458baaccb9fada7046e056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000e246a761202000000000000000000000000ca11bde05977b3631167028862be2a173976ca11');
    });

    it('should prioritize separated raw input over URL parameter', async () => {
      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=base-mainnet&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B&rawFunctionInput=0xshort

Insert the following hex into the 'Raw input data' field:
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      // Should use the separated raw input, not the URL parameter
      expect(link.rawFunctionInput).toBe('0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001');
    });

    it('should handle empty output gracefully', async () => {
      const sampleOutput = `
== Logs ==
Some unrelated output that doesn't match any patterns
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.nestedHashes).toHaveLength(0);
      expect(result.simulationLink).toBeUndefined();
      expect(result.approvalHash).toBeUndefined();
      expect(result.signingData).toBeUndefined();
    });

    it('should handle malformed URLs gracefully', async () => {
      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/malformed-url-without-query-params
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      expect(link.url).toBe('https://dashboard.tenderly.co/malformed-url-without-query-params');
      expect(link.network).toBe('unknown');
      expect(link.contractAddress).toBe('0x0000000000000000000000000000000000000000');
      expect(link.from).toBe('0x0000000000000000000000000000000000000000');
    });
  });

  describe('runAndExtract with script execution', () => {
         it('should execute forge command and extract data', async () => {
       const mockOutput = `
Nested hash for safe 0x6AF0674791925f767060Dd52f7fB20984E8639d8: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=11155111&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B
       `;

       mockedFs.existsSync.mockReturnValue(true);
       mockedExecSync.mockReturnValue(mockOutput);
       mockedFs.writeFileSync.mockImplementation(() => {});

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
        signature: 'sign(address[])',
        args: ['["0x123","0x456"]'],
        sender: '0xb2d9a52e76841279EF0372c534C539a4f68f8C0B',
        saveOutput: 'test-output.txt',
      });

      expect(mockedExecSync).toHaveBeenCalledWith(
        'forge script --rpc-url https://mock-rpc.com MockScript --sig "sign(address[])" ["0x123","0x456"] --sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B',
        expect.any(Object)
      );

      expect(result.nestedHashes).toHaveLength(1);
      expect(result.simulationLink).toBeTruthy();
    });

    it('should handle script execution failure', async () => {
      const mockError = new Error('Script failed');
      (mockError as any).stdout = 'Some stdout';
      (mockError as any).stderr = 'Some stderr';

      mockedFs.existsSync.mockReturnValue(true);
      mockedExecSync.mockImplementation(() => {
        throw mockError;
      });

      await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
      });

      expect(process.exit).toHaveBeenCalledWith(1);
    });

    it('should handle missing script directory', async () => {
      mockedFs.existsSync.mockReturnValue(false);

      await runAndExtract({
        scriptPath: '/nonexistent/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
      });

      expect(process.exit).toHaveBeenCalledWith(1);
    });
  });

  describe('forge command building', () => {
    it('should build basic forge command', async () => {
      mockedFs.existsSync.mockReturnValue(true);
      mockedExecSync.mockReturnValue('');

      await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
      });

      expect(mockedExecSync).toHaveBeenCalledWith(
        'forge script --rpc-url https://mock-rpc.com MockScript',
        expect.any(Object)
      );
    });

    it('should build forge command with signature and args', async () => {
      mockedFs.existsSync.mockReturnValue(true);
      mockedExecSync.mockReturnValue('');

      await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
        signature: 'sign(address[])',
        args: ['["0x123","0x456"]'],
      });

      expect(mockedExecSync).toHaveBeenCalledWith(
        'forge script --rpc-url https://mock-rpc.com MockScript --sig "sign(address[])" ["0x123","0x456"]',
        expect.any(Object)
      );
    });

    it('should build forge command with sender', async () => {
      mockedFs.existsSync.mockReturnValue(true);
      mockedExecSync.mockReturnValue('');

      await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
        sender: '0xb2d9a52e76841279EF0372c534C539a4f68f8C0B',
      });

      expect(mockedExecSync).toHaveBeenCalledWith(
        'forge script --rpc-url https://mock-rpc.com MockScript --sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B',
        expect.any(Object)
      );
    });
  });

  describe('file operations', () => {
    it('should save output and extracted data when saveOutput is provided', async () => {
      const mockOutput = 'mock script output';
      const mockExtractedData = {
        nestedHashes: [],
        simulationLinks: [],
        approvalHashes: [],
        signingData: [],
      };

             mockedFs.existsSync.mockReturnValue(true);
       mockedExecSync.mockReturnValue(mockOutput);
       mockedFs.writeFileSync.mockImplementation(() => {});

       await runAndExtract({
         scriptPath: '/mock/path',
         rpcUrl: 'https://mock-rpc.com',
         scriptName: 'MockScript',
         saveOutput: 'test-output.txt',
       });

      expect(mockedFs.writeFileSync).toHaveBeenCalledWith('test-output.txt', mockOutput);
      expect(mockedFs.writeFileSync).toHaveBeenCalledWith(
        'test-output-extracted.json',
        expect.stringContaining('"nestedHashes"')
      );
    });

    it('should read from existing file in extract-only mode', async () => {
      const mockOutput = 'existing file content';

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(mockOutput);

      await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'https://mock-rpc.com',
        scriptName: 'MockScript',
        saveOutput: 'existing-output.txt',
        extractOnly: true,
      });

      expect(mockedFs.readFileSync).toHaveBeenCalledWith('existing-output.txt', 'utf8');
      expect(mockedExecSync).not.toHaveBeenCalled();
    });
  });

  describe('edge cases and validation', () => {
    it('should handle complex state overrides parsing', async () => {
      const complexStateOverrides = [
        {
          contractAddress: '0x1234567890123456789012345678901234567890',
          storage: [
            { key: '0x0000000000000000000000000000000000000000000000000000000000000000', value: '0x0000000000000000000000000000000000000000000000000000000000000001' },
            { key: '0x0000000000000000000000000000000000000000000000000000000000000001', value: '0x0000000000000000000000000000000000000000000000000000000000000002' }
          ]
        },
        {
          contractAddress: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
          storage: [
            { key: '0x0000000000000000000000000000000000000000000000000000000000000002', value: '0x0000000000000000000000000000000000000000000000000000000000000003' }
          ]
        }
      ];

      const encodedOverrides = encodeURIComponent(JSON.stringify(complexStateOverrides));
      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/user/project/simulator/new?network=base-mainnet&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B&stateOverrides=${encodedOverrides}
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      expect(result.simulationLink).toBeTruthy();
      const link = result.simulationLink!;
      expect(link.stateOverrides).toBeTruthy();

      // Verify that state overrides can be parsed
      const decodedOverrides = JSON.parse(decodeURIComponent(link.stateOverrides!));
      expect(decodedOverrides).toHaveLength(2);
      expect(decodedOverrides[0].storage).toHaveLength(2);
      expect(decodedOverrides[1].storage).toHaveLength(1);
    });

    it('should extract only first match for single-match patterns', async () => {
      const sampleOutput = `
Simulation link:
  https://dashboard.tenderly.co/first-link

Simulation link:
  https://dashboard.tenderly.co/second-link

If submitting onchain, call Safe.approveHash on 0x6AF0674791925f767060Dd52f7fB20984E8639d8 with the following hash: 0x1111111111111111111111111111111111111111111111111111111111111111

If submitting onchain, call Safe.approveHash on 0x646132A1667ca7aD00d36616AFBA1A28116C770A with the following hash: 0x2222222222222222222222222222222222222222222222222222222222222222

Data to sign:
  vvvvvvvv
  0x1111111111111111111111111111111111111111111111111111111111111111
  ^^^^^^^^

Data to sign:
  vvvvvvvv
  0x2222222222222222222222222222222222222222222222222222222222222222
  ^^^^^^^^
      `;

      mockedFs.existsSync.mockReturnValue(true);
      mockedFs.readFileSync.mockReturnValue(sampleOutput);

      const result = await runAndExtract({
        scriptPath: '/mock/path',
        rpcUrl: 'http://mock-rpc',
        scriptName: 'MockScript',
        saveOutput: 'mock-output.txt',
        extractOnly: true,
      });

      // Should only extract first match for single-match patterns
      expect(result.simulationLink).toBeTruthy();
      expect(result.simulationLink!.url).toBe('https://dashboard.tenderly.co/first-link');

      expect(result.approvalHash).toBeTruthy();
      expect(result.approvalHash!.hash).toBe('0x1111111111111111111111111111111111111111111111111111111111111111');

      expect(result.signingData).toBeTruthy();
      expect(result.signingData!.dataToSign).toBe('0x1111111111111111111111111111111111111111111111111111111111111111');
    });
  });
});
