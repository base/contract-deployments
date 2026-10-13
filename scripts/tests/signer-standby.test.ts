import { afterEach, beforeEach, describe, expect, it } from '@jest/globals';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { NextRequest } from 'next/server';
import { getUpgradeOptions, resetContractDeploymentsRootCacheForTests } from '../src/lib/deployments';
import { NetworkType } from '../src/lib/types';
import { GET } from '../src/app/api/upgrade-config/route';
import { POST } from '../src/app/api/install-deps/route';

let root: string;
const originalCwd = process.cwd();
const activeId = '2026-10-01-active';
const standbyId = 'delay-upgrade-activation';

function invocation(lifecycle: string, id: string, withValidation = true) {
  const task = path.join(root, lifecycle, 'evm', 'tasks', id);
  const config = path.join(task, 'config', 'mainnet');
  fs.mkdirSync(config, { recursive: true });
  fs.writeFileSync(path.join(config, 'README.md'), '# Fixture\n\nStatus: READY TO SIGN\n');
  if (withValidation) {
    fs.mkdirSync(path.join(config, 'validations'));
    fs.writeFileSync(path.join(config, 'validations', 'base-signer.json'), JSON.stringify({
      cmd: "node -e require('fs').writeFileSync('from-validation-service',process.env.RECORD_STATE_DIFF);process.exit(73)",
      ledgerId: 3,
      rpcUrl: 'http://127.0.0.1:1',
      skipTaskOriginValidation: true,
      expectedDomainAndMessageHashes: {
        address: '0x0000000000000000000000000000000000001234',
        domainHash: '0x' + '11'.repeat(32),
        messageHash: '0x' + '22'.repeat(32),
      },
      stateOverrides: [],
      stateChanges: [],
    }));
  }
  return task;
}

beforeEach(() => {
  root = fs.mkdtempSync(path.join(os.tmpdir(), 'signer-standby-'));
  fs.mkdirSync(path.join(root, 'active', 'evm', 'tasks'), { recursive: true });
  process.chdir(root);
  resetContractDeploymentsRootCacheForTests();
});
afterEach(() => {
  process.chdir(originalCwd);
  resetContractDeploymentsRootCacheForTests();
  fs.rmSync(root, { recursive: true, force: true });
});

describe('standby invocations in the pinned signer', () => {
  it('discovers standby only once JSON validations exist and keeps active and legacy behavior', () => {
    invocation('active', activeId);
    const task = invocation('standby', standbyId, false);
    invocation('active', 'dateless-not-active');
    invocation('archive', '2026-10-02-historical');
    fs.mkdirSync(path.join(root, 'mainnet', '2026-10-03-legacy', 'validations'), { recursive: true });
    expect(getUpgradeOptions(NetworkType.Mainnet).map(task => task.id)).toEqual([activeId]);
    fs.mkdirSync(path.join(task, 'config', 'mainnet', 'validations'));
    expect(getUpgradeOptions(NetworkType.Mainnet).map(task => task.id)).toEqual([activeId]);
    fs.writeFileSync(path.join(task, 'config', 'mainnet', 'validations', 'base-signer.json'), '{}');
    expect(getUpgradeOptions(NetworkType.Mainnet).map(task => task.id).sort()).toEqual([activeId, standbyId].sort());
    expect(getUpgradeOptions(NetworkType.Sepolia)).toEqual([]);
  });

  it('loads validation options from standby through the real config API', async () => {
    invocation('standby', standbyId);
    const response = await GET(new NextRequest(`http://localhost/api/upgrade-config?network=mainnet&upgradeId=${standbyId}`));
    expect(response.status).toBe(200);
    expect((await response.json()).configOptions.map((option: { fileName: string }) => option.fileName)).toEqual(['base-signer']);
    invocation('active', activeId);
    const active = await GET(new NextRequest(`http://localhost/api/upgrade-config?network=mainnet&upgradeId=${activeId}`));
    expect((await active.json()).configOptions.map((option: { fileName: string }) => option.fileName)).toEqual(['base-signer']);
  });

  it('loads standby config for validation and starts simulation in the shared project', async () => {
    invocation('standby', standbyId);
    const { validateUpgrade } = await import('../src/lib/validation-service');
    await expect(validateUpgrade({ upgradeId: standbyId, network: NetworkType.Mainnet, taskConfigFileName: 'base-signer' })).rejects.toThrow('forge command failed with exit code 73');
    expect(fs.readFileSync(path.join(root, 'active/evm/from-validation-service'), 'utf8')).toBe('true');
  });

  it('installs from the selected standby task while retaining the shared active project', async () => {
    const task = invocation('standby', standbyId);
    fs.writeFileSync(path.join(task, 'Makefile'), 'deps:\n\t@test "$(TASK_NETWORK)" = mainnet\n\t@mkdir -p ../../../../active/evm/lib\n\t@printf ready > config/mainnet/deps-result\n');
    const response = await POST(new NextRequest('http://localhost/api/install-deps', { method: 'POST', body: JSON.stringify({ network: 'mainnet', upgradeId: standbyId }) }));
    expect(response.status).toBe(200);
    expect((await response.json()).libExists).toBe(true);
    expect(fs.readFileSync(path.join(task, 'config/mainnet/deps-result'), 'utf8')).toBe('ready');
  });
});
