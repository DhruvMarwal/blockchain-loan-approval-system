const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying P2PLending contract...");

  const P2PLending = await ethers.getContractFactory("P2PLending");
  const contract = await P2PLending.deploy();

  await contract.waitForDeployment();

  console.log("P2PLending deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
