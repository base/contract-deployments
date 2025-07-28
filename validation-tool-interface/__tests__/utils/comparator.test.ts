import { DiffComparator } from '../../utils/comparator';
import { StateChange, StateOverride } from '../../utils/types/index';

describe('DiffComparator', () => {
  let comparator: DiffComparator;

  beforeEach(() => {
    comparator = new DiffComparator();
  });

  describe('compareStateOverride', () => {
    const baseOverride: StateOverride = {
      name: "ProxyAdminOwner",
      address: "0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c",
      overrides: [
        {
          key: "0x0000000000000000000000000000000000000000000000000000000000000004",
          value: "0x0000000000000000000000000000000000000000000000000000000000000001",
          description: "Override the threshold to 1 so the transaction simulation can occur"
        }
      ]
    };

    it('should return success result for identical StateOverride objects', () => {
      const result = comparator.compareStateOverride(baseOverride, baseOverride);

      expect(result.status).toBe('match');
      expect(result.summary).toBe('✅ StateOverride objects match perfectly');
      expect(result.stats.mismatchedFields).toBe(0);
      expect(result.stats.matchingFields).toBeGreaterThan(0);
      expect(result.diffs).toHaveLength(1);
      expect(result.diffs[0].status).toBe('match');
    });

    it('should detect name mismatch', () => {
      const modified = { ...baseOverride, name: "ModifiedProxyAdminOwner" };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateOverride differences found:');
      expect(result.stats.mismatchedFields).toBeGreaterThan(0);

      const nameFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'name');
      expect(nameFieldDiff).toBeDefined();
      expect(nameFieldDiff!.type).toBe('modified');
      expect(nameFieldDiff!.expected).toBe('ProxyAdminOwner');
      expect(nameFieldDiff!.actual).toBe('ModifiedProxyAdminOwner');
    });

    it('should detect address mismatch', () => {
      const modified = { ...baseOverride, address: "0x1111111111111111111111111111111111111111" };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateOverride differences found:');

      const addressFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'address');
      expect(addressFieldDiff).toBeDefined();
      expect(addressFieldDiff!.type).toBe('modified');
      expect(addressFieldDiff!.expected).toBe('0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c');
      expect(addressFieldDiff!.actual).toBe('0x1111111111111111111111111111111111111111');
    });

    it('should detect overrides count mismatch', () => {
      const modified = { ...baseOverride, overrides: [] };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateOverride differences found:');
      expect(result.stats.removedFields).toBeGreaterThan(0);
    });

    it('should detect override key mismatch', () => {
      const modified = {
        ...baseOverride,
        overrides: [{
          ...baseOverride.overrides[0],
          key: "0x0000000000000000000000000000000000000000000000000000000000000005"
        }]
      };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');

      const keyFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'overrides[0].key');
      expect(keyFieldDiff).toBeDefined();
      expect(keyFieldDiff!.type).toBe('modified');
    });

    it('should detect override value mismatch', () => {
      const modified = {
        ...baseOverride,
        overrides: [{
          ...baseOverride.overrides[0],
          value: "0x0000000000000000000000000000000000000000000000000000000000000002"
        }]
      };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');

      const valueFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'overrides[0].value');
      expect(valueFieldDiff).toBeDefined();
      expect(valueFieldDiff!.type).toBe('modified');
    });

    it('should detect override description mismatch', () => {
      const modified = {
        ...baseOverride,
        overrides: [{
          ...baseOverride.overrides[0],
          description: "Modified description"
        }]
      };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');

      const descFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'overrides[0].description');
      expect(descFieldDiff).toBeDefined();
      expect(descFieldDiff!.type).toBe('modified');
    });

    it('should handle extra overrides', () => {
      const modified = {
        ...baseOverride,
        overrides: [
          ...baseOverride.overrides,
          {
            key: "0x0000000000000000000000000000000000000000000000000000000000000005",
            value: "0x0000000000000000000000000000000000000000000000000000000000000001",
            description: "Extra override"
          }
        ]
      };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.stats.addedFields).toBeGreaterThan(0);

      const extraKeyField = result.diffs[0].fieldDiffs.find(f => f.path === 'overrides[1].key');
      expect(extraKeyField).toBeDefined();
      expect(extraKeyField!.expected).toBe('');
      expect(extraKeyField!.actual).toBe('0x0000000000000000000000000000000000000000000000000000000000000005');
    });

    it('should handle missing overrides', () => {
      const modified = { ...baseOverride, overrides: [] };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.stats.removedFields).toBeGreaterThan(0);

      const missingKeyField = result.diffs[0].fieldDiffs.find(f => f.path === 'overrides[0].key');
      expect(missingKeyField).toBeDefined();
      expect(missingKeyField!.expected).toBe('0x0000000000000000000000000000000000000000000000000000000000000004');
      expect(missingKeyField!.actual).toBe('');
    });

    it('should handle multiple differences in one comparison', () => {
      const modified: StateOverride = {
        name: "ModifiedName",
        address: "0x1111111111111111111111111111111111111111",
        overrides: [
          {
            key: "0x0000000000000000000000000000000000000000000000000000000000000005",
            value: "0x0000000000000000000000000000000000000000000000000000000000000002",
            description: "Modified description"
          }
        ]
      };
      const result = comparator.compareStateOverride(baseOverride, modified);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateOverride differences found:');
      expect(result.stats.mismatchedFields).toBeGreaterThanOrEqual(5); // name, address, key, value, description

      // Check that all modified fields are detected
      const fieldPaths = result.diffs[0].fieldDiffs.filter(f => f.type === 'modified').map(f => f.path);
      expect(fieldPaths).toContain('name');
      expect(fieldPaths).toContain('address');
      expect(fieldPaths).toContain('overrides[0].key');
      expect(fieldPaths).toContain('overrides[0].value');
      expect(fieldPaths).toContain('overrides[0].description');
    });

    it('should provide character-level string diffs', () => {
      const modified = { ...baseOverride, name: "Modified ProxyAdminOwner" };
      const result = comparator.compareStateOverride(baseOverride, modified);

      const nameFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'name');
      expect(nameFieldDiff).toBeDefined();
      expect(nameFieldDiff!.diffs).toHaveLength(2); // "Modified " (added) + "ProxyAdminOwner" (unchanged)

      expect(nameFieldDiff!.diffs[0].type).toBe('added');
      expect(nameFieldDiff!.diffs[0].value).toBe('Modified ');
      expect(nameFieldDiff!.diffs[1].type).toBe('unchanged');
      expect(nameFieldDiff!.diffs[1].value).toBe('ProxyAdminOwner');
    });
  });

  describe('compareStateChange', () => {
    const baseChange: StateChange = {
      name: "System Config",
      address: "0x73a79Fab69143498Ed3712e519A88a918e1f4072",
      changes: [
        {
          key: "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc",
          before: "0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647",
          after: "0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e",
          description: "Updates the System Config implementation address"
        }
      ]
    };

    it('should return success result for identical StateChange objects', () => {
      const result = comparator.compareStateChange(baseChange, baseChange);

      expect(result.status).toBe('match');
      expect(result.summary).toBe('✅ StateChange objects match perfectly');
      expect(result.stats.mismatchedFields).toBe(0);
      expect(result.stats.matchingFields).toBeGreaterThan(0);
      expect(result.diffs).toHaveLength(1);
      expect(result.diffs[0].status).toBe('match');
    });

    it('should detect name mismatch', () => {
      const modified = { ...baseChange, name: "Modified System Config" };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateChange differences found:');

      const nameFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'name');
      expect(nameFieldDiff).toBeDefined();
      expect(nameFieldDiff!.type).toBe('modified');
      expect(nameFieldDiff!.expected).toBe('System Config');
      expect(nameFieldDiff!.actual).toBe('Modified System Config');
    });

    it('should detect address mismatch', () => {
      const modified = { ...baseChange, address: "0x1111111111111111111111111111111111111111" };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');

      const addressFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'address');
      expect(addressFieldDiff).toBeDefined();
      expect(addressFieldDiff!.type).toBe('modified');
    });

    it('should detect changes count mismatch', () => {
      const modified = { ...baseChange, changes: [] };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');
      expect(result.stats.removedFields).toBeGreaterThan(0);
    });

    it('should detect change key mismatch', () => {
      const modified = {
        ...baseChange,
        changes: [{
          ...baseChange.changes[0],
          key: "0x1111111111111111111111111111111111111111111111111111111111111111"
        }]
      };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');

      const keyFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'changes[0].key');
      expect(keyFieldDiff).toBeDefined();
      expect(keyFieldDiff!.type).toBe('modified');
    });

    it('should detect change before value mismatch', () => {
      const modified = {
        ...baseChange,
        changes: [{
          ...baseChange.changes[0],
          before: "0x1111111111111111111111111111111111111111111111111111111111111111"
        }]
      };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');

      const beforeFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'changes[0].before');
      expect(beforeFieldDiff).toBeDefined();
      expect(beforeFieldDiff!.type).toBe('modified');
    });

    it('should detect change after value mismatch', () => {
      const modified = {
        ...baseChange,
        changes: [{
          ...baseChange.changes[0],
          after: "0x1111111111111111111111111111111111111111111111111111111111111111"
        }]
      };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');

      const afterFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'changes[0].after');
      expect(afterFieldDiff).toBeDefined();
      expect(afterFieldDiff!.type).toBe('modified');
    });

    it('should detect change description mismatch', () => {
      const modified = {
        ...baseChange,
        changes: [{
          ...baseChange.changes[0],
          description: "Modified description"
        }]
      };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');

      const descFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'changes[0].description');
      expect(descFieldDiff).toBeDefined();
      expect(descFieldDiff!.type).toBe('modified');
    });

    it('should handle extra changes', () => {
      const modified = {
        ...baseChange,
        changes: [
          ...baseChange.changes,
          {
            key: "0x1111111111111111111111111111111111111111111111111111111111111111",
            before: "0x0000000000000000000000000000000000000000000000000000000000000000",
            after: "0x0000000000000000000000000000000000000000000000000000000000000001",
            description: "Extra change"
          }
        ]
      };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');
      expect(result.stats.addedFields).toBeGreaterThan(0);
    });

    it('should handle missing changes', () => {
      const modified = { ...baseChange, changes: [] };
      const result = comparator.compareStateChange(baseChange, modified);

      expect(result.status).toBe('mismatch');
      expect(result.stats.removedFields).toBeGreaterThan(0);
    });
  });

  describe('edge cases', () => {
    it('should handle complex nested differences', () => {
      const override1: StateOverride = {
        name: "Test",
        address: "0x1111111111111111111111111111111111111111",
        overrides: [
          { key: "0x01", value: "0x01", description: "first" },
          { key: "0x02", value: "0x02", description: "second" }
        ]
      };

      const override2: StateOverride = {
        name: "Test",
        address: "0x1111111111111111111111111111111111111111",
        overrides: [
          { key: "0x01", value: "0x01", description: "first" },
          { key: "0x03", value: "0x03", description: "third" }  // Different key and description
        ]
      };

      const result = comparator.compareStateOverride(override1, override2);

      expect(result.status).toBe('mismatch');
      expect(result.summary).toContain('❌ StateOverride differences found:');

      const mismatchedFields = result.diffs[0].fieldDiffs.filter(f => f.type === 'modified');
      expect(mismatchedFields.length).toBeGreaterThanOrEqual(3); // key, value, description for second override
    });
  });

  describe('string diff functionality', () => {
    it('should provide detailed character-level diffs', () => {
      const original = "Hello World";
      const modified = "Hello Beautiful World";

      const override1: StateOverride = {
        name: original,
        address: "0x1111111111111111111111111111111111111111",
        overrides: []
      };

      const override2: StateOverride = {
        name: modified,
        address: "0x1111111111111111111111111111111111111111",
        overrides: []
      };

      const result = comparator.compareStateOverride(override1, override2);
      const nameFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'name');

      expect(nameFieldDiff).toBeDefined();
      expect(nameFieldDiff!.diffs).toHaveLength(3);
      expect(nameFieldDiff!.diffs[0].type).toBe('unchanged');
      expect(nameFieldDiff!.diffs[0].value).toBe('Hello ');
      expect(nameFieldDiff!.diffs[1].type).toBe('added');
      expect(nameFieldDiff!.diffs[1].value).toBe('Beautiful ');
      expect(nameFieldDiff!.diffs[2].type).toBe('unchanged');
      expect(nameFieldDiff!.diffs[2].value).toBe('World');
    });

    it('should handle identical strings', () => {
      const sameText = "Identical Text";

      const override1: StateOverride = {
        name: sameText,
        address: "0x1111111111111111111111111111111111111111",
        overrides: []
      };

      const result = comparator.compareStateOverride(override1, override1);
      const nameFieldDiff = result.diffs[0].fieldDiffs.find(f => f.path === 'name');

      expect(nameFieldDiff).toBeDefined();
      expect(nameFieldDiff!.type).toBe('unchanged');
      expect(nameFieldDiff!.diffs).toHaveLength(1);
      expect(nameFieldDiff!.diffs[0].type).toBe('unchanged');
      expect(nameFieldDiff!.diffs[0].value).toBe(sameText);
    });
  });
});
