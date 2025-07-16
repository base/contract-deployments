import React from 'react';

interface StepIndicatorProps {
  currentStep: string;
  hasUser: boolean;
  hasNetwork: boolean;
  hasWallet: boolean;
}

export const StepIndicator: React.FC<StepIndicatorProps> = ({
  currentStep,
  hasUser,
  hasNetwork,
  hasWallet
}) => {
  if (currentStep === 'validation' || currentStep === 'signing') return null;

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
        <div style={{
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          background: currentStep === 'user' || hasUser ? '#6366F1' : '#D1D5DB'
        }}></div>
        <div style={{
          width: '48px',
          height: '2px',
          background: hasUser ? '#6366F1' : '#D1D5DB'
        }}></div>
        <div style={{
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          background: currentStep === 'network' || hasNetwork ? '#6366F1' : '#D1D5DB'
        }}></div>
        <div style={{
          width: '48px',
          height: '2px',
          background: hasNetwork ? '#6366F1' : '#D1D5DB'
        }}></div>
        <div style={{
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          background: currentStep === 'upgrade' || hasWallet ? '#6366F1' : '#D1D5DB'
        }}></div>
      </div>
    </div>
  );
};
