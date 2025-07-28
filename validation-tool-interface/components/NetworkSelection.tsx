import React from 'react';

interface NetworkSelectionProps {
  onSelect: (network: 'Mainnet' | 'Sepolia' | 'Test') => void;
}

export const NetworkSelection: React.FC<NetworkSelectionProps> = ({ onSelect }) => {
  const options = ['Mainnet', 'Sepolia', 'Test'] as const;

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
        Which network?
      </h2>
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '12px',
        }}
      >
        {options.map(option => (
          <button
            key={option}
            onClick={() => onSelect(option)}
            style={{
              width: '100%',
              background: 'white',
              border: '1px solid #E5E7EB',
              borderRadius: '12px',
              padding: '20px',
              color: '#374151',
              fontWeight: '500',
              fontSize: '16px',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              fontFamily: 'inherit',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            }}
            onMouseEnter={e => {
              e.currentTarget.style.background = '#F9FAFB';
              e.currentTarget.style.borderColor = '#D1D5DB';
              e.currentTarget.style.transform = 'translateY(-1px)';
              e.currentTarget.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = 'white';
              e.currentTarget.style.borderColor = '#E5E7EB';
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
            }}
          >
            <span>🌐</span> {option}
          </button>
        ))}
      </div>
    </div>
  );
};
