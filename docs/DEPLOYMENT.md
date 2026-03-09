# Elysium Deployment Guide

## Overview

This guide covers deploying the Elysium system to a testnet or mainnet using the parameterized `DeployAll.s.sol` script.

## Prerequisites

- Foundry installed and configured
- RPC endpoint for target network (e.g., Sepolia, Arbitrum Sepolia)
- Etherscan/Blockscout API key for contract verification
- Deployer private key with sufficient ETH for gas
- Multisig signer addresses (eligible H1/H2 citizens with appropriate phases)

## Environment Variables

Set these in your shell or in a `.env` file:

```bash
# RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
HOLESKY_RPC_URL=https://holesky.infura.io/v3/YOUR_KEY
ARBITRUM_SEPOLIA_RPC_URL=https://arbitrum-sepolia.infura.io/v3/YOUR_KEY

# Explorer API key (Etherscan, Blockscout, etc.)
ETHERSCAN_API_KEY=YOUR_API_KEY

# Deploy script configuration
TIMELOCK_DELAY_DAYS=2  # Minimum delay for timelock

# Comma-separated signer addresses (must be eligible; they will be minted Founder-tier H1)
UPGRADE_SIGNERS="0x...,0x...,0x...,0x...,0x..."
PAUSE_SIGNERS="0x...,0x...,0x..."
TREASURY_SIGNERS="0x...,0x...,0x...,0x...,0x..."
JURY_SIGNERS="0x...,0x...,0x...,0x...,0x..."
```

Ensure the deployer address (the one whose private key you use) is also an H1 Founder (phase=1, tier=3); the script will mint NFTs for signers only. If the deployer needs to be a signer, include them in at least one signer set.

## Local Testnet (Anvil)

1. Start a local node: `anvil`
2. Fund deployer: `forge script script/DeployAll.s.sol --private-key 0x... --rpc-url http://localhost:8545 --broadcast`
3. The script uses default 2-day timelock and the following signers (hardcoded legacy addresses) if env vars are not set:
   - Upgrade: 5 addresses
   - Pause: 3 addresses
   - Treasury: 5 addresses
   - Jury: 5 addresses
   If you want to customize signers, set env vars as above.

## Testnet Deployment

Example for Sepolia:

```bash
export SEPOLIA_RPC_URL=...
export ETHERSCAN_API_KEY=...
export UPGRADE_SIGNERS="0xaddr1,0xaddr2,0xaddr3,0xaddr4,0xaddr5"
export PAUSE_SIGNERS="0xaddrA,0xaddrB,0xaddrC"
export TREASURY_SIGNERS="0xaddrX,0xaddrY,0xaddrZ,0xaddrW,0xaddrV"
export JURY_SIGNERS="0xaddrM,0xaddrN,0xaddrO,0xaddrP,0xaddrQ"
export TIMELOCK_DELAY_DAYS=2

forge script script/DeployAll.s.sol --private-key 0xYOUR_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

The script will:
1. Deploy ELYS, Timelock, OperatorRegistry, CitizenshipNFT
2. Mint Founder-tier H1 NFTs for all provided signers
3. Deploy Staking, TreasuryMultiSig, PauseMultiSig, UpgradeMultiSig, CitizenshipJury, Governor
4. Wire up roles and permissions
5. Print contract addresses (capture these!)

## Post-Deployment Steps

1. **Verify contracts** on Etherscan/Blockscout (if not using `--verify`).
2. **Set verifier role** on CitizenshipNFT for accounts that will verify human phases:
   ```bash
   cast send <citizenshipNFT> "grantRole(bytes32,address)" $(cast keccak256 "VERIFIER_ROLE") <verifierAddress> --private-key 0x... --rpc-url $RPC
   ```
3. **Set meritor grantor role** if needed:
   ```bash
   cast send <citizenshipNFT> "grantRole(bytes32,address)" $(cast keccak256 "MERIT_GRANTOR_ROLE") <grantorAddress> --private-key 0x... --rpc-url $RPC
   ```
4. **Fund the treasury** with ETH for future multisig spends.
5. **Test a proposal** through the governor to ensure timelock and voting work.
6. **Test jury challenge** by creating a challenge and verifying random juror selection.
7. **Test phase transitions** by verifying a human (30-day cooldown, increment only).

## Network-Specific Notes

- **Sepolia**: Use `--etherscan-api-key` with Etherscan.
- **Arbitrum Sepolia**: `--etherscan-api-key` with Arbitrum Explorer.
- **Local anvil**: RPC `http://localhost:8545`; no verification.

## Troubleshooting

- **Insufficient gas**: Ensure deployer has enough ETH.
- **Invalid signer env vars**: Ensure comma-separated hex addresses with `0x` prefix.
- **Role assignment failures**: The deployer must have DEFAULT_ADMIN_ROLE on contracts to grant roles; the script runs as `msg.sender`.
- **Verification failures**: Ensure `foundry.toml` has correct `[etherscan]` section for the network.

## After Deployment

Update `memory/backlog.md` with deployed addresses and network. Consider creating a `networks/<network>.json` file to store these for future scripts.
