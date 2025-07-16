import Head from 'next/head';
import { useState } from 'react';
import {
  Header,
  Layout,
  LedgerSigning,
  NetworkSelection,
  SelectionSummary,
  SigningConfirmation,
  StepIndicator,
  UpgradeSelection,
  UserSelection,
  ValidationResults,
} from '../components';

type UserType = 'Base SC' | 'Coinbase' | 'OP' | null;
type NetworkType = 'Sepolia' | 'Mainnet' | 'Test' | null;
type UpgradeType = string | null;
type SimulationMethod = 'tenderly' | 'state-diff';
type Step = 'user' | 'network' | 'upgrade' | 'validation' | 'ledger' | 'signing';

interface StateChange {
  key: string;
  before: string;
  after: string;
  description: string;
}

interface Contract {
  name: string;
  address: string;
  changes: StateChange[];
}

interface ValidationData {
  state_changes: Contract[];
}

interface SigningData {
  signature: string;
  signerAddress: string;
  domainHash: string;
  messageHash: string;
}

// Mock upgrade data
const upgradeOptions = [
  {
    id: 1,
    name: 'Smart Wallet v2.1.0',
    description: 'Enhanced security features and gas optimization',
  },
  { id: 2, name: 'Bridge Contract v1.5.2', description: 'Cross-chain functionality improvements' },
  {
    id: 3,
    name: 'Governance Module v3.0.0',
    description: 'New voting mechanisms and proposal system',
  },
  { id: 4, name: 'Token Contract v2.3.1', description: 'ERC-20 compliance updates and bug fixes' },
];

// Mock validation data
const mockExpectedData: ValidationData = {
  state_changes: [
    {
      name: 'System Config',
      address: '0x73a79Fab69143498Ed3712e519A88a918e1f4072',
      changes: [
        {
          key: '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc',
          before: '0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647',
          after: '0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e',
          description: 'Updates the System Config implementation address',
        },
      ],
    },
  ],
};

const mockActualData: ValidationData = {
  state_changes: [
    {
      name: 'System Config',
      address: '0x73a79Fab69143498Ed3712e519A88a918e1f4072',
      changes: [
        {
          key: '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc',
          before: '0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647',
          after: '0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e',
          description: 'Updates the System Config implementation address',
        },
      ],
    },
  ],
};

export default function Home() {
  const [currentStep, setCurrentStep] = useState<Step>('user');
  const [selectedUser, setSelectedUser] = useState<UserType>(null);
  const [selectedNetwork, setSelectedNetwork] = useState<NetworkType>(null);
  const [selectedUpgrade, setSelectedUpgrade] = useState<UpgradeType>(null);
  const [selectedSimulationMethod, setSelectedSimulationMethod] = useState<SimulationMethod | null>(
    null
  );
  const [currentChangeIndex, setCurrentChangeIndex] = useState(0);
  const [validationData, setValidationData] = useState<any>(null);
  const [signingData, setSigningData] = useState<SigningData | null>(null);
  const [userLedgerAddress, setUserLedgerAddress] = useState<string>('');
  const [userLedgerAccount, setUserLedgerAccount] = useState<number>(0);

  const handleUserSelection = (
    userType: UserType,
    ledgerAddress: string,
    ledgerAccount: number
  ) => {
    setSelectedUser(userType);
    setUserLedgerAddress(ledgerAddress);
    setUserLedgerAccount(ledgerAccount);
    setCurrentStep('network');
  };

  const handleNetworkSelection = (network: NetworkType) => {
    setSelectedNetwork(network);
    setCurrentStep('upgrade');
  };

  const handleWalletSelection = (upgradeId: string) => {
    setSelectedUpgrade(upgradeId);
  };

  const handleStartValidation = async (simulationMethod: SimulationMethod) => {
    if (!selectedNetwork || !selectedUpgrade) {
      console.error('❌ Missing network or upgrade selection');
      return;
    }

    setSelectedSimulationMethod(simulationMethod);
    setCurrentStep('validation');
  };

  const handleBackToSetup = () => {
    setCurrentStep('upgrade');
    // Keep user selections but reset upgrade-specific data
    setSelectedUpgrade(null);
    setSelectedSimulationMethod(null);
    setValidationData(null);
    setSigningData(null);
    setCurrentChangeIndex(0);
  };

  const handleProceedToLedgerSigning = (validationResult: any) => {
    setValidationData(validationResult);
    setCurrentStep('ledger');
  };

  const handleLedgerSigningComplete = (signature: string) => {
    // Extract domain and message hash from validation data
    const domainHash = validationData?.expected?.domainAndMessageHashes?.domain_hash || '';
    const messageHash = validationData?.expected?.domainAndMessageHashes?.message_hash || '';

    setSigningData({
      signature,
      signerAddress: userLedgerAddress, // Use the address we already have from user selection
      domainHash,
      messageHash,
    });
    setCurrentStep('signing');
  };

  const handleBackToValidation = () => {
    setCurrentStep('validation');
  };

  const handleBackToLedger = () => {
    setCurrentStep('ledger');
  };

  const handleGoToUserSelection = () => {
    setCurrentStep('user');
    setSelectedUser(null);
    setSelectedNetwork(null);
    setSelectedUpgrade(null);
    setSelectedSimulationMethod(null);
    setValidationData(null);
    setSigningData(null);
    setUserLedgerAddress('');
    setUserLedgerAccount(0);
  };

  const handleGoToNetworkSelection = () => {
    setCurrentStep('network');
    setSelectedNetwork(null);
    setSelectedUpgrade(null);
    setSelectedSimulationMethod(null);
    setValidationData(null);
    setSigningData(null);
  };

  const handleGoToUpgradeSelection = () => {
    setCurrentStep('upgrade');
    setSelectedUpgrade(null);
    setSelectedSimulationMethod(null);
    setValidationData(null);
    setSigningData(null);
  };

  const handleNextChange = () => {
    setCurrentChangeIndex(prev => prev + 1);
  };

  const handlePrevChange = () => {
    setCurrentChangeIndex(prev => prev - 1);
  };

  const totalChanges = 2; // Based on mock data

  return (
    <>
      <Head>
        <title>Contract Deployment Verification Tool</title>
        <meta
          name="description"
          content="Streamline your smart contract deployment verification process"
        />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <Layout
        maxWidth={
          currentStep === 'validation'
            ? '1200px'
            : currentStep === 'ledger'
            ? '800px'
            : currentStep === 'signing'
            ? '800px'
            : currentStep === 'upgrade'
            ? '900px'
            : '600px'
        }
      >
        <Header />

        <StepIndicator
          currentStep={currentStep}
          hasUser={!!selectedUser}
          hasNetwork={!!selectedNetwork}
          hasWallet={!!selectedUpgrade}
        />

        <SelectionSummary
          selectedUser={selectedUser}
          selectedNetwork={selectedNetwork}
          selectedWallet={selectedUpgrade}
          onUserClick={currentStep !== 'user' ? handleGoToUserSelection : undefined}
          onNetworkClick={
            currentStep !== 'user' && currentStep !== 'network'
              ? handleGoToNetworkSelection
              : undefined
          }
          onWalletClick={
            currentStep === 'validation' || currentStep === 'ledger' || currentStep === 'signing'
              ? handleGoToUpgradeSelection
              : undefined
          }
        />

        {currentStep === 'user' && <UserSelection onSelect={handleUserSelection} />}

        {currentStep === 'network' && <NetworkSelection onSelect={handleNetworkSelection} />}

        {currentStep === 'upgrade' && (
          <UpgradeSelection
            selectedWallet={selectedUpgrade}
            selectedNetwork={selectedNetwork}
            onSelect={handleWalletSelection}
            onStartValidation={handleStartValidation}
          />
        )}

        {currentStep === 'validation' && selectedSimulationMethod && (
          <ValidationResults
            userType={selectedUser || ''}
            network={selectedNetwork || ''}
            selectedUpgrade={{
              id: selectedUpgrade || '',
              name: selectedUpgrade || '',
            }}
            simulationMethod={selectedSimulationMethod}
            userLedgerAddress={userLedgerAddress}
            onBackToSetup={handleBackToSetup}
            onProceedToLedgerSigning={handleProceedToLedgerSigning}
          />
        )}

        {currentStep === 'ledger' && validationData && (
          <LedgerSigning
            domainHash={validationData.expected?.domainAndMessageHashes?.domain_hash || ''}
            messageHash={validationData.expected?.domainAndMessageHashes?.message_hash || ''}
            expectedSignerAddress={userLedgerAddress}
            ledgerAccount={userLedgerAccount}
            onSigningComplete={handleLedgerSigningComplete}
            onCancel={handleBackToValidation}
          />
        )}

        {currentStep === 'signing' && selectedSimulationMethod && (
          <SigningConfirmation
            userType={selectedUser || ''}
            network={selectedNetwork || ''}
            selectedUpgrade={{
              id: selectedUpgrade || '',
              name: selectedUpgrade || '',
            }}
            simulationMethod={selectedSimulationMethod}
            signingData={signingData}
            onBackToValidation={handleBackToValidation}
            onBackToLedger={signingData ? handleBackToLedger : undefined}
            onBackToSetup={handleBackToSetup}
          />
        )}
      </Layout>
    </>
  );
}
