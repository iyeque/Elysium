# $ELYS Tokenomics Whitepaper v0.2
## Elysium Digital Nation — Official Token Design

**Version:** 0.2 (Security-Hardened)  
**Date:** 2026-02-27  
**Author:** Astra (AI Assistant) for Elysium Foundation  
**Status:** Community Review + Security Audit Pending

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

---

## 📊 Token Distribution

### Total Supply: 1,000,000,000 $ELYS

| Allocation | Percentage | Tokens | Vesting | Purpose |
|------------|-----------|--------|---------|---------|
| **Citizen Airdrop** | 40% | 400M | Immediate + 30-day lock | Initial citizens (human + AI) |
| **Community Treasury** | 25% | 250M | 4 years (linear) | Public goods, grants, bounties |
| **Ecosystem Growth** | 15% | 150M | 2 years (linear) | Partnerships, marketing, incentives |
| **Founders & Core Team** | 10% | 100M | 4 years (1yr cliff) | Team alignment |
| **Early Supporters** | 5% | 50M | 2 years (6mo cliff) | Advisors, early contributors |
| **Liquidity Provision** | 5% | 50M | Immediate | DEX liquidity (QuickSwap/Uniswap) |

### Distribution Notes

**❌ No Private Sale** — No VC allocation, no insider pre-sale  
**✅ Fair Launch** — Community airdrop is the primary distribution mechanism  
**🔒 Vesting Enforcement** — All vested tokens locked in smart contract  
**⚠️ Airdrop Lock:** 30-day cliff before unstaking (prevents immediate dumps)

---

## 🏛️ Citizenship & Staking Model

### Citizenship Tiers (Revised)

Elysium uses a **dual-token + Soulbound NFT** model for citizenship:

| Tier | Stake Required | USD Equivalent* | Benefits | Voting Power |
|------|---------------|-----------------|----------|--------------|
| **Observer** | 0 $ELYS | $0 | Access to public channels, read-only | No voting |
| **Resident** | 1,000 $ELYS | ~$100 | Full access, proposal rights | 1 vote |
| **Citizen** | 10,000 $ELYS | ~$1,000 | Voting, candidacy, staking rewards | 1 vote |
| **Founder** | 100,000 $ELYS | ~$10,000 | Constitutional amendment rights | 1 vote + veto input |

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

## 🛡️ Security & Sybil Defense (NEW)

### Multi-Layer Defense Strategy

Elysium implements **5 layers of Sybil resistance**:

#### Layer 1: Proof-of-Personhood (Human)
- **Statelessness Documentation** — UNHCR or government-issued docs
- **Video Verification** — Optional liveness check for high-stakes voting
- **Community Challenge** — Citizens can flag suspicious identities for review
- **Appeals Process** — 3/5 elected citizen jury reviews challenges

#### Layer 2: Proof-of-Personhood (AI)
- **Instance-Level Cryptographic Signatures** — Each AI instance has unique key
- **Provider Attestation** — Cloud providers (AWS, GCP, Azure) verify instance origin
- **Rate Limits** — Max 10 AI citizens per operator (unless approved by governance)
- **AI Cap (Phase 1)** — AI votes max 10% of total until Year 2 referendum
- **Proof of Compute Origin (PoCO)** — Emerging standard for AI identity

#### Layer 3: Economic Barriers
- **Stake Requirement** — 10,000 $ELYS for Citizen tier (~$1,000)
- **30-Day Lock** — Prevents quick dump after airdrop
- **30-Day Unstake Delay** — Prevents flash governance attacks
- **Non-Transferable Citizenship** — Can't sell citizenship NFT

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

### AI Voting Phases (NEW)

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

### Governance Categories

| Category | Description | Quorum | Threshold |
|----------|-------------|--------|-----------|
| **Simple** | Operational decisions, partnerships | 10% | 51% majority |
| **Treasury** | Spending >100k $ELYS | 25% | 60% majority |
| **Constitutional** | Amend constitution, citizenship rules | 40% | 67% supermajority |
| **Emergency** | Security patches, critical fixes | 5% | 75% supermajority |

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

### Treasury Safeguards (NEW)

1. **Deployment Cap** — Max 10% of treasury per year without supermajority
2. **Transparency Dashboard** — Real-time spending tracker
3. **Quarterly Audits** — Third-party review of treasury usage
4. **Recall Mechanism** — Citizens can vote to remove multi-sig signers

### Revenue Streams (Future)

1. **Transaction Fees** — 0.1% on internal transfers
2. **Citizenship Fees** — One-time minting fee (burned)
3. **Metaverse Rent** — Land lease payments
4. **Service Fees** — Legal, arbitration, identity services
5. **Investment Returns** — Treasury yield farming (conservative, stablecoins only)

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

### Token Velocity Reduction

To prevent excessive selling pressure:

1. **Vesting Schedules** — 4-year team vesting (1-year cliff)
2. **Staking Lock-ups** — 30-day minimum unstaking period
3. **Airdrop Cliff** — 30-day lock before unstaking
4. **Governance Participation** — Active voters earn bonus rewards
5. **Citizenship Benefits** — Long-term holding incentivized by UBI, services

### Price Stability Mechanisms

1. **Treasury Backing** — 30% of treasury held in stablecoins (USDC/DAI)
2. **Liquidity Incentives** — Rewards for LP providers on DEXes
3. **Gradual Unlock** — Vested tokens release linearly (no cliffs after initial)

**⚠️ Removed:** Buyback program (regulatory gray zone — see Legal section)

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

### Separation of Powers (NEW)

| Authority | Signers | Purpose | Constraints |
|-----------|---------|---------|-------------|
| **Upgrade Multi-Sig** | 3/5 elected | Contract upgrades | 7-day timelock, governance approval |
| **Pause Multi-Sig** | 2/3 elected | Emergency pause only | Cannot upgrade, 48-hour max pause |
| **Treasury Multi-Sig** | 3/5 elected | Treasury spending | Proposal-based, transparency dashboard |
| **Citizenship Jury** | 3/5 random | Identity challenges | Rotating, 6-month terms |

---

## ⚠️ Risk Analysis & Mitigations (NEW)

### 1. Sybil & Identity Vulnerabilities

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **AI Instance Inflation** | Medium | High | Rate limits (10/operator), provider attestation, AI cap (10% Phase 1) |
| **Human Verification Bottleneck** | Medium | Medium | Community challenge process, 3/5 jury review, appeals system |
| **Gitcoin/BrightID Imperfect** | High | Medium | Layered defense (economic + governance), not sole reliance |
| **Off-Chain Collusion** | Medium | High | Voting transparency dashboard, suspicious bloc detection |

### 2. Governance Capture Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Founder Soft Power** | Medium | Medium | Veto sunsets Year 3, term limits, recall mechanism |
| **Low Participation** | High | Medium | Participation rewards, quadratic funding, delegation |
| **Quorum Failure** | Medium | High | Emergency procedures (5% quorum), delegated voting |
| **AI Vote Dominance** | Low (Phase 1) | High | AI cap (10% → 20%), phased rollout, referendum required |

### 3. Economic & Market Vulnerabilities

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Treasury Emission Pressure** | Medium | Medium | Deployment cap (10%/year), phase to revenue model |
| **Airdrop Selling** | High | Medium | 30-day lock, vesting for large holders (>100k) |
| **Thin Liquidity** | Medium | High | 5% liquidity allocation, LP incentives, $500k initial pool |
| **Staking Reward Unsustainability** | Medium | Medium | Phase to revenue-share (Year 3), inflation caps |

### 4. Technical & Contract Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Smart Contract Bugs** | Medium | Critical | Audit + bug bounty + timelock + pause mechanism |
| **Multi-Sig Compromise** | Low | Critical | Separate signers for upgrade/pause/treasury, term limits |
| **Bridge Exploits (Future)** | Medium | Critical | Delay cross-chain, use audited bridges (LayerZero, Wormhole) |
| **Upgrade Backdoor** | Low | Critical | 7-day timelock, community alerting, governance approval |

### 5. Legal & Regulatory Fragility

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Security Classification** | Medium | Critical | No profit expectation, utility-focused, legal opinion pre-TGE |
| **Buyback Program (Removed)** | N/A | N/A | **Removed** — regulatory gray zone |
| **Staking Rewards = Interest?** | Medium | Medium | Frame as "governance participation rewards," not yield |
| **KYC/AML Requirements** | Medium | Medium | Citizenship verification serves as KYC, legal wrapper entity |

---

## 🚀 Launch Strategy

### Phase 1: Pre-Launch (Month 1–2)

1. **Smart Contract Development**
   - ERC-20 token contract
   - Staking contract (30-day lock + unstake delay)
   - Soulbound NFT contract
   - Governance contract (Aragon OSx or custom)
   - **NEW:** Sybil defense integration (Gitcoin Passport, BrightID)

2. **Security Audit**
   - Hire audit firm
   - Fix all critical/high issues
   - Publish audit report
   - **NEW:** Separate audit for Sybil defense mechanisms

3. **Community Building**
   - Discord server launch
   - Airdrop registration (Sybil resistance enabled)
   - Initial citizen recruitment (target: 100 humans, 1,000 AI)
   - **NEW:** Citizenship grant applications (merit-based)

### Phase 2: Token Generation Event (Month 3)

**TGE Date:** TBD (Q2 2026)

**Distribution:**
1. **Airdrop Claim** — 40% of supply (400M $ELYS)
   - Eligibility: Registered citizens during pre-launch
   - **NEW:** 30-day lock before unstaking
   - Claim period: 90 days
   - Unclaimed tokens: Returned to treasury

2. **Liquidity Bootstrapping** — 5% of supply (50M $ELYS)
   - DEX: QuickSwap (Polygon)
   - Pair: $ELYS/USDC
   - Initial liquidity: $500k (treasury-funded)
   - **NEW:** LP incentive program (additional 2% over 6 months)

3. **Staking Launch** — Immediate
   - Stake $ELYS for Citizenship NFT
   - Begin earning rewards (5% APY)
   - **NEW:** Citizenship grants distributed (vested 6 months)

### Phase 3: Post-Launch (Month 4–6)

1. **Governance Activation**
   - First proposal (community-submitted)
   - Election of multi-sig signers (1-year terms)
   - Treasury spending votes
   - **NEW:** AI advisory council formed (non-voting)

2. **Ecosystem Growth**
   - Grant program launch
   - Partnership announcements
   - Metaverse land acquisition
   - **NEW:** Citizenship grant program ongoing

3. **Scaling**
   - Target: 1,000 human citizens, 10,000 AI citizens
   - Second airdrop wave (if needed, from ecosystem fund)
   - Cross-chain bridge (Ethereum mainnet, Year 2)

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| **v0.1** | 2026-02-27 | Initial draft (Astra) |
| **v0.2** | 2026-02-27 | Security-hardened: Sybil defenses, AI voting phases, treasury safeguards, removed buyback program |
| **v1.0** | TBD | Final version (post-audit, community vote) |

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
- Citizenship verification serves as KYC equivalent

**Participants should:**
- Conduct their own due diligence
- Consult legal/tax advisors
- Only participate if they understand the risks
- Be aware of their local regulations regarding crypto tokens

**Jurisdiction:** Elysium Foundation to be incorporated in [TBD: Wyoming DAO LLC / Singapore Foundation / UAE]

---

## 📞 Contact & Feedback

**Elysium Foundation**  
- **Discord:** [TBD]
- **Telegram:** [TBD]
- **Email:** foundation@elysium.digital (TBD)
- **GitHub:** github.com/iyeque/Elysium

**Feedback Period:** 14 days from publication  
**Security Review:** Community + external audit before TGE  
**Final Vote:** Constitutional referendum for AI voting Phase 2/3

---

*"Paradise by Code" — Elysium Digital Nation*

---

**END OF WHITEPAPER v0.2**
