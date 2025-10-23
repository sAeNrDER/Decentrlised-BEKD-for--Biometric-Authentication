// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BiometricWallet
 * @notice ERC-4337 compatible wallet with EIP-1271 signature validation
 * @dev Integrates BEKD token-based biometric authentication
 */

interface ISpentSet {
    function isUsed(bytes32 rho) external view returns (bool);
    function markUsed(bytes32 rho) external;
}

contract BiometricWallet {
    // ========== State Variables ==========
    
    // Authorized signing keys (derived from biometric K = g^k)
    mapping(address => bool) public authorizedKey;
    
    address public owner;
    ISpentSet public immutable spentSet;
    
    // EIP-712 Domain Separator (computed once)
    bytes32 private immutable DOMAIN_SEPARATOR;
    
    // EIP-712 TypeHash for authentication message
    bytes32 private constant AUTH_MESSAGE_TYPEHASH = 
        keccak256("AuthMessage(bytes32 tokenId,bytes32 userOpHash)");
    
    // EIP-1271 magic values
    bytes4 private constant MAGIC_VALUE = 0x1626ba7e;
    bytes4 private constant INVALID_SIGNATURE = 0xffffffff;
    
    // ========== Events ==========
    
    event AuthorizedKeyAdded(address indexed key);
    event AuthorizedKeyRemoved(address indexed key);
    event OperationExecuted(bytes32 indexed tokenId, bool success);
    event WalletDeployed(address indexed owner, address indexed spentSet);
    
    // ========== Constructor ==========
    
    /**
     * @notice Deploy wallet with biometric-derived owner
     * @param ownerAddr Address derived from K = g^k (biometric key)
     * @param _spentSet Address of deployed SpentSet contract
     */
    constructor(address ownerAddr, address _spentSet) {
        require(ownerAddr != address(0), "Invalid owner address");
        require(_spentSet != address(0), "Invalid SpentSet address");
        
        owner = ownerAddr;
        spentSet = ISpentSet(_spentSet);
        authorizedKey[ownerAddr] = true;
        
        // Initialize EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("BiometricWallet")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        
        emit AuthorizedKeyAdded(ownerAddr);
        emit WalletDeployed(ownerAddr, _spentSet);
    }
    
    // ========== Key Management ==========
    
    /**
     * @notice Add authorized signing key
     * @param key Address to authorize
     */
    function addAuthorizedKey(address key) external {
        require(msg.sender == owner || msg.sender == address(this), "Unauthorized");
        require(key != address(0), "Invalid key");
        authorizedKey[key] = true;
        emit AuthorizedKeyAdded(key);
    }
    
    /**
     * @notice Remove authorized signing key
     * @param key Address to revoke
     */
    function removeAuthorizedKey(address key) external {
        require(msg.sender == owner || msg.sender == address(this), "Unauthorized");
        require(key != owner, "Cannot revoke owner");
        authorizedKey[key] = false;
        emit AuthorizedKeyRemoved(key);
    }
    
    // ========== Authentication (ERC-4337 Style) ==========
    
    /**
     * @notice Validate user operation with biometric token
     * @param rho Token identifier (keccak256(R0))
     * @param userOpHash Hash of the user operation
     * @param signature ECDSA signature (65 bytes: r, s, v)
     * @return success True if validation succeeds
     */
    function validateUserOp(
        bytes32 rho,
        bytes32 userOpHash,
        bytes memory signature
    ) external returns (bool success) {
        // Step 1: Check token freshness
        require(!spentSet.isUsed(rho), "Token already spent");
        
        // Step 2: Compute EIP-712 typed hash
        bytes32 typedHash = _hashTypedDataV4(rho, userOpHash);
        
        // Step 3: Verify signature
        address signer = _recoverSigner(typedHash, signature);
        require(signer != address(0), "Invalid signature");
        require(authorizedKey[signer], "Unauthorized signer");
        
        // Step 4: Burn token atomically
        spentSet.markUsed(rho);
        
        emit OperationExecuted(rho, true);
        return true;
    }
    
    /**
     * @notice Simplified validation (without userOpHash)
     * @dev Useful for testing
     */
    function validateUserOpSimple(
        bytes32 rho,
        bytes memory signature
    ) external returns (bool success) {
        return this.validateUserOp(rho, bytes32(0), signature);
    }
    
    // ========== EIP-1271: Contract Signature Validation ==========
    
    /**
     * @notice Validate signature according to EIP-1271
     * @param hash Message hash
     * @param signature ECDSA signature
     * @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) public view returns (bytes4 magicValue) {
        address signer = _recoverSigner(hash, signature);
        
        if (signer != address(0) && authorizedKey[signer]) {
            return MAGIC_VALUE;
        }
        
        return INVALID_SIGNATURE;
    }
    
    // ========== Internal Functions ==========
    
    /**
     * @notice Compute EIP-712 typed hash
     * @param tokenId Token identifier (ρ)
     * @param userOpHash User operation hash
     * @return Typed structured hash
     */
    function _hashTypedDataV4(
        bytes32 tokenId,
        bytes32 userOpHash
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                AUTH_MESSAGE_TYPEHASH,
                tokenId,
                userOpHash
            )
        );
        
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
    }
    
    /**
     * @notice Recover signer from ECDSA signature
     * @param hash Message hash
     * @param signature 65-byte signature (r, s, v)
     * @return signer Recovered address (address(0) if invalid)
     */
    function _recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address signer) {
        if (signature.length != 65) {
            return address(0);
        }
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        // Handle Ethereum's chain-specific v values
        if (v < 27) {
            v += 27;
        }
        
        if (v != 27 && v != 28) {
            return address(0);
        }
        
        return ecrecover(hash, v, r, s);
    }
    
    // ========== View Functions ==========
    
    /**
     * @notice Check if an address is authorized
     */
    function isAuthorized(address key) external view returns (bool) {
        return authorizedKey[key];
    }
    
    /**
     * @notice Get domain separator
     */
    function domainSeparator() external view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }
    
    /**
     * @notice Get auth message typehash
     */
    function authMessageTypehash() external pure returns (bytes32) {
        return AUTH_MESSAGE_TYPEHASH;
    }
    
    // ========== Receive ETH ==========
    
    receive() external payable {}
    
    fallback() external payable {}
}

/**
 * REMIX DEPLOYMENT INSTRUCTIONS:
 * ================================
 * 
 * Constructor Parameters:
 * 
 * ownerAddr: [Address derived from biometric K, e.g. 0x742d35Cc6634C0532925a3b844bc9e7eb6ad5f3C]
 * _spentSet: [Deployed SpentSet contract address, e.g. 0x5c4b3a2C1e3f8D6b9e5A0F6B4c3F5d6E7b8c9E4a]
 * 
 * STEP-BY-STEP:
 * 1. Deploy SpentSet first
 * 2. Generate owner address from Python (biometric K)
 * 3. Compile BiometricWallet (Ctrl+S)
 * 4. Fill constructor:
 *    - ownerAddr: <biometric-derived address>
 *    - _spentSet: <SpentSet contract address>
 * 5. Click "Deploy"
 * 6. Go to SpentSet contract
 * 7. Call authorizeWallet(<BiometricWallet address>)
 * 
 * TESTING:
 * - Use validateUserOpSimple() for basic testing
 * - Use isValidSignature() to test EIP-1271
 */
