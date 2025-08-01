import { exec } from 'child_process';
import fs from 'fs';
import { NextApiRequest, NextApiResponse } from 'next';
import path from 'path';
import { promisify } from 'util';

const execAsync = promisify(exec);

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { network, upgradeId } = req.body;

    if (!network || !upgradeId) {
      return res.status(400).json({
        error: 'Missing required parameters: network and upgradeId are required',
      });
    }

    const actualNetwork = network.toLowerCase();

    // Construct the path to the upgrade folder and lib subdirectory
    const contractDeploymentsPath = path.join(process.cwd(), '..');
    
    // Handle test network specially - load from validation-tool-interface/test-upgrade instead of root/test
    const upgradePath = actualNetwork === 'test'
      ? path.join(process.cwd(), 'test-upgrade', upgradeId)
      : path.join(contractDeploymentsPath, actualNetwork, upgradeId);
    const libPath = path.join(upgradePath, 'lib');

    // Check if the upgrade folder exists
    if (!fs.existsSync(upgradePath)) {
      return res.status(404).json({
        error: `Upgrade folder not found: ${network}/${upgradeId}`,
      });
    }

    // Check if the lib folder already exists
    const libExists = fs.existsSync(libPath);

    if (libExists) {
      console.log(`✅ Lib folder already exists for ${actualNetwork}/${upgradeId}`);
      return res.status(200).json({
        success: true,
        message: `Dependencies already installed for ${actualNetwork}/${upgradeId}`,
        libExists: true,
        depsInstalled: false, // No installation was needed
      });
    }

    console.log(
      `📦 Lib folder missing for ${actualNetwork}/${upgradeId}, installing dependencies...`
    );
    console.log(`📁 Working directory: ${upgradePath}`);

    // Run make deps in the upgrade folder
    const { stdout, stderr } = await execAsync('make deps', {
      cwd: upgradePath,
      timeout: 300000, // 5 minutes timeout
      env: {
        ...process.env,
        PATH: process.env.PATH,
        HOME: process.env.HOME,
        USER: process.env.USER,
      },
    });

    console.log(`✅ Dependencies installed successfully for ${actualNetwork}/${upgradeId}`);

    if (stdout) {
      console.log('📤 stdout:', stdout);
    }

    if (stderr) {
      console.log('📤 stderr:', stderr);
    }

    // Verify that lib folder was created
    const libExistsAfterInstall = fs.existsSync(libPath);

    if (!libExistsAfterInstall) {
      console.warn(`⚠️ Warning: lib folder still doesn't exist after running make deps`);
    }

    res.status(200).json({
      success: true,
      message: `Dependencies installed successfully for ${actualNetwork}/${upgradeId}`,
      libExists: libExistsAfterInstall,
      depsInstalled: true,
      stdout: stdout || '',
      stderr: stderr || '',
    });
  } catch (error) {
    console.error(`❌ Error installing dependencies:`, error);

    let errorMessage = 'Failed to install dependencies';

    if (error instanceof Error) {
      errorMessage = error.message;

      // Check for specific error patterns to provide better user feedback
      if (error.message.includes('Command failed')) {
        errorMessage = `make deps command failed. ${error.message}`;
      } else if (error.message.includes('timeout')) {
        errorMessage =
          'Dependency installation timed out (5 minutes). This upgrade may require manual setup.';
      } else if (error.message.includes('ENOENT')) {
        errorMessage = 'make command not found. Please ensure make is installed on the system.';
      }
    }

    res.status(500).json({
      success: false,
      error: errorMessage,
    });
  }
}

// Increase timeout for dependency installation
export const config = {
  api: {
    externalResolver: true,
    responseLimit: false,
  },
};
