import React from 'react';
import { StringDiff } from '../utils/types/index';
import { HighlightedText } from './HighlightedText';

interface ComparisonCardProps {
  type: 'expected' | 'actual';
  contractName: string;
  contractAddress: string;
  storageKey: string;
  storageKeyDiffs?: StringDiff[];
  beforeValue?: string;
  beforeValueDiffs?: StringDiff[];
  afterValue: string;
  afterValueDiffs?: StringDiff[];
}

export const ComparisonCard: React.FC<ComparisonCardProps> = ({
  type,
  contractName,
  contractAddress,
  storageKey,
  storageKeyDiffs,
  beforeValue,
  beforeValueDiffs,
  afterValue,
  afterValueDiffs
}) => {
  const isExpected = type === 'expected';
  const bgColor = isExpected ? '#EFF6FF' : '#F0F9FF';
  const borderColor = isExpected ? '#93C5FD' : '#7DD3FC';
  const headerColor = isExpected ? '#1D4ED8' : '#0369A1';
  const headerIcon = isExpected ? '✅' : '🔍';
  const headerText = isExpected ? 'Expected' : 'Actual';
  const contractBgColor = isExpected ? '#DBEAFE' : '#E0F2FE';

  return (
    <div style={{
      background: bgColor,
      border: `2px solid ${borderColor}`,
      borderRadius: '20px',
      padding: '24px'
    }}>
      <h3 style={{
        color: headerColor,
        fontWeight: '700',
        fontSize: '18px',
        marginBottom: '16px',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        margin: '0 0 16px 0'
      }}>
        <span>{headerIcon}</span> {headerText}
      </h3>

      <div style={{
        background: contractBgColor,
        borderRadius: '12px',
        padding: '16px',
        marginBottom: '16px'
      }}>
        <h4 style={{
          fontWeight: '600',
          color: '#1F2937',
          marginBottom: '8px',
          margin: '0 0 8px 0'
        }}>{contractName}</h4>
        <p style={{
          fontSize: '12px',
          color: '#6B7280',
          fontFamily: 'monospace',
          wordBreak: 'break-all',
          margin: 0
        }}>
          {contractAddress}
        </p>
      </div>

      <div style={{
        background: 'white',
        borderRadius: '12px',
        padding: '16px',
        border: `1px solid ${borderColor}`
      }}>


        <div style={{ marginBottom: '16px' }}>
          <label style={{
            fontSize: '10px',
            fontWeight: '600',
            color: '#6B7280',
            textTransform: 'uppercase',
            letterSpacing: '0.05em'
          }}>Storage Key</label>
          <div style={{
            background: '#F9FAFB',
            borderRadius: '8px',
            padding: '12px',
            marginTop: '4px',
            fontFamily: 'monospace',
            fontSize: '11px',
            color: '#1F2937',
            wordBreak: 'break-all'
          }}>
            {storageKeyDiffs ? (
              <HighlightedText diffs={storageKeyDiffs} />
            ) : (
              storageKey
            )}
          </div>
        </div>

        {beforeValue && (
          <div style={{ marginBottom: '16px' }}>
            <label style={{
              fontSize: '10px',
              fontWeight: '600',
              color: '#6B7280',
              textTransform: 'uppercase',
              letterSpacing: '0.05em'
            }}>Before</label>
            <div style={{
              background: '#FEF3C7',
              borderRadius: '8px',
              padding: '12px',
              marginTop: '4px',
              fontFamily: 'monospace',
              fontSize: '11px',
              color: '#D97706',
              wordBreak: 'break-all'
            }}>
              {beforeValueDiffs ? (
                <HighlightedText diffs={beforeValueDiffs} />
              ) : (
                beforeValue
              )}
            </div>
          </div>
        )}

        <div>
          <label style={{
            fontSize: '10px',
            fontWeight: '600',
            color: '#6B7280',
            textTransform: 'uppercase',
            letterSpacing: '0.05em'
          }}>{beforeValue ? 'After' : 'Value'}</label>
          <div style={{
            background: '#EFF6FF',
            borderRadius: '8px',
            padding: '12px',
            marginTop: '4px',
            fontFamily: 'monospace',
            fontSize: '11px',
            color: '#1D4ED8',
            wordBreak: 'break-all'
          }}>
            {afterValueDiffs ? (
              <HighlightedText diffs={afterValueDiffs} />
            ) : (
              afterValue
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
