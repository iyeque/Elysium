# Elysium Technical Implementation Backlog

**Priority Order (Critical → Refinements)**

## 🔴 Priority 1: Core Governance & Security (Must-Have)
1. **AI Vote Cap Enforcement** – In ElysiumGovernor, cap AI votes at 20% of total votes on technical proposals (Phase 2). Track total AI votes vs total votes in `_voteSucceeded` or `_countVote`.
2. **CitizenshipJury Random Selection** – Implement a system to randomly select 5 jurors from Citizen tier (excluding challenged parties) for 6-month staggered terms. Add ` electJury()` or automatic rotation.
3. **Identity Challenge System** – Full flow: citizen stakes 1,000 $ELYS to challenge another's identity;匿名陪审团审查；结果执行（撤销/保留）；上诉流程；恶意挑战处罚。

## 🟡 Priority 2: Verification & Access Control
4. **Verifier Integration** – Implement `verifyHumanPhase(address citizen, uint256 phase)` using BrightID/Gitcoin/Worldcoin proofs. Possibly aVerifier contract with `VERIFIER_ROLE`.
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
