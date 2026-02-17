# Skills v1.1.0 + v1.1.1 Release Notes

**Date:** 2026-02-17  
**Author:** iyeque  
**Total Skills Updated:** 7 skills  
**Successfully Published:** 8 releases (5 @ v1.1.0, 3 @ v1.1.1 security patches)  

---

## Security Vulnerabilities Fixed

### 1. iyeque-device-control (v1.1.0) ✅ PUBLISHED
**Skill ID:** `k9717syd1cwe8vnfrbc14dfh9x81ay9j`

**Vulnerabilities Fixed:**
- ❌ **Command Injection (CRITICAL):** All shell command inputs were unsanitized
  - `openApp()` and `closeApp()` accepted arbitrary strings
  - `setVolume()` and `setBrightness()` didn't validate numeric inputs
- ✅ **Fixed:** Added `sanitizeAppName()` and `sanitizeNumber()` functions
  - Blocks shell metacharacters: `;&|`$(){}[]<>\\!#*?~`
  - Validates numeric ranges (0-100 for volume/brightness)
  - Limits app name length to 256 characters

**New Features:**
- Added `change_volume` action (delta-based volume adjustment)
- Improved WSL support with proper path handling
- Added platform support table to SKILL.md

---

### 2. iyeque-audio-processing (v1.1.0) ✅ PUBLISHED
**Skill ID:** `k9720xh1gjd9ndjwafmbgbcj5n81bba1`

**Vulnerabilities Fixed:**
- ❌ **Path Traversal:** File paths weren't validated
- ✅ **Fixed:** Added `validate_file_path()` function
  - Resolves absolute paths
  - Blocks access to system directories: `/etc/`, `/proc/`, `/sys/`, `/root/`
  - Validates file existence before processing

**Security Improvements:**
- TTS text input limited to 10,000 characters
- Better error handling for missing files
- JSON parsing validation for `--ops` parameter

---

### 3. iyeque-unified-web-search (v1.1.0) ✅ PUBLISHED
**Skill ID:** `k977qshhkarn37thy3pn5z4a3181ae3t`

**Vulnerabilities Fixed:**
- ❌ **Command Injection:** Search queries passed directly to shell commands
- ❌ **Path Traversal:** Local file search could escape workspace
- ✅ **Fixed:** Added `sanitizeQuery()` function
  - Blocks shell metacharacters
  - Limits query length to 500 characters
  - Validates local file paths stay within workspace

**Implementation Improvements:**
- Replaced mock data with real Tavily API integration
- Proper error handling for API failures
- Structured JSON output with source attribution

---

### 4. iyeque-local-system-info (v1.1.0) ✅ PUBLISHED
**Skill ID:** `k977ydfr3p8xjfwreb49wda1qx81as5y`

**Documentation Updates:**
- Added detailed output format examples
- Platform support notes (Linux, macOS, Windows, WSL)
- Metrics explanation section

---

## SKILL.md Documentation Fixes

### 5. iyeque-pdf-reader (v1.1.0) ✅ PUBLISHED
**Skill ID:** `k976rxbhsvpt9zcvw6dvaxx3an81adpm`

**Documentation Fixed:**
- ❌ **Mismatch:** SKILL.md described `pdfminer` and `PyPDF2` libraries
- ✅ **Fixed:** Updated to match actual `PyMuPDF` (pymupdf) implementation
- Removed non-existent `search` and `summarize` functions from docs
- Corrected API to reflect actual `extract` and `metadata` commands

---

### 6. tavily-search (v1.1.0) ⚠️ NOT PUBLISHED
**Reason:** Already owned by another user on ClawHub

**Documentation Created:**
- ❌ **Missing:** Only had README.md (63 bytes)
- ✅ **Created:** Full SKILL.md with:
  - Complete API documentation
  - Environment variable requirements
  - Usage examples for `search` and `extract` commands
  - API limits and pricing info

---

### 7. sonoscli (v1.1.0) ⚠️ NOT PUBLISHED
**Reason:** Already owned by another user on ClawHub

**Documentation Updated:**
- Added version metadata to SKILL.md
- Improved examples and troubleshooting section
- Updated _meta.json to v1.1.0

---

## v1.1.1 Security Patches (Audit Remediation)

Following a security audit, three skills received critical patches:

| Skill | Version | Skill ID | Fix Applied |
|-------|---------|----------|-------------|
| iyeque-device-control | 1.1.1 | `k9783n8qhr9ngphpyn6japqy1n81a3tj` | Removed hardcoded WSL path, strict allowlist for app names |
| iyeque-unified-web-search | 1.1.1 | `k9725281ze3zp6z9dd331fkdk981a851` | Block quotes in queries, strict workspace root |
| iyeque-audio-processing | 1.1.1 | `k972evfkmw94z68fbjsm9yc8xx81ahsm` | Enforce workspace containment for file paths |

## Summary (v1.1.0)

| Skill | Version | Status | Security Fixes | Docs Fixed |
|-------|---------|--------|----------------|------------|
| iyeque-audio-processing | 1.1.0→1.1.1 | ✅ Published | ✅ Path validation + containment | ✅ |
| iyeque-device-control | 1.1.0→1.1.1 | ✅ Published | ✅ Command injection + allowlist | ✅ |
| iyeque-local-system-info | 1.1.0 | ✅ Published | - | ✅ |
| iyeque-unified-web-search | 1.1.0→1.1.1 | ✅ Published | ✅ Query sanitization + workspace | ✅ |
| iyeque-pdf-reader | 1.1.0 | ✅ Published | - | ✅ |
| tavily-search | 1.1.0 | ⚠️ Blocked | - | ✅ |
| sonoscli | 1.1.0 | ⚠️ Blocked | - | ✅ |

---

## Next Steps

1. **For blocked skills** (tavily-search, sonoscli):
   - Contact current owners to transfer ownership OR
   - Create forked versions with different slugs

2. **Testing:**
   - Test all published skills with malicious inputs
   - Verify command injection fixes work correctly
   - Test path traversal prevention

3. **Monitoring:**
   - Watch for any new security vulnerabilities
   - Set up automated security scanning for future updates

---

## Security Best Practices Applied

1. **Input Validation:** All user inputs are now validated before use
2. **Command Sanitization:** Shell metacharacters are blocked
3. **Path Validation:** File paths are resolved and checked for traversal
4. **Length Limits:** Inputs have reasonable maximum lengths
5. **Error Handling:** Graceful failures without leaking sensitive info
