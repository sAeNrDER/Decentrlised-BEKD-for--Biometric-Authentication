const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require('fs');

/**
 * Comprehensive Gas Profiling Tests for Research Paper
 * Generates data for Section VII: Performance Analysis
 */

describe("Gas Consumption Analysis", function () {
    let paramRegistry, spentSet, biometricWallet, gasProfiler;
    let owner, user1, user2;
    let deploymentGas = {};
    let operationGas = {};
    
    // Test parameters (from deployment_params.txt)
    const CA_PUBLIC_KEY_X = "0xe979882d5deec5bfe551e5624f6534d2d45ddbdae57b64f9dd43fd37f6f8239e";
    const CA_PUBLIC_KEY_Y = "0xae764de15f98ef5b0de9dc9488d6c323bef1f01db2ca3db9a6f652f9af7ccd28";
    const THRESHOLD_T = 1;
    const TOTAL_NODES_N = 3;
    const HASH_SPEC = "Keccak256-H0-H1";
    
    before(async function () {
        [owner, user1, user2] = await ethers.getSigners();
    });
    
    describe("1. Deployment Gas Costs (Table 1)", function () {
        it("Should measure ParamRegistry deployment", async function () {
            const ParamRegistry = await ethers.getContractFactory("ParamRegistry");
            const tx = await ParamRegistry.deploy(
                CA_PUBLIC_KEY_X,
                CA_PUBLIC_KEY_Y,
                THRESHOLD_T,
                TOTAL_NODES_N,
                HASH_SPEC
            );
            const receipt = await tx.deployTransaction.wait();
            
            deploymentGas.paramRegistry = receipt.gasUsed.toNumber();
            console.log(`ParamRegistry deployment: ${deploymentGas.paramRegistry} gas`);
            
            paramRegistry = tx;
        });
        
        it("Should measure SpentSet deployment", async function () {
            const SpentSet = await ethers.getContractFactory("SpentSet");
            const tx = await SpentSet.deploy();
            const receipt = await tx.deployTransaction.wait();
            
            deploymentGas.spentSet = receipt.gasUsed.toNumber();
            console.log(`SpentSet deployment: ${deploymentGas.spentSet} gas`);
            
            spentSet = tx;
        });
        
        it("Should measure BiometricWallet deployment", async function () {
            const BiometricWallet = await ethers.getContractFactory("BiometricWallet");
            const tx = await BiometricWallet.deploy(user1.address, spentSet.address);
            const receipt = await tx.deployTransaction.wait();
            
            deploymentGas.biometricWallet = receipt.gasUsed.toNumber();
            console.log(`BiometricWallet deployment: ${deploymentGas.biometricWallet} gas`);
            
            biometricWallet = tx;
        });
        
        it("Should measure wallet authorization gas", async function () {
            const tx = await spentSet.authorizeWallet(biometricWallet.address);
            const receipt = await tx.wait();
            
            deploymentGas.authorization = receipt.gasUsed.toNumber();
            console.log(`Wallet authorization: ${deploymentGas.authorization} gas`);
        });
        
        it("Should calculate total deployment cost", async function () {
            const total = Object.values(deploymentGas).reduce((a, b) => a + b, 0);
            deploymentGas.total = total;
            console.log(`\nTotal deployment: ${total} gas`);
            console.log(`Estimated cost at 30 gwei: ${ethers.utils.formatEther(ethers.BigNumber.from(total).mul(30))} ETH`);
        });
    });
    
    describe("2. Read Operation Gas Costs (Table 2)", function () {
        it("Should measure getPublicKey() - cold access", async function () {
            const gasEstimate = await paramRegistry.estimateGas.getPublicKey();
            operationGas.getPublicKey_cold = gasEstimate.toNumber();
            console.log(`getPublicKey (cold): ${operationGas.getPublicKey_cold} gas`);
        });
        
        it("Should measure getPublicKey() - warm access", async function () {
            await paramRegistry.getPublicKey(); // Warm up
            const gasEstimate = await paramRegistry.estimateGas.getPublicKey();
            operationGas.getPublicKey_warm = gasEstimate.toNumber();
            console.log(`getPublicKey (warm): ${operationGas.getPublicKey_warm} gas`);
        });
        
        it("Should measure getThresholdConfig()", async function () {
            const gasEstimate = await paramRegistry.estimateGas.getThresholdConfig();
            operationGas.getThresholdConfig = gasEstimate.toNumber();
            console.log(`getThresholdConfig: ${operationGas.getThresholdConfig} gas`);
        });
        
        it("Should measure isUsed() - fresh token", async function () {
            const tokenId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test-token-1"));
            const gasEstimate = await spentSet.estimateGas.isUsed(tokenId);
            operationGas.isUsed_fresh = gasEstimate.toNumber();
            console.log(`isUsed (fresh): ${operationGas.isUsed_fresh} gas`);
        });
        
        it("Should measure isAuthorized()", async function () {
            const gasEstimate = await biometricWallet.estimateGas.isAuthorized(user1.address);
            operationGas.isAuthorized = gasEstimate.toNumber();
            console.log(`isAuthorized: ${operationGas.isAuthorized} gas`);
        });
    });
    
    describe("3. Write Operation Gas Costs (Table 3)", function () {
        it("Should measure markUsed() - first token burn", async function () {
            const tokenId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test-token-1"));
            
            // Authorize this test contract
            await spentSet.authorizeWallet(owner.address);
            
            const tx = await spentSet.markUsed(tokenId);
            const receipt = await tx.wait();
            
            operationGas.markUsed_first = receipt.gasUsed.toNumber();
            console.log(`markUsed (first token): ${operationGas.markUsed_first} gas`);
        });
        
        it("Should measure markUsed() - subsequent tokens", async function () {
            const tokenId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test-token-2"));
            
            const tx = await spentSet.markUsed(tokenId);
            const receipt = await tx.wait();
            
            operationGas.markUsed_subsequent = receipt.gasUsed.toNumber();
            console.log(`markUsed (subsequent): ${operationGas.markUsed_subsequent} gas`);
        });
        
        it("Should measure addAuthorizedKey()", async function () {
            const tx = await biometricWallet.connect(user1).addAuthorizedKey(user2.address);
            const receipt = await tx.wait();
            
            operationGas.addAuthorizedKey = receipt.gasUsed.toNumber();
            console.log(`addAuthorizedKey: ${operationGas.addAuthorizedKey} gas`);
        });
    });
    
    describe("4. Signature Validation Gas (Table 4)", function () {
        let messageHash, signature;
        
        before(async function () {
            // Create test signature
            messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test-message"));
            signature = await user1.signMessage(ethers.utils.arrayify(messageHash));
        });
        
        it("Should measure isValidSignature() - EIP-1271", async function () {
            const gasEstimate = await biometricWallet.estimateGas.isValidSignature(
                messageHash,
                signature
            );
            operationGas.isValidSignature = gasEstimate.toNumber();
            console.log(`isValidSignature (EIP-1271): ${operationGas.isValidSignature} gas`);
        });
        
        it("Should measure ecrecover cost", async function () {
            // Direct ecrecover comparison
            const TestEcrecover = await ethers.getContractFactory("TestEcrecover");
            const testContract = await TestEcrecover.deploy();
            
            const gasEstimate = await testContract.estimateGas.testEcrecover(
                messageHash,
                signature
            );
            operationGas.ecrecover_baseline = gasEstimate.toNumber();
            console.log(`ecrecover (baseline): ${operationGas.ecrecover_baseline} gas`);
        });
    });
    
    describe("5. Authentication Flow Gas (Table 5)", function () {
        it("Should measure complete authentication flow", async function () {
            const tokenId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("auth-token-1"));
            const userOpHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("user-operation"));
            
            // Create EIP-712 signature
            const domain = {
                name: "BiometricWallet",
                version: "1",
                chainId: await ethers.provider.getNetwork().then(n => n.chainId),
                verifyingContract: biometricWallet.address
            };
            
            const types = {
                AuthMessage: [
                    { name: "tokenId", type: "bytes32" },
                    { name: "userOpHash", type: "bytes32" }
                ]
            };
            
            const value = {
                tokenId: tokenId,
                userOpHash: userOpHash
            };
            
            const signature = await user1._signTypedData(domain, types, value);
            
            const tx = await biometricWallet.validateUserOp(tokenId, userOpHash, signature);
            const receipt = await tx.wait();
            
            operationGas.fullAuthentication = receipt.gasUsed.toNumber();
            console.log(`Full authentication flow: ${operationGas.fullAuthentication} gas`);
        });
    });
    
    describe("6. Batch Operations Comparison (Table 6)", function () {
        it("Should measure individual isUsed() calls", async function () {
            const tokenIds = Array.from({length: 10}, (_, i) => 
                ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`batch-token-${i}`))
            );
            
            let totalGas = 0;
            for (const tokenId of tokenIds) {
                const gasEstimate = await spentSet.estimateGas.isUsed(tokenId);
                totalGas += gasEstimate.toNumber();
            }
            
            operationGas.individual_checks = totalGas;
            operationGas.individual_checks_avg = totalGas / tokenIds.length;
            console.log(`Individual checks (10 tokens): ${totalGas} gas`);
            console.log(`Average per token: ${totalGas / tokenIds.length} gas`);
        });
        
        it("Should measure batch isUsed() call", async function () {
            const tokenIds = Array.from({length: 10}, (_, i) => 
                ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`batch-token-${i}`))
            );
            
            const gasEstimate = await spentSet.estimateGas.batchIsUsed(tokenIds);
            
            operationGas.batch_checks = gasEstimate.toNumber();
            operationGas.batch_checks_avg = gasEstimate.toNumber() / tokenIds.length;
            console.log(`Batch check (10 tokens): ${operationGas.batch_checks} gas`);
            console.log(`Average per token: ${operationGas.batch_checks_avg} gas`);
            
            const savings = ((operationGas.individual_checks - operationGas.batch_checks) / operationGas.individual_checks * 100).toFixed(2);
            console.log(`Gas savings: ${savings}%`);
        });
    });
    
    after(function () {
        // Generate comprehensive report
        console.log("\n========================================");
        console.log("FINAL GAS CONSUMPTION REPORT");
        console.log("========================================\n");
        
        console.log("DEPLOYMENT COSTS:");
        console.log("-".repeat(40));
        for (const [operation, gas] of Object.entries(deploymentGas)) {
            console.log(`${operation.padEnd(25)}: ${gas.toLocaleString()} gas`);
        }
        
        console.log("\n\nOPERATION COSTS:");
        console.log("-".repeat(40));
        for (const [operation, gas] of Object.entries(operationGas)) {
            console.log(`${operation.padEnd(25)}: ${gas.toLocaleString()} gas`);
        }
        
        // Save to JSON for Python analysis
        const results = {
            deployment: deploymentGas,
            operations: operationGas,
            timestamp: new Date().toISOString(),
            network: "hardhat"
        };
        
        fs.writeFileSync(
            './test-results/gas-profile.json',
            JSON.stringify(results, null, 2)
        );
        
        console.log("\n✅ Results saved to: test-results/gas-profile.json");
    });
});

// Helper contract for ecrecover testing
const TestEcrecoverSource = `
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TestEcrecover {
    function testEcrecover(bytes32 hash, bytes memory signature) 
        external 
        pure 
        returns (address) 
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        if (v < 27) v += 27;
        
        return ecrecover(hash, v, r, s);
    }
}
`;

/**
 * RUNNING THE TESTS:
 * ==================
 * 
 * 1. Setup Hardhat project:
 *    npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers
 * 
 * 2. Configure hardhat.config.js:
 *    module.exports = {
 *      solidity: "0.8.20",
 *      gasReporter: {
 *        enabled: true,
 *        currency: 'USD'
 *      }
 *    };
 * 
 * 3. Run tests:
 *    npx hardhat test test/gas-profiling.test.js --network hardhat
 * 
 * 4. Results will be saved to: test-results/gas-profile.json
 * 
 * FOR RESEARCH PAPER:
 * Use the generated JSON to populate tables in Section VII
 */
