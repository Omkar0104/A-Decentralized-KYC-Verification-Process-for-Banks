const hre = require("hardhat");
async function main() {
  const BankKycSystem = await hre.ethers.getContractFactory("BankKycSystem");

  const bankKycSystem = await BankKycSystem.deploy();
  await bankKycSystem.deployed();
  console.log(" BankKycSystem deployed to:" + bankKycSystem.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
