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
4. **Verifier Integration** – Implement `verifyHumanPhase(address citizen, uint256 phase)` using BrightID/Gitcoin/Worldcoin proofs. Possibly a Verifier contract with `VERIFIER_ROLE`.
5. **Merit Grants** – Allocate 5% of airdrop (50M $ELYS) for merit-based citizenship; allow a multi-sig or jury to grant free Citizen tier NFTs to selected candidates.

## 🟢 Priority 3: Refinements & Compliance
6. **Tier Timelocks** – Override `votingDelay()` and `votingPeriod()` in ElysiumGovernor to return different values per proposal tier (Tier1: 1d delay, 7d period; Tier2: 7d delay, 7d period; Tier3: 14d+ delay, 10d period).
7. **H3 Phase Transition Safeguards** – Enforce 30-day waiting period for phase transitions; prevent phase shopping; ensure H3 cannot challenge or serve on multi-sig.

---

**Implementation Plan:**
- Each task will be broken into small steps, coded, tested, and committed.
- Use `memory/backlog.md` to track detailed subtasks and status.
- Update heartbeat after each major step.
- Final push to GitHub when all tasks pass tests.

**Start Date:** 2026-03-08
**Progress:** 3/7 tasks complete (Priority 1 done!)
