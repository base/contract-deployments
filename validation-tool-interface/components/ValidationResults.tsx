import React, { useEffect, useState } from 'react';
import { DiffComparator } from '../utils/comparator';
import { StringDiff } from '../utils/types/index';
import { ValidationData } from '../utils/validation-service';
import { ComparisonCard } from './index';

interface ValidationResultsProps {
  userType: string;
  network: string;
  selectedUpgrade: {
    id: string;
    name: string;
  };
  simulationMethod: 'tenderly' | 'state-diff';
  userLedgerAddress: string;
  onBackToSetup: () => void;
  onProceedToLedgerSigning: (validationResult: any) => void;
}

export const ValidationResults: React.FC<ValidationResultsProps> = ({
  userType,
  network,
  selectedUpgrade,
  simulationMethod,
  userLedgerAddress,
  onBackToSetup,
  onProceedToLedgerSigning,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentChangeIndex, setCurrentChangeIndex] = useState(0);
  const [validationResult, setValidationResult] = useState<ValidationData | null>(null);
  const [isInstallingDeps, setIsInstallingDeps] = useState(false);

  // Create a diff comparator instance
  const diffComparator = new DiffComparator();

  const createStringDiffs = (expected: string, actual: string): StringDiff[] => {
    if (expected === actual) {
      return [{ type: 'unchanged', value: expected }];
    }

    // Use a simple diff algorithm for character-level comparison
    const diffs: StringDiff[] = [];

    // Find common prefix
    let prefixLength = 0;
    while (
      prefixLength < Math.min(expected.length, actual.length) &&
      expected[prefixLength] === actual[prefixLength]
    ) {
      prefixLength++;
    }

    // Find common suffix
    let suffixLength = 0;
    while (
      suffixLength < Math.min(expected.length - prefixLength, actual.length - prefixLength) &&
      expected[expected.length - 1 - suffixLength] === actual[actual.length - 1 - suffixLength]
    ) {
      suffixLength++;
    }

    // Add unchanged prefix
    if (prefixLength > 0) {
      diffs.push({
        type: 'unchanged',
        value: expected.substring(0, prefixLength),
        startIndex: 0,
        endIndex: prefixLength,
      });
    }

    // Add removed part (from expected)
    const removedPart = expected.substring(prefixLength, expected.length - suffixLength);
    if (removedPart) {
      diffs.push({
        type: 'removed',
        value: removedPart,
        startIndex: prefixLength,
        endIndex: expected.length - suffixLength,
      });
    }

    // Add added part (from actual)
    const addedPart = actual.substring(prefixLength, actual.length - suffixLength);
    if (addedPart) {
      diffs.push({
        type: 'added',
        value: addedPart,
        startIndex: prefixLength,
        endIndex: actual.length - suffixLength,
      });
    }

    // Add unchanged suffix
    if (suffixLength > 0) {
      diffs.push({
        type: 'unchanged',
        value: expected.substring(expected.length - suffixLength),
        startIndex: expected.length - suffixLength,
        endIndex: expected.length,
      });
    }

    return diffs;
  };

  // Helper function to get highlighted diffs for a specific field comparison
  const getFieldDiffs = (expectedValue: string, actualValue: string): StringDiff[] => {
    return createStringDiffs(expectedValue, actualValue);
  };

  const getAllValidationItems = (): Array<{
    step: 1 | 2 | 3;
    stepName: string;
    type: 'signing-data' | 'override' | 'change';
    stateChangeIndex?: number;
    changeIndex?: number;
    stateOverrideIndex?: number;
    overrideIndex?: number;
    expected: any;
    actual?: any;
    contractName: string;
    contractAddress?: string;
  }> => {
    if (!validationResult) return [];

    const items: Array<{
      step: 1 | 2 | 3;
      stepName: string;
      type: 'signing-data' | 'override' | 'change';
      stateChangeIndex?: number;
      changeIndex?: number;
      stateOverrideIndex?: number;
      overrideIndex?: number;
      expected: any;
      actual?: any;
      contractName: string;
      contractAddress?: string;
    }> = [];

    // Step 1: Domain and Message Hash Validation
    const expectedDomainAndMessageHashes = validationResult.expected.domainAndMessageHashes;
    const actualSigningData = validationResult.extractedData?.signingData;

    if (expectedDomainAndMessageHashes && actualSigningData) {
      // Combine domain and message hash with EIP-712 prefix (0x1901)
      const expectedDataToSign = `0x1901${expectedDomainAndMessageHashes.domain_hash.replace(
        '0x',
        ''
      )}${expectedDomainAndMessageHashes.message_hash.replace('0x', '')}`;

      items.push({
        step: 1,
        stepName: 'Domain/Message Hash',
        type: 'signing-data' as const,
        expected: {
          dataToSign: expectedDataToSign,
          address: expectedDomainAndMessageHashes.address,
          domainHash: expectedDomainAndMessageHashes.domain_hash,
          messageHash: expectedDomainAndMessageHashes.message_hash,
        },
        actual: actualSigningData,
        contractName: 'EIP-712 Signing Data',
        contractAddress: expectedDomainAndMessageHashes.address,
      });
    }

    // Step 2: State Overrides validation
    validationResult.expected.stateOverrides.forEach((stateOverride, soIndex) => {
      stateOverride.overrides.forEach((override, oIndex) => {
        items.push({
          step: 2,
          stepName: 'State Overrides',
          type: 'override' as const,
          stateOverrideIndex: soIndex,
          overrideIndex: oIndex,
          expected: override,
          actual: validationResult.actual.stateOverrides[soIndex]?.overrides[oIndex],
          contractName: stateOverride.name,
          contractAddress: stateOverride.address,
        });
      });
    });

    // Step 3: State Changes validation
    validationResult.expected.stateChanges.forEach((stateChange, scIndex) => {
      stateChange.changes.forEach((change, cIndex) => {
        items.push({
          step: 3,
          stepName: 'State Changes',
          type: 'change' as const,
          stateChangeIndex: scIndex,
          changeIndex: cIndex,
          expected: change,
          actual: validationResult.actual.stateChanges[scIndex]?.changes[cIndex],
          contractName: stateChange.name,
          contractAddress: stateChange.address,
        });
      });
    });

    return items;
  };

  useEffect(() => {
    handleRunValidation();
  }, [userType, network, selectedUpgrade, simulationMethod]);

  const handleRunValidation = async () => {
    setLoading(true);
    setError(null);
    setValidationResult(null);

    try {
      // First, check and install dependencies if needed
      console.log(`🔍 Checking dependencies for ${network.toLowerCase()}/${selectedUpgrade.id}`);
      setIsInstallingDeps(true);

      const depsResponse = await fetch('/api/install-deps', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          network: network.toLowerCase(),
          upgradeId: selectedUpgrade.id,
        }),
      });

      const depsResult = await depsResponse.json();

      if (!depsResult.success) {
        setError(`Dependency installation failed: ${depsResult.error}`);
        setIsInstallingDeps(false);
        setLoading(false);
        return;
      }

      if (depsResult.depsInstalled) {
        console.log(
          `✅ Dependencies installed successfully for ${network.toLowerCase()}/${
            selectedUpgrade.id
          }`
        );
      } else {
        console.log(
          `✅ Dependencies already exist for ${network.toLowerCase()}/${selectedUpgrade.id}`
        );
      }

      setIsInstallingDeps(false);

      // Now proceed with validation
      console.log('Running validation with options:', {
        upgradeId: selectedUpgrade.id,
        network,
        userType,
        simulationMethod,
        userLedgerAddress,
      });

      const response = await fetch('/api/validate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          upgradeId: selectedUpgrade.id,
          network: network.toLowerCase(),
          userType,
          simulationMethod,
          userLedgerAddress,
        }),
      });

      const result = await response.json();

      if (result.success) {
        setValidationResult(result.data);
        console.log('Validation completed successfully');
      } else {
        setError(result.error || 'Validation failed');
        console.error('Validation failed:', result.error);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error occurred';
      setError(errorMessage);
      console.error('Validation error:', err);
    } finally {
      setLoading(false);
      setIsInstallingDeps(false);
    }
  };



  const allValidationItems = getAllValidationItems();
  const currentValidationItem = allValidationItems[currentChangeIndex];
  const totalValidationItems = allValidationItems.length;

  // Check if there are any blocking validation errors
  const hasBlockingErrors = () => {
    if (!validationResult) return false;
    
    return allValidationItems.some(item => {
      // Missing actual data is a blocking error
      if (!item.actual) {
        return true;
      }
      
      // Check for mismatch that is NOT an expected difference
      if (item.type === 'signing-data') {
        return item.expected.dataToSign !== item.actual.dataToSign;
      } else if (item.type === 'override') {
        const match = item.expected.key === item.actual.key && item.expected.value === item.actual.value;
        const isExpectedDifference = 
          item.expected.description && 
          item.expected.description.toLowerCase().includes('difference is expected');
        return !match && !isExpectedDifference;
      } else if (item.type === 'change') {
        return !(
          item.expected.key === item.actual.key &&
          item.expected.before === item.actual.before &&
          item.expected.after === item.actual.after
        );
      }
      return false;
    });
  };

  const blockingErrorsExist = hasBlockingErrors();

  // Get step-specific counts and current step info
  const getStepInfo = () => {
    const step1Items = allValidationItems.filter(item => item.step === 1);
    const step2Items = allValidationItems.filter(item => item.step === 2);
    const step3Items = allValidationItems.filter(item => item.step === 3);

    let currentStepItems: typeof allValidationItems = [];
    let currentStepIndex = 0;

    if (currentValidationItem?.step === 1) {
      currentStepItems = step1Items;
      currentStepIndex = step1Items.findIndex(item => item === currentValidationItem) + 1;
    } else if (currentValidationItem?.step === 2) {
      currentStepItems = step2Items;
      currentStepIndex = step2Items.findIndex(item => item === currentValidationItem) + 1;
    } else if (currentValidationItem?.step === 3) {
      currentStepItems = step3Items;
      currentStepIndex = step3Items.findIndex(item => item === currentValidationItem) + 1;
    }

    return {
      step1Count: step1Items.length,
      step2Count: step2Items.length,
      step3Count: step3Items.length,
      currentStepItems: currentStepItems.length,
      currentStepIndex,
      currentStep: currentValidationItem?.step || 1,
    };
  };

  const stepInfo = getStepInfo();

  const getMatchStatus = () => {
    if (!currentValidationItem || !currentValidationItem.actual) {
      return {
        status: 'missing',
        color: '#3B82F6',
        icon: '❌',
        text: 'Missing - Not found in actual results',
      };
    }

    const expected = currentValidationItem.expected;
    const actual = currentValidationItem.actual;

    if (currentValidationItem.type === 'signing-data') {
      // Step 1: Compare EIP-712 data to sign
      const match = expected.dataToSign === actual.dataToSign;
      return match
        ? {
            status: 'match',
            color: '#1D4ED8',
            icon: '✅',
            text: 'Match - EIP-712 data matches expected',
          }
        : {
            status: 'mismatch',
            color: '#DC2626',
            icon: '❌',
            text: 'Mismatch - EIP-712 data does not match expected',
          };
    } else if (currentValidationItem.type === 'override') {
      // Step 2: Compare state override (only key and value)
      const match = expected.key === actual.key && expected.value === actual.value;

      // Check if description indicates this difference is expected
      const isExpectedDifference =
        expected.description &&
        expected.description.toLowerCase().includes('difference is expected');

      if (match) {
        return {
          status: 'match',
          color: '#1D4ED8',
          icon: '✅',
          text: 'Match - This override is correct',
        };
      } else if (isExpectedDifference) {
        return {
          status: 'expected-difference',
          color: '#059669',
          icon: '✅',
          text: 'Expected Difference - This mismatch is acceptable and expected',
        };
      } else {
        return {
          status: 'mismatch',
          color: '#DC2626',
          icon: '❌',
          text: 'Mismatch - Override values do not match expected',
        };
      }
    } else {
      // Step 3: Compare state change (key, before, and after values)
      const match =
        expected.key === actual.key &&
        expected.before === actual.before &&
        expected.after === actual.after;

      // Check if description indicates this difference is expected
      const isExpectedDifference =
        expected.description &&
        expected.description.toLowerCase().includes('difference is expected');

      if (match) {
        return {
          status: 'match',
          color: '#1D4ED8',
          icon: '✅',
          text: 'Match - This change is correct',
        };
      } else if (isExpectedDifference) {
        return {
          status: 'expected-difference',
          color: '#059669',
          icon: '✅',
          text: 'Expected Difference - This mismatch is acceptable and expected',
        };
      } else {
        return {
          status: 'mismatch',
          color: '#DC2626',
          icon: '❌',
          text: 'Mismatch - Change values do not match expected',
        };
      }
    }
  };

  if (loading) {
    const getLoadingMessage = () => {
      if (isInstallingDeps) {
        return 'Checking dependencies and running make deps if needed...';
      } else if (simulationMethod === 'state-diff') {
        return 'Extracting script data, running native simulator, and comparing with expected results...';
      } else {
        return 'Extracting script data, calling Tenderly API, and comparing with expected results...';
      }
    };

    const getLoadingTitle = () => {
      if (isInstallingDeps) {
        return 'Installing Dependencies';
      } else {
        return 'Running Validation';
      }
    };

    return (
      <div style={{ textAlign: 'center', padding: '64px 0' }}>
        <div
          style={{
            display: 'inline-block',
            width: '48px',
            height: '48px',
            border: '4px solid #E5E7EB',
            borderTop: '4px solid #6366F1',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            marginBottom: '24px',
          }}
        />
        <h3 style={{ color: '#374151', marginBottom: '8px' }}>{getLoadingTitle()}</h3>
        <p style={{ color: '#6B7280', margin: 0 }}>{getLoadingMessage()}</p>
        <style jsx>{`
          @keyframes spin {
            0% {
              transform: rotate(0deg);
            }
            100% {
              transform: rotate(360deg);
            }
          }
        `}</style>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ textAlign: 'center', padding: '64px 0' }}>
        <div
          style={{
            background: '#FEE2E2',
            color: '#DC2626',
            padding: '24px',
            borderRadius: '12px',
            marginBottom: '24px',
            maxWidth: '600px',
            margin: '0 auto 24px',
          }}
        >
          <h3 style={{ margin: '0 0 8px 0' }}>❌ Validation Failed</h3>
          <p style={{ margin: 0 }}>{error}</p>
        </div>



        <button
          onClick={() => handleRunValidation()}
          style={{
            background: '#F3F4F6',
            color: '#374151',
            padding: '12px 24px',
            borderRadius: '12px',
            border: 'none',
            fontWeight: '600',
            cursor: 'pointer',
            marginRight: '12px',
          }}
        >
          Retry Validation
        </button>

        <button
          onClick={onBackToSetup}
          style={{
            background: '#6B7280',
            color: 'white',
            padding: '12px 24px',
            borderRadius: '12px',
            border: 'none',
            fontWeight: '600',
            cursor: 'pointer',
          }}
        >
          Back to Setup
        </button>
      </div>
    );
  }

  if (!validationResult || totalValidationItems === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '64px 0' }}>
        <div
          style={{
            background: '#FEF3C7',
            color: '#D97706',
            padding: '24px',
            borderRadius: '12px',
            marginBottom: '24px',
            maxWidth: '600px',
            margin: '0 auto 24px',
          }}
        >
          <h3 style={{ margin: '0 0 8px 0' }}>⚠️ No Changes Found</h3>
          <p style={{ margin: 0 }}>
            No state changes or overrides were found in the validation data.
          </p>
        </div>
        <button
          onClick={onBackToSetup}
          style={{
            background: '#6B7280',
            color: 'white',
            padding: '12px 24px',
            borderRadius: '12px',
            border: 'none',
            fontWeight: '600',
            cursor: 'pointer',
          }}
        >
          Back to Setup
        </button>
      </div>
    );
  }

  const matchStatus = getMatchStatus();

  return (
    <div>
      <div
        style={{
          textAlign: 'center',
          marginBottom: '32px',
        }}
      >
        <h2
          style={{
            fontSize: '32px',
            fontWeight: '700',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
            marginBottom: '8px',
            margin: '0 0 8px 0',
          }}
        >
          Validation Results
        </h2>
        <div
          style={{
            color: '#6B7280',
            margin: 0,
            fontSize: '16px',
          }}
        >
          <div style={{ marginBottom: '4px' }}>
            <strong>
              Step {stepInfo.currentStep}: {currentValidationItem?.stepName}
            </strong>{' '}
            • Item {stepInfo.currentStepIndex} of {stepInfo.currentStepItems}
          </div>
          <div style={{ fontSize: '14px', opacity: 0.8 }}>
            Step 1: {stepInfo.step1Count} items • Step 2: {stepInfo.step2Count} items • Step 3:{' '}
            {stepInfo.step3Count} items
          </div>
        </div>
      </div>

      {/* Navigation */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '32px',
        }}
      >
        <button
          onClick={() => setCurrentChangeIndex(Math.max(0, currentChangeIndex - 1))}
          disabled={currentChangeIndex === 0}
          style={{
            padding: '12px 24px',
            borderRadius: '12px',
            fontWeight: '600',
            border: 'none',
            cursor: currentChangeIndex === 0 ? 'not-allowed' : 'pointer',
            background: currentChangeIndex === 0 ? '#E5E7EB' : '#F3F4F6',
            color: currentChangeIndex === 0 ? '#9CA3AF' : '#374151',
            fontFamily: 'inherit',
          }}
        >
          ← Previous
        </button>

        <div
          style={{
            background: '#DBEAFE',
            color: '#1D4ED8',
            padding: '8px 16px',
            borderRadius: '20px',
            fontSize: '14px',
            fontWeight: '600',
          }}
        >
          {currentValidationItem?.contractName || 'Unknown Contract'}
        </div>

        <button
          onClick={() =>
            setCurrentChangeIndex(Math.min(totalValidationItems - 1, currentChangeIndex + 1))
          }
          disabled={currentChangeIndex === totalValidationItems - 1}
          style={{
            padding: '12px 24px',
            borderRadius: '12px',
            fontWeight: '600',
            border: 'none',
            cursor: currentChangeIndex === totalValidationItems - 1 ? 'not-allowed' : 'pointer',
            background: currentChangeIndex === totalValidationItems - 1 ? '#E5E7EB' : '#6366F1',
            color: currentChangeIndex === totalValidationItems - 1 ? '#9CA3AF' : 'white',
            fontFamily: 'inherit',
          }}
        >
          Next →
        </button>
      </div>

      {/* Comparison Cards */}
      {currentValidationItem && (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: '24px',
            marginBottom: '24px',
          }}
        >
          {(() => {
            // Handle different types of validation
            if (currentValidationItem.type === 'signing-data') {
              // Step 1: Domain/Message Hash validation
              const expectedData = currentValidationItem.expected.dataToSign;
              const actualData = currentValidationItem.actual?.dataToSign || 'Not found';
              const dataDiffs = getFieldDiffs(expectedData, actualData);

              return (
                <>
                  <ComparisonCard
                    type="expected"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey="EIP-712 Data to Sign"
                    afterValue={expectedData}
                  />
                  <ComparisonCard
                    type="actual"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey="EIP-712 Data to Sign"
                    afterValue={actualData}
                    afterValueDiffs={dataDiffs}
                  />
                </>
              );
            } else if (currentValidationItem.type === 'override') {
              // Step 2: State Override validation (no before/after, just key/value)
              const expectedKey = currentValidationItem.expected.key;
              const expectedValue = currentValidationItem.expected.value;
              const actualKey = currentValidationItem.actual?.key || 'Not found';
              const actualValue = currentValidationItem.actual?.value || 'Not found';

              const keyDiffs = getFieldDiffs(expectedKey, actualKey);
              const valueDiffs = getFieldDiffs(expectedValue, actualValue);

              return (
                <>
                  <ComparisonCard
                    type="expected"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey={expectedKey}
                    afterValue={expectedValue}
                  />
                  <ComparisonCard
                    type="actual"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey={actualKey}
                    storageKeyDiffs={keyDiffs}
                    afterValue={actualValue}
                    afterValueDiffs={valueDiffs}
                  />
                </>
              );
            } else {
              // Step 3: State Change validation (has before/after values)
              const expectedKey = currentValidationItem.expected.key;
              const actualKey = currentValidationItem.actual?.key || 'Not found';

              const expectedBefore = currentValidationItem.expected.before;
              const expectedAfter = currentValidationItem.expected.after;
              const actualBefore = currentValidationItem.actual?.before || 'Not found';
              const actualAfter = currentValidationItem.actual?.after || 'Not found';

              // Generate diffs only for actual card (comparing actual vs expected)
              const keyDiffs = getFieldDiffs(expectedKey, actualKey);
              const beforeDiffs = getFieldDiffs(expectedBefore, actualBefore);
              const afterDiffs = getFieldDiffs(expectedAfter, actualAfter);

              return (
                <>
                  <ComparisonCard
                    type="expected"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey={expectedKey}
                    beforeValue={expectedBefore}
                    afterValue={expectedAfter}
                  />
                  <ComparisonCard
                    type="actual"
                    contractName={currentValidationItem.contractName}
                    contractAddress={currentValidationItem.contractAddress || 'Unknown Address'}
                    storageKey={actualKey}
                    storageKeyDiffs={keyDiffs}
                    beforeValue={actualBefore}
                    beforeValueDiffs={beforeDiffs}
                    afterValue={actualAfter}
                    afterValueDiffs={afterDiffs}
                  />
                </>
              );
            }
          })()}
        </div>
      )}

      {/* Description Box - show when available */}
      {currentValidationItem && currentValidationItem.expected.description && (
        <div
          style={{
            background: currentValidationItem.expected.description
              .toLowerCase()
              .includes('difference is expected')
              ? 'linear-gradient(135deg, #ECFDF5 0%, #D1FAE5 100%)'
              : 'linear-gradient(135deg, #F0F9FF 0%, #E0F2FE 100%)',
            border: currentValidationItem.expected.description
              .toLowerCase()
              .includes('difference is expected')
              ? '2px solid #10B981'
              : '2px solid #7DD3FC',
            borderRadius: '16px',
            padding: '24px',
            marginBottom: '32px',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-start',
              gap: '12px',
            }}
          >
            <span
              style={{
                fontSize: '24px',
                marginTop: '2px',
              }}
            >
              {currentValidationItem.expected.description
                .toLowerCase()
                .includes('difference is expected')
                ? '✅'
                : '💡'}
            </span>
            <div style={{ flex: 1 }}>
              <h4
                style={{
                  fontSize: '16px',
                  fontWeight: '700',
                  color: currentValidationItem.expected.description
                    .toLowerCase()
                    .includes('difference is expected')
                    ? '#059669'
                    : '#0369A1',
                  textTransform: 'uppercase',
                  letterSpacing: '0.05em',
                  margin: '0 0 8px 0',
                }}
              >
                {currentValidationItem.expected.description
                  .toLowerCase()
                  .includes('difference is expected')
                  ? 'Expected Difference - This is Fine'
                  : 'What this does'}
              </h4>
              <p
                style={{
                  fontSize: '16px',
                  color: currentValidationItem.expected.description
                    .toLowerCase()
                    .includes('difference is expected')
                    ? '#064E3B'
                    : '#0C4A6E',
                  margin: 0,
                  lineHeight: '1.6',
                  fontWeight: '500',
                }}
              >
                {currentValidationItem.expected.description}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Match Status */}
      <div
        style={{
          textAlign: 'center',
          marginBottom: '32px',
        }}
      >
        <div
          style={{
            background: matchStatus.color,
            color: 'white',
            padding: '16px 32px',
            borderRadius: '20px',
            display: 'inline-flex',
            alignItems: 'center',
            fontWeight: '700',
            fontSize: '18px',
            gap: '8px',
          }}
        >
          <span>{matchStatus.icon}</span> {matchStatus.text}
        </div>
      </div>

      {/* Debug Info */}
      {validationResult.extractedData && (
        <details style={{ marginBottom: '32px', fontSize: '14px' }}>
          <summary style={{ cursor: 'pointer', fontWeight: '600', marginBottom: '12px' }}>
            Debug Information
          </summary>
          <div
            style={{
              background: '#F9FAFB',
              padding: '16px',
              borderRadius: '8px',
              fontFamily: 'monospace',
            }}
          >
            <p>
              <strong>Simulation Method:</strong>{' '}
              {simulationMethod === 'state-diff' ? 'Native Go Simulator' : 'Tenderly API'}
            </p>
            <p>
              <strong>Extracted Hashes:</strong>{' '}
              {validationResult.extractedData.nestedHashes?.length || 0}
            </p>
            <p>
              <strong>Simulation Link:</strong>{' '}
              {validationResult.extractedData.simulationLink ? '✅' : '❌'}
            </p>
            {simulationMethod === 'tenderly' && (
              <p>
                <strong>Tenderly Simulation:</strong>{' '}
                {validationResult.tenderlyResponse ? '✅' : '❌'}
              </p>
            )}
            {simulationMethod === 'state-diff' && (
              <p>
                <strong>State-Diff Output:</strong> {validationResult.stateDiffOutput ? '✅' : '❌'}
              </p>
            )}
            <p>
              <strong>Domain/Message Hash Validation:</strong>{' '}
              {validationResult.expected.domainAndMessageHashes ? '✅' : '❌'}
            </p>
            <p>
              <strong>Signing Data Available:</strong>{' '}
              {validationResult.extractedData.signingData ? '✅' : '❌'}
            </p>
            <p>
              <strong>Expected State Changes:</strong>{' '}
              {validationResult.expected.stateChanges.length}
            </p>
            <p>
              <strong>Actual State Changes:</strong> {validationResult.actual.stateChanges.length}
            </p>
            <p>
              <strong>Expected State Overrides:</strong>{' '}
              {validationResult.expected.stateOverrides.length}
            </p>
            <p>
              <strong>Actual State Overrides:</strong>{' '}
              {validationResult.actual.stateOverrides.length}
            </p>
            <p>
              <strong>Total Validation Items:</strong> {totalValidationItems}
            </p>
          </div>
        </details>
      )}



      {/* Proceed to Signing Button */}
      {currentChangeIndex === totalValidationItems - 1 && (
        <div
          style={{
            textAlign: 'center',
            marginTop: '48px',
          }}
        >
          {/* Status Summary */}
          <div
            style={{
              background: blockingErrorsExist 
                ? 'linear-gradient(135deg, #FEE2E2 0%, #FECACA 100%)'
                : 'linear-gradient(135deg, #D1FAE5 0%, #A7F3D0 100%)',
              border: `2px solid ${blockingErrorsExist ? '#FECACA' : '#86EFAC'}`,
              borderRadius: '16px',
              padding: '24px',
              marginBottom: '24px',
              maxWidth: '500px',
              margin: '0 auto 24px',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '12px',
                marginBottom: blockingErrorsExist ? '12px' : '8px',
              }}
            >
              <span style={{ fontSize: '28px' }}>{blockingErrorsExist ? '🚫' : '✅'}</span>
              <h3
                style={{
                  margin: 0,
                  fontSize: '20px',
                  fontWeight: '700',
                  color: blockingErrorsExist ? '#DC2626' : '#047857',
                }}
              >
                {blockingErrorsExist ? 'Cannot Sign' : 'Ready to Sign'}
              </h3>
            </div>
            {blockingErrorsExist && (
              <p
                style={{
                  margin: 0,
                  fontSize: '14px',
                  color: '#DC2626',
                  textAlign: 'center',
                  lineHeight: '1.4',
                }}
              >
                Found <strong>Missing</strong> or <strong>Different</strong> instances. Contact developers before continuing.
              </p>
            )}
          </div>

          {/* Ledger Signing Button - Only show when no blocking errors */}
          {!blockingErrorsExist &&
            validationResult?.expected?.domainAndMessageHashes &&
            validationResult?.expected?.domainAndMessageHashes?.domain_hash &&
            validationResult?.expected?.domainAndMessageHashes?.message_hash && (
                <button
                  onClick={() => onProceedToLedgerSigning(validationResult)}
                  style={{
                    background: 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)',
                    color: 'white',
                    padding: '16px 48px',
                    borderRadius: '12px',
                    fontWeight: '600',
                    fontSize: '18px',
                    border: 'none',
                    cursor: 'pointer',
                    fontFamily: 'inherit',
                    transition: 'all 0.2s ease',
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '12px',
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.transform = 'translateY(-2px)';
                    e.currentTarget.style.boxShadow =
                      '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)';
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.boxShadow =
                      '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)';
                  }}
                >
                  <span style={{ fontSize: '20px' }}>🔐</span>
                  Sign with Ledger →
                </button>
            )}

          {/* Show message if signing is not available */}
          {(!validationResult?.expected?.domainAndMessageHashes ||
            !validationResult?.expected?.domainAndMessageHashes?.domain_hash ||
            !validationResult?.expected?.domainAndMessageHashes?.message_hash) && (
            <div
              style={{
                background: '#FEF3C7',
                border: '1px solid #FCD34D',
                borderRadius: '8px',
                padding: '16px',
                marginBottom: '20px',
              }}
            >
              <p
                style={{
                  margin: '0 0 8px 0',
                  fontSize: '14px',
                  fontWeight: '600',
                  color: '#92400E',
                }}
              >
                ⚠️ Signing Not Available
              </p>
              <p
                style={{
                  margin: 0,
                  fontSize: '14px',
                  color: '#92400E',
                }}
              >
                Domain and message hashes are required for signing but were not generated during
                validation. This may indicate an issue with the script execution or validation
                process.
              </p>
            </div>
          )}
        </div>
      )}

      {/* Bottom Navigation Buttons */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: '48px',
        }}
      >
        {/* Back to Setup - Left */}
        <button
          onClick={onBackToSetup}
          style={{
            background: '#F3F4F6',
            color: '#6B7280',
            padding: '12px 24px',
            borderRadius: '12px',
            fontWeight: '500',
            fontSize: '16px',
            border: 'none',
            cursor: 'pointer',
            fontFamily: 'inherit',
            transition: 'all 0.2s ease',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
          onMouseEnter={e => {
            e.currentTarget.style.background = '#E5E7EB';
          }}
          onMouseLeave={e => {
            e.currentTarget.style.background = '#F3F4F6';
          }}
        >
          ← Back to Setup
        </button>

        {/* Rerun Validation - Right */}
        <button
          onClick={handleRunValidation}
          disabled={loading}
          style={{
            background: loading ? '#E5E7EB' : '#6366F1',
            color: loading ? '#9CA3AF' : 'white',
            padding: '16px 32px',
            borderRadius: '12px',
            border: 'none',
            fontWeight: '600',
            cursor: loading ? 'not-allowed' : 'pointer',
            fontSize: '16px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontFamily: 'inherit',
            transition: 'all 0.2s ease',
          }}
          onMouseEnter={e => {
            if (!loading) {
              e.currentTarget.style.background = '#4F46E5';
            }
          }}
          onMouseLeave={e => {
            if (!loading) {
              e.currentTarget.style.background = '#6366F1';
            }
          }}
        >
          {loading ? (
            <>
              <div
                style={{
                  width: '16px',
                  height: '16px',
                  border: '2px solid #9CA3AF',
                  borderTop: '2px solid transparent',
                  borderRadius: '50%',
                  animation: 'spin 1s linear infinite',
                }}
              />
              Running Validation...
            </>
          ) : (
            <>
              <span style={{ fontSize: '16px' }}>🔄</span>
              Rerun Validation
            </>
          )}
        </button>
      </div>
    </div>
  );
};
