// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SpentSet
 * @notice Enforces one-time token use through atomic freshness checks
 * @dev Gas-optimized using bool mapping instead of uint256
 */
contract SpentSet {
    // Token burn status: tokenId => isSpent
    mapping(bytes32 => bool) public used;
    
    // Authorized wallet contracts allowed to burn tokens
    mapping(address => bool) public authorizedWallet;
    
    address public owner;
    
    event TokenBurned(bytes32 indexed rho, uint256 timestamp, address indexed wallet);
    event WalletAuthorized(address indexed wallet);
    event WalletRevoked(address indexed wallet);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    modifier onlyAuthorizedWallet() {
        require(authorizedWallet[msg.sender], "Wallet not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Authorize a wallet contract to burn tokens
     * @param wallet Address of the BiometricWallet contract
     */
    function authorizeWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid wallet address");
        authorizedWallet[wallet] = true;
        emit WalletAuthorized(wallet);
    }

    /**
     * @notice Revoke wallet authorization
     * @param wallet Address to revoke
     */
    function revokeWallet(address wallet) external onlyOwner {
        authorizedWallet[wallet] = false;
        emit WalletRevoked(wallet);
    }

    /**
     * @notice Mark a token as spent (burn it permanently)
     * @dev Can only be called by authorized wallet contracts
     * @param rho Token identifier (keccak256(R0))
     */
    function markUsed(bytes32 rho) external onlyAuthorizedWallet {
        require(!used[rho], "Token already spent");
        used[rho] = true;
        emit TokenBurned(rho, block.timestamp, msg.sender);
    }

    /**
     * @notice Check if a token has been spent
     * @param rho Token identifier
     * @return True if token is spent, false otherwise
     */
    function isUsed(bytes32 rho) external view returns (bool) {
        return used[rho];
    }
    
    /**
     * @notice Batch check multiple tokens (gas efficient)
     * @param rhos Array of token identifiers
     * @return Array of spent status for each token
     */
    function batchIsUsed(bytes32[] calldata rhos) external view returns (bool[] memory) {
        bool[] memory results = new bool[](rhos.length);
        for (uint256 i = 0; i < rhos.length; i++) {
            results[i] = used[rhos[i]];
        }
        return results;
    }
}

/**
 * REMIX DEPLOYMENT INSTRUCTIONS:
 * ================================
 * 
 * This contract has NO constructor arguments!
 * 
 * STEP-BY-STEP:
 * 1. Compile contract (Ctrl+S)
 * 2. Go to "Deploy & Run Transactions"
 * 3. Select "SpentSet" from dropdown
 * 4. Click "Deploy" (no arguments needed)
 * 5. Save the deployed contract address
 * 
 * AFTER DEPLOYMENT:
 * - Call `authorizeWallet(walletAddress)` to authorize BiometricWallet contracts
 */
