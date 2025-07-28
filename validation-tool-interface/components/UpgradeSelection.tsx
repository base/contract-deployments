import React, { useEffect, useState } from 'react';

interface ExecutionLink {
  url: string;
  label: string;
}

interface Upgrade {
  id: string;
  name: string;
  description: string;
  date: string;
  network: string;
  status?: 'EXECUTED' | 'READY TO SIGN' | 'PENDING';
  executionLinks?: ExecutionLink[];
}

interface UpgradeSelectionProps {
  selectedWallet: string | null;
  selectedNetwork: string | null;
  onSelect: (upgradeId: string) => void;
}

export const UpgradeSelection: React.FC<UpgradeSelectionProps> = ({
  selectedWallet,
  selectedNetwork,
  onSelect,
}) => {
  const [upgradeOptions, setUpgradeOptions] = useState<Upgrade[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!selectedNetwork) return;

    const fetchUpgrades = async () => {
      setLoading(true);
      setError(null);

      try {
        const network = selectedNetwork.toLowerCase();
        const response = await fetch(`/api/upgrades?network=${network}`);

        if (!response.ok) {
          throw new Error('Failed to fetch upgrades');
        }

        const upgrades = await response.json();
        setUpgradeOptions(upgrades);
      } catch (err) {
        setError('Failed to load upgrades');
        console.error('Error fetching upgrades:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchUpgrades();
  }, [selectedNetwork]);

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '40px' }}>
        <div
          style={{
            display: 'inline-block',
            width: '32px',
            height: '32px',
            border: '3px solid #f3f3f3',
            borderTop: '3px solid #6366F1',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
          }}
        ></div>
        <p style={{ marginTop: '16px', color: '#6B7280' }}>Loading upgrades...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ textAlign: 'center', padding: '40px' }}>
        <p style={{ color: '#DC2626', marginBottom: '16px' }}>{error}</p>
        <button
          onClick={() => window.location.reload()}
          style={{
            background: '#6366F1',
            color: 'white',
            padding: '8px 16px',
            borderRadius: '8px',
            border: 'none',
            cursor: 'pointer',
          }}
        >
          Retry
        </button>
      </div>
    );
  }

  if (upgradeOptions.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '40px' }}>
        <p style={{ color: '#6B7280' }}>No upgrades available for {selectedNetwork}</p>
      </div>
    );
  }

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
        Which upgrade do you want to validate?
      </h2>

      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '20px',
          marginBottom: '32px',
          maxHeight: '400px',
          overflowY: 'auto',
          paddingRight: '8px',
        }}
      >
        {upgradeOptions.map(option => (
          <button
            key={option.id}
            onClick={() => onSelect(option.id)}
            onMouseEnter={e => {
              if (selectedWallet !== option.id) {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.1)';
              }
            }}
            onMouseLeave={e => {
              if (selectedWallet !== option.id) {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
              }
            }}
            style={{
              width: '100%',
              textAlign: 'left',
              borderRadius: '20px',
              padding: '28px 32px',
              border: selectedWallet === option.id ? 'none' : '1px solid #E5E7EB',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              fontFamily: 'inherit',
              background:
                selectedWallet === option.id
                  ? 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)'
                  : '#F9FAFB',
              color: selectedWallet === option.id ? 'white' : '#374151',
              boxShadow:
                selectedWallet === option.id
                  ? '0 10px 25px rgba(99, 102, 241, 0.3)'
                  : '0 2px 4px rgba(0, 0, 0, 0.05)',
              position: 'relative',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start',
                marginBottom: '12px',
              }}
            >
              <div style={{ flex: 1, marginRight: '16px' }}>
                <div
                  style={{
                    fontSize: '20px',
                    fontWeight: '700',
                    marginBottom: '4px',
                    lineHeight: '1.2',
                  }}
                >
                  {option.name}
                </div>
                <div
                  style={{
                    fontSize: '14px',
                    opacity: selectedWallet === option.id ? 0.9 : 0.7,
                    fontWeight: '500',
                  }}
                >
                  {option.date}
                </div>
              </div>

              <StatusBadge status={option.status} executionLinks={option.executionLinks} />
            </div>

            <div
              style={{
                fontSize: '16px',
                lineHeight: '1.5',
                opacity: selectedWallet === option.id ? 0.95 : 0.8,
              }}
            >
              {option.description}
            </div>

            {selectedWallet === option.id && (
              <div
                style={{
                  position: 'absolute',
                  top: '20px',
                  right: '20px',
                  background: 'rgba(255, 255, 255, 0.2)',
                  borderRadius: '50%',
                  width: '32px',
                  height: '32px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '16px',
                  fontWeight: '700',
                }}
              >
                ✓
              </div>
            )}
          </button>
        ))}
      </div>

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

const StatusBadge: React.FC<{
  status?: string;
  executionLinks?: ExecutionLink[];
}> = ({ status, executionLinks }) => {
  const [showDropdown, setShowDropdown] = useState(false);

  if (!status) return null;

  const getStatusStyle = (status: string) => {
    switch (status) {
      case 'EXECUTED':
        return {
          backgroundColor: '#DCFCE7', // green-100
          color: '#166534', // green-800
          borderColor: '#BBF7D0', // green-200
        };
      case 'READY TO SIGN':
        return {
          backgroundColor: '#FEF3C7', // yellow-100
          color: '#92400E', // yellow-800
          borderColor: '#FDE68A', // yellow-200
        };
      case 'PENDING':
        return {
          backgroundColor: '#F3F4F6', // gray-100
          color: '#1F2937', // gray-800
          borderColor: '#E5E7EB', // gray-200
        };
      default:
        return {
          backgroundColor: '#F3F4F6', // gray-100
          color: '#1F2937', // gray-800
          borderColor: '#E5E7EB', // gray-200
        };
    }
  };

  const handleLinkClick = (url: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  // If it's executed and has links
  if (status === 'EXECUTED' && executionLinks && executionLinks.length > 0) {
    // Single link - make the badge clickable
    if (executionLinks.length === 1) {
      const styles = getStatusStyle(status);
      return (
        <span
          style={{
            padding: '4px 8px',
            borderRadius: '9999px',
            fontSize: '12px',
            fontWeight: '500',
            border: `1px solid ${styles.borderColor}`,
            cursor: 'pointer',
            transition: 'opacity 0.2s ease',
            ...styles,
          }}
          onClick={e => handleLinkClick(executionLinks[0].url, e)}
          title={`View transaction: ${executionLinks[0].label}`}
          onMouseEnter={e => {
            e.currentTarget.style.opacity = '0.8';
          }}
          onMouseLeave={e => {
            e.currentTarget.style.opacity = '1';
          }}
        >
          {status}
        </span>
      );
    }

    // Multiple links - show dropdown on hover
    const styles = getStatusStyle(status);
    return (
      <div
        style={{
          position: 'relative',
          display: 'inline-block',
        }}
        onMouseEnter={() => setShowDropdown(true)}
        onMouseLeave={() => setShowDropdown(false)}
      >
        <span
          style={{
            padding: '4px 8px',
            borderRadius: '9999px',
            fontSize: '12px',
            fontWeight: '500',
            border: `1px solid ${styles.borderColor}`,
            cursor: 'pointer',
            transition: 'opacity 0.2s ease',
            ...styles,
          }}
          title="Multiple transactions available - hover to see options"
          onMouseEnter={e => {
            e.currentTarget.style.opacity = '0.8';
          }}
          onMouseLeave={e => {
            e.currentTarget.style.opacity = '1';
          }}
        >
          {status} ({executionLinks.length})
        </span>

        {showDropdown && (
          <div
            style={{
              position: 'absolute',
              top: '100%',
              left: '0',
              marginTop: '4px',
              backgroundColor: 'white',
              border: '1px solid #E5E7EB',
              borderRadius: '6px',
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
              zIndex: 50,
              minWidth: '192px',
            }}
          >
            <div style={{ padding: '4px 0' }}>
              {executionLinks.map((link, index) => (
                <button
                  key={index}
                  onClick={e => handleLinkClick(link.url, e)}
                  style={{
                    display: 'block',
                    width: '100%',
                    textAlign: 'left',
                    padding: '8px 12px',
                    fontSize: '14px',
                    color: '#374151',
                    backgroundColor: 'transparent',
                    border: 'none',
                    cursor: 'pointer',
                    transition: 'background-color 0.2s ease',
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.backgroundColor = '#F3F4F6';
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }}
                >
                  <div style={{ fontWeight: '500' }}>{link.label}</div>
                  <div
                    style={{
                      fontSize: '12px',
                      color: '#6B7280',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {link.url.includes('etherscan.io') ? 'Etherscan' : 'Transaction'}
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  }

  // Regular status badge (not executed or no links)
  const styles = getStatusStyle(status);
  return (
    <span
      style={{
        padding: '4px 8px',
        borderRadius: '9999px',
        fontSize: '12px',
        fontWeight: '500',
        border: `1px solid ${styles.borderColor}`,
        ...styles,
      }}
    >
      {status}
    </span>
  );
};
