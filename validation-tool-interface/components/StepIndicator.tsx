import React from 'react';

interface StepIndicatorProps {
  currentStep: string;
  hasNetwork: boolean;
  hasWallet: boolean;
  hasUser: boolean;
  hasSimulation?: boolean;
}

export const StepIndicator: React.FC<StepIndicatorProps> = ({
  currentStep,
  hasNetwork,
  hasWallet,
  hasUser,
  hasSimulation = false
}) => {
  if (currentStep === 'validation' || currentStep === 'ledger' || currentStep === 'signing') return null;

  const steps = [
    { key: 'network', completed: hasNetwork },
    { key: 'upgrade', completed: hasWallet },
    { key: 'user', completed: hasUser },
    { key: 'simulation', completed: hasSimulation }
  ];

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      marginBottom: '48px'
    }}>
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: '16px'
      }}>
        {steps.map((step, index) => (
          <React.Fragment key={step.key}>
            <div style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: currentStep === step.key || step.completed ? '#6366F1' : '#D1D5DB'
            }}></div>
            {index < steps.length - 1 && (
              <div style={{
                width: '48px',
                height: '2px',
                background: step.completed ? '#6366F1' : '#D1D5DB'
              }}></div>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
};
