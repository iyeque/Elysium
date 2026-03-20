# Elysium Post-Deployment Checklist

This checklist provides step-by-step verification tasks to perform immediately after deploying the Elysium system to a testnet or mainnet. Follow these in order to ensure the system is configured correctly and operational.

## Pre-Flight Checks (Before Deployment)

- [ ] **Environment Setup**
  - [ ] RPC URL for target network configured (e.g., `SEPOLIA_RPC_URL`).
  - [ ] Etherscan/Blockscout API key set (`ETHERSCAN_API_KEY`).
  - [ ] Deployer private key available and has sufficient ETH (estimate deployment gas + buffer).
  - [ ] Signer addresses collected (for Upgrade, Pause, Treasury, Jury multisigs). They must be eligible (non-AI, will be minted as H1 Founder).
  - [ ] Optional: `TIMELOCK_DELAY_DAYS` set if deviating from default 2 days.

- [ ] **Repository & Build**
  - [ ] Working on `deployment-readiness` branch (or `origin/main`).
  - [ ] All contracts compile without errors: `forge build`.
  - [ ] All tests pass: `forge test --rerun` (60+ passing).

- [ ] **Script Configuration**
  - [ ] `script/DeployAll.s.sol` updated to environment variable support (if using custom signers).
  - [ ] Signer lists meet constraints:
    - Upgrade: 3-5 signers
    - Pause: 2-3 signers (max 3)
    - Treasury: 3-5 signers
    - Jury: 3-5 signers
  - [ ] Verify signer addresses are correct and belong to trusted parties.

## Deployment Execution

- [ ] **Run Deployment Script**
  - For local anvil:
    ```bash
    anvil &
    forge script script/DeployAll.s.sol --private-key 0x... --rpc-url http://localhost:8545 --broadcast
    ```
  - For testnet (e.g., Sepolia):
    ```bash
    export SEPOLIA_RPC_URL=...
    export UPGRADE_SIGNERS="0x...,0x...,..."
    export PAUSE_SIGNERS="0x...,0x..."
    export TREASURY_SIGNERS="0x...,0x...,..."
    export JURY_SIGNERS="0x...,0x...,..."
    export TIMELOCK_DELAY_DAYS=2
    forge script script/DeployAll.s.sol --private-key 0xYOUR_KEY --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
    ```
  - Capture the console output: it prints all contract addresses.

- [ ] **Verify Transaction Success**
  - [ ] No reverts during execution.
  - [ ] All contract deployment transactions confirmed.
  - [ ] Save deployed addresses in a secure location (e.g., `networks/sepolia.json`).

- [ ] **(Optional) Contract Verification**
  - [ ] If not using `--verify`, verify contracts manually on Etherscan/Blockscout using `forge verify-contract`.
  - [ ] Ensure all contracts are verified and source code is public.

## Immediate Post-Deployment Verification

### 1. Role Assignment Audit

Connect to the network with `cast` or a block explorer and verify:

- [ ] Timelock: `PROPOSER_ROLE` and `EXECUTOR_ROLE` granted to Governor.
- [ ] All multisigs: `ADMIN_ROLE` granted to Governor.
- [ ] CitizenshipNFT: `DEFAULT_ADMIN_ROLE` granted to Governor.
- [ ] Staking:
  - [ ] `PAUSER_ROLE` granted to PauseMultiSig.
  - [ ] `REWARDER_ROLE` granted to Treasury.
- [ ] CitizenshipNFT:
  - [ ] `MINTER_ROLE` granted to Staking.
  - [ ] `JURY_ROLE` granted to CitizenshipJury.
  - [ ] `VERIFIER_ROLE` granted to designated verifiers (if any; may be done later).
  - [ ] `MERIT_GRANTOR_ROLE` granted to appropriate account(s) (if needed).

**Commands** (example):
```bash
cast call <timelock> "getRoleMember(bytes32,uint256)" $(cast keccak256 "PROPOSER_ROLE") 0 --rpc-url $RPC
# Should return Governor address
```

### 2. ELYS Configuration

- [ ] Rewards pool set to Staking address:
  - `cast call <elys> "rewardsPool()"` → should equal Staking address.
  - If not, call `elys.setRewardsPool(address(staking))` (requires DEFAULT_ADMIN_ROLE, currently Governor).

### 3. Timelock Delay

- [ ] Timelock delay set correctly:
  - `cast call <timelock> "getMinDelay()"` should return `timelockDelay` (in seconds).
  - Compare with intended delay (e.g., 2 days = 172800 seconds).

### 4. Governance Parameters

- [ ] Voting delay and period vary by proposal tier (check ElysiumGovernor):
  - For a Tier1 proposal type (e.g., `1` for ParameterChange), `votingDelay()` should return 1 day, `votingPeriod()` 7 days.
  - For Tier3 (e.g., `4` for Constitutional), values should be 14 days and 10 days.
  - You can test by crafting a mock proposal or calling view functions if accessible; otherwise, trust the code.

### 5. Citizen NFTs

- [ ] Signer addresses have been minted Founder-tier (tier=3) H1 NFTs:
  - For a few signer addresses, call `citizenshipNFT.citizenTokenId(address)`; should return a token ID > 0.
  - Check tier: `citizenshipNFT.getCitizen(tokenId).tier == 3`.
  - Check phase: `phase == 1`.

### 6. Treasury Setup

- [ ] Treasury multisig has the expected signers (call `isSigner` mapping or getSigners function if available).
- [ ] Treasury has some ETH balance for future operations (fund it with a small amount via transfer).
- [ ] Annual cap initialized: call `getRemainingCap()`; should reflect treasury balance * 10% cap.
- [ ] Fiscal year start is recent (block.timestamp near deployment).

### 7. Staking

- [ ] Staking contract linked to correct ELYS and CitizenshipNFT.
- [ ] Minimum stake for citizenship (10,000 ELYS) is set (constant check).
- [ ] Test staking function (from an account with enough ELYS):
  - Approve and stake some tokens.
  - Verify `balanceOf(user)` updates.
  - If stake ≥ 10,000 ELYS, verify CitizenshipNFT minted (tier based on amount).

### 8. Citizen Jury

- [ ] Jury signers are set correctly and eligible.
- [ ] Challenge deposit amount (1000 ELYS) is set.
- [ ] Test basic jury workflow (on testnet):
  - Use a funded account to create a challenge against a test citizen (or use two accounts; one stakes to become citizen, another challenges).
  - Verify challenge created, jurors selected (5 addresses), votes can be cast.
  - Finalize challenge and check result (revoke/refund).
  - Note: This is a critical test; ensure it works.

### 9. Governor Proposal Test

- [ ] Create a small test proposal (e.g., a parameter change that doesn't affect value). Use a signer to propose via Governor.
- [ ] Verify proposal enters voting period with correct timelock (queued first).
  - After voting period, check that proposal can be executed (by anyone if quorum reached).
  - Confirm execution calls through Timelock and executes the target call.
- [ ] This end-to-end test validates Timelock-Governor integration.

### 10. AI & Phase Restrictions

- [ ] Verify AI cannot vote more than 20% weight (requires AI attestation; may need to set up test AI).
- [ ] Verify H3 cannot be added as signer to any multisig (attempt via Governor to add an H3 address; expect revert).
- [ ] Verify H3 cannot challenge (attempt challenge with H3 account; expect revert).
- [ ] Verify phase progression: H1 cannot become H2 before 30 days; attempts to call `updatePhase` should revert with appropriate error.

### 11. Pause & Emergency Functions

- [ ] Test pausing Staking:
  - Call `pauseMultiSig.submitTransaction` to call `staking.pause()`.
  - Get required confirmations (2-of-3).
  - Execute and verify `staking.paused()` returns true.
- [ ] Test unpausing similarly.
- [ ] Ensure PauseMultiSig signers can execute the transaction.

### 12. Upgrade Process (If Upgradeable)

- **If contracts are upgradeable (UUPS)**, verify:
  - [ ] UpgradeMultiSig signers are set.
  - [ ] Governor does not have direct upgrade rights (should go through multisig).
  - [ ] Test a no-op upgrade on a dummy contract or a non-critical contract.

## Ongoing Monitoring (After Deployment)

- [ ] Set up monitoring/alerting for:
  - [ ] Treasury spends (large transactions)
  - [ ] Challenges and outcomes
  - [ ] Role changes (any grant/revoke of critical roles)
  - [ ] Governor proposals and votes
  - [ ] Staking activities (stake/unstake/withdraw volumes)

- [ ] Track key metrics:
  - [ ] Number of citizens per tier/phase.
  - [ ] Treasury balance and annual spend.
  - [ ] Staking APY and rewards pool size.
  - [ ] Voter participation rates.

## Emergency Procedures

If a critical issue is discovered:

1. **Pause affected contracts** using PauseMultiSig (if Staking or other pausable functions are compromised).
2. **Cancel pending proposals** if possible via Timelock canceller role (if assigned) or via governance.
3. **Execute emergency upgrades** if a fix is ready and UpgradeMultiSig is in place.
4. **Communication**: Inform the community via official channels.

**Important**: Pause and Upgrade multisigs should have distributed signers; avoid unilateral actions.

## Go/No-Go Decision

After completing this checklist, assess:

- [ ] All critical checks passed.
- [ ] No unexpected reverts or misconfigurations.
- [ ] Signer keys are securely stored.
- [ ] Community is aware of deployment and test plans.

If any critical item fails, **DO NOT PROCEED** to encourage broad usage. Fix the issue, redeploy if necessary, and repeat verification.

## Notes

- Document all deployed addresses, transaction hashes, and verification URLs.
- Keep this checklist updated for future network deployments.
- Review and adjust parameters via governance as the system evolves.

---

**Last Updated:** 2026-03-20

**Responsible:** Elysium Deployment Team
