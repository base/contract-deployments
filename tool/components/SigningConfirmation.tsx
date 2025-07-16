import React, { useState } from 'react';

interface SigningData {
  signature: string;
  signerAddress: string;
  domainHash: string;
  messageHash: string;
}

interface SigningConfirmationProps {
  userType: string;
  network: string;
  selectedUpgrade: {
    id: string;
    name: string;
  };
  simulationMethod: 'tenderly' | 'state-diff';
  signingData?: SigningData | null;
  onBackToValidation: () => void;
  onBackToLedger?: () => void;
  onBackToSetup: () => void;
}

export const SigningConfirmation: React.FC<SigningConfirmationProps> = ({
  userType,
  network,
  selectedUpgrade,
  simulationMethod,
  signingData,
  onBackToValidation,
  onBackToLedger,
  onBackToSetup
}) => {
  const [copied, setCopied] = useState(false);

  const handleCopySignature = () => {
    if (signingData?.signature) {
      navigator.clipboard.writeText(signingData.signature);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div style={{
      maxWidth: '800px',
      margin: '0 auto',
      padding: '32px 0'
    }}>
      {/* Header */}
      <div style={{
        textAlign: 'center',
        marginBottom: '48px'
      }}>
        <h2 style={{
          fontSize: '32px',
          fontWeight: '700',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text',
          marginBottom: '16px',
          margin: '0 0 16px 0'
        }}>Signing Complete!</h2>
        <p style={{
          color: '#6B7280',
          fontSize: '16px',
          margin: 0
        }}>
          {signingData ? 'Your transaction has been signed with Ledger' : 'No signature data available'}
        </p>
      </div>

      {/* Summary Card */}
      <div style={{
        background: '#F9FAFB',
        border: '1px solid #E5E7EB',
        borderRadius: '16px',
        padding: '24px',
        marginBottom: '32px'
      }}>
        <h3 style={{
          margin: '0 0 16px 0',
          fontSize: '18px',
          fontWeight: '600',
          color: '#1F2937'
        }}>Transaction Summary</h3>

        <div style={{ display: 'grid', gap: '12px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#6B7280' }}>User Type:</span>
            <span style={{ fontWeight: '500', color: '#1F2937' }}>{userType}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#6B7280' }}>Network:</span>
            <span style={{ fontWeight: '500', color: '#1F2937' }}>{network}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#6B7280' }}>Upgrade:</span>
            <span style={{ fontWeight: '500', color: '#1F2937' }}>{selectedUpgrade.name}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: '#6B7280' }}>Simulation Method:</span>
            <span style={{ fontWeight: '500', color: '#1F2937' }}>
              {simulationMethod === 'tenderly' ? '☁️ Tenderly' : '⚡ State-Diff'}
            </span>
          </div>
          {signingData && (
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#6B7280' }}>Signer Address:</span>
              <span style={{ fontWeight: '500', color: '#1F2937', fontFamily: 'monospace', fontSize: '14px' }}>
                {signingData.signerAddress}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Signature Display */}
      {signingData && (
        <div style={{ marginBottom: '48px' }}>
          <div style={{
            background: '#D1FAE5',
            border: '1px solid #6EE7B7',
            borderRadius: '12px',
            padding: '24px',
            marginBottom: '24px'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '16px'
            }}>
              <h3 style={{
                margin: 0,
                fontSize: '18px',
                fontWeight: '600',
                color: '#065F46',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}>
                <span style={{ fontSize: '24px' }}>✅</span>
                Ledger Signature Generated
              </h3>
            </div>

            <div style={{
              background: '#F0FDF4',
              border: '1px solid #BBF7D0',
              borderRadius: '8px',
              padding: '16px',
              fontFamily: 'monospace',
              fontSize: '14px',
              wordBreak: 'break-all',
              color: '#14532D',
              position: 'relative'
            }}>
              {signingData.signature}

              <button
                onClick={handleCopySignature}
                style={{
                  position: 'absolute',
                  top: '8px',
                  right: '8px',
                  background: copied ? '#10B981' : '#6366F1',
                  color: 'white',
                  padding: '6px 12px',
                  borderRadius: '6px',
                  border: 'none',
                  fontWeight: '500',
                  fontSize: '12px',
                  cursor: 'pointer',
                  fontFamily: 'sans-serif',
                  transition: 'all 0.2s ease'
                }}
              >
                {copied ? '✓ Copied!' : 'Copy'}
              </button>
            </div>
          </div>

          {/* EIP-712 Data Details */}
          <div style={{
            background: '#EBF8FF',
            border: '1px solid #90CDF4',
            borderRadius: '12px',
            padding: '20px',
            marginBottom: '24px'
          }}>
            <h4 style={{
              margin: '0 0 12px 0',
              fontSize: '16px',
              fontWeight: '600',
              color: '#1E40AF'
            }}>
              EIP-712 Signing Details:
            </h4>
            <div style={{ marginBottom: '12px' }}>
              <p style={{ margin: '0 0 4px 0', fontSize: '14px', fontWeight: '500', color: '#1E40AF' }}>
                Domain Hash:
              </p>
              <div style={{
                fontFamily: 'monospace',
                fontSize: '13px',
                color: '#312E81',
                background: 'white',
                padding: '8px',
                borderRadius: '4px',
                wordBreak: 'break-all'
              }}>
                {signingData.domainHash}
              </div>
            </div>
            <div>
              <p style={{ margin: '0 0 4px 0', fontSize: '14px', fontWeight: '500', color: '#1E40AF' }}>
                Message Hash:
              </p>
              <div style={{
                fontFamily: 'monospace',
                fontSize: '13px',
                color: '#312E81',
                background: 'white',
                padding: '8px',
                borderRadius: '4px',
                wordBreak: 'break-all'
              }}>
                {signingData.messageHash}
              </div>
            </div>
          </div>

          <div style={{
            background: '#E0E7FF',
            border: '1px solid #A5B4FC',
            borderRadius: '12px',
            padding: '20px'
          }}>
            <h4 style={{
              margin: '0 0 12px 0',
              fontSize: '16px',
              fontWeight: '600',
              color: '#312E81'
            }}>
              Next Steps:
            </h4>
            <ol style={{
              margin: 0,
              paddingLeft: '20px',
              color: '#4C1D95'
            }}>
              <li style={{ marginBottom: '8px' }}>
                Copy the signature above using the copy button
              </li>
              <li style={{ marginBottom: '8px' }}>
                Share this signature with other signers if this is a multisig transaction
              </li>
              <li style={{ marginBottom: '8px' }}>
                Once all required signatures are collected, execute the transaction
              </li>
            </ol>
          </div>
        </div>
      )}

      {/* No Signature Available */}
      {!signingData && (
        <div style={{
          background: '#FEF3C7',
          border: '1px solid #FCD34D',
          borderRadius: '12px',
          padding: '24px',
          marginBottom: '32px',
          textAlign: 'center'
        }}>
          <h3 style={{
            margin: '0 0 12px 0',
            fontSize: '18px',
            fontWeight: '600',
            color: '#92400E'
          }}>
            No Signature Data
          </h3>
          <p style={{
            margin: 0,
            color: '#92400E'
          }}>
            No signature was provided. Please go back and complete the Ledger signing process.
          </p>
        </div>
      )}

      {/* Action Buttons */}
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        gap: '16px',
        flexWrap: 'wrap'
      }}>
        {onBackToLedger && (
          <button
            onClick={onBackToLedger}
            style={{
              background: '#6366F1',
              color: 'white',
              padding: '12px 24px',
              borderRadius: '12px',
              fontWeight: '500',
              fontSize: '16px',
              border: 'none',
              cursor: 'pointer',
              fontFamily: 'inherit',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#4F46E5';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = '#6366F1';
            }}
          >
            ← Back to Ledger
          </button>
        )}

        <button
          onClick={onBackToValidation}
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
            transition: 'all 0.2s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.background = '#E5E7EB';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = '#F3F4F6';
          }}
        >
          ← Back to Validation
        </button>

        <button
          onClick={onBackToSetup}
          style={{
            background: '#6B7280',
            color: 'white',
            padding: '12px 24px',
            borderRadius: '12px',
            fontWeight: '500',
            fontSize: '16px',
            border: 'none',
            cursor: 'pointer',
            fontFamily: 'inherit',
            transition: 'all 0.2s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.background = '#4B5563';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = '#6B7280';
          }}
        >
          Start New Validation
        </button>
      </div>
    </div>
  );
};
