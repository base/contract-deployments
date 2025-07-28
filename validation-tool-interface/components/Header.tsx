import React from 'react';

export const Header: React.FC = () => {
  return (
    <div
      style={{
        textAlign: 'center',
        marginBottom: '48px',
      }}
    >
      <h1
        style={{
          fontSize: '42px',
          fontWeight: '800',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text',
          marginBottom: '16px',
          lineHeight: '1.2',
          margin: 0,
        }}
      >
        Contract Upgrade
        <br />
        Verification Tool
      </h1>
      <p
        style={{
          color: '#6B7280',
          fontSize: '18px',
          lineHeight: '1.6',
          margin: '16px 0 0 0',
        }}
      >
        Streamline your smart contract deployment
        <br />
        verification process with our comprehensive tool.
      </p>
    </div>
  );
};
