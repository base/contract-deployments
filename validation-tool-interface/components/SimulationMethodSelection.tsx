import React, { useState } from 'react';

type SimulationMethod = 'tenderly' | 'state-diff';

interface SimulationMethodSelectionProps {
  onSelect: (method: SimulationMethod) => void;
}

export const SimulationMethodSelection: React.FC<SimulationMethodSelectionProps> = ({ 
  onSelect 
}) => {
  const [selectedSimulationMethod, setSelectedSimulationMethod] = useState<SimulationMethod | null>(null);

  const handleStartValidation = () => {
    if (selectedSimulationMethod) {
      onSelect(selectedSimulationMethod);
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
        Choose simulation method
      </h2>

      <div
        style={{
          display: 'flex',
          gap: '20px',
          justifyContent: 'center',
          marginBottom: '32px',
        }}
      >
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => setSelectedSimulationMethod('state-diff')}
            onMouseEnter={e => {
              if (selectedSimulationMethod !== 'state-diff') {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.1)';
              }
            }}
            onMouseLeave={e => {
              if (selectedSimulationMethod !== 'state-diff') {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
              }
            }}
            style={{
              padding: '20px 24px',
              borderRadius: '16px',
              border: selectedSimulationMethod === 'state-diff' ? 'none' : '1px solid #E5E7EB',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              fontFamily: 'inherit',
              background:
                selectedSimulationMethod === 'state-diff'
                  ? 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)'
                  : '#F9FAFB',
              color: selectedSimulationMethod === 'state-diff' ? 'white' : '#374151',
              boxShadow:
                selectedSimulationMethod === 'state-diff'
                  ? '0 10px 25px rgba(99, 102, 241, 0.3)'
                  : '0 2px 4px rgba(0, 0, 0, 0.05)',
              width: '280px',
              textAlign: 'left',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                marginBottom: '8px',
              }}
            >
              <span style={{ fontSize: '24px' }}>⚡</span>
              <span style={{ fontSize: '18px', fontWeight: '600' }}>State-Diff</span>
            </div>
            <p
              style={{
                fontSize: '14px',
                margin: 0,
                opacity: selectedSimulationMethod === 'state-diff' ? 0.9 : 0.7,
              }}
            >
              Base's Go-based simulation with native EVM execution
            </p>
          </button>

          {/* Recommended Badge with Arrow */}
          <div
            style={{
              position: 'absolute',
              top: '-12px',
              right: '-8px',
              background: '#10B981',
              color: 'white',
              padding: '4px 8px',
              borderRadius: '12px',
              fontSize: '11px',
              fontWeight: '600',
              boxShadow: '0 2px 4px rgba(16, 185, 129, 0.3)',
              zIndex: 10,
            }}
          >
            ✨ RECOMMENDED
          </div>

          {/* Arrow pointing to the button */}
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '-20px',
              transform: 'translateY(-50%)',
              fontSize: '20px',
              color: '#10B981',
              animation: 'bounce 2s infinite',
            }}
          >
            👉
          </div>
        </div>

        <button
          onClick={() => setSelectedSimulationMethod('tenderly')}
          onMouseEnter={e => {
            if (selectedSimulationMethod !== 'tenderly') {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.1)';
            }
          }}
          onMouseLeave={e => {
            if (selectedSimulationMethod !== 'tenderly') {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.05)';
            }
          }}
          style={{
            padding: '20px 24px',
            borderRadius: '16px',
            border: selectedSimulationMethod === 'tenderly' ? 'none' : '1px solid #E5E7EB',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            fontFamily: 'inherit',
            background:
              selectedSimulationMethod === 'tenderly'
                ? 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)'
                : '#F9FAFB',
            color: selectedSimulationMethod === 'tenderly' ? 'white' : '#374151',
            boxShadow:
              selectedSimulationMethod === 'tenderly'
                ? '0 10px 25px rgba(99, 102, 241, 0.3)'
                : '0 2px 4px rgba(0, 0, 0, 0.05)',
            width: '280px',
            textAlign: 'left',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '8px',
            }}
          >
            <span style={{ fontSize: '24px' }}>☁️</span>
            <span style={{ fontSize: '18px', fontWeight: '600' }}>Tenderly</span>
          </div>
          <p
            style={{
              fontSize: '14px',
              margin: 0,
              opacity: selectedSimulationMethod === 'tenderly' ? 0.9 : 0.7,
            }}
          >
            Third-party simulation service
          </p>
        </button>
      </div>

      {/* Show Start Validation button only after a method is selected */}
      {selectedSimulationMethod && (
        <button
          onClick={handleStartValidation}
          style={{
            background: 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%)',
            color: 'white',
            padding: '16px 32px',
            borderRadius: '20px',
            fontWeight: '700',
            fontSize: '18px',
            border: 'none',
            cursor: 'pointer',
            boxShadow: '0 10px 25px rgba(99, 102, 241, 0.3)',
            transition: 'all 0.3s ease',
            textTransform: 'uppercase',
            letterSpacing: '1px',
            minWidth: '200px',
          }}
          onMouseEnter={e => {
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = '0 15px 35px rgba(99, 102, 241, 0.4)';
          }}
          onMouseLeave={e => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 10px 25px rgba(99, 102, 241, 0.3)';
          }}
        >
          Start Validation
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

        @keyframes bounce {
          0%,
          20%,
          50%,
          80%,
          100% {
            transform: translateY(-50%) translateX(0);
          }
          40% {
            transform: translateY(-50%) translateX(-5px);
          }
          60% {
            transform: translateY(-50%) translateX(-3px);
          }
        }
      `}</style>
    </div>
  );
}; 