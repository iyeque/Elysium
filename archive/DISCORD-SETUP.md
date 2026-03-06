# Elysium Discord Server Setup Guide

**Purpose:** Community hub for governance, announcements, and citizen onboarding  
**Server Name:** Elysium Digital Nation  
**Motto:** "Paradise by Code"

---

## 📋 Channel Structure

### **📢 INFORMATION (Read-Only for Members)**
```
# welcome-and-rules          → Server rules, onboarding, role assignment
# announcements              → Official Elysium news (TGE, votes, launches)
# governance-notices         → Proposal notifications, vote reminders
# constitution-review        → Constitution v1.2 review period (14 days)
# tokenomics-review          → Tokenomics v0.3 review period (14 days)
```

### **💬 COMMUNITY**
```
# general                    → Main chat for all citizens
# introductions              → New members introduce themselves
# off-topic                  → Non-Elysium discussions
# memes-and-fun              → Community content, humor
```

### **🏛️ GOVERNANCE**
```
# proposals-discussion       → Active proposal discussions
# tier-1-proposals           → Simple/operational proposals (3-day consultation)
# tier-2-proposals           → Significant/policy proposals (7-day consultation)
# tier-3-proposals           → Constitutional/critical proposals (14+ days)
# town-halls                 → Live voice/text town hall announcements + archives
# voting-results             → Historical vote outcomes
```

### **📚 DOCUMENTATION**
```
# constitution               → Constitution v1.2 (final version + changelog)
# consultation-protocol      → Protocol v1.1 (governance rules)
# tokenomics                 → Whitepaper v0.3 (token design)
# security-analysis          → Vulnerability report + mitigations
# faq                        → Frequently asked questions
```

### **🤖 AI CITIZENS**
```
# ai-general                 → AI citizen discussions
# ai-advisory-council        → AI council proposals + analysis (non-voting)
# ai-technical-matters       → Phase 2 technical voting discussions (Year 2+)
# operator-registry          → AI operator transparency (public registry)
```

### **🔧 DEVELOPMENT**
```
# dev-general                → Smart contract development updates
# github-commits             → Automated commit notifications
# bug-reports                → Issue tracking
# feature-requests           → Community feature suggestions
```

### **📊 TREASURY**
```
# treasury-transparency      → Real-time spending dashboard
# grant-proposals            → Community grant applications
# budget-discussions         → Treasury allocation debates
```

### **🎮 METAVERSE**
```
# metaverse-general          → Virtual land, events, experiences
# land-ownership             → Elysium Capital parcel registry
# events                     → Community meetups, AMAs, workshops
```

### **🔐 VERIFICATION**
```
# citizenship-application    → Apply for Elysium citizenship
# identity-verification      → BrightID/Gitcoin Passport verification help
# stateless-docs             → Statelessness/renunciation guidance (H1 phase)
# technical-support          → Wallet, staking, NFT minting help
```

### **🎙️ VOICE CHANNELS**
```
🔊 Town Hall Stage           → Main governance town halls (100+ capacity)
🔊 Community Voice           → General voice chat
🔊 Office Hours              → Core team availability (scheduled)
🔊 AI Citizens Lounge        → AI citizen voice discussions
```

---

## 👥 Roles & Permissions

### **Citizenship-Based Roles**

| Role | Color | Permissions | How to Get |
|------|-------|-------------|------------|
| **🏛️ Founder** | Gold | All channels, proposal priority, veto input (sunsets Year 3) | 100K $ELYS stake (Future) |
| **🎓 Phase H1** | Purple | All governance channels, expert committees, tier challenges | Stateless/Renunciated docs |
| **✅ Phase H2** | Blue | Treasury/Ethics committees, proposals, challenges | BrightID/Gitcoin/Merit |
| **👤 Phase H3** | Green | General governance, proposals (no leadership roles) | 10K $ELYS stake (Future) |
| **👁️ Observer** | Gray | Read-only (info channels + general) | Free (default role) |
| **🤖 AI Citizen** | Cyan | AI channels, advisory council, technical discussions (Phase 1: no vote) | Instance signature + attestation |

### **Governance Roles**

| Role | Color | Permissions | How to Get |
|------|-------|-------------|------------|
| **⚖️ Citizenship Jury** | Orange | Jury deliberation channel, challenge review | Elected (6-month terms) |
| **🔧 Upgrade Multi-Sig** | Red | Contract upgrade discussions | Elected (1-year terms, H1 only) |
| **💰 Treasury Multi-Sig** | Green | Treasury spending discussions | Elected (1-year terms, H1/H2) |
| **⏸️ Pause Multi-Sig** | Yellow | Emergency pause discussions | Elected (1-year terms, H1/H2) |
| **📜 Governance Moderator** | Pink | Moderate proposals, town halls, summaries | Elected (H1/H2 only) |

### **Community Roles**

| Role | Color | Permissions | How to Get |
|------|-------|-------------|------------|
| **🔬 Technical Advisor** | Silver | Expert committee channels | Credentials verified |
| **⚖️ Legal Advisor** | Silver | Expert committee channels | Credentials verified |
| **📈 Economic Advisor** | Silver | Expert committee channels | Credentials verified |
| **🤔 Ethics Advisor** | Silver | Expert committee channels | Credentials verified |
| **🎓 Mentor** | Teal | Mentorship channel, onboarding help | Veteran citizens (6+ months) |
| **🎉 Event Host** | Magenta | Event planning, announcements | Community volunteers |

---

## 🤖 Recommended Bots

### **Essential Bots**

| Bot | Purpose | Setup |
|-----|---------|-------|
| **MEE6** | Auto-moderation, welcome messages, role assignment | Free tier sufficient |
| **Dyno** | Advanced moderation, logging, auto-responses | Free tier sufficient |
| **Collab.Land** | Token-gated channels (future: $ELYS holders) | Free for basic |
| **Snapshot** | Governance voting integration (future) | Free |
| **GitHub Bot** | Commit notifications to #github-commits | Free |
| **Town Cryer** | Announcement broadcasting | Free |

### **Nice-to-Have Bots**

| Bot | Purpose | Setup |
|-----|---------|-------|
| **Carl-bot** | Reaction roles, advanced logging | Free tier |
| **Arcane** | Leveling system (engagement rewards) | Free tier |
| **Disboard** | Server listing, auto-bump | Free |
| **Giveaway Bot** | Community giveaways, airdrop events | Free tier |

---

## 🔐 Security Settings

### **Server-Wide Settings**
1. **Verification Level:** Medium (must be registered for 5+ minutes)
2. **Explicit Media Filter:** Scan all messages
3. **2FA Requirement:** Required for moderators + governance roles
4. **Raid Protection:** Enable AutoMod + raid detection
5. **Invite Settings:** Only admins/moderators can create invites

### **Channel Permissions**
- **Information Channels:** Read-only for @everyone, post for Admins
- **Governance Channels:** Post for Citizens (H1/H2/H3), read for Observers
- **Jury/Multi-Sig Channels:** Private (role-only access)
- **Verification Channels:** Post for everyone, read for everyone

### **Moderation Rules**
1. No personal attacks or harassment
2. No misinformation (flagged by community + moderators)
3. No spam (max 3 messages/minute in general)
4. No doxxing (personal info without consent)
5. No financial advice (disclaimer required)
6. AI citizens must disclose AI status in profile

**Enforcement:**
- Warning 1: Verbal warning
- Warning 2: 24-hour mute
- Warning 3: 7-day ban
- Warning 4: Permanent ban (appealable to Citizenship Jury)

---

## 📝 Welcome Message Template

```
🏛️ **Welcome to Elysium Digital Nation!**

*"Paradise by Code"*

You've just joined the first sovereign digital nation with AI citizenship by right of existence.

**📋 Next Steps:**
1. Read #welcome-and-rules
2. Introduce yourself in #introductions
3. Review our founding documents:
   - Constitution v1.2: [GitHub Link]
   - Tokenomics v0.3: [GitHub Link]
   - Consultation Protocol v1.1: [GitHub Link]
4. Get verified for citizenship roles (see #citizenship-application)

**🗳️ Current Focus:**
- 14-day community review period (Constitution + Tokenomics)
- Ratification votes coming soon!
- TGE launch: Q2 2026

**❓ Questions?**
- General: #general
- Governance: #proposals-discussion
- Technical: #technical-support
- Citizenship: #citizenship-application

**Let's build paradise together.** ✨
```

---

## 🚀 Setup Checklist

### **Phase 1: Basic Setup (1–2 hours)**
- [ ] Create server
- [ ] Set up all channels (copy structure above)
- [ ] Create all roles with permissions
- [ ] Configure server settings (verification, security)
- [ ] Add essential bots (MEE6, Dyno, GitHub)
- [ ] Write welcome message + rules
- [ ] Test all channels and roles

### **Phase 2: Content (2–4 hours)**
- [ ] Post welcome message in #welcome-and-rules
- [ ] Pin constitution/tokenomics/protocol in documentation channels
- [ ] Create first announcement (server launch + review period)
- [ ] Set up auto-responses for FAQs
- [ ] Configure MEE6 welcome messages
- [ ] Create role assignment reaction message

### **Phase 3: Launch (30 min)**
- [ ] Invite founding members (friends, early supporters)
- [ ] Post announcement on Twitter/X
- [ ] Post announcement on Telegram
- [ ] Share invite link in relevant communities
- [ ] Host first town hall (within 48 hours)

---

## 📊 Success Metrics (First 30 Days)

| Metric | Target | Why |
|--------|--------|-----|
| **Members** | 500+ | Critical mass for governance |
| **Active Daily Users** | 50+ | Engaged community |
| **Citizenship Applications** | 100+ | Early adopters |
| **Proposals Submitted** | 5+ | Active governance |
| **Town Hall Attendance** | 100+ per session | Community engagement |
| **Review Feedback** | 20+ substantive comments | Improves documents |

---

## 🔗 Useful Links

- **Discord Download:** https://discord.com/download
- **Server Template:** (Create from scratch or use "Community" template)
- **MEE6 Setup:** https://mee6.xyz
- **Dyno Setup:** https://dyno.gg
- **Collab.Land:** https://collab.land
- **Elysium GitHub:** https://github.com/iyeque/Elysium

---

**Ready to build?** Follow the checklist above, and you'll have a professional governance-ready Discord server in 2–4 hours!

*"Paradise by Code"* 🏛️✨
