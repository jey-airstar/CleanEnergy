# CleanEnergy Synthetic Assets Contract

A sophisticated synthetic assets smart contract built on the Stacks blockchain that provides synthetic exposure to renewable energy and clean technology assets. This contract enables users to mint synthetic tokens backed by STX collateral that track clean energy asset performance.

## 🌱 Overview

CleanEnergy creates a decentralized synthetic asset system where users can:
- Deposit STX as collateral
- Mint synthetic tokens (CEST) representing clean energy asset exposure
- Trade and transfer synthetic tokens
- Participate in a liquidation mechanism to maintain system stability

## ✨ Features

### Core Functionality
- **SIP-010 Compliant Token**: Full fungible token implementation with transfer capabilities
- **Collateralized Debt Positions (CDPs)**: Over-collateralized positions to maintain system stability
- **Oracle Price Feeds**: Authorized oracle system for real-time price updates
- **Liquidation Mechanism**: Automated liquidation when positions fall below safety thresholds
- **Administrative Controls**: Pause/unpause functionality and oracle management

### Security Features
- **150% Collateralization Ratio**: Required minimum collateral ratio for minting
- **120% Liquidation Threshold**: Automatic liquidation trigger to protect the system
- **10% Liquidation Penalty**: Incentive for liquidators to maintain system health
- **Price Validity Checks**: 24-hour price freshness requirement
- **Access Controls**: Owner-only administrative functions

## 🔧 Technical Specifications

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Token Name** | CleanEnergy Synthetic Token | Full token name |
| **Token Symbol** | CEST | Trading symbol |
| **Decimals** | 6 | Token precision |
| **Blockchain** | Stacks | Layer-1 blockchain |
| **Language** | Clarity | Smart contract language |
| **Collateral Ratio** | 150% | Minimum collateralization |
| **Liquidation Threshold** | 120% | Liquidation trigger point |
| **Liquidation Penalty** | 10% | Penalty for liquidated positions |
| **Price Validity** | 144 blocks (~24 hours) | Maximum price age |

## 🚀 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm
- Stacks wallet for testing

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd CleanEnergy

# Navigate to contract directory
cd CleanEnergy_contract

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

## 📖 Usage Examples

### Depositing Collateral
```clarity
;; Deposit 1000 microSTX as collateral
(contract-call? .CleanEnergy deposit-collateral u1000000)
```

### Minting Synthetic Tokens
```clarity
;; Mint 100 CEST tokens (requires sufficient collateral)
(contract-call? .CleanEnergy mint-synthetic u100000000)
```

### Burning Synthetic Tokens
```clarity
;; Burn 50 CEST tokens to reduce debt
(contract-call? .CleanEnergy burn-synthetic u50000000)
```

### Withdrawing Collateral
```clarity
;; Withdraw 500 microSTX collateral (if collateral ratio allows)
(contract-call? .CleanEnergy withdraw-collateral u500000)
```

### Transferring Tokens
```clarity
;; Transfer 25 CEST tokens to another user
(contract-call? .CleanEnergy transfer u25000000 tx-sender 'SP1EXAMPLE... none)
```

## 📋 Contract Functions Documentation

### Public Functions

#### Core Token Operations
- `transfer(amount, from, to, memo)` - Transfer tokens between users
- `deposit-collateral(amount)` - Deposit STX as collateral
- `withdraw-collateral(amount)` - Withdraw collateral (subject to ratio requirements)
- `mint-synthetic(amount)` - Mint new synthetic tokens against collateral
- `burn-synthetic(amount)` - Burn synthetic tokens to reduce debt

#### Liquidation
- `liquidate(user, amount)` - Liquidate undercollateralized positions

#### Oracle Management (Owner Only)
- `add-oracle(oracle)` - Authorize a new price oracle
- `remove-oracle(oracle)` - Remove oracle authorization
- `update-price(new-price)` - Update asset price (oracle only)

#### Administrative (Owner Only)
- `pause-contract()` - Emergency pause all operations
- `unpause-contract()` - Resume contract operations
- `set-contract-owner(new-owner)` - Transfer contract ownership

### Read-Only Functions

#### Token Information
- `get-name()` - Returns token name
- `get-symbol()` - Returns token symbol
- `get-decimals()` - Returns token decimals
- `get-balance(who)` - Returns user token balance
- `get-total-supply()` - Returns total token supply

#### Position Information
- `get-price()` - Returns current asset price
- `get-position(user)` - Returns user's collateral position
- `get-collateral-ratio(user)` - Returns user's collateralization ratio
- `is-liquidatable(user)` - Checks if position can be liquidated
- `is-oracle-authorized(oracle)` - Checks oracle authorization status

#### System Information
- `get-contract-info()` - Returns comprehensive contract parameters
- `get-last-price-update()` - Returns last price update block height

## 🚀 Deployment Guide

### Testnet Deployment
```bash
# Deploy to testnet
clarinet deploy --testnet

# Verify deployment
clarinet console --testnet
```

### Mainnet Deployment
```bash
# Deploy to mainnet (ensure thorough testing first)
clarinet deploy --mainnet
```

### Post-Deployment Setup
1. **Add Oracles**: Authorize trusted price feed providers
2. **Set Initial Price**: Update the clean energy asset price
3. **Test Operations**: Verify all functions work correctly
4. **Monitor System**: Set up monitoring for price updates and liquidations

## 🔒 Security Considerations

### Audit Recommendations
- **Oracle Security**: Ensure price oracles are secure and decentralized
- **Price Manipulation**: Monitor for price manipulation attempts
- **Liquidation Monitoring**: Set up automated liquidation monitoring
- **Admin Key Security**: Secure contract owner private keys

### Risk Factors
- **Oracle Dependency**: System relies on external price feeds
- **Collateral Volatility**: STX price volatility affects system stability
- **Liquidation Cascades**: Large liquidations could impact system stability
- **Smart Contract Risk**: Potential bugs or vulnerabilities in contract code

### Best Practices
- Start with small positions to test the system
- Monitor collateralization ratios regularly
- Keep price feeds updated within the 24-hour window
- Maintain excess collateral as a safety buffer

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Discord**: [Stacks Discord](https://discord.gg/stacks)
- **GitHub Issues**: Open an issue for bug reports or feature requests

## 🔗 Links

- [Stacks Blockchain](https://www.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [SIP-010 Fungible Token Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)

---

**⚠️ Disclaimer**: This is experimental software. Use at your own risk. Always test thoroughly on testnet before mainnet deployment.