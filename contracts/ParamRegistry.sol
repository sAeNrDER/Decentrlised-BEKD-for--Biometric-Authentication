// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ParamRegistry
 * @notice Stores immutable CA consortium public key and threshold configuration
 * @dev Optimized for gas efficiency using immutable storage
 */
contract ParamRegistry {
    // Immutable CA public key components (uncompressed secp256k1: 32 + 32 bytes)
    bytes32 public immutable pkCA_x;
    bytes32 public immutable pkCA_y;
    
    // Threshold configuration
    uint8 public immutable thresholdT;
    uint8 public immutable totalNodesN;
    
    // Hash function specification
    string public hashSpec;
    
    event ParamsPublished(
        bytes32 indexed pkCA_x,
        bytes32 indexed pkCA_y,
        uint8 t,
        uint8 n,
        string hashSpec
    );

    /**
     * @notice Deploy with CA public key split into x and y coordinates
     * @param _pkCA_x X coordinate of CA public key (32 bytes)
     * @param _pkCA_y Y coordinate of CA public key (32 bytes)
     * @param _t Threshold (minimum signers required)
     * @param _n Total number of CA nodes
     * @param _hashSpec Hash function specification (e.g., "Keccak256")
     */
    constructor(
        bytes32 _pkCA_x,
        bytes32 _pkCA_y,
        uint8 _t,
        uint8 _n,
        string memory _hashSpec
    ) {
        require(_t < _n, "Threshold must be less than total nodes");
        require(_n >= 3, "Minimum 3 nodes required for fault tolerance");
        require(_t >= 1, "Threshold must be at least 1");
        
        pkCA_x = _pkCA_x;
        pkCA_y = _pkCA_y;
        thresholdT = _t;
        totalNodesN = _n;
        hashSpec = _hashSpec;
        
        emit ParamsPublished(_pkCA_x, _pkCA_y, _t, _n, _hashSpec);
    }

    /**
     * @notice Get CA public key as separate coordinates
     * @return x coordinate, y coordinate
     */
    function getPublicKey() external view returns (bytes32, bytes32) {
        return (pkCA_x, pkCA_y);
    }

    /**
     * @notice Get CA public key as concatenated bytes (64 bytes)
     * @return Full uncompressed public key
     */
    function getPublicKeyBytes() external view returns (bytes memory) {
        return abi.encodePacked(pkCA_x, pkCA_y);
    }

    /**
     * @notice Get threshold configuration
     * @return t (threshold), n (total nodes)
     */
    function getThresholdConfig() external view returns (uint8 t, uint8 n) {
        return (thresholdT, totalNodesN);
    }
    
    /**
     * @notice Get all parameters at once (gas efficient)
     */
    function getAllParams() external view returns (
        bytes32 x,
        bytes32 y,
        uint8 t,
        uint8 n,
        string memory hash
    ) {
        return (pkCA_x, pkCA_y, thresholdT, totalNodesN, hashSpec);
    }
}

/**
 * REMIX DEPLOYMENT INSTRUCTIONS:
 * ================================
 * 
 * Use these EXAMPLE constructor arguments (replace with your actual CA public key):
 * 
 * _pkCA_x: 0x742d35cc6634c0532925a3b844bc9e7eb6ad5f3c4b6f0a5e9b6d8f3e1c2a4b5c
 * _pkCA_y: 0x5c4b3a2c1e3f8d6b9e5a0f6b4c3f5d6e7b8c9e4a5b3c2d1e0f9a8b7c6d5e4f3a
 * _t: 1
 * _n: 3
 * _hashSpec: "Keccak256-H0-H1"
 * 
 * STEP-BY-STEP in Remix:
 * 1. Compile this contract (Ctrl+S)
 * 2. Go to "Deploy & Run Transactions" tab
 * 3. Select "ParamRegistry" from dropdown
 * 4. Expand the deployment box
 * 5. Fill in constructor parameters (see above format)
 * 6. Click "Deploy"
 * 7. Contract address will appear under "Deployed Contracts"
 */
