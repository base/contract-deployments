const path = require("path");
const fs = require("fs");
const solc = require("solc");

const contractsPath = path.resolve(__dirname, "..", "contracts");
const artifactsPath = path.resolve(__dirname, "..", "artifacts");

if (!fs.existsSync(artifactsPath)) {
  fs.mkdirSync(artifactsPath);
}

const contractFiles = fs.readdirSync(contractsPath);

const sources = contractFiles.reduce((acc, file) => {
  const filePath = path.resolve(contractsPath, file);
  const content = fs.readFileSync(filePath, "utf8");
  acc[file] = { content };
  return acc;
}, {});

function findImports(importPath) {
  try {
    const importFullPath = require.resolve(importPath);
    const importContent = fs.readFileSync(importFullPath, "utf8");
    return { contents: importContent };
  } catch (error) {
    return { error: `File not found: ${importPath}` };
  }
}

const compilerInput = {
  language: "Solidity",
  sources: sources,
  settings: {
    outputSelection: {
      "*": {
        "*": ["abi", "evm.bytecode"],
      },
    },
  },
};

console.log("Compiling contracts...");
const compiledContracts = JSON.parse(
  solc.compile(JSON.stringify(compilerInput), { import: findImports })
);


if (compiledContracts.errors) {
  console.error("Compilation errors:");
  let hasErrors = false;
  compiledContracts.errors.forEach((err) => {
    if (err.severity === "error") {
        console.error(err.formattedMessage)
        hasErrors = true;
    }
    else {
        console.warn(err.formattedMessage)
    }
    });
    if (hasErrors) {
        process.exit(1);
    }
}

console.log("Compilation successful!");

for (const contractFile in compiledContracts.contracts) {
  for (const contractName in compiledContracts.contracts[contractFile]) {
    const artifact = {
      abi: compiledContracts.contracts[contractFile][contractName].abi,
      bytecode: compiledContracts.contracts[contractFile][contractName].evm.bytecode.object,
    };
    fs.writeFileSync(
      path.resolve(artifactsPath, `${contractName}.json`),
      JSON.stringify(artifact, null, 2)
    );
    console.log(`- Wrote artifact for ${contractName}`);
  }
}

const compilerVersion = solc.version();
fs.writeFileSync(
  path.resolve(artifactsPath, "solc-version.json"),
  JSON.stringify({ version: compilerVersion }, null, 2)
);
console.log(`- Wrote compiler version: ${compilerVersion}`);
