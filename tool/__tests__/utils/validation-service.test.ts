import { StateChange, StateOverride } from '../../utils/types';
import { ValidationService } from '../../utils/validation-service';

// Mock the dependencies
jest.mock('../../utils/tenderly');
jest.mock('../../utils/script-extractor');
jest.mock('../../utils/parser');
jest.mock('fs');
jest.mock('path');

describe('ValidationService', () => {
  let validationService: ValidationService;

  beforeEach(() => {
    validationService = new ValidationService();

    // Mock console methods to avoid cluttering test output
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('sortValidationData', () => {
    it('should sort state overrides by address then by storage slot', () => {
      const unsortedData = {
        stateOverrides: [
          {
            name: 'Contract B',
            address: '0xB000000000000000000000000000000000000000',
            overrides: [
              { key: '0x02', value: '0x456', description: 'Second override' },
              { key: '0x01', value: '0x123', description: 'First override' }
            ]
          },
          {
            name: 'Contract A',
            address: '0xA000000000000000000000000000000000000000',
            overrides: [
              { key: '0x04', value: '0xabc', description: 'Fourth override' },
              { key: '0x03', value: '0x789', description: 'Third override' }
            ]
          },
          {
            name: 'Contract C', // Same address as B, order should be preserved
            address: '0xB000000000000000000000000000000000000000',
            overrides: []
          }
        ] as StateOverride[],
        stateChanges: []
      };

      // Access private method through type assertion
      const result = (validationService as any).sortValidationData(unsortedData);

      // Should be sorted by address first
      expect(result.stateOverrides[0].address).toBe('0xA000000000000000000000000000000000000000');
      expect(result.stateOverrides[1].address).toBe('0xB000000000000000000000000000000000000000');
      expect(result.stateOverrides[2].address).toBe('0xB000000000000000000000000000000000000000');

      // For same address, order should be preserved (no secondary sort by name)
      expect(result.stateOverrides[1].name).toBe('Contract B');
      expect(result.stateOverrides[2].name).toBe('Contract C');

      // Overrides within each contract should be sorted by storage slot (key)
      expect(result.stateOverrides[0].overrides[0].key).toBe('0x03');
      expect(result.stateOverrides[0].overrides[1].key).toBe('0x04');
      expect(result.stateOverrides[1].overrides[0].key).toBe('0x01');
      expect(result.stateOverrides[1].overrides[1].key).toBe('0x02');
    });

    it('should sort state changes by address then by storage slot', () => {
      const unsortedData = {
        stateOverrides: [],
        stateChanges: [
          {
            name: 'System Config',
            address: '0xC000000000000000000000000000000000000000',
            changes: [
              { key: '0x06', before: '0x000', after: '0x111', description: 'Sixth change' },
              { key: '0x05', before: '0x000', after: '0x222', description: 'Fifth change' }
            ]
          },
          {
            name: 'Base Config',
            address: '0xA000000000000000000000000000000000000000',
            changes: [
              { key: '0x08', before: '0x000', after: '0x333', description: 'Eighth change' },
              { key: '0x07', before: '0x000', after: '0x444', description: 'Seventh change' }
            ]
          }
        ] as StateChange[]
      };

      const result = (validationService as any).sortValidationData(unsortedData);

      // Should be sorted by contract address
      expect(result.stateChanges[0].address).toBe('0xA000000000000000000000000000000000000000');
      expect(result.stateChanges[1].address).toBe('0xC000000000000000000000000000000000000000');

      // Changes within each contract should be sorted by storage slot (key)
      expect(result.stateChanges[0].changes[0].key).toBe('0x07');
      expect(result.stateChanges[0].changes[1].key).toBe('0x08');
      expect(result.stateChanges[1].changes[0].key).toBe('0x05');
      expect(result.stateChanges[1].changes[1].key).toBe('0x06');
    });

    it('should handle case-insensitive sorting', () => {
      const unsortedData = {
        stateOverrides: [
          {
            name: 'contract b', // lowercase
            address: '0xb000000000000000000000000000000000000000', // lowercase
            overrides: [
              { key: '0x0B', value: '0x456', description: 'Mixed case key' },
              { key: '0x0a', value: '0x123', description: 'Lowercase key' }
            ]
          },
          {
            name: 'Contract A', // mixed case
            address: '0xA000000000000000000000000000000000000000', // uppercase
            overrides: []
          }
        ] as StateOverride[],
        stateChanges: []
      };

      const result = (validationService as any).sortValidationData(unsortedData);

      // Should sort case-insensitively by address
      expect(result.stateOverrides[0].address).toBe('0xA000000000000000000000000000000000000000');
      expect(result.stateOverrides[1].address).toBe('0xb000000000000000000000000000000000000000');

      // Should sort overrides case-insensitively by key
      expect(result.stateOverrides[1].overrides[0].key).toBe('0x0a');
      expect(result.stateOverrides[1].overrides[1].key).toBe('0x0B');
    });

    it('should not mutate original data', () => {
      const originalData = {
        stateOverrides: [
          {
            name: 'Contract B',
            address: '0xB000000000000000000000000000000000000000',
            overrides: [
              { key: '0x02', value: '0x456', description: 'Second override' }
            ]
          }
        ] as StateOverride[],
        stateChanges: []
      };

      const originalOverride = originalData.stateOverrides[0];
      const originalKey = originalOverride.overrides[0].key;

      (validationService as any).sortValidationData(originalData);

      // Original data should remain unchanged
      expect(originalData.stateOverrides[0]).toBe(originalOverride);
      expect(originalData.stateOverrides[0].overrides[0].key).toBe(originalKey);
    });

    it('should handle empty arrays', () => {
      const emptyData = {
        stateOverrides: [],
        stateChanges: []
      };

      const result = (validationService as any).sortValidationData(emptyData);

      expect(result.stateOverrides).toEqual([]);
      expect(result.stateChanges).toEqual([]);
    });
  });
});
