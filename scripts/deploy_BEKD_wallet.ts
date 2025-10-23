// scripts/deploy_bekd_wallet.ts
import { ethers } from "ethers";
import { hardhat } from "hardhat"; // Remix exposes hardhat.ethers shim

(async () => {
  const provider = new ethers.providers.Web3Provider((window as any).ethereum);
  const signer = provider.getSigner();

  // Load compiled artifacts from Remix
  const ParamRegistry = await (hardhat as any).ethers.getContractFactory("ParamRegistry", signer);
  const SpentSet = await (hardhat as any).ethers.getContractFactory("SpentSet", signer);
  const BiometricWallet = await (hardhat as any).ethers.getContractFactory("BiometricWallet", signer);

  const pkCA = "0x" + "11".repeat(64); // 64 bytes dummy
  const t = 1, n = 3;

  const param = await ParamRegistry.deploy(pkCA, t, n);
  await param.deployed();
  console.log("ParamRegistry:", param.address);

  const spent = await SpentSet.deploy();
  await spent.deployed();
  console.log("SpentSet:", spent.address);

  const ownerAddr = await signer.getAddress(); // placeholder; replace with derived wallet later
  const wallet = await BiometricWallet.deploy(ownerAddr, spent.address);
  await wallet.deployed();
  console.log("BiometricWallet:", wallet.address);

  const tx = await spent.authorizeWallet(wallet.address, true);
  await tx.wait();
  console.log("Authorized wallet in SpentSet");
})();
