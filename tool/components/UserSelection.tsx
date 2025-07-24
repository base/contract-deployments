import React, { useState, useEffect } from 'react';

interface ConfigOption {
  fileName: string;
  displayName: string;
  configFile: string;
  ledgerId: number;
}

interface UserSelectionProps {
  network: string;
  upgradeId: string;
  onSelect: (
    user: string,
    ledgerAddress: string,
    ledgerAccount: number
  ) => void;
}

export const UserSelection: React.FC<UserSelectionProps> = ({ 
  network, 
  upgradeId, 
  onSelect 
}) => {
  const [availableUsers, setAvailableUsers] = useState<ConfigOption[]>([]);
  const [selectedUser, setSelectedUser] = useState<ConfigOption | null>(null);
  const [ledgerAddress, setLedgerAddress] = useState<string>('');
  const [ledgerAccount, setLedgerAccount] = useState<number>(0);
  const [loading, setLoading] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [error, setError] = useState<string>('');
  const [addressInputMethod, setAddressInputMethod] = useState<'ledger' | 'manual'>('ledger');
  const [manualAddress, setManualAddress] = useState<string>('');
  const [showAdvancedLedger, setShowAdvancedLedger] = useState<boolean>(false);

  // Fetch available users when network and upgradeId change
  useEffect(() => {
    const fetchAvailableUsers = async () => {
      if (!network || !upgradeId) return;
      
      setLoadingUsers(true);
      try {
        const response = await fetch(`/api/upgrade-config?network=${network.toLowerCase()}&upgradeId=${upgradeId}`);
        const { configOptions, error: apiError } = await response.json();
        
        if (apiError) {
          setError(`Failed to load config options: ${apiError}`);
          setAvailableUsers([]);
        } else {
          setAvailableUsers(configOptions);
          setError('');
        }
      } catch (err) {
        console.error('Failed to fetch upgrade config:', err);
        setError('Failed to load config options');
        setAvailableUsers([]);
      } finally {
        setLoadingUsers(false);
      }
    };

    fetchAvailableUsers();
  }, [network, upgradeId]);

  const handleUserSelect = (userOption: ConfigOption) => {
    setSelectedUser(userOption);
    setError('');
    // Reset address states when user changes
    setLedgerAddress('');
    setManualAddress('');
    
    // Set ledger account to the value from validation file
    setLedgerAccount(userOption.ledgerId);
    console.log(`Set default ledger account to: ${userOption.ledgerId} for user: ${userOption.displayName}`);
  };

  const handleGetLedgerAddress = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/sign', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'get-address',
          ledgerAccount,
        }),
      });

      const result = await response.json();

      if (result.success) {
        setLedgerAddress(result.address);
      } else {
        setError(result.error || 'Failed to get Ledger address');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to connect to Ledger');
    } finally {
      setLoading(false);
    }
  };

  const validateAddress = (address: string): boolean => {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
  };

  const handleManualAddressChange = (address: string) => {
    setManualAddress(address);
    setError('');

    if (address && validateAddress(address)) {
      setLedgerAddress(address);
    } else if (address) {
      setLedgerAddress('');
    }
  };

  const handleProceed = () => {
    if (selectedUser && ledgerAddress) {
      onSelect(selectedUser.fileName, ledgerAddress, ledgerAccount);
    }
  };

  return (
    <div style={{ textAlign: 'center' }}>
      <h2
        style={{
          fontSize: '24px',
          fontWeight: '600',
          color: '#374151',
          marginBottom: '32px',
          margin: '0 0 32px 0',
        }}
      >
        Setup Your Validation
      </h2>

      {/* Step 1: User Type Selection */}
      <div style={{ marginBottom: '32px' }}>
        <h3
          style={{
            fontSize: '18px',
            fontWeight: '600',
            color: '#374151',
            marginBottom: '16px',
            margin: '0 0 16px 0',
          }}
        >
          Step 1: Who are you?
        </h3>
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          {loadingUsers ? (
            <p>Loading user options...</p>
          ) : availableUsers.length === 0 ? (
            <p>No user options available for this network and upgrade ID.</p>
          ) : (
            availableUsers.map(option => (
              <button
                key={option.fileName}
                onClick={() => handleUserSelect(option)}
                style={{
                  width: '100%',
                  background: selectedUser?.fileName === option.fileName ? '#EBF8FF' : 'white',
                  border: selectedUser?.fileName === option.fileName ? '2px solid #3B82F6' : '1px solid #E5E7EB',
                  borderRadius: '12px',
                  padding: '20px',
                  color: selectedUser?.fileName === option.fileName ? '#1E40AF' : '#374151',
                  fontWeight: selectedUser?.fileName === option.fileName ? '600' : '500',
                  fontSize: '16px',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontFamily: 'inherit',
                  boxShadow:
                    selectedUser?.fileName === option.fileName
                      ? '0 4px 6px rgba(59, 130, 246, 0.15)'
                      : '0 1px 3px rgba(0, 0, 0, 0.1)',
                }}
                onMouseEnter={e => {
                  if (selectedUser?.fileName !== option.fileName) {
                    e.currentTarget.style.background = '#F9FAFB';
                    e.currentTarget.style.borderColor = '#D1D5DB';
                    e.currentTarget.style.transform = 'translateY(-1px)';
                    e.currentTarget.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
                  }
                }}
                onMouseLeave={e => {
                  if (selectedUser?.fileName !== option.fileName) {
                    e.currentTarget.style.background = 'white';
                    e.currentTarget.style.borderColor = '#E5E7EB';
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
                  }
                }}
              >
                {selectedUser?.fileName === option.fileName && <span style={{ marginRight: '8px' }}>✓</span>}
                {option.displayName}
              </button>
            ))
          )}
        </div>
      </div>

      {/* Step 2: Ledger Address */}
      {selectedUser && (
        <div style={{ marginBottom: '32px' }}>
          <h3
            style={{
              fontSize: '18px',
              fontWeight: '600',
              color: '#374151',
              marginBottom: '16px',
              margin: '0 0 16px 0',
            }}
          >
            Step 2: Get Your Address
          </h3>

          {/* Address Input Method Toggle */}
          <div
            style={{
              display: 'flex',
              background: '#F3F4F6',
              borderRadius: '8px',
              padding: '4px',
              marginBottom: '20px',
            }}
          >
            <button
              onClick={() => {
                setAddressInputMethod('ledger');
                setError('');
                setLedgerAddress('');
                setManualAddress('');
              }}
              style={{
                flex: 1,
                padding: '8px 16px',
                borderRadius: '6px',
                border: 'none',
                background: addressInputMethod === 'ledger' ? 'white' : 'transparent',
                color: addressInputMethod === 'ledger' ? '#374151' : '#6B7280',
                fontWeight: addressInputMethod === 'ledger' ? '600' : '500',
                cursor: 'pointer',
                boxShadow:
                  addressInputMethod === 'ledger' ? '0 1px 3px rgba(0, 0, 0, 0.1)' : 'none',
              }}
            >
              🔗 Connect Ledger
            </button>
            <button
              onClick={() => {
                setAddressInputMethod('manual');
                setError('');
                setLedgerAddress('');
              }}
              style={{
                flex: 1,
                padding: '8px 16px',
                borderRadius: '6px',
                border: 'none',
                background: addressInputMethod === 'manual' ? 'white' : 'transparent',
                color: addressInputMethod === 'manual' ? '#374151' : '#6B7280',
                fontWeight: addressInputMethod === 'manual' ? '600' : '500',
                cursor: 'pointer',
                boxShadow:
                  addressInputMethod === 'manual' ? '0 1px 3px rgba(0, 0, 0, 0.1)' : 'none',
              }}
            >
              ✏️ Paste Address
            </button>
          </div>

          {/* Ledger Connection Method */}
          {addressInputMethod === 'ledger' && (
            <>
              <div
                style={{
                  background: '#EBF8FF',
                  border: '1px solid #90CDF4',
                  borderRadius: '12px',
                  padding: '20px',
                  marginBottom: '20px',
                }}
              >
                <p
                  style={{
                    color: '#1E40AF',
                    marginBottom: '16px',
                    margin: '0 0 16px 0',
                  }}
                >
                  Please ensure your Ledger device is:
                </p>
                <ul
                  style={{
                    margin: 0,
                    paddingLeft: '20px',
                    color: '#1E40AF',
                    textAlign: 'left',
                  }}
                >
                  <li style={{ marginBottom: '4px' }}>Connected via USB</li>
                  <li style={{ marginBottom: '4px' }}>Unlocked with your PIN</li>
                  <li style={{ marginBottom: '4px' }}>Ethereum app is open and ready</li>
                </ul>
              </div>

              <div style={{ marginBottom: '20px' }}>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    marginBottom: '12px',
                  }}
                >
                  <label
                    style={{
                      fontSize: '14px',
                      fontWeight: '500',
                      color: '#374151',
                    }}
                  >
                    Ledger Account Index: {ledgerAccount}
                  </label>
                  <button
                    type="button"
                    onClick={() => setShowAdvancedLedger(!showAdvancedLedger)}
                    style={{
                      background: 'transparent',
                      border: '1px solid #D1D5DB',
                      borderRadius: '6px',
                      padding: '4px 8px',
                      fontSize: '12px',
                      color: '#6B7280',
                      cursor: 'pointer',
                      fontWeight: '500',
                    }}
                  >
                    {showAdvancedLedger ? 'Hide Advanced' : 'Advanced'}
                  </button>
                </div>

                {showAdvancedLedger && (
                  <div style={{ marginBottom: '12px' }}>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '12px',
                        marginBottom: '8px',
                      }}
                    >
                      <input
                        type="number"
                        min="0"
                        max="10"
                        value={ledgerAccount}
                        onChange={e => setLedgerAccount(parseInt(e.target.value) || 0)}
                        style={{
                          width: '100px',
                          padding: '8px 12px',
                          border: '1px solid #D1D5DB',
                          borderRadius: '6px',
                          fontSize: '14px',
                        }}
                      />
                      <span
                        style={{
                          fontSize: '14px',
                          color: '#6B7280',
                        }}
                      >
                        HD Path: m/44'/60'/{ledgerAccount}'/0/0
                      </span>
                    </div>
                    <div
                      style={{
                        background: '#F3F4F6',
                        border: '1px solid #D1D5DB',
                        borderRadius: '6px',
                        padding: '8px 12px',
                        fontSize: '12px',
                        color: '#6B7280',
                      }}
                    >
                      💡 Tip: Mainnet Upgrade is likely 0 and Testnet Upgrade is likely 1
                    </div>
                  </div>
                )}
              </div>

              {/* Address retrieval section */}
              {!ledgerAddress ? (
                <button
                  onClick={handleGetLedgerAddress}
                  disabled={loading}
                  style={{
                    background: loading ? '#E5E7EB' : '#6366F1',
                    color: loading ? '#9CA3AF' : 'white',
                    padding: '12px 24px',
                    borderRadius: '8px',
                    border: 'none',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    margin: '0 auto',
                    width: '100%',
                    justifyContent: 'center',
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
                      Getting Address...
                    </>
                  ) : (
                    'Get Ledger Address'
                  )}
                </button>
              ) : (
                <div>
                  <div
                    style={{
                      background: '#D1FAE5',
                      border: '1px solid #6EE7B7',
                      borderRadius: '8px',
                      padding: '16px',
                      marginBottom: '16px',
                    }}
                  >
                    <p
                      style={{
                        margin: '0 0 8px 0',
                        fontSize: '14px',
                        fontWeight: '500',
                        color: '#065F46',
                      }}
                    >
                      ✅ Address Retrieved for Account {ledgerAccount}:
                    </p>
                    <div
                      style={{
                        fontFamily: 'monospace',
                        fontSize: '14px',
                        color: '#14532D',
                        background: '#F0FDF4',
                        padding: '8px',
                        borderRadius: '4px',
                        border: '1px solid #BBF7D0',
                        wordBreak: 'break-all',
                      }}
                    >
                      {ledgerAddress}
                    </div>
                  </div>

                  {/* Single button to get account again */}
                  <button
                    onClick={handleGetLedgerAddress}
                    disabled={loading}
                    style={{
                      background: loading ? '#E5E7EB' : '#6366F1',
                      color: loading ? '#9CA3AF' : 'white',
                      padding: '8px 16px',
                      borderRadius: '6px',
                      border: 'none',
                      fontWeight: '500',
                      cursor: loading ? 'not-allowed' : 'pointer',
                      fontSize: '14px',
                      width: '100%',
                    }}
                  >
                    {loading ? 'Getting...' : `Get Account Again`}
                  </button>
                </div>
              )}
            </>
          )}

          {/* Manual Address Input Method */}
          {addressInputMethod === 'manual' && (
            <div
              style={{
                background: '#FFFBEB',
                border: '1px solid #F59E0B',
                borderRadius: '12px',
                padding: '20px',
                marginBottom: '20px',
              }}
            >
              <p
                style={{
                  color: '#92400E',
                  marginBottom: '16px',
                  margin: '0 0 16px 0',
                }}
              >
                You should only use this for simulation purposes. Signing does not make sense at the
                last step.
              </p>
              <div style={{ marginBottom: '16px' }}>
                <label
                  style={{
                    display: 'block',
                    fontSize: '14px',
                    fontWeight: '500',
                    color: '#92400E',
                    marginBottom: '8px',
                    textAlign: 'left',
                  }}
                >
                  Ethereum Address:
                </label>
                <input
                  type="text"
                  placeholder="0x..."
                  value={manualAddress}
                  onChange={e => handleManualAddressChange(e.target.value)}
                  style={{
                    width: '420px',
                    maxWidth: '100%',
                    padding: '12px',
                    border: `1px solid ${
                      manualAddress && !validateAddress(manualAddress) ? '#DC2626' : '#D1D5DB'
                    }`,
                    borderRadius: '6px',
                    fontSize: '14px',
                    fontFamily: 'monospace',
                  }}
                />
                {manualAddress && !validateAddress(manualAddress) && (
                  <p
                    style={{
                      color: '#DC2626',
                      fontSize: '12px',
                      margin: '4px 0 0 0',
                    }}
                  >
                    Please enter a valid Ethereum address (42 characters starting with 0x)
                  </p>
                )}
              </div>
            </div>
          )}

          {error && (
            <div
              style={{
                background: '#FEE2E2',
                border: '1px solid #FECACA',
                borderRadius: '8px',
                padding: '16px',
                marginTop: '16px',
              }}
            >
              <p
                style={{
                  margin: '0 0 8px 0',
                  fontSize: '14px',
                  fontWeight: '500',
                  color: '#DC2626',
                }}
              >
                ❌ Error:
              </p>
              <p
                style={{
                  margin: 0,
                  fontSize: '14px',
                  color: '#DC2626',
                }}
              >
                {error}
              </p>
              {error.includes('not found') && (
                <p
                  style={{
                    margin: '8px 0 0 0',
                    fontSize: '12px',
                    color: '#DC2626',
                  }}
                >
                  Run:{' '}
                  <code style={{ background: '#FEE2E2', padding: '2px 4px', borderRadius: '4px' }}>
                    make install-eip712sign
                  </code>{' '}
                  in project root
                </p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Proceed Button */}
      {selectedUser && ledgerAddress && (
        <button
          onClick={handleProceed}
          style={{
            background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
            color: 'white',
            padding: '16px 32px',
            borderRadius: '12px',
            fontWeight: '600',
            fontSize: '16px',
            border: 'none',
            cursor: 'pointer',
            fontFamily: 'inherit',
            transition: 'all 0.2s ease',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
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
          Continue to Network Selection →
        </button>
      )}

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
};
