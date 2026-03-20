# Elysium Security Considerations

## Overview

This document outlines security considerations for deploying, operating, and upgrading the Elysium decentralized governance system. It is intended for auditors, deployers, and system administrators.

## 1. Access Control & Roles

Elysium uses OpenZeppelin AccessControl extensively. Key roles:

- `DEFAULT_ADMIN_ROLE`: Central administration role; initially held by deployer, then transferred to Governor.
- `PROPOSER_ROLE` (Timelock): Allows proposing contract calls; assigned to Governor.
- `EXECUTOR_ROLE` (Timelock): Allows executing queued calls; assigned to Governor.
- `SIGNER_ROLE` (Multisigs): Identifies authorized signers for multisig operations.
- `ADMIN_ROLE` (Multisigs): Allows adding/removing signers; assigned to Governor.
- `MINTER_ROLE` (CitizenshipNFT): Allows minting citizenship NFTs; assigned to Staking (and optionally Merit Grantor).
- `VERIFIER_ROLE` (CitizenshipNFT): Allows verifying human identities; to be assigned to trusted verifiers.
- `MERIT_GRANTOR_ROLE` (CitizenshipNFT): Allows minting NFTs via merit grants; assign sparingly.
- `JURY_ROLE` (CitizenshipNFT): Required for jury operations; assigned to CitizenshipJury.
- `PAUSER_ROLE` (Staking): Allows pausing staking; assigned to PauseMultiSig.
- `REWARDER_ROLE` (Staking): Allows adding reward distributions; assigned to Treasury.

**Key Points**
- The Governor is the central administrator for multisig signer sets and for managing CitizenNFT roles. Ensure the Governor contract itself is secure and upgradeable only via strict multisig processes.
- All multisig signers must meet eligibility criteria (non-AI, appropriate tier and phase). Contracts enforce this in `_checkEligibility`; however, the admin (Governor) should also exercise due diligence.
- The `VERIFIER_ROLE` is powerful: it can promote users to higher phases. Only trusted entities (e.g., a multisig or designated verification DAO) should hold this role.

## 2. Timelock Delays

Elysium uses a Timelock controller to introduce delays before executable proposals. The timelock delay is configurable (default 2 days) but should be chosen carefully:

- **Longer delays** provide more time for community scrutiny and emergency interventions.
- **Tier-specific voting delays and periods** are implemented in ElysiumGovernor:
  - Tier1 (ParameterChange, TreasurySpendSmall): 1 day delay, 7 days voting
  - Tier2 (TreasurySpendMedium, MultiSigElection): 7 days delay, 7 days voting
  - Tier3 (Constitutional, CorePrinciple, AIPhaseTransition, TreasurySpendLarge): 14 days delay, 10 days voting

Ensure these values are appropriate for the community's pace and security requirements.

## 3. Governor Protections

ElysiumGovernor includes several safeguards:

- **AI Vote Caps**: AI-controlled voting power is capped at 20% of total votes, with further restrictions (AI Phase2 restricted to ParameterChange only). Implemented via `_applyAICap` and proposal type restrictions.
- **Founder Veto**: Founders (special flag) can veto queued proposals before execution, with a sunset (after a certain block? need to confirm). This is an emergency brake; limit founder privileges appropriately.
- **Tier-based timelocks**: As above, more impactful proposals face longer delays.
- **Proposal thresholds**: Ensure the `proposalThreshold()` is set at a level that prevents spam while allowing legitimate participation.

## 4. Citizenship & Identity

The system grants citizenship via non-transferable NFTs (ERC721). Several mechanisms ensure Sybil resistance:

- **Staking-based citizenship**: Users can mint by staking a minimum amount (10,000 ELYS for Citizen tier, etc.). This creates economic disincentive for Sybil attacks.
- **Verifier role**: Trusted verifiers can manually verify identities and assign phases.
- **Merit grants**: Admin can mint without staking for recognized contributors; grantor role should be limited.
- **Phase progression**: H1 → H2 requires 30 days and strict increment; H3 cannot challenge identities and cannot serve as multisig signers.
- **Challenge system**: Any citizen (except H1) can challenge another's citizenship by depositing 1000 ELYS (H1 exempt). A random jury of 5 jurors votes; deposit is burned if citizenship revoked, refunded otherwise. Rate limit: 3 challenges per 30 days.

**Security Notes**
- The randomness for jury selection uses `block.timestamp`, `block.prevrandao`, and `challengeId`. This is not cryptographically secure but is likely sufficient for non-critical decisions. If high security is required, consider integrating a VRF or trusted randomness beacon.
- Challenge deposit amount should be sufficient to deter frivolous challenges but not so high as to prevent legitimate challenges. The current 1000 ELYS is adjustable only via contract upgrade (likely).

## 5. Treasury & Multisig Security

The TreasuryMultiSig manages fund spend with the following features:

- **Annual cap**: 10% of treasury balance per fiscal year, unless a 67% supermajority approves excess. This prevents excessive drainage.
- **Fiscal year reset**: Automatically resets after 365 days.
- **Multi-sig requirements**: 3-of-5 signers required (default). Signers must be eligible citizens (H1/H2, tier ≥ 1, non-AI). H3 are explicitly excluded.
- **Admin control**: The Governor can add/remove signers; ensure Governor is not compromised.

**Considerations**
- Treasury holds significant value; signers should use hardware wallets and follow key management best practices.
- Consider implementing a timelock on treasury spends (already present via Governor/Timelock).
- The annual cap calculation uses current treasury balance at execution time. Large fluctuations could affect cap; monitor.

## 6. Staking & Tokenomics

ELYS token has a 0.1% transfer fee, half burned, half sent to staking rewards pool. Staking contract:

- **Lock periods**: 30-day stake lock, 30-day unstake delay, minimum stake for citizenship (10,000 ELYS).
- **Reward distribution**: Uses rewardPerToken accounting; rewards can be added by Treasury (REWARDER_ROLE).
- **Pausable**: Staking can be paused by PauseMultiSig.

**Security Notes**
- Ensure rewards pool is set correctly after deployment (script does this).
- Reentrancy guard protects stake/unstake/withdraw.
- The minting of CitizenshipNFT upon reaching threshold is handled internally; should not be exploitable for double-mint due to `citizenshipStakeId` tracking.

## 7. Upgradeability & Pausing

- **PauseMultiSig**: Can pause Staking (and potentially other contracts if they implement pausable). Ensure PauseMultiSig signers are responsive and secure.
- **UpgradeMultiSig**: Can upgrade contract implementations (assuming proxies? The scripts deploy non-proxy contracts? Check if contracts are upgradeable. The current deployment appears to be concrete contracts, not proxies. If upgradeability is needed, consider using proxies orUUPS. The UpgradeMultiSig as defined can call `upgradeTo` on upgradeable contracts. Verify which contracts are upgradeable; currently none appear to be using UUPS. So UpgradeMultiSig may not be functional unless contracts are made upgradeable. This should be clarified before deployment.

**Important**: If contracts are not Upgradeable, the UpgradeMultiSig is useless. Consider making key contracts upgradeable via UUPS or透明 proxies if future upgrades are anticipated. However, upgradeability introduces complexity and risk.

## 8. Randomness

The only randomness used is in CitizenshipJury for juror selection. It uses:

```
keccak256(abi.encodePacked(
    block.timestamp,
    block.prevrandao,
    challengeId
))
```

While `block.prevrandao` is more robust than `block.difficulty` post-merge, it's still somewhat predictable by miners/validators. However, for selecting 5 jurors out of a large pool, the bias is minimal and the cost to influence is high. Acceptable for non-critical disputes. For higher security, consider a VRF-based solution.

## 9. Front-Running & Transaction Ordering

- All state-changing operations go through the Governor and Timelock, which queue transactions for future execution. This mitigates front-running of proposals (they are publicly known before execution).
- However, vote casting itself may be front-run. Consider using commit-reveal schemes if secrecy is needed. Current system likely uses token/NFT balance at proposal start snapshot, which is public; front-running to acquire votes after the fact is prevented by snapshot.
- The Staking rewards addition (`addRewards`) is callable by Treasury; could be front-run. Use Timelock for such privileged actions if needed (already the case if Treasury is multisig that operates via Governor? Actually TreasuryMultiSig executes directly; might want to route privileged ops via Timelock for transparency).

## 10. Testing & Auditing

- Current test suite: 60 tests covering core functionality, including edge cases (AI caps, phase transitions, H3 restrictions, challenge flow, tier timelocks, staking rewards, treasury annual cap).
- **Notable gaps**:
  - No fuzz tests defined. Consider adding fuzz tests for integer overflows, boundary conditions, and complex interactions (e.g., staking + minting + tier updates).
  - No invariant tests defined. Invariants to check: total supply of ELYS (except burns), sum of stakes vs globalTotalStaked, no duplicate tokenIds, etc.
  - No formal verification.
  - No stress tests with high loads (many signers, many challenges).
- **Recommendation**: Before mainnet, conduct a comprehensive external security audit focusing on:
  - Access control and role assignment
  - Timelock bypass possibilities
  - Randomness robustness
  - Economic attack vectors (vote buying, staking manipulation)
  - Code quality and upgradeability strategy

## 11. Key Management & Operational Security

- Deployer private key must be secured and ideally destroyed after deployment if not needed. The script sets initial roles; after that, the deployer's admin role on various contracts may be revoked or renounced if possible.
- Multisig signers should use hardware wallets and maintain operational security. Consider key rotation mechanisms.
- Have an incident response plan: use PauseMultiSig to pause critical functions if a vulnerability is discovered. Ensure the PauseMultiSig signers are distinct from UpgradeMultiSig to provide separation of duties.
- Maintain secure backups of contract addresses, ABIs, and Etherscan/Blockscout verification.

## 12. Known Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Compromise of Governor admin role | Total control | Low (multisig) | Use multisig with distributed keys; consider timelock on role changes |
| Randomness bias in jury selection | Unfair jury | Low-Moderate | Monitor jury outcomes; later upgrade to VRF if needed |
| Staking manipulation to gain tier | Economic attack | Medium | Minimum stakes are high; monitor for flash loan attacks (but staking has lock) |
| UpgradeMultiSig misuse if upgradeable | Contract takeover | Low | Signers should be highly trusted; use timelock on upgrades |
| Verifier role abuse to grant citizenship | Identity spoofing | Medium | Verifiers should be reputable; revocable via Governor |
| H3 signer eligibility bypass | Governance centralization | Low | Code checks; audits |

## 13. Post-Deployment Verification

After deployment, verify:

- All contract addresses stored and verified on block explorer.
- Role assignments as per the deployment script.
- Timelock delay set correctly.
- ELYS rewards pool set to Staking address.
- Treasury funded and annual cap initialized.
- Governor parameters (voting delay/period/threshold) reflect intended values.
- Sample proposal created and passes through timelock.
- Jury challenge test on testnet.

See POST-DEPLOYMENT-CHECKLIST.md for step-by-step verification tasks.

## 14. Maintenance & Upgrades

- Monitor contract events for unusual activity (large treasury spends, role changes, challenges).
- Keep software dependencies updated (OpenZeppelin, Foundry).
- If contracts are made upgradeable, follow a rigorous upgrade process: proposal, timelock, testing on testnet, community review.
- Periodically review signer composition for multisigs (add/remove as needed via Governor).
- Review and adjust governance parameters (timelocks, thresholds, fee BPS) via governance proposals.

## Conclusion

Elysium implements a robust set of governance mechanisms with multiple layers of security. Careful attention to role management, key security, and proactive monitoring will ensure the system remains resilient. Always test thoroughly on testnets before mainnet, and consider an external audit for production deployments.
