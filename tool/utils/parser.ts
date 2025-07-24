import { z } from 'zod';
import {
  ParsedConfig,
  ParseResult,
  StateChange,
  StateOverride,
  TaskConfig,
} from './types/index';

// Zod validation schemas
const AddressSchema = z.string().regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum address');
const HashSchema = z.string().regex(/^0x[a-fA-F0-9]{64}$/, 'Invalid hash format');

const ExpectedHashesSchema = z.object({
  address: AddressSchema,
  domain_hash: HashSchema,
  message_hash: HashSchema,
});

const OverrideSchema = z.object({
  key: HashSchema,
  value: HashSchema,
  description: z.string(),
});

const StateOverrideSchema = z.object({
  name: z.string().min(1),
  address: AddressSchema,
  overrides: z.array(OverrideSchema),
});

const ChangeSchema = z.object({
  key: HashSchema,
  before: HashSchema,
  after: HashSchema,
  description: z.string(),
});

const StateChangeSchema = z.object({
  name: z.string().min(1),
  address: AddressSchema,
  changes: z.array(ChangeSchema),
});

const TaskConfigSchema = z.object({
  task_name: z.string().min(1),
  script_name: z.string().min(1),
  signature: z.string().min(1),
  args: z.string(), // Allow empty string for scripts with no arguments
  "ledger-id": z.number().int().nonnegative(), // Required ledger account index
  expected_domain_and_message_hashes: ExpectedHashesSchema,
  expected_nested_hash: z
    .string()
    .refine(
      val => val === '' || /^0x[a-fA-F0-9]{64}$/.test(val),
      'Must be empty string or valid 32-byte hex hash'
    ),
  state_overrides: z.array(StateOverrideSchema),
  state_changes: z.array(StateChangeSchema),
});

export class ConfigParser {
  /**
   * Parse a JSON configuration file using Zod for validation
   *
   * @param jsonData - Raw JSON object containing multisig configuration
   * @returns ParsedConfig object with config and validation results
   */
  static parseConfig(jsonData: any): ParsedConfig {
    try {
      // Parse and validate using Zod
      const config = TaskConfigSchema.parse(jsonData);
      return {
        config,
        result: {
          success: true,
        },
      };
    } catch (error) {
      return {
        config: this.getDefaultConfig(),
        result: {
          success: false,
          zodError:
            error instanceof z.ZodError
              ? error
              : new z.ZodError([
                  {
                    code: z.ZodIssueCode.custom,
                    path: [],
                    message: `Failed to parse configuration: ${error instanceof Error ? error.message : 'Unknown error'}`,
                  },
                ]),
        },
      };
    }
  }

  /**
   * Parse JSON string and return parsed config
   */
  static parseFromString(jsonString: string): ParsedConfig {
    try {
      const jsonData = JSON.parse(jsonString);
      return this.parseConfig(jsonData);
    } catch (error) {
      // Create a ZodError for JSON parsing errors
      const jsonError = new z.ZodError([
        {
          code: z.ZodIssueCode.custom,
          path: [],
          message: `Invalid JSON: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ]);

      return {
        config: this.getDefaultConfig(),
        result: {
          success: false,
          zodError: jsonError,
        },
      };
    }
  }

  /**
   * Helper method to get validation summary using ZodError
   */
  static getValidationSummary(result: ParseResult): string {
    if (result.success) {
      return '✅ Configuration is valid';
    }

    // We always have zodError when success is false
    const parts: string[] = ['❌ Configuration has errors'];

    parts.push(`\nErrors (${result.zodError!.issues.length}):`);
    result.zodError!.issues.forEach(issue => {
      const path = issue.path.length > 0 ? `${issue.path.join('.')}: ` : '';
      parts.push(`  • ${path}${issue.message}`);
    });

    return parts.join('\n');
  }

  private static getDefaultConfig(): TaskConfig {
    return {
      task_name: '',
      script_name: '',
      signature: '',
      args: '',
      "ledger-id": 0,
      expected_domain_and_message_hashes: { address: '', domain_hash: '', message_hash: '' },
      expected_nested_hash: '',
      state_overrides: [],
      state_changes: [],
    };
  }
}

// Utility functions for working with parsed configurations
export class ConfigUtils {
  /**
   * Find state override by contract name
   */
  static findStateOverride(config: TaskConfig, contractName: string): StateOverride | undefined {
    return config.state_overrides.find((override: StateOverride) =>
      override.name.toLowerCase().includes(contractName.toLowerCase())
    );
  }

  /**
   * Find state override by contract address (exact match)
   */
  static findStateOverrideByAddress(
    config: TaskConfig,
    contractAddress: string
  ): StateOverride | undefined {
    return config.state_overrides.find(
      (override: StateOverride) => override.address.toLowerCase() === contractAddress.toLowerCase()
    );
  }

  /**
   * Find state change by contract name
   */
  static findStateChange(config: TaskConfig, contractName: string): StateChange | undefined {
    return config.state_changes.find((change: StateChange) =>
      change.name.toLowerCase().includes(contractName.toLowerCase())
    );
  }

  /**
   * Find state change by contract address (exact match)
   */
  static findStateChangeByAddress(
    config: TaskConfig,
    contractAddress: string
  ): StateChange | undefined {
    return config.state_changes.find(
      (change: StateChange) => change.address.toLowerCase() === contractAddress.toLowerCase()
    );
  }

  /**
   * Get all addresses from configuration
   */
  static getAllAddresses(config: TaskConfig): string[] {
    const addresses = new Set<string>();

    // Add multisig address
    if (config.expected_domain_and_message_hashes?.address) {
      addresses.add(config.expected_domain_and_message_hashes.address);
    }

    // Add state override addresses
    config.state_overrides?.forEach((override: StateOverride) => {
      if (override.address) addresses.add(override.address);
    });

    // Add state change addresses
    config.state_changes?.forEach((change: StateChange) => {
      if (change.address) addresses.add(change.address);
    });

    return Array.from(addresses);
  }

  /**
   * Validate configuration completeness
   */
  static validateCompleteness(config: TaskConfig): { isComplete: boolean; issues: string[] } {
    const issues: string[] = [];

    if (!config.task_name) issues.push('Missing task name');
    if (!config.script_name) issues.push('Missing script name');
    if (!config.signature) issues.push('Missing script signature');
    // args can be empty for scripts that don't require arguments
    if (!config.expected_domain_and_message_hashes?.address)
      issues.push('Missing multisig address');
    if (config.state_overrides?.length === 0) issues.push('No state overrides defined');
    if (config.state_changes?.length === 0) issues.push('No state changes defined');

    return {
      isComplete: issues.length === 0,
      issues,
    };
  }
}
