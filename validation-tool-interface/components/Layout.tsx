import Image from 'next/image';
import React from 'react';

interface LayoutProps {
  children: React.ReactNode;
  maxWidth?: string;
}

export const Layout: React.FC<LayoutProps> = ({ children, maxWidth = '600px' }) => {
  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
      padding: '32px 16px',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center'
    }}>
      <div style={{
        width: '100%',
        maxWidth: maxWidth,
        margin: '0 auto',
        transition: 'max-width 0.3s ease'
      }}>
        {/* Logo */}
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          marginBottom: '32px'
        }}>
          <div style={{
            width: '120px',
            height: '120px',
            borderRadius: '50%',
            background: 'white',
            boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden'
          }}>
            <Image
              src="/base.jpg"
              alt="Base Logo"
              width={120}
              height={120}
              style={{ borderRadius: '50%' }}
            />
          </div>
        </div>

        {/* Main Card */}
        <div style={{
          background: 'white',
          borderRadius: '32px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          padding: '48px',
          marginBottom: '32px'
        }}>
          {children}
        </div>
      </div>
    </div>
  );
};
