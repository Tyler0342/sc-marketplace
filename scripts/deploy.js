const hre = require("hardhat");

async function main() {
  const MaggiosMarketplace = await hre.ethers.getContractFactory("MaggiosMarketplace");
  const maggiosMarketplace = await MaggiosMarketplace.deploy();

  await maggiosMarketplace.deployed();

  console.log("Maggio's Marketplace deployed to:", maggiosMarketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
