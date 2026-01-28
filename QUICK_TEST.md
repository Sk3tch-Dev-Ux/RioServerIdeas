# DEA vs Cartel - Quick Test (5 Minutes)

## Setup
- 2 Players: Criminal + DEA Officer (grade 2+)
- Start in same location
- Both have money

---

## Criminal Test (2 min)

### 1. Open Menu
```
Press F6
Expected: Menu appears with 5 main options
```

### 2. Try One Operation
```
F6 → Market → Market Prices
Expected: See drug prices and time of day
```

### 3. Check Heat
```
F6 → Survive & Thrive → Check Heat
Expected: Notification shows heat level (probably 0)
```

✓ **CRIMINAL WORKING**

---

## DEA Officer Test (2 min)

### 1. Open Menu
```
Press F6
Expected: DEA Operations menu appears
```

### 2. Access Surveillance
```
F6 → Surveillance Tools → Drug Test Kit
Expected: Dialog appears, can select drug type
```

✓ **DEA WORKING**

---

## Cross-Test (1 min)

### 1. Both Test Progress Bar
```
Criminal: F6 → Market → Launder Money → (pick amount) → Confirm
Expected: 8-second progress bar "Laundering..."

DEA: F6 → Surveillance → Drug Test Kit → Marijuana
Expected: 10-second progress bar "Testing substance..."
```

✓ **OX_LIB INTEGRATION WORKING**

---

## PASS / FAIL

| System | Status |
|--------|--------|
| F6 Menu Opens | ☐ PASS |
| Criminal Menu Works | ☐ PASS |
| DEA Menu Works | ☐ PASS |
| Progress Bars Display | ☐ PASS |
| Notifications Show | ☐ PASS |
| No Errors in Console | ☐ PASS |

**Overall Status:** ☐ READY FOR FULL TEST

---

## If FAIL: Check These

1. **Menu doesn't appear**: 
   - Verify ox_lib installed
   - Check F6 key binding: `RegisterCommand('openmenu'...)`
   - Look for errors in console

2. **Progress bars missing**:
   - Check client/growth.lua has `lib.progressBar()` calls
   - Verify client/sales.lua has updated `OpenBlackMarketSaleDialog()`
   - Confirm all `lib.progressBar()` configs are valid

3. **Notifications don't show**:
   - Verify ox_lib is loaded
   - Check `lib.notify()` is being called with proper table structure

4. **Menu navigation broken**:
   - Clear ox_lib context: Press ESC multiple times
   - Reload resource
   - Try again

---

## Console Must Show:

```
[DEA-Cartel] Growth system client loaded
[DEA-Cartel] DEA client tools loaded
[DEA-Cartel] Dealer vs DEA dynamics client loaded
[DEA-Cartel] Comprehensive interaction system loaded
```

**If missing**: Resource didn't load. Check fxmanifest.lua client_scripts order.

---

**Time: ~5 minutes | Result: GO / NO-GO for full testing**
