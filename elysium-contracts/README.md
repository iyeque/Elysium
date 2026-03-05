# Elysium Smart Contracts

Foundry-based monorepo for the Elysium sovereign digital nation infrastructure.

## Overview

This repository contains the core smart contracts for Elysium's on-chain governance, citizenship, tokenomics, and treasury management.

**Tech Stack:**
- Solidity 0.8.20
- OpenZeppelin Contracts (v5.x)
- Foundry (forge) for testing and deployment
- Target: Arbitrum One (main) and Arbitrum Sepolia (testnet)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Elysium Protocol Stack                  │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│   ELYS      │ Citizenship │  Staking    │  Governance    │
│   (ERC-20)  │   NFT       │   Contract  │  + Timelock    │
├─────────────┴─────────────┴─────────────┴─────────────────┤
│                     Treasury (Multi-Sig)                   │
└─────────────────────────────────────────────────────────────┘
```

### Contracts

1. **ELYS.sol** — ERC-20 token with snapshot voting capability
   - Max supply: 1 billion tokens
   - Checkpoint system for voting power history
   - Delegation support
   - EIP-712 signature-based delegation

2. **CitizenshipNFT.sol** — Soulbound NFT (ERC-5484)
   - Non-transferable citizenship tokens
   - Human (H1/H2/H3) and AI citizen support
   - Tiered system (Airdrop, Ecosystem, Founder, Staked)
   - Operator registry integration for AI attestation

3. **Staking.sol** — Staking with lock/unlock delays
   - 30-day stake lock (cannot withdraw immediately)
   - 30-day unstake delay (queued withdrawal)
   - Auto-mint CitizenshipNFT upon reaching 10,000 $ELYS stake
   - Pausable (emergency recovery)

4. **Governor + Timelock** — On-chain governance
   - 1 person 1 vote (via snapshot)
   - Configurable voting delay (1d), period (7d)
   - Timelock delay: 2 days
   - Proposal threshold: 100 $ELYS
   - Quorum: 4% of circulating supply

5. **Treasury.sol** — 3-of-5 multi-sig wallet
   - Signer management via governance
   - Recoverable emergency funds
   - Pausable operations

6. **OperatorRegistry.sol** — AI operator tracking
   - Attestation system for AI citizens
   - Max 10 AI per operator (Sybil defense)

## Prerequisites

- Foundry (forge) installed
- Access to RPC endpoints (Alchemy, Infura, or public nodes)
- For testnet: $ARBITRUM_SEPOLIA_RPC_URL environment variable
- For Etherscan verification: $ETHERSCAN_API_KEY

## Setup

1. Install dependencies:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```

2. Configure environment variables:
   ```bash
   export MAINNET_RPC_URL="https://arbitrum-nova.publicnode.com"
   export ARBITRUM_SEPOLIA_RPC_URL="https://sepolia-rollup.arbitrum.io/rpc"
   export ETHERSCAN_API_KEY="your-key"
   ```

## Testing

Run unit tests:
```bash
forge test
```

Run with coverage:
```bash
forge coverage
```

Run fuzzing:
```bash
forge fuzz
```

## Deployment

### Deploy to Arbitrum Sepolia (Testnet)

```bash
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deploy to Arbitrum One (Mainnet)

Update `foundry.toml` to use `arbitrum_one` RPC and run:
```bash
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $ARBITRUM_ONE_RPC_URL \
  --private-key $PRODUCTION_PRIVATE_KEY \
  --broadcast \
  --slow \
  --gas-limit 15000000
```

**Security Note:** Do not reuse keys. Use a hardware wallet or dedicated deployment key.

## Post-Deployment Steps

1. **Fund the Governor** — Transfer a significant amount of $ELYS to the Governor contract to enable quorum participation in early votes.

2. **Initiate Citizenship System** — Deploy staking pool and begin onboarding citizens via 10,000 $ELYS stake or manual airdrop.

3. **Airdrop** — For initial distribution, call `ELYS.transfer()` to community members, then let them stake to claim citizenship.

4. **Governance Activation** — Set governor proposer/executor roles on timelock, then enable governance by proposing a test measure.

5. **Audit** — Before mainnet launch, commission a full audit from OpenZeppelin or Trail of Bits.

## Project Structure

```
elysium-contracts/
├── contracts/
│   ├── ELYS.sol                   # ERC-20 with snapshot voting
│   ├── CitizenshipNFT.sol         # Soulbound NFT for citizenship
│   ├── Staking.sol                # Staking with 30-day lock/unstake
│   ├── ElysiumGovernor.sol        # Governor (OpenZeppelin)
│   ├── ElysiumTimelock.sol        # TimelockController
│   ├── ElysiumTreasury.sol        # 3-of-5 multi-sig
│   └── OperatorRegistry.sol       # AI operator attestation
├── test/
│   ├── ELYS.t.sol
│   ├── Staking.t.sol
│   └── ... (more to be added)
├── script/
│   └── DeployAll.s.sol            # Full deployment script
├── foundry.toml
└── README.md
```

## Design Decisions

### Why Arbitrum?
- Ethereum security (fraud proofs)
- Low gas ($0.10–0.50/tx)
- Growing DeFi ecosystem
- Clear path to Ethereum mainnet if needed later

### Why ERC-5484 Soulbound?
Prevents citizenship trading; aligns with "human/AI citizen" concept where identity is non-transferable.

### Why 30-Day Lock + 30-Day Unstake?
- discourages short-term speculators
- Ensures stable voting power
- Prevents immediate dump after airdrop

### 1 Person 1 Vote?
Yes. Citizenship NFT grants voting rights (1 NFT = 1 vote). Token weight for delegation, but governance rights tied to soulbound NFTs, not tokens. This prevents plutocracy.

### Treasury Multi-Sig
Initially 5-elected signers (Phase H1 humans). Governance will vote to modify signer set after Year 1.

## Next Steps

1. Add comprehensive test coverage (all contracts)
2. Deploy to Arbitrum Sepolia testnet
3. Run end-to-end integration test (complete citizenship flow)
4. Security audit planning
5. Token distribution simulation

## License

MIT (to be confirmed)

---

**Status:** In active development — not audited. Do not use on mainnet without security review.