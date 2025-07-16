#!/usr/bin/env node

import { DiffComparator } from '../comparator.js';
import { StateChange, StateOverride } from '../types/index';

/**
 * Simple test case using real data from base-nested.json
 */
function testBasicComparison() {
  console.log('🧪 Basic DiffComparator Test\n');

  const comparator = new DiffComparator();

  // Test data from base-nested.json
  const stateOverride: StateOverride = {
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

  const stateChange: StateChange = {
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

  // Test 1: Perfect match
  console.log('1. Testing perfect match:');
  const perfectMatch = comparator.compareStateOverride(stateOverride, stateOverride);
  console.log('Summary:', perfectMatch.summary);
  console.log('Status:', perfectMatch.status);
  console.log('Stats:', JSON.stringify(perfectMatch.stats, null, 2));

  // Test 2: Create a modified version to show differences
  const modifiedOverride = { ...stateOverride };
  modifiedOverride.name = "Modified ProxyAdminOwner";
  modifiedOverride.address = "0x1111111111111111111111111111111111111111";

  console.log('\n2. Testing mismatch detection:');
  const mismatchResult = comparator.compareStateOverride(stateOverride, modifiedOverride);
  console.log('Summary:', mismatchResult.summary);
  console.log('Status:', mismatchResult.status);
  console.log('Stats:', JSON.stringify(mismatchResult.stats, null, 2));

  // Test 3: StateChange comparison
  console.log('\n3. Testing StateChange comparison:');
  const changeResult = comparator.compareStateChange(stateChange, stateChange);
  console.log('Summary:', changeResult.summary);
  console.log('Status:', changeResult.status);

  // Test 4: Show field-by-field differences with character-level highlighting
  console.log('\n4. 🎯 FIELD-BY-FIELD DIFFERENCES (for frontend highlighting):');
  console.log('='.repeat(70));

  mismatchResult.diffs[0].fieldDiffs.forEach((fieldDiff, index) => {
    if (fieldDiff.type === 'modified') {
      console.log(`\n  Field ${index + 1}: ${fieldDiff.path}`);
      console.log(`    Expected: "${fieldDiff.expected}"`);
      console.log(`    Actual:   "${fieldDiff.actual}"`);
      console.log(`    Character-level diffs:`);

      fieldDiff.diffs.forEach((stringDiff, i) => {
        const typeEmoji = {
          unchanged: '⚪',
          added: '🟢',
          removed: '🔴',
          modified: '🟡'
        }[stringDiff.type];

        console.log(`      ${i + 1}. ${typeEmoji} ${stringDiff.type}: "${stringDiff.value}"`);
        if (stringDiff.startIndex !== undefined && stringDiff.endIndex !== undefined) {
          console.log(`         Position: ${stringDiff.startIndex}-${stringDiff.endIndex}`);
        }
      });
    }
  });

  console.log('\n🎉 Basic test completed!');
  console.log('💡 For comprehensive unit tests, see cli/src/__tests__/utils/comparator.test.ts');
}

testBasicComparison();
