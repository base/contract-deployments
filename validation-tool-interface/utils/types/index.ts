// ------------------------------- Validation Task Configs -------------------------------
export interface TaskConfig {
  task_name: string;
  script_name: string;
  signature: string;
  args: string;
  "ledger-id": number; // Required field for ledger account index
  expected_domain_and_message_hashes: ExpectedHashes;
  expected_nested_hash: string;
  state_overrides: StateOverride[];
  state_changes: StateChange[];
}

export interface ExpectedHashes {
  address: string;
  domain_hash: string;
  message_hash: string;
}

export interface StateOverride {
  name: string;
  address: string;
  overrides: Override[];
}

export interface Override {
  key: string;
  value: string;
  description: string;
}

export interface StateChange {
  name: string;
  address: string;
  changes: Change[];
}

export interface Change {
  key: string;
  before: string;
  after: string;
  description: string;
}

export interface ParseResult {
  success: boolean;
  zodError?: import('zod').ZodError;
}

export interface ParsedConfig {
  config: TaskConfig;
  result: ParseResult;
}

// ------------------------------- Script Runner Output -------------------------------
export interface SimulationLink {
  url: string;
  network: string;
  contractAddress: string;
  from: string;
  stateOverrides?: string;
  rawFunctionInput?: string;
}

export interface NestedHash {
  safeAddress: string;
  hash: string;
}

export interface ApprovalHash {
  safeAddress: string;
  hash: string;
}

export interface SigningData {
  dataToSign: string;
}

export interface ExtractedData {
  nestedHashes: NestedHash[];
  simulationLink?: SimulationLink;
  approvalHash?: ApprovalHash;
  signingData?: SigningData;
}

export interface ScriptRunnerOptions {
  scriptPath: string;
  rpcUrl: string;
  scriptName: string;
  signature?: string;
  args?: string[];
  sender?: string;
  saveOutput?: string; // Optional: save raw output to file
  extractOnly?: boolean; // Extract from existing file
}

// ------------------------------- Diff Comparison Types -------------------------------
export type DiffType = 'added' | 'removed' | 'modified' | 'unchanged';

export interface StringDiff {
  type: DiffType;
  value: string;
  startIndex?: number;
  endIndex?: number;
}

export interface FieldDiff {
  field: string;
  path: string; // e.g., "name", "overrides[0].key", "changes[1].description"
  expected: string;
  actual: string;
  diffs: StringDiff[]; // Character-level or word-level diffs
  type: DiffType;
}

export interface ObjectDiff {
  type: 'StateOverride' | 'StateChange' | 'Override' | 'Change';
  index?: number;
  fieldDiffs: FieldDiff[];
  status: 'match' | 'mismatch' | 'added' | 'removed';
}

export interface ComparisonResult {
  // Human-readable summary
  summary: string;
  status: 'match' | 'mismatch';

  // Structured diff data for frontend highlighting
  diffs: ObjectDiff[];

  // Statistics
  stats: {
    totalFields: number;
    matchingFields: number;
    mismatchedFields: number;
    addedFields: number;
    removedFields: number;
  };
}

// ------------------------------- Tenderly API Types -------------------------------
export interface TenderlySimulationRequest {
  network_id: string;
  from: string;
  to: string;
  input: string;
  gas?: number;
  block_number?: number;
  value?: string;
  save?: boolean;
  save_if_fails?: boolean;
  simulation_type?: string;
  state_objects?: { [contractAddress: string]: TenderlyStateObject };
}

export interface TenderlyStateObject {
  nonce?: number;
  code?: string;
  balance?: {
    value: string;
  };
  stateDiff?: { [storageSlot: string]: string };
}

export interface TenderlySimulationResponse {
  simulation: {
    id: string;
    status: boolean;
    block_number: number;
    network_id: string;
    gas_used: number;
    error_message?: string;
    state_diff?: { [address: string]: { [slot: string]: { from: string; to: string } } };
  };
  transaction?: {
    'transaction-info'?: {
      call_trace?: {
        state_diff?: Array<{
          address: string;
          soltype?: {
            name: string;
            type: string;
            storage_location: string;
            offset: number;
            index: string;
            indexed: boolean;
            simple_type: {
              type: string;
            };
          };
          original: string;
          dirty: string;
          raw?: Array<{
            address: string;
            key: string;
            original: string;
            dirty: string;
          }>;
        }>;
      };
    };
  };
}

// ------------------------------- State Diff Types -------------------------------
export interface StateDiffOptions {
  rpcUrl: string;
  workdir: string;
  sender: string;
  scriptArgs?: string[];
  prefix?: string;
  suffix?: string;
}

export interface ExtractedStateDiffOptions {
  rpcUrl: string;
  extractedData: ExtractedData;
}

export interface StateDiffResult {
  domain_hash: string;
  message_hash: string;
  target_safe: string;
  state_overrides: StateOverride[];
  state_changes: StateChange[];
}

// ------------------------------- Validation Data (Last Steps) Types -------------------------------
export interface ValidationData {
  expected: {
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
    domainAndMessageHashes?: {
      address: string;
      domain_hash: string;
      message_hash: string;
    };
  };
  actual: {
    stateOverrides: StateOverride[];
    stateChanges: StateChange[];
  };
  extractedData?: ExtractedData;
  tenderlyResponse?: TenderlySimulationResponse;
  stateDiffOutput?: string;
}
