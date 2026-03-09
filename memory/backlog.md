# Elysium Technical Implementation Backlog

**Priority Order (Critical → Refinements)**

## 🔴 Priority 1: Core Governance & Security (Must-Have)
1. **AI Vote Cap Enforcement** – ✅ **COMPLETE** (2026-03-08)
   - AI Phase 2: 0.5x vote weight (per constitution)
   - AI Phase 2: restricted to ParameterChange proposals only
   - AI vote cap: 20% of total votes with proportional scaling
   - Refactored with `_applyAICap` helper to fix stack depth
   
2. **CitizenshipJury Random Selection** – ✅ **COMPLETE** (2026-03-08)
   - Random selection of 5 jurors from eligible citizens (H1/H2, non-AI)
   - Uses block.timestamp + block.prevrandao + challengeId for randomness
   - Fisher-Yates style selection from eligible pool
   
3. **Identity Challenge System** – ✅ **COMPLETE** (2026-03-08)
   - Challenge deposit: 1000 ELYS (H1 exempt)
   - H3 and AI cannot challenge
   - Rate limit: 3 challenges per 30 days
   - 5 random jurors vote; majority decides revoke/refund
   - Deposit burned if citizenship revoked

## 🟡 Priority 2: Verification & Access Control
4. **Verifier Integration** – ✅ **COMPLETE** (2026-03-09)
   - Added `isVerified` mapping and `Verified` event
   - `verifyHumanPhase(address wallet, uint256 phase)` only callable by `VERIFIER_ROLE`
   - Updates citizen phase and marks as verified
   - 4 tests passing (unauthorized, AI revert, non-citizen revert, multiple verifies)
   
5. **Merit Grants** – ✅ **COMPLETE** (2026-03-09)
   - Added `MERIT_GRANTOR_ROLE` (deployer gets it initially)
   - `grantMerit(address wallet, uint256 tier, uint256 phase, string metadataURI)` free mint
   - 4 tests: onlyGrantor, nonGrantorReverts, alreadyCitizenReverts, emitsEvents
   - Total tests: 52 passing

## 🟢 Priority 3: Refinements & Compliance
6. **Tier Timelocks** – ✅ **COMPLETE** (2026-03-09)
   - Override `votingDelay()` and `votingPeriod()` to return tier-specific values:
     - Tier1 (ParameterChange, TreasurySpendSmall): 1 day delay, 7 days voting
     - Tier2 (TreasurySpendMedium, MultiSigElection): 7 days delay, 7 days voting
     - Tier3 (Constitutional, CorePrinciple, AIPhaseTransition, TreasurySpendLarge): 14 days delay, 10 days voting
   - Implementation uses `currentProposalTier` storage variable set during `propose()` to provide context to `votingDelay()` and `votingPeriod()`.

7. **H3 Phase Transition Safeguards** – ✅ **COMPLETE** (2026-03-09)
   - Enforced 30-day waiting period for phase transitions in `CitizenshipNFT.updatePhase()`
   - Prevent phase shopping: require strict increment-by-1 progression (H1→H2→H3 only)
   - Ensure H3 cannot challenge identities (CitizenshipJury._checkChallengerEligibility)
   - Ensure H3 cannot serve as multi-sig signers:
     - `_checkEligibility` excludes H3 from signer pool
     - Added explicit eligibility checks in `submitTransaction`, `confirmTransaction`, `executeTransaction` to block H3 even if they have SIGNER_ROLE
   - Added comprehensive test coverage:
     - `CitizenshipNFTPhaseTransition.t.sol` (3 tests)
     - `CitizenshipJuryChallenge.t.sol`: `test_H3_CannotBeAddedAsSigner`, `test_H3_CannotSubmitTransactionIfSigner`
   - All 60 tests passing (commit `4c8de0e`)

---

## 🧩 Repository Separation

On 2026-03-09, OpenClaw workspace identity/config files were moved to a dedicated repository:

- **New repo:** `wilma` (https://github.com/iyeque/wilma)
- **Files moved:** IDENTITY.md, USER.md, SOUL.md, AGENTS.md, TOOLS.md, HEARTBEAT.md, BOOTSTRAP.md
- **Elysium repo:** Now clean — only Elysium project files and memory.

**Future tasks:** Keep OpenClaw-specific configuration in the wilma repository; Elysium work stays in the Elysium repository. The local workspace still contains both (OpenClaw needs the files), but the Elysium git no longer tracks them.
