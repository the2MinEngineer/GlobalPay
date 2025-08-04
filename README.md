# GlobalPay

A decentralized cross-border payment protocol that enables instant, low-cost, and transparent international transfers using stablecoins, decentralized FX markets, and on-chain compliance — built with Clarity smart contracts.

---

## Overview

GlobalPay consists of ten main smart contracts that together form a secure, compliant, and efficient ecosystem for global remittances and business payments:

1. **Payment Router Contract** – Handles cross-border transfers with multi-hop routing for optimal speed and cost.  
2. **Stablecoin Vault Contract** – Manages deposits, withdrawals, and wrapping/unwrapping of different fiat-backed stablecoins.  
3. **FX Swap Contract** – Provides decentralized currency conversion via AMM pools with oracle-driven rates.  
4. **Compliance/KYC Contract** – Enforces on-chain KYC/AML checks and sanctions screening using decentralized identity proofs.  
5. **Escrow & Arbitration Contract** – Facilitates secure escrow services with community-approved dispute resolution.  
6. **Fee Management Contract** – Collects and distributes transaction fees to liquidity providers and stakers.  
7. **Liquidity Pool Contract** – Allows users to provide liquidity for FX swaps and earn proportional fees.  
8. **Oracle Integration Contract** – Connects to off-chain FX rates and compliance databases for accurate conversions.  
9. **Programmable Payout Contract** – Enables businesses to schedule recurring and conditional payouts for payroll or supplier settlements.  
10. **Governance DAO Contract** – Allows token holders to vote on protocol parameters, fee structures, and upgrades.  

---

## Features

- **Instant cross-border transfers** with significantly lower fees  
- **Multi-currency stablecoin support** for global coverage  
- **Decentralized FX swaps** with on-chain liquidity pools  
- **Built-in compliance layer** for KYC and AML enforcement  
- **Secure escrow and arbitration system** for large transactions  
- **Fee optimization** with smart routing  
- **Programmable payouts** for businesses  
- **Oracle-driven FX rates** for fair conversions  
- **Liquidity rewards** for community contributors  
- **DAO governance** for transparent protocol upgrades  

---

## Smart Contracts

### Payment Router Contract
- Routes cross-border payments  
- Finds cheapest and fastest paths  
- Integrates FX swap and vaults for seamless transfers  

### Stablecoin Vault Contract
- Securely stores multiple stablecoins  
- Handles deposits and withdrawals  
- Wraps/unlocks tokens for cross-border transfers  

### FX Swap Contract
- AMM-based currency conversion  
- Uses oracles for real-world FX rates  
- Incentivizes liquidity providers with swap fees  

### Compliance/KYC Contract
- On-chain KYC verification  
- Sanctions screening and AML enforcement  
- Supports decentralized identity proofs  

### Escrow & Arbitration Contract
- Locks funds until conditions are met  
- Dispute resolution via approved arbitrators  
- Transparent resolution logs  

### Fee Management Contract
- Collects protocol fees automatically  
- Distributes rewards to LPs and DAO treasury  
- Adjustable fee rates via governance  

### Liquidity Pool Contract
- Allows adding/removing liquidity for FX swaps  
- Tracks pool balances and user shares  
- Distributes trading fees to LPs  

### Oracle Integration Contract
- Fetches FX rates from off-chain providers  
- Integrates compliance and sanction data  
- Ensures secure and verifiable updates  

### Programmable Payout Contract
- Enables recurring and conditional payments  
- Automated payrolls and supplier settlements  
- Configurable release schedules  

### Governance DAO Contract
- Token-based voting on protocol changes  
- On-chain proposal execution  
- Manages parameters like fees and arbitration rules  

---

## Installation

1. Install [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started)  
2. Clone this repository:  
   ```bash
   git clone https://github.com/yourusername/globalpay.git
   ```
3. Run tests:
    ```bash
    npm test
    ```
4. Deploy contracts:
    ```bash
    clarinet deploy
    ```

---

## Usage

Each smart contract operates independently but works together to power GlobalPay’s decentralized payment network.
Refer to the documentation in each contract folder for details on function calls, parameters, and integration examples.

---
## License

MIT License