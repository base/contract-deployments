# Welcome to the New Signers Tool! 🎉

Welcome everyone to our streamlined signing process. This guide will walk you through the 4 simple steps to safely sign transactions using our validation UI.

## Quick Start Guide for Signers

### Prerequisites
- ✅ Ledger device connected and unlocked
- ✅ Ethereum app open on Ledger (should display "Application is ready")
- ✅ Modern web browser (Chrome, Firefox, Safari, Edge)

---

```bash
make validation
```

This command will reinstall all dependencies and automatically open a UI in your browser at **http://localhost:1234/** (default port).

> 💡 **Note:** If the tool doesn't automatically open, manually navigate to `http://localhost:1234/` in your browser.

### Custom Port (Optional)
If port 1234 is already in use, you can specify a different port:

```bash
PORT=3000 make validation  # Uses port 3000
PORT=8080 make validation  # Uses port 8080
```

Then navigate to the corresponding URL (e.g., `http://localhost:3000/`)

## Step 3: Follow the Validation UI

The validation tool will guide you through a secure, step-by-step process:

### 3.1 Initial Setup
1. **Confirm your role and address** - Verify your signer identity
2. **Choose the upgrade network** - Select the appropriate network (typically Mainnet)
3. **Select the upgrades** - Choose the specific transactions to validate

### 3.2 Simulation Method
4. **Choose simulation method** - Select **"State-diff"** (recommended for validation)

### 3.3 State Validation
5. **Review state-overrides and state-changes** 
   - Compare the **Expected** vs **Actual** columns carefully
   - ⚠️ **Critical:** There should be NO differences between expected and actual states
   - 📝 If you see any differences, check the explanation section below each comparison
   - ❌ **Stop immediately** if there are unexplained differences and contact the facilitator

### 3.4 Transaction Signing
6. **Click "Start Signing"** once all validations pass
7. **Verify domain/message hash** 
   - ⚠️ **Security Critical:** Ensure the hash displayed in the app **exactly matches** what appears on your Ledger screen
   - Double-check character by character
8. **Sign on your Ledger** when hashes are confirmed to match

## Step 4: Submit Your Signature

After successful signing:

1. **Copy the generated signature** from the UI
2. **Send the signature to facilitators** along with your signer address
3. **You're done!** 🎉

---

## 🔒 Security Reminders

- ⚠️ **Always verify** domain/message hashes match between the UI and your Ledger
- 🛑 **Never sign** if there are unexplained state differences  
- ✅ **Double-check** your signer address is correct
- 📞 **Contact facilitators** immediately if anything seems wrong
- 🔒 **Remember:** Nothing happens onchain until all required signatures are collected

---

## ❓ Troubleshooting

**UI doesn't load?**
- Check that `make validation` completed successfully
- Try refreshing your browser or manually visiting the correct URL (default: `http://localhost:1234/`)
- If you see a "port already in use" error, try a different port: `PORT=3000 make validation` and navigate to `http://localhost:3000/`

**Ledger not responding?**
- Ensure Ledger is unlocked and Ethereum app is open
- Try disconnecting and reconnecting your Ledger
- Check USB cable connection

**Hash mismatch?**
- **STOP** the signing process immediately
- Contact facilitators before proceeding
- Do not sign until the issue is resolved

---


*Need help? Contact the facilitator team immediately. Safety first! 🛡️*