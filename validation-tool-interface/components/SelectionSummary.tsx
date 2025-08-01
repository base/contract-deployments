import React from 'react';

interface SelectionSummaryProps {
  selectedUser: string | null;
  selectedNetwork: string | null;
  selectedWallet: string | null;
  onUserClick?: () => void;
  onNetworkClick?: () => void;
  onWalletClick?: () => void;
}

export const SelectionSummary: React.FC<SelectionSummaryProps> = ({
  selectedUser,
  selectedNetwork,
  selectedWallet,
  onUserClick,
  onNetworkClick,
  onWalletClick
}) => {
  if (!selectedUser && !selectedNetwork && !selectedWallet) return null;

  // Format user display name from filename (base-nested -> Base Nested)
  const formatUserDisplayName = (fileName: string) => {
    return fileName
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  const badgeBaseStyle = {
    color: 'white',
    padding: '6px 14px',
    borderRadius: '16px',
    fontSize: '13px',
    fontWeight: '500',
    boxShadow: '0 2px 4px rgba(99, 102, 241, 0.3)',
    transition: 'all 0.2s ease',
    border: 'none',
    fontFamily: 'inherit'
  };

  const clickableBadgeStyle = {
    ...badgeBaseStyle,
    background: 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)',
    cursor: 'pointer'
  };

  const nonClickableBadgeStyle = {
    ...badgeBaseStyle,
    background: 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)'
  };

  return (
    <div style={{
      background: 'rgba(238, 242, 255, 0.5)',
      borderRadius: '16px',
      padding: '20px',
      marginBottom: '32px',
      backdropFilter: 'blur(10px)',
      border: '1px solid rgba(255, 255, 255, 0.2)'
    }}>
      <h3 style={{
        textAlign: 'center',
        color: '#4B5563',
        fontWeight: '600',
        marginBottom: '12px',
        fontSize: '14px',
        margin: '0 0 12px 0',
        textTransform: 'uppercase',
        letterSpacing: '0.05em'
      }}>Your Selections</h3>
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        flexWrap: 'wrap',
        gap: '8px'
      }}>
        {/* NEW ORDER: Network, Upgrade, User */}
        
        {selectedNetwork && (
          onNetworkClick ? (
            <button
              onClick={onNetworkClick}
              style={{
                ...clickableBadgeStyle,
                display: 'flex',
                alignItems: 'center',
                gap: '4px'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #5B21B6 0%, #7C3AED 100%)';
                e.currentTarget.style.transform = 'translateY(-1px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
              title="Click to change network selection"
            >
              <span>🌐</span> {selectedNetwork}
            </button>
          ) : (
            <span style={{
              ...nonClickableBadgeStyle,
              display: 'flex',
              alignItems: 'center',
              gap: '4px'
            }}>
              <span>🌐</span> {selectedNetwork}
            </span>
          )
        )}

        {selectedWallet && (
          onWalletClick ? (
            <button
              onClick={onWalletClick}
              style={clickableBadgeStyle}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #5B21B6 0%, #7C3AED 100%)';
                e.currentTarget.style.transform = 'translateY(-1px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
              title="Click to change upgrade selection"
            >
              {selectedWallet}
            </button>
          ) : (
            <span style={nonClickableBadgeStyle}>
              {selectedWallet}
            </span>
          )
        )}

        {selectedUser && (
          onUserClick ? (
            <button
              onClick={onUserClick}
              style={clickableBadgeStyle}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #5B21B6 0%, #7C3AED 100%)';
                e.currentTarget.style.transform = 'translateY(-1px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
              title="Click to change user selection"
            >
              {formatUserDisplayName(selectedUser)}
            </button>
          ) : (
            <span style={nonClickableBadgeStyle}>
              {formatUserDisplayName(selectedUser)}
            </span>
          )
        )}
      </div>
    </div>
  );
};
