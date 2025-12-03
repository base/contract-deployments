const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const artifactsPath = path.resolve(__dirname, "..", "artifacts");

async function main() {
  const allContracts = fs.readdirSync(artifactsPath)
    .filter(f => f.endsWith('.json') && f !== 'solc-version.json')
    .map((file) => file.replace(".json", ""));

  const availableContracts = allContracts.filter(c => !c.startsWith("I") && !c.startsWith("E") && c !== "Ownable" && c !== "Context" && c !== "Strings" && c !== "ERC165" && c !== "Math" && c !== "SafeCast" && c !== "SignedMath" && c !== "EnumerableSet" && c !== "Address" && c !== "SillyStringUtils" && c !== "Employee" && c !== "Hourly" && c !== "Manager" && c !== "Salaried" && c !== "Salesperson" && c !== "EngineeringManager");

  const contractToDeploy = process.argv[2];

  if (!contractToDeploy) {
    console.log("Please provide the name of the contract to deploy.");
    console.log("\nAvailable contracts:");
    availableContracts.forEach(c => console.log(`- ${c}`));
    process.exit(1);
  }

  if (!availableContracts.includes(contractToDeploy)) {
    console.error(`Error: Contract "${contractToDeploy}" not found or is not a deployable contract.`);
    console.log("\nAvailable contracts:");
    availableContracts.forEach(c => console.log(`- ${c}`));
    process.exit(1);
  }

  console.log(`Deploying ${contractToDeploy}...`);

  const provider = new ethers.JsonRpcProvider("https://sepolia.base.org");
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  const artifact = JSON.parse(
    fs.readFileSync(path.resolve(artifactsPath, `${contractToDeploy}.json`))
  );

  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  let contract;
  let constructorArgs = [];

  // Handle special deployment cases with constructor arguments
  if (contractToDeploy === "EmployeeStorage") {
    constructorArgs = [1000, "Pat", 50000, 112358132134];
    contract = await factory.deploy(...constructorArgs);
  } else if (contractToDeploy === "InheritanceSubmission") {
    console.log("The 'Inheritance' exercise requires deploying two contracts first.");
    const SalespersonArtifact = JSON.parse(fs.readFileSync(path.resolve(artifactsPath, "Salesperson.json")));
    const EngineeringManagerArtifact = JSON.parse(fs.readFileSync(path.resolve(artifactsPath, "EngineeringManager.json")));

    const SalespersonFactory = new ethers.ContractFactory(SalespersonArtifact.abi, SalespersonArtifact.bytecode, wallet);
    const EngineeringManagerFactory = new ethers.ContractFactory(EngineeringManagerArtifact.abi, EngineeringManagerArtifact.bytecode, wallet);

    console.log("Deploying Salesperson...");
    const salesperson = await SalespersonFactory.deploy(55555, 12345, 20);
    await salesperson.waitForDeployment();
    const salespersonAddress = await salesperson.getAddress();
    console.log(`Salesperson deployed to: ${salespersonAddress}`);

    console.log("Deploying EngineeringManager...");
    const engineeringManager = await EngineeringManagerFactory.deploy(54321, 11111, 200000);
    await engineeringManager.waitForDeployment();
    const engineeringManagerAddress = await engineeringManager.getAddress();
    console.log(`EngineeringManager deployed to: ${engineeringManagerAddress}`);

    constructorArgs = [salespersonAddress, engineeringManagerAddress];
    contract = await factory.deploy(...constructorArgs);
  } else if (contractToDeploy === "WeightedVoting") {
    constructorArgs = ["MyVoteToken", "MVT"];
    contract = await factory.deploy(...constructorArgs);
  }
  else {
    contract = await factory.deploy();
  }

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.log(`\n✅ ${contractToDeploy} deployed successfully!`);
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`View on BaseScan: https://sepolia.basescan.org/address/${contractAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
