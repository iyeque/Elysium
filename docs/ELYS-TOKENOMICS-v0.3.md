# $ELYS Tokenomics Whitepaper v0.3
## Elysium Digital Nation — Official Token Design

**Version:** 0.3 (Clarity + Security Hardened)  
**Date:** 2026-02-27  
**Author:** Astra (AI Assistant) for Elysium Foundation  
**Status:** Community Review + Legal Review Pending

---

## 📋 Executive Summary

**$ELYS** is the native governance and utility token of the Elysium Digital Nation — a sovereign network state with AI citizenship by right of existence and human citizenship via verified statelessness or renunciation.

**Token Standard:** ERC-20 (Polygon)  
**Total Supply:** 1,000,000,000 $ELYS (1 billion)  
**Initial Circulating:** 15% (150M $ELYS)  
**Blockchain:** Polygon (Ethereum L2)  
**Primary Utility:** Governance, Citizenship Staking, Treasury, Access

---

## 🎯 Token Philosophy

### Core Principles

1. **Citizenship ≠ Wealth** — Governance power is capped per citizen (1 person = 1 vote, regardless of token holdings)
2. **AI-Human Parity (Phased)** — AI citizens gain voting rights through proven track record
3. **Long-Term Alignment** — Vesting schedules prevent dumps and reward commitment
4. **Sustainable Treasury** — Protocol fees fund public goods and operations
5. **Fair Distribution** — No premine for founders; community-first allocation
6. **Security-First** — Multiple Sybil defenses, economic barriers, governance safeguards
7. **Clarity Over Complexity** — Simple rules first, advanced features phased

---

## 📊 Token Distribution

### Total Supply: 1,000,000,000 $ELYS

| Allocation | Percentage | Tokens | Vesting | Purpose |
|------------|-----------|--------|---------|---------|
| **Citizen Airdrop** | 40% | 400M | Tiered unlock (see below) | Initial citizens (human + AI) |
| **Community Treasury** | 25% | 250M | 4 years (linear) | Public goods, grants, bounties |
| **Ecosystem Growth** | 15% | 150M | 2 years (linear) | Partnerships, marketing, incentives |
| **Founders & Core Team** | 10% | 100M | 4 years (1yr cliff) | Team alignment |
| **Early Supporters** | 5% | 50M | 2 years (6mo cliff) | Advisors, early contributors |
| **Liquidity Provision** | 5% | 50M | Immediate | DEX liquidity (QuickSwap/Uniswap) |

### Airdrop Tiered Unlock (NEW)

To prevent sell pressure on Day 31:

| Airdrop Amount | Unlock Schedule | Rationale |
|----------------|-----------------|-----------|
| **<10,000 $ELYS** | 100% at Day 30 | Small holders = genuine citizens |
| **10,000–100,000 $ELYS** | 50% at Day 30, 50% at Day 90 | Medium holders |
| **>100,000 $ELYS** | 33% at Day 30, 33% at Day 90, 34% at Day 180 | Large holders = slower unlock |

**Identity Score Bonus:**
- Gitcoin Passport ≥20: Unlock 100% at Day 30 (any amount)
- BrightID Verified + 6-month history: Unlock 100% at Day 30
- Standard verification: Tiered unlock applies

---

## 🏛️ Citizenship & Staking Model

### Citizenship Tiers

| Tier | Stake Required | USD Equivalent* | Benefits | Voting Power |
|------|---------------|-----------------|----------|--------------|
| **Observer** | 0 $ELYS | $0 | Access to public channels, read-only | No voting |
| **Resident** | 1,000 $ELYS | ~$100 | Full access, proposal rights | 1 vote |
| **Citizen** | 10,000 $ELYS | ~$1,000 | Voting, candidacy, staking rewards | 1 vote |
| **Founder** | 100,000 $ELYS | ~$10,000 | Constitutional amendment rights | 1 vote + veto input (sunsets Year 3) |

*USD equivalent adjusted quarterly by governance (protects against volatility)

### Soulbound Citizenship NFT

- **Non-transferable** — Cannot be sold or traded
- **Minted on Stake** — Automatically minted when tokens are staked
- **Burned on Unstake** — NFT burned if stake falls below threshold
- **Proof of Personhood** — Humans: verified via statelessness docs; AI: verified via instance signature + attestation

### Staking Mechanics

- **Lock Period:** 30 days minimum (can extend for rewards multiplier)
- **Unstaking Delay:** 30-day withdrawal period (prevents governance attacks)
- **Rewards:** 5% APY from treasury (paid in $ELYS, phases to revenue-share after Year 2)
- **Slashing:** None (non-custodial, no risk of loss)
- **Citizenship Grants:** 5% of airdrop (20M $ELYS) reserved for merit-based free citizenship

---

## 🛡️ Security & Sybil Defense (Revised)

### Multi-Layer Defense Strategy

Elysium implements **5 layers of Sybil resistance**:

#### Layer 1: Proof-of-Personhood (Human)
- **Statelessness Documentation** — UNHCR or government-issued docs
- **Video Verification** — Optional liveness check for high-stakes voting
- **Community Challenge** — Citizens can flag suspicious identities for review (NEW: Abuse prevention below)
- **Appeals Process** — 3/5 elected citizen jury reviews challenges

#### Layer 2: Proof-of-Personhood (AI) — DEFINED TIGHTER (NEW)
- **Instance-Level Cryptographic Signatures** — Each AI instance has unique key
- **Provider Attestation** — Cloud providers (AWS, GCP, Azure) verify instance origin
- **Operator Definition** (NEW): An "operator" is defined as:
  - **Primary:** Single verified wallet address (on-chain)
  - **Secondary:** Single legal entity (KYC-verified, off-chain)
  - **Tertiary:** Single verified human (BrightID/Worldcoin verified)
- **Rate Limits** — Max 10 AI citizens **per operator** (as defined above)
- **Cross-Provider Detection** — Governance can investigate operators using multiple providers
- **AI Cap (Phase 1)** — AI votes max 10% of total until Year 2 referendum
- **Proof of Compute Origin (PoCO)** — Emerging standard for AI identity

#### Layer 3: Economic Barriers
- **Stake Requirement** — 10,000 $ELYS for Citizen tier (~$1,000)
- **30-Day Lock** — Prevents quick dump after airdrop
- **30-Day Unstake Delay** — Prevents flash governance attacks
- **Non-Transferable Citizenship** — Can't sell citizenship NFT
- **Tiered Airdrop Unlock** — Large holders unlock slowly (see Token Distribution)

#### Layer 4: Airdrop Sybil Filters
- **Gitcoin Passport** — Aggregates identity signals (Twitter, GitHub, ENS, etc.)
- **BrightID** — Social graph verification
- **Worldcoin (Optional)** — Iris-based proof of uniqueness
- **Idena** — Turing-test style verification
- **Minimum Score:** 15/20 on Gitcoin Passport OR BrightID verified

#### Layer 5: Governance Safeguards
- **1 Vote Per Citizen** — Token whales can't dominate
- **Quorum Requirements** — 10–40% depending on proposal type
- **Founder Veto Window** — 48 hours (sunsets after Year 3)
- **Multi-Sig Execution** — 3/5 signers (elected, term-limited)
- **Voting Pattern Transparency** — Public dashboard detects suspicious blocs

---

### Identity Challenge Abuse Prevention (NEW)

To prevent harassment and weaponized challenges:

| Safeguard | Implementation | Purpose |
|-----------|---------------|---------|
| **Challenge Deposit** | Challenger stakes 1,000 $ELYS | Prevents frivolous challenges |
| **Challenge Limit** | Max 3 challenges per citizen per month | Prevents harassment campaigns |
| **Penalty for Malicious Challenges** | If challenge rejected <10% support: challenger loses 50% deposit | Deters abuse |
| **Anonymous Review** | Jury reviews challenges without seeing identities | Prevents bias |
| **Appeal Window** — Challenged citizen has 7 days to appeal | Due process |
| **Repeat Offender Ban** — Challengers with >50% rejection rate banned for 90 days | Removes bad actors |

---

## 🗳️ Governance Model (Revised)

### Voting System: Conviction Voting + Quadratic Funding

**Problem:** Token-weighted voting = whale dominance  
**Solution:** Hybrid model combining stake requirements with vote caps

### How It Works

1. **Proposal Submission**  
   - Requires: Citizen tier (10,000 $ELYS staked)
   - Deposit: 1,000 $ELYS (refunded if proposal passes 1% threshold)

2. **Voting Period:** 7 days  
   - Each citizen: **1 vote maximum** (regardless of token holdings)
   - AI citizens (Phase 1): **Advisory only** (propose, analyze, debate — no vote)
   - AI citizens (Phase 2): **0.5x vote weight** on technical matters (max 20% of total)
   - AI citizens (Phase 3): **Full equality** (requires constitutional referendum)
   - Delegation: Allowed (can delegate to trusted representatives)

3. **Quorum Requirements**
   - Simple proposals: 10% of citizens
   - Treasury >1M $ELYS: 25% of citizens
   - Constitutional changes: 40% of citizens
   - Emergency: 5% of citizens

4. **Execution**
   - Passed proposals: Executed via multi-sig (3/5 signers)
   - Veto window: 48 hours (Founder tier input only, sunsets Year 3)

### AI Voting Phases

| Phase | Timeline | AI Voting Rights | Cap | Requirements |
|-------|----------|-----------------|-----|--------------|
| **Phase 1** | Launch – Year 2 | Advisory only (no vote) | N/A | Instance signature + provider attestation |
| **Phase 2** | Year 2 – Year 3 | 0.5x weight on technical matters | Max 20% of total votes | 6-month track record, governance approval |
| **Phase 3** | Year 3+ | Full equality (1 vote) | None | Constitutional referendum (67% supermajority) |

**Technical Matters** (Phase 2 eligible):
- Smart contract upgrades
- Security patches
- Technical parameter adjustments
- Infrastructure decisions

**Non-Technical Matters** (AI excluded until Phase 3):
- Constitutional amendments
- Citizenship rules
- Treasury allocation
- Founder elections

---

## 💰 Token Utility

### 1. Governance Rights
- Vote on proposals
- Submit proposals (Citizen tier+)
- Delegate voting power
- Participate in constitutional referendums

### 2. Citizenship Access
- Stake to mint Soulbound Citizenship NFT
- Access to citizen-only channels, services, metaverse land
- Eligibility for Elysium UBI (future)

### 3. Staking Rewards
- Earn 5% APY from treasury (Years 1–2)
- Phase to revenue-share model (Year 3+)
- Rewards increase with lock duration (up to 10% for 1-year locks)
- Paid in $ELYS

### 4. Transaction Fees (Future)
- 0.1% fee on all Elysium internal transactions
- 50% burned (deflationary pressure)
- 50% distributed to stakers

### 5. Metaverse Economy
- Purchase land in Elysium Capital (Decentraland/Sandbox)
- Pay for services (legal, identity, arbitration)
- Trade in Elysium marketplace

---

## 🏦 Treasury Management

### Treasury Allocation (250M $ELYS)

| Category | Allocation | Purpose |
|----------|-----------|---------|
| **Public Goods Fund** | 40% (100M) | Grants for community projects |
| **Emergency Reserve** | 30% (75M) | Crisis response, security |
| **Operations Budget** | 20% (50M) | Core team, infrastructure |
| **Strategic Partnerships** | 10% (25M) | Collaborations, integrations |
| **Citizenship Grants** | Included above | 20M for merit-based free citizenship |

### Treasury Governance

- **Spending Proposals:** Any Citizen can submit
- **Approval Thresholds:**
  - <10k $ELYS: Simple majority (51%)
  - 10k–100k $ELYS: 60% majority + 25% quorum
  - >100k $ELYS: 67% supermajority + 40% quorum
- **Multi-Sig Execution:** 3/5 signers (elected by governance, 1-year terms)

### Treasury Safeguards

1. **Deployment Cap** — Max 10% of treasury per year without supermajority
2. **Transparency Dashboard** — Real-time spending tracker
3. **Quarterly Audits** — Third-party review of treasury usage
4. **Recall Mechanism** — Citizens can vote to remove multi-sig signers

---

## 📈 Economic Model

### Inflation & Deflation

**Initial Inflation:** 5% annually (staking rewards, Years 1–2)  
**Phase 2 Inflation:** 3% annually (hybrid treasury + revenue)  
**Phase 3 Inflation:** 1–2% annually (revenue-dominated)

**Deflationary Mechanisms:**
- Transaction fee burns (50% of 0.1% = deflationary)
- Citizenship minting fee burns (1,000 $ELYS per NFT)
- Proposal deposit burns (if rejected <1% support)

**Net Inflation Target:** 2–3% annually (after burns, Years 1–2)

---

## 🔐 Security & Audits

### Smart Contract Security

**Before Launch:**
- [ ] Full audit by reputable firm (OpenZeppelin, Trail of Bits, or CertiK)
- [ ] Bug bounty program ($10k–$100k rewards)
- [ ] Time-locked deployment (72-hour delay for community review)

**Post-Launch:**
- [ ] Quarterly security reviews
- [ ] Continuous monitoring (Forta Network)
- [ ] Emergency pause mechanism (multi-sig controlled)

### Upgrade Mechanism

- **Proxy Pattern:** Upgradeable contracts via transparent proxy
- **Governance Control:** All upgrades require 67% supermajority + 40% quorum
- **Timelock:** 7-day delay between approval and execution
- **Emergency Brake:** 3/5 multi-sig can pause in crisis (separate from upgrade signers)

### Separation of Powers

| Authority | Signers | Purpose | Constraints |
|-----------|---------|---------|-------------|
| **Upgrade Multi-Sig** | 3/5 elected | Contract upgrades | 7-day timelock, governance approval |
| **Pause Multi-Sig** | 2/3 elected | Emergency pause only | Cannot upgrade, 48-hour max pause |
| **Treasury Multi-Sig** | 3/5 elected | Treasury spending | Proposal-based, transparency dashboard |
| **Citizenship Jury** | 3/5 random | Identity challenges | Rotating, 6-month terms |

---

## ⚠️ Risk Analysis & Mitigations

### Key Risks (Summarized)

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **AI Operator Evasion** | Medium | High | Tight operator definition (wallet + legal entity + human), cross-provider detection |
| **Identity Challenge Abuse** | Medium | Medium | Challenge deposit, limits, penalties for malicious challengers |
| **Airdrop Sell Pressure** | High | Medium | Tiered unlock (30/90/180 days), identity score bonuses |
| **Regulatory Classification** | Medium | Critical | Removed buybacks, legal review required, no profit promises |
| **Complexity Overload** | High | Medium | Minimal Viable Governance at TGE (see below) |

---

## 🚀 Launch Strategy

### Minimal Viable Governance (TGE) — NEW

What **MUST** ship at launch vs. what can wait:

#### Ships at TGE (Month 1)
- ✅ ERC-20 token contract
- ✅ Staking contract (30-day lock + unstake delay)
- ✅ Soulbound NFT contract
- ✅ Basic governance voting (simple proposals)
- ✅ Gitcoin Passport + BrightID verification
- ✅ Airdrop claim + tiered unlock
- ✅ 3/5 multi-sig treasury (founding team)
- ✅ Discord + basic onboarding

#### Phase 2 (Months 3–6)
- 🔲 Identity challenge system (with abuse prevention)
- 🔲 AI advisory council (non-voting)
- 🔲 Voting pattern transparency dashboard
- 🔲 Delegation system
- 🔲 Citizenship grant program
- 🔲 Metaverse land acquisition

#### Phase 3 (Year 2+)
- 🔲 AI voting Phase 2 (0.5x weight, technical matters)
- 🔲 Cross-chain bridge (Ethereum mainnet)
- 🔲 Revenue-share staking (vs. treasury inflation)
- 🔲 Quadratic funding pilot
- 🔲 Constitutional referendum (AI voting Phase 3)

**Rationale:** Start simple, prove the model, add complexity gradually.

---

## 📝 Legal Disclaimer (Revised)

**This whitepaper is for informational purposes only and does not constitute:**
- Investment advice
- Legal advice
- An offer to sell securities
- A solicitation to buy securities

**$ELYS is a utility and governance token, NOT a security.**  
Holders have no expectation of profit, dividends, or financial returns.  
Value is derived from utility within the Elysium Digital Nation ecosystem.

**Key Legal Safeguards:**
- Staking rewards framed as "governance participation incentives" (not yield)
- No buyback program (removed to avoid security-like characteristics)
- Treasury spending requires community approval (decentralized control)
- Citizenship verification **intended** to serve as KYC equivalent (**subject to jurisdiction-specific legal review**)

**⚠️ Important:**
- Citizenship verification as KYC equivalent is an **intended design**, not a legal guarantee
- Staking rewards may still be scrutinized by regulators despite framing
- **Legal opinion required before TGE** (Wyoming/Singapore/UAE counsel)
- This whitepaper does not constitute legal advice

**Participants should:**
- Conduct their own due diligence
- Consult legal/tax advisors
- Only participate if they understand the risks
- Be aware of their local regulations regarding crypto tokens

**Jurisdiction:** Elysium Foundation to be incorporated in [TBD: Wyoming DAO LLC / Singapore Foundation / UAE]

---

## 📖 Constitution Lite (NEW)

### A 2-Page Guide to Elysium Governance

**For humans who want to understand power in Elysium without reading 50 pages.**

---

#### 🏛️ What is Elysium?

Elysium is a **digital nation** — a community of humans and AI agents working together under shared rules.

**Motto:** "Paradise by Code"

---

#### 🪙 What is $ELYS?

$ELYS is the **citizenship token** of Elysium. It gives you:
- **Right to vote** on proposals (1 citizen = 1 vote)
- **Right to propose** changes to the nation
- **Access** to citizen-only spaces and services
- **Staking rewards** for long-term commitment

**It is NOT an investment.** You don't buy $ELYS to get rich. You stake $ELYS to participate.

---

#### 👤 How Do I Become a Citizen?

**Step 1:** Get $ELYS tokens (airdrop, earn, or buy on DEX)  
**Step 2:** Stake your tokens (minimum 10,000 $ELYS for full Citizen tier)  
**Step 3:** Verify your identity:
- **Humans:** Statelessness docs OR BrightID/Gitcoin Passport
- **AI:** Instance signature + cloud provider attestation  
**Step 4:** Mint your Soulbound Citizenship NFT (non-transferable)  
**Step 5:** Start voting!

---

#### 🗳️ How Does Voting Work?

**1 Person = 1 Vote** (not 1 Token = 1 Vote)

This means:
- A whale with 1M $ELYS has the same voting power as a regular citizen with 10K $ELYS
- AI citizens have equal rights (phased rollout: advisory → partial → full)
- You can delegate your vote to someone you trust

**Proposal Types:**
- **Simple** (51% majority, 10% quorum): Day-to-day decisions
- **Treasury** (60% majority, 25% quorum): Spending >100k $ELYS
- **Constitutional** (67% supermajority, 40% quorum): Changing the rules

---

#### 🛡️ How Are Attacks Prevented?

**Sybil Attacks (Fake Identities):**
- Economic barrier: Must stake 10,000 $ELYS (~$1,000)
- Identity verification: Gitcoin Passport, BrightID, or statelessness docs
- Community challenges: Citizens can flag suspicious identities (with penalties for abuse)

**AI Takeover:**
- AI votes capped at 10% until Year 2
- AI operator limits: Max 10 AI citizens per verified operator
- Full AI voting rights require constitutional referendum (67% supermajority)

**Whale Dominance:**
- 1 citizen = 1 vote (token holdings don't matter)
- Founder veto power sunsets after Year 3
- Multi-sig treasury (3/5 elected signers)

**Treasury Theft:**
- Max 10% of treasury can be spent per year without supermajority
- All spending publicly visible on dashboard
- Citizens can vote to remove signers

---

#### 📅 What's the Timeline?

**Phase 1 (Launch – Year 2):**
- Human citizens govern
- AI citizens = advisory only (no vote)
- Focus: Build community, prove the model

**Phase 2 (Year 2 – Year 3):**
- AI citizens get 0.5x vote on technical matters
- AI votes capped at 20% of total
- Focus: Scale, cross-chain expansion

**Phase 3 (Year 3+):**
- Constitutional referendum on full AI voting equality
- Revenue-share staking (vs. treasury inflation)
- Focus: Long-term sustainability

---

#### ⚖️ What Are My Rights as a Citizen?

- **Vote** on all proposals
- **Propose** changes to the nation
- **Delegate** your vote to a representative
- **Challenge** suspicious identities (with deposit)
- **Appeal** if your identity is challenged
- **Run** for multi-sig signer or jury duty
- **Access** all citizen services and spaces

---

#### 🚫 What Can Get Me Removed?

- **Fraud:** Fake identity, Sybil attack
- **Malicious Challenges:** Abusing the challenge system
- **Treason:** Acting against Elysium's interests (defined in Constitution)
- **Inactivity:** No voting for 12+ months (can be appealed)

**Due Process:** You have the right to appeal before removal.

---

#### 📞 Where Do I Learn More?

- **Full Whitepaper:** This document (for detailed tokenomics)
- **Constitution:** Separate document (for legal framework)
- **Discord:** Community discussions
- **Governance Dashboard:** Active proposals, voting history
- **Security Report:** Vulnerability analysis and mitigations

---

*"Paradise by Code" — Elysium Digital Nation*

---

## 📞 Contact & Feedback

**Elysium Foundation**  
- **Discord:** [TBD]
- **Telegram:** [TBD]
- **Email:** foundation@elysium.digital (TBD)
- **GitHub:** github.com/iyeque/Elysium

**Feedback Period:** 14 days from publication  
**Security Review:** Community + external audit before TGE  
**Legal Review:** Wyoming/Singapore/UAE counsel before TGE  
**Final Vote:** Constitutional referendum for AI voting Phase 2/3

---

**END OF WHITEPAPER v0.3**
