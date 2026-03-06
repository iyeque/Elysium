# GitHub Repository Setup – Elysium

## ✅ Local Git Repository: DONE

Your local git repo is initialized with the first commit!

**Files committed:**
- `README.md` – Project overview
- `elysium.md` – Complete task master list (200+ tasks)
- `docs/constitution-draft-v0.md` – First constitution draft
- `docs/NETWORK-STATE-SUMMARY.md` – Balaji's book summary
- `PHASE1-ACTION-PLAN.md` – Week-by-week action plan

---

## 🔐 Step 1: Authenticate GitHub CLI

Run this command in your terminal:

```bash
gh auth login
```

**Follow the prompts:**
1. **GitHub.com** → Select `GitHub.com`
2. **Protocol** → Select `HTTPS`
3. **Login** → Select `Login with a web browser`
4. **Copy the one-time code** shown
5. **Open the URL** in your browser
6. **Paste the code** and authorize
7. **Done!** You'll see "Authentication complete"

---

## 🚀 Step 2: Create GitHub Repository

After authentication, run:

```bash
cd /home/iyeque/.openclaw/workspace/elysium
gh repo create Elysium --public --source=. --push
```

**This will:**
- Create a new public repo called `Elysium` on GitHub
- Set it as the remote for your local repo
- Push your first commit

**Expected output:**
```
✓ Created repository iyeque/Elysium on GitHub
https://github.com/iyeque/Elysium
```

---

## 📁 Step 3: Verify Repository

Visit your new repo:
```
https://github.com/iyeque/Elysium
```

You should see all 5 files from the initial commit.

---

## 🔄 Step 4: Future Workflow

**When you make changes:**

```bash
# 1. Make your changes (edit files, add new ones)
# 2. Stage changes
git add .

# 3. Commit with message
git commit -m "Description of changes"

# 4. Push to GitHub
git push
```

**Example:**
```bash
git add .
git commit -m "Add tokenomics whitepaper v0"
git push
```

---

## 👥 Step 5: Add Collaborators (Optional)

To add contributors:

1. Go to `https://github.com/iyeque/Elysium/settings/access`
2. Click "Add people"
3. Enter their GitHub username
4. Choose permission level (Read, Write, Admin)

---

## 📝 Suggested Next Commits

Here's what to add next:

1. **Tokenomics draft**
   ```bash
   # After creating docs/tokenomics-v0.md
   git add .
   git commit -m "Add tokenomics whitepaper v0"
   git push
   ```

2. **Governance model**
   ```bash
   # After creating docs/governance-model.md
   git add .
   git commit -m "Add governance model specification"
   git push
   ```

3. **Community feedback**
   ```bash
   # After updating constitution based on feedback
   git add .
   git commit -m "Update constitution v1 based on community feedback"
   git push
   ```

---

## 🎯 Repository Structure

Your repo will look like:

```
Elysium/
├── README.md                 # Project overview
├── elysium.md               # Complete task list (200+ tasks)
├── PHASE1-ACTION-PLAN.md    # Week-by-week plan
├── docs/
│   ├── constitution-draft-v0.md
│   ├── NETWORK-STATE-SUMMARY.md
│   ├── tokenomics-v0.md     # TODO
│   ├── governance-model.md  # TODO
│   └── citizenship-guide.md # TODO
├── legal/
│   ├── jurisdiction-research.md  # TODO
│   └── compliance-checklist.md   # TODO
├── tech/
│   ├── blockchain-selection.md   # TODO
│   └── smart-contracts/          # TODO
├── community/
│   ├── content-strategy.md       # TODO
│   └── growth-plan.md            # TODO
└── economy/
    ├── token-design.md           # TODO
    └── treasury-policy.md        # TODO
```

---

## 🔗 Quick Links

- **Your Repo:** https://github.com/iyeque/Elysium
- **GitHub CLI Docs:** https://cli.github.com/manual/
- **GitHub Desktop (optional):** https://desktop.github.com/

---

## ❓ Troubleshooting

### "Not logged in"
```bash
gh auth login
```

### "Repository already exists"
```bash
# If you already created it manually:
git remote add origin https://github.com/iyeque/Elysium.git
git push -u origin main
```

### "Permission denied"
Make sure you authenticated with the correct GitHub account:
```bash
gh auth status
```

---

*Created: 2026-02-26*  
*For: Elysium Project*
