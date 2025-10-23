#!/usr/bin/env python3
"""
Generate constructor parameters for Remix deployment
This script helps create properly formatted arguments for deploying contracts
"""

from eth_utils import keccak, to_checksum_address, to_hex
from py_ecc.secp256k1 import secp256k1
import secrets

def generate_ca_keypair():
    """Generate a sample CA threshold keypair"""
    # Generate private key
    sk = secrets.randbelow(secp256k1.N - 1) + 1
    
    # Compute public key K = g^sk
    pk = secp256k1.multiply(secp256k1.G, sk)
    
    return sk, pk

def point_to_bytes32_pair(point):
    """Convert EC point to two bytes32 values for Solidity"""
    x, y = point
    x_bytes32 = x.to_bytes(32, 'big')
    y_bytes32 = y.to_bytes(32, 'big')
    return x_bytes32, y_bytes32

def point_to_address(point):
    """Convert EC point to Ethereum address"""
    x, y = point
    public_key = x.to_bytes(32, 'big') + y.to_bytes(32, 'big')
    hash_output = keccak(public_key)
    address = to_checksum_address(hash_output[-20:])
    return address

def format_for_remix(value, value_type):
    """Format values for Remix deployment"""
    if value_type == "bytes32":
        return to_hex(value)
    elif value_type == "address":
        return value
    elif value_type == "uint":
        return str(value)
    elif value_type == "string":
        return f'"{value}"'
    return str(value)

def main():
    print("=" * 70)
    print("REMIX DEPLOYMENT PARAMETER GENERATOR")
    print("=" * 70)
    print()
    
    # Generate CA keypair
    print("🔑 Generating CA Threshold Keypair...")
    ca_sk, ca_pk = generate_ca_keypair()
    
    # Convert to Solidity format
    pk_x, pk_y = point_to_bytes32_pair(ca_pk)
    
    print(f"✅ CA Private Key (for testing): {hex(ca_sk)}")
    print(f"✅ CA Public Key X: {to_hex(pk_x)}")
    print(f"✅ CA Public Key Y: {to_hex(pk_y)}")
    print()
    
    # Generate sample owner address from biometric K
    print("👤 Generating Sample Biometric-Derived Owner Address...")
    owner_sk, owner_pk = generate_ca_keypair()
    owner_address = point_to_address(owner_pk)
    
    print(f"✅ Owner Private Key (simulated biometric): {hex(owner_sk)}")
    print(f"✅ Owner Address: {owner_address}")
    print()
    
    # Print deployment parameters
    print("=" * 70)
    print("📋 STEP 1: DEPLOY ParamRegistry")
    print("=" * 70)
    print("\nCopy these parameters into Remix:")
    print("-" * 70)
    print(f"_pkCA_x:    {format_for_remix(pk_x, 'bytes32')}")
    print(f"_pkCA_y:    {format_for_remix(pk_y, 'bytes32')}")
    print(f"_t:         {format_for_remix(1, 'uint')}")
    print(f"_n:         {format_for_remix(3, 'uint')}")
    print(f"_hashSpec:  {format_for_remix('Keccak256-H0-H1', 'string')}")
    print("-" * 70)
    print()
    
    print("=" * 70)
    print("📋 STEP 2: DEPLOY SpentSet")
    print("=" * 70)
    print("\n✅ No constructor arguments needed!")
    print("Just click 'Deploy'")
    print()
    
    print("=" * 70)
    print("📋 STEP 3: DEPLOY BiometricWallet")
    print("=" * 70)
    print("\nAfter deploying SpentSet, use these parameters:")
    print("-" * 70)
    print(f"ownerAddr:  {format_for_remix(owner_address, 'address')}")
    print(f"_spentSet:  [PASTE_SPENTSET_ADDRESS_HERE]")
    print("-" * 70)
    print()
    
    print("=" * 70)
    print("📋 STEP 4: AUTHORIZE WALLET IN SPENTSET")
    print("=" * 70)
    print("\nAfter deploying BiometricWallet:")
    print("1. Go to deployed SpentSet contract")
    print("2. Call: authorizeWallet([PASTE_BIOMETRIC_WALLET_ADDRESS])")
    print()
    
    # Save to file
    with open('/mnt/user-data/outputs/deployment_params.txt', 'w') as f:
        f.write("DEPLOYMENT PARAMETERS\n")
        f.write("=" * 70 + "\n\n")
        
        f.write("ParamRegistry Constructor:\n")
        f.write(f"  _pkCA_x: {to_hex(pk_x)}\n")
        f.write(f"  _pkCA_y: {to_hex(pk_y)}\n")
        f.write(f"  _t: 1\n")
        f.write(f"  _n: 3\n")
        f.write(f"  _hashSpec: \"Keccak256-H0-H1\"\n\n")
        
        f.write("BiometricWallet Constructor:\n")
        f.write(f"  ownerAddr: {owner_address}\n")
        f.write(f"  _spentSet: [PASTE_SPENTSET_ADDRESS]\n\n")
        
        f.write("Testing Keys (Keep Secret!):\n")
        f.write(f"  CA Private Key: {hex(ca_sk)}\n")
        f.write(f"  Owner Private Key: {hex(owner_sk)}\n")
    
    print("✅ Parameters saved to: deployment_params.txt")
    print()

if __name__ == "__main__":
    # Check dependencies
    try:
        from eth_utils import keccak
        from py_ecc.secp256k1 import secp256k1
    except ImportError:
        print("❌ Missing dependencies!")
        print("Run: pip install eth-utils py_ecc")
        exit(1)
    
    main()
