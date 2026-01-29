async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Example = await ethers.getContractFactory("ExampleContract");
  const example = await Example.deploy();
  await example.deployed();

  console.log("Example deployed at:", example.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
