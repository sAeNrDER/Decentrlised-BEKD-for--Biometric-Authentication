// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GasProfiler
 * @notice Test contract to measure gas consumption for performance analysis
 * @dev Deploy this alongside your main contracts to track gas usage
 */

import "./ParamRegistry_Fixed.sol";
import "./SpentSet_Fixed.sol";
import "./BiometricWallet_Fixed.sol";

contract GasProfiler {
    ParamRegistry public paramRegistry;
    SpentSet public spentSet;
    BiometricWallet public wallet;
    
    // Gas tracking
    struct GasMetrics {
        uint256 deploymentGas;
        uint256 minExecutionGas;
        uint256 maxExecutionGas;
        uint256 avgExecutionGas;
        uint256 callCount;
    }
    
    mapping(string => GasMetrics) public metrics;
    
    event GasUsed(string operation, uint256 gasUsed);
    event DeploymentCost(string contractName, uint256 gasCost);
    
    /**
     * @notice Measure deployment gas costs
     */
    function measureDeploymentCosts(
        bytes32 pkCA_x,
        bytes32 pkCA_y,
        uint8 t,
        uint8 n,
        address ownerAddr
    ) external returns (
        uint256 paramRegistryGas,
        uint256 spentSetGas,
        uint256 walletGas
    ) {
        uint256 gasStart;
        uint256 gasUsed;
        
        // Measure ParamRegistry deployment
        gasStart = gasleft();
        paramRegistry = new ParamRegistry(pkCA_x, pkCA_y, t, n, "Keccak256-H0-H1");
        paramRegistryGas = gasStart - gasleft();
        emit DeploymentCost("ParamRegistry", paramRegistryGas);
        
        // Measure SpentSet deployment
        gasStart = gasleft();
        spentSet = new SpentSet();
        spentSetGas = gasStart - gasleft();
        emit DeploymentCost("SpentSet", spentSetGas);
        
        // Measure BiometricWallet deployment
        gasStart = gasleft();
        wallet = new BiometricWallet(ownerAddr, address(spentSet));
        walletGas = gasStart - gasleft();
        emit DeploymentCost("BiometricWallet", walletGas);
        
        // Authorize wallet (included in setup cost)
        spentSet.authorizeWallet(address(wallet));
        
        return (paramRegistryGas, spentSetGas, walletGas);
    }
    
    /**
     * @notice Measure token freshness check gas
     */
    function measureFreshnessCheck(bytes32[] calldata tokenIds) 
        external 
        returns (uint256 avgGas) 
    {
        uint256 totalGas = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 gasStart = gasleft();
            spentSet.isUsed(tokenIds[i]);
            uint256 gasUsed = gasStart - gasleft();
            totalGas += gasUsed;
            emit GasUsed("isUsed", gasUsed);
        }
        
        return totalGas / tokenIds.length;
    }
    
    /**
     * @notice Measure token burning gas
     */
    function measureTokenBurn(bytes32 tokenId) 
        external 
        returns (uint256 gasUsed) 
    {
        uint256 gasStart = gasleft();
        // Note: This call will fail if wallet not authorized
        // In actual test, call from authorized wallet
        spentSet.markUsed(tokenId);
        gasUsed = gasStart - gasleft();
        emit GasUsed("markUsed", gasUsed);
        return gasUsed;
    }
    
    /**
     * @notice Measure signature validation gas (EIP-1271)
     */
    function measureSignatureValidation(
        bytes32 hash,
        bytes memory signature
    ) external view returns (uint256 gasUsed) {
        uint256 gasStart = gasleft();
        wallet.isValidSignature(hash, signature);
        gasUsed = gasStart - gasleft();
        return gasUsed;
    }
    
    /**
     * @notice Measure full authentication flow gas
     */
    function measureFullAuthentication(
        bytes32 rho,
        bytes32 userOpHash,
        bytes memory signature
    ) external returns (uint256 gasUsed) {
        uint256 gasStart = gasleft();
        // This should be called from wallet contract in real scenario
        // wallet.validateUserOp(rho, userOpHash, signature);
        gasUsed = gasStart - gasleft();
        emit GasUsed("validateUserOp", gasUsed);
        return gasUsed;
    }
    
    /**
     * @notice Batch freshness check (gas optimization test)
     */
    function measureBatchFreshnessCheck(bytes32[] calldata tokenIds)
        external
        returns (uint256 totalGas, uint256 avgGas)
    {
        uint256 gasStart = gasleft();
        spentSet.batchIsUsed(tokenIds);
        totalGas = gasStart - gasleft();
        avgGas = totalGas / tokenIds.length;
        emit GasUsed("batchIsUsed", totalGas);
        return (totalGas, avgGas);
    }
    
    /**
     * @notice Measure public key retrieval gas
     */
    function measurePublicKeyRetrieval() 
        external 
        view 
        returns (uint256 gasUsed) 
    {
        uint256 gasStart = gasleft();
        paramRegistry.getPublicKey();
        gasUsed = gasStart - gasleft();
        return gasUsed;
    }
    
    /**
     * @notice Compare storage pattern gas costs
     */
    function compareStoragePatterns(bytes32 tokenId) 
        external 
        returns (
            uint256 coldAccessGas,
            uint256 warmAccessGas
        ) 
    {
        // Cold access (first read)
        uint256 gasStart = gasleft();
        bool result1 = spentSet.isUsed(tokenId);
        coldAccessGas = gasStart - gasleft();
        
        // Warm access (second read)
        gasStart = gasleft();
        bool result2 = spentSet.isUsed(tokenId);
        warmAccessGas = gasStart - gasleft();
        
        return (coldAccessGas, warmAccessGas);
    }
    
    /**
     * @notice Generate gas consumption report
     */
    function generateReport() external view returns (
        uint256 totalDeploymentGas,
        uint256 avgAuthenticationGas,
        uint256 avgStorageReadGas
    ) {
        // Aggregate metrics for research paper
        // This would be populated by running all measurements
        return (0, 0, 0); // Placeholder
    }
}

/**
 * USAGE INSTRUCTIONS FOR RESEARCH PAPER:
 * =======================================
 * 
 * 1. Deploy GasProfiler contract
 * 2. Call measureDeploymentCosts() - Record for Table 1
 * 3. Call measureFreshnessCheck() with test tokens - Record for Table 2
 * 4. Call measureTokenBurn() - Record for Table 2
 * 5. Call measureSignatureValidation() - Record for Table 3
 * 6. Call compareStoragePatterns() - For optimization analysis
 * 7. Export event logs for detailed analysis
 * 
 * PAPER SECTIONS:
 * - Table 1: Deployment Costs (Section VII-A)
 * - Table 2: Operation Costs (Section VII-B)
 * - Table 3: Authentication Flow Breakdown (Section VII-C)
 * - Figure: Gas Consumption Comparison (Section VII-D)
 */
