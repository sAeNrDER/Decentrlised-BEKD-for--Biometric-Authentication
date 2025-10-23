# 🔐 Decentralized Biometric Authentication with BEKD

> Token-based biometric authentication framework using threshold cryptography and ERC-4337 smart wallets

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Python](https://img.shields.io/badge/Python-3.9+-green)](https://python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A decentralized biometric authentication system that eliminates offline brute-force attacks through token-based rate limiting while maintaining privacy and security on blockchain networks.

---

## 🎯 Key Features

- ✅ **Brute-force resistant** - Token-based one-time use authentication
- ✅ **Privacy-preserving** - No biometric data stored on-chain
- ✅ **Decentralized** - Threshold CA consortium (no single point of failure)
- ✅ **Standards compliant** - ERC-4337, EIP-1271, EIP-712, ISO/IEC 24745
- ✅ **Gas optimized** - Immutable storage patterns, batch operations

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| Enrollment Time | 16.2 ms |
| Authentication Time | 0.11 ms |
| Deployment Cost | $76.73 |
| Auth Transaction | $2.63 |
| Token Size (off-chain) | 417 bytes |
| Gas Savings (batch) | 33% |

---

## 📚 Library & Dependencies

### Smart Contracts
```
Solidity: 0.8.20
Remix IDE: Latest version
Network: Ethereum-compatible (tested on Remix VM)
```

### Off-Chain Components
```bash
# Python 3.9+
pip install web3 py_ecc eth-utils eth-account ecdsa

# For visualization (optional)
pip install matplotlib numpy
```

### Testing Tools (Optional)
```bash
# Hardhat for gas profiling
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers hardhat-gas-reporter
```

---

## 🚀 Quick Start

### 1. Generate Deployment Parameters

```bash
python generate_deployment_params.py
```

This creates `deployment_params.txt` with CA keys and owner address.

### 2. Deploy Contracts (Remix IDE)

#### **Step 1: Deploy ParamRegistry**
```
File: ParamRegistry_Fixed.sol
Arguments from deployment_params.txt:
- _pkCA_x, _pkCA_y, _t=1, _n=3, _hashSpec=Keccak256-H0-H1
```

#### **Step 2: Deploy SpentSet**
```
File: SpentSet_Fixed.sol
No arguments needed
```

#### **Step 3: Deploy BiometricWallet**
```
File: BiometricWallet_Fixed.sol
Arguments:
- ownerAddr: [from deployment_params.txt]
- _spentSet: [SpentSet address from Step 2]
```

#### **Step 4: Authorize Wallet**
```
Call in SpentSet: authorizeWallet([BiometricWallet address])
```

**✅ Deployment Complete!** Total time: ~5 minutes

### 3. Test Authentication Flow

See [REMIX_DEPLOYMENT_GUIDE.md](REMIX_DEPLOYMENT_GUIDE.md) for detailed testing instructions.

---

## 📊 Performance Testing
#### Complexity Analysis (Python)
```bash
python complexity_analysis.py
# Output: complexity_analysis.json, scalability_analysis.png, complexity_tables.tex
# Time: ~3 minutes
```
#### Gas Analysis (Hardhat)
```bash
# Setup
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers
npx hardhat test test/gas-profiling.test.js

# Generate visualizations
python gas_analysis.py
# Output: deployment_costs.png, operation_costs.png, gas_tables.tex
# Time: ~10 minutes
```

For detailed testing guide, see [PERFORMANCE_TESTING_GUIDE.md](PERFORMANCE_TESTING_GUIDE.md)

---

## 🛠️ Troubleshooting

### Common Issues

**Q: Remix deployment fails**
- Check Solidity version is 0.8.20
- Remove quotes from `hashSpec` parameter
- Verify all addresses have 0x prefix

**Q: Python module not found**
```bash
pip install web3 py_ecc eth-utils --break-system-packages
```

**Q: Gas estimation failed**
- Increase gas limit in Remix (3,000,000)
- Check wallet is authorized in SpentSet

For detailed solutions, see [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

This project is specficly designed for Monash Minor-thesis project.
---


## 📞 Contact

For questions or issues:
- Open an issue on GitHub
- Email: hche0126@gmail.com

**Built with ❤️ for secure, privacy-preserving biometric authentication**
