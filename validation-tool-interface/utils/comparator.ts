import { ComparisonResult, DiffType, FieldDiff, ObjectDiff, StateChange, StateOverride, StringDiff } from './types/index';

export class DiffComparator {
  /**
   * Compare two StateOverride objects and return structured diff data
   */
  compareStateOverride(expected: StateOverride, actual: StateOverride): ComparisonResult {
    const fieldDiffs: FieldDiff[] = [];
    let matchingFields = 0;
    let mismatchedFields = 0;

    // Compare basic properties
    const nameDiff = this.createFieldDiff('name', 'name', expected.name, actual.name);
    fieldDiffs.push(nameDiff);
    if (nameDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

    const addressDiff = this.createFieldDiff('address', 'address', expected.address, actual.address);
    fieldDiffs.push(addressDiff);
    if (addressDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

    // Compare overrides
    const maxLength = Math.max(expected.overrides.length, actual.overrides.length);
    for (let i = 0; i < maxLength; i++) {
      const expectedOverride = expected.overrides[i];
      const actualOverride = actual.overrides[i];

      if (!expectedOverride && actualOverride) {
        // Added override
        fieldDiffs.push(this.createFieldDiff('key', `overrides[${i}].key`, '', actualOverride.key));
        fieldDiffs.push(this.createFieldDiff('value', `overrides[${i}].value`, '', actualOverride.value));
        fieldDiffs.push(this.createFieldDiff('description', `overrides[${i}].description`, '', actualOverride.description));
        mismatchedFields += 3;
      } else if (expectedOverride && !actualOverride) {
        // Removed override
        fieldDiffs.push(this.createFieldDiff('key', `overrides[${i}].key`, expectedOverride.key, ''));
        fieldDiffs.push(this.createFieldDiff('value', `overrides[${i}].value`, expectedOverride.value, ''));
        fieldDiffs.push(this.createFieldDiff('description', `overrides[${i}].description`, expectedOverride.description, ''));
        mismatchedFields += 3;
      } else if (expectedOverride && actualOverride) {
        // Compare existing overrides
        const keyDiff = this.createFieldDiff('key', `overrides[${i}].key`, expectedOverride.key, actualOverride.key);
        fieldDiffs.push(keyDiff);
        if (keyDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

        const valueDiff = this.createFieldDiff('value', `overrides[${i}].value`, expectedOverride.value, actualOverride.value);
        fieldDiffs.push(valueDiff);
        if (valueDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

        // Note: Description excluded from comparison as requested
      }
    }

    const totalFields = fieldDiffs.length;
    const status = mismatchedFields === 0 ? 'match' : 'mismatch';

    const objectDiff: ObjectDiff = {
      type: 'StateOverride',
      fieldDiffs,
      status: status === 'match' ? 'match' : 'mismatch'
    };

    const summary = status === 'match'
      ? '✅ StateOverride objects match perfectly'
      : `❌ StateOverride differences found: ${mismatchedFields}/${totalFields} fields differ`;

    return {
      summary,
      status,
      diffs: [objectDiff],
      stats: {
        totalFields,
        matchingFields,
        mismatchedFields,
        addedFields: fieldDiffs.filter(f => f.expected === '').length,
        removedFields: fieldDiffs.filter(f => f.actual === '').length
      }
    };
  }

  /**
   * Compare two StateChange objects and return structured diff data
   */
  compareStateChange(expected: StateChange, actual: StateChange): ComparisonResult {
    const fieldDiffs: FieldDiff[] = [];
    let matchingFields = 0;
    let mismatchedFields = 0;

    // Compare basic properties
    const nameDiff = this.createFieldDiff('name', 'name', expected.name, actual.name);
    fieldDiffs.push(nameDiff);
    if (nameDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

    const addressDiff = this.createFieldDiff('address', 'address', expected.address, actual.address);
    fieldDiffs.push(addressDiff);
    if (addressDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

    // Compare changes
    const maxLength = Math.max(expected.changes.length, actual.changes.length);
    for (let i = 0; i < maxLength; i++) {
      const expectedChange = expected.changes[i];
      const actualChange = actual.changes[i];

      if (!expectedChange && actualChange) {
        // Added change
        fieldDiffs.push(this.createFieldDiff('key', `changes[${i}].key`, '', actualChange.key));
        fieldDiffs.push(this.createFieldDiff('before', `changes[${i}].before`, '', actualChange.before));
        fieldDiffs.push(this.createFieldDiff('after', `changes[${i}].after`, '', actualChange.after));
        fieldDiffs.push(this.createFieldDiff('description', `changes[${i}].description`, '', actualChange.description));
        mismatchedFields += 4;
      } else if (expectedChange && !actualChange) {
        // Removed change
        fieldDiffs.push(this.createFieldDiff('key', `changes[${i}].key`, expectedChange.key, ''));
        fieldDiffs.push(this.createFieldDiff('before', `changes[${i}].before`, expectedChange.before, ''));
        fieldDiffs.push(this.createFieldDiff('after', `changes[${i}].after`, expectedChange.after, ''));
        fieldDiffs.push(this.createFieldDiff('description', `changes[${i}].description`, expectedChange.description, ''));
        mismatchedFields += 4;
      } else if (expectedChange && actualChange) {
        // Compare existing changes
        const keyDiff = this.createFieldDiff('key', `changes[${i}].key`, expectedChange.key, actualChange.key);
        fieldDiffs.push(keyDiff);
        if (keyDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

        const beforeDiff = this.createFieldDiff('before', `changes[${i}].before`, expectedChange.before, actualChange.before);
        fieldDiffs.push(beforeDiff);
        if (beforeDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

        const afterDiff = this.createFieldDiff('after', `changes[${i}].after`, expectedChange.after, actualChange.after);
        fieldDiffs.push(afterDiff);
        if (afterDiff.type === 'unchanged') matchingFields++; else mismatchedFields++;

        // Note: Description excluded from comparison as requested
      }
    }

    const totalFields = fieldDiffs.length;
    const status = mismatchedFields === 0 ? 'match' : 'mismatch';

    const objectDiff: ObjectDiff = {
      type: 'StateChange',
      fieldDiffs,
      status: status === 'match' ? 'match' : 'mismatch'
    };

    const summary = status === 'match'
      ? '✅ StateChange objects match perfectly'
      : `❌ StateChange differences found: ${mismatchedFields}/${totalFields} fields differ`;

    return {
      summary,
      status,
      diffs: [objectDiff],
      stats: {
        totalFields,
        matchingFields,
        mismatchedFields,
        addedFields: fieldDiffs.filter(f => f.expected === '').length,
        removedFields: fieldDiffs.filter(f => f.actual === '').length
      }
    };
  }

  /**
   * Create character-level diffs for two strings
   */
  private createStringDiffs(expected: string, actual: string): StringDiff[] {
    if (expected === actual) {
      return [{ type: 'unchanged', value: expected }];
    }

    // Simple implementation - for production, consider using a proper diff library
    const diffs: StringDiff[] = [];

    // Find common prefix
    let prefixLength = 0;
    while (prefixLength < Math.min(expected.length, actual.length) &&
           expected[prefixLength] === actual[prefixLength]) {
      prefixLength++;
    }

    // Find common suffix
    let suffixLength = 0;
    while (suffixLength < Math.min(expected.length - prefixLength, actual.length - prefixLength) &&
           expected[expected.length - 1 - suffixLength] === actual[actual.length - 1 - suffixLength]) {
      suffixLength++;
    }

    // Add unchanged prefix
    if (prefixLength > 0) {
      diffs.push({
        type: 'unchanged',
        value: expected.substring(0, prefixLength),
        startIndex: 0,
        endIndex: prefixLength
      });
    }

    // Add removed part (from expected)
    const removedPart = expected.substring(prefixLength, expected.length - suffixLength);
    if (removedPart) {
      diffs.push({
        type: 'removed',
        value: removedPart,
        startIndex: prefixLength,
        endIndex: expected.length - suffixLength
      });
    }

    // Add added part (from actual)
    const addedPart = actual.substring(prefixLength, actual.length - suffixLength);
    if (addedPart) {
      diffs.push({
        type: 'added',
        value: addedPart,
        startIndex: prefixLength,
        endIndex: actual.length - suffixLength
      });
    }

    // Add unchanged suffix
    if (suffixLength > 0) {
      diffs.push({
        type: 'unchanged',
        value: expected.substring(expected.length - suffixLength),
        startIndex: expected.length - suffixLength,
        endIndex: expected.length
      });
    }

    return diffs;
  }

  /**
   * Create a field diff for two field values
   */
  private createFieldDiff(field: string, path: string, expected: string, actual: string): FieldDiff {
    const type: DiffType = expected === actual ? 'unchanged' : 'modified';

    return {
      field,
      path,
      expected,
      actual,
      diffs: this.createStringDiffs(expected, actual),
      type
    };
  }
}
