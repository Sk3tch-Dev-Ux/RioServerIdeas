# DEA vs Cartel Game Mode - End-to-End Testing Flow

## Prerequisites
- FiveM server running
- QBCore framework installed
- ox_lib and ox_target installed
- Test players: 1 Criminal, 1 DEA Officer (police job grade 2+)

---

## PHASE 1: SERVER STARTUP & INITIALIZATION

### Test 1.1: Resource Load
```
Expected: Console shows:
[DEA-Cartel] Growth system client loaded
[DEA-Cartel] DEA client tools loaded
[DEA-Cartel] Dealer vs DEA dynamics client loaded
[DEA-Cartel] Comprehensive interaction system loaded
[DEA-Cartel] Growth system initialized
[DEA-Cartel] DEA mechanics initialized
[DEA-Cartel] Dealer vs DEA dynamics initialized
```
**Status: PASS / FAIL**

### Test 1.2: Config Verification
- ClientOperations table initializes
- ClientPlants table initializes
- Config.ProductionTypes loads (marijuana, cocaine, methamphetamine)
- Config.Hideouts loads with 3 safe houses

**Status: PASS / FAIL**

---

## PHASE 2: CRIMINAL OPERATIONS FLOW

### Test 2.1: Open Criminal Menu (F6 Key)
**Criminal Player:**
1. Press F6
2. Expected: Main menu appears with options:
   - My Operations
   - Nearby Operations
   - Market
   - Safe Houses
   - Survive & Thrive

**Status: PASS / FAIL**

### Test 2.2: View Operations
**Criminal Player:**
1. Press F6 → "My Operations"
2. Expected: "You don't own any operations" message
3. Go to nearby operation and press F6 → "Nearby Operations"
4. Expected: List of available operations with distance

**Status: PASS / FAIL**

### Test 2.3: Plant Seeds (Growth Operation)
**Criminal Player (with operation):**
1. F6 → "My Operations" → Select grow house
2. Select "Plant Seeds"
3. Expected: Progress bar appears (5 seconds) labeled "Planting seed..."
4. Expected: Notification "Seed Planted - Marijuana seed planted successfully"
5. Check ClientPlants table updates with new plant

**Event Flow:**
- Client: `dea-cartel:server:plantSeed` triggered
- Server: Validates ownership, creates plant object
- Server: Broadcasts `dea-cartel:client:syncPlants` to all clients
- Client: Renders plant in 3D

**Status: PASS / FAIL**

### Test 2.4: Harvest Plants
**Criminal Player (with ready plants):**
1. F6 → "My Operations" → Select grow house → "Harvest Plants"
2. Expected: Menu shows ready plants
3. Select plant
4. Expected: Progress bar (8 seconds) "Harvesting plant..."
5. Expected: Notification "Plant Harvested - Successfully harvested marijuana"
6. Verify inventory receives harvestYield grams

**Status: PASS / FAIL**

### Test 2.5: Buy Grow Upgrades
**Criminal Player (in grow house):**
1. F6 → "My Operations" → Select grow house → "Manage Upgrades"
2. Select "Advanced Lighting" ($8000)
3. Expected: Progress bar (10 seconds) "Installing upgrade..."
4. Expected: Notification "Upgrade Installed - Advanced Lighting installed successfully"
5. Verify player money reduced by $8000

**Status: PASS / FAIL**

---

## PHASE 3: MARKET OPERATIONS

### Test 3.1: Access Market Menu
**Criminal Player:**
1. F6 → "Market"
2. Expected: Menu shows:
   - Street Dealers
   - Black Market Van
   - Bulk Delivery
   - Launder Money
   - Market Prices

**Status: PASS / FAIL**

### Test 3.2: Check Market Prices
**Criminal Player:**
1. F6 → "Market" → "Market Prices"
2. Expected: Current prices for marijuana, cocaine, methamphetamine
3. Prices show both Street and Black Market rates
4. Time of day displays

**Status: PASS / FAIL**

### Test 3.3: Black Market Sale
**Criminal Player (with drugs, near van):**
1. Find black market van (or trigger spawn)
2. Approach and interact
3. Select drug type and amount
4. Expected: Progress bar (6 seconds) "Completing transaction..."
5. Expected: Notification "Transaction Complete - 50g sold to black market van"
6. Verify inventory changes

**Event Flow:**
- Client: `dea-cartel:server:sellToBlackMarket` triggered
- Server: Validates item, calculates payout with variance
- Server: Removes item from inventory, adds money
- Client: Confirmation notification

**Status: PASS / FAIL**

### Test 3.4: Money Laundering
**Criminal Player (with dirty cash, at laundering business):**
1. F6 → "Market" → "Launder Money" → Select business
2. Approach business and interact
3. Enter amount ($10,000)
4. Confirm warning dialog
5. Expected: Progress bar (8 seconds) "Laundering $10,000..."
6. Expected: Notification "Money Laundered - $10,000 converted to clean cash"
7. Verify: Money removed from cash, re-added as clean (with conversion loss)

**Status: PASS / FAIL**

---

## PHASE 4: CRIMINAL SURVIVAL MECHANICS

### Test 4.1: Heat System
**Criminal Player:**
1. Do suspicious activities (sales, production, etc.)
2. Open Survival Menu (F6 → "Survive & Thrive" → "Check Heat")
3. Expected: Notification shows heat level (0-100)
4. Perform raids/sales, verify heat increases
5. Hide in safe house, verify heat reduces

**Heat Triggers:**
- Black market sale: +15 heat
- Laundering detected: +10 heat
- Raid survived: -25 heat

**Status: PASS / FAIL**

### Test 4.2: Bribe DEA Agent
**Criminal Player (heat > 50, near DEA agent):**
1. F6 → "Survive & Thrive" → "Bribe Agent"
2. Find nearby agents (within 50m)
3. Select agent
4. Confirm bribery dialog
5. Expected: Progress bar (3 seconds) "Making offer..."
6. Expected: Notification "Offer Made - Agent may accept or report you to DEA"
7. Server rolls for betrayal (20% chance)
8. If success: Agent protected, "Agent working in your favor for 30 minutes"
9. If betrayal: Heat increases +25, "BETRAYED: Agent reported you to DEA!"

**Status: PASS / FAIL**

### Test 4.3: Recruit Informant
**Criminal Player (with cash):**
1. F6 → "Survive & Thrive" → "Raid Response" → "Recruit Informant"
2. Select informant type (Street Dealer, Police Officer, etc.)
3. Confirm cost dialog
4. Expected: Progress bar (5 seconds) "Recruiting informant..."
5. Expected: Notification "Informant Recruited - Type now provides intel"
6. Verify money deducted

**Status: PASS / FAIL**

### Test 4.4: Enter Safe House
**Criminal Player:**
1. F6 → "Safe Houses" → Select hideout
2. Interact with hideout
3. Select "Enter Hideout"
4. Expected: Notification "Entered hideout: [Name]"
5. Verify: Heat reduction applies (15-20% in hideout)
6. Select "Exit Hideout"
7. Expected: Notification "Left hideout"

**Status: PASS / FAIL**

### Test 4.5: Install Hideout Defenses
**Criminal Player (in hideout):**
1. F6 → "Safe Houses" → Select hideout → "Install Defenses"
2. Select defense (Alarm, Jammer, Reinforced Door, etc.)
3. Confirm cost dialog
4. Expected: Progress bar (12 seconds) "Installing defense system..."
5. Expected: Notification "Defense Installed - [Name] installed successfully"
6. Verify money deducted

**Status: PASS / FAIL**

### Test 4.6: Raid Evasion
**Criminal Player (during raid warning):**
1. Trigger raid (increase heat or admin command)
2. Receive warning: "RAID WARNING: incoming raid! Take cover or evade!"
3. F6 → "Survive & Thrive" → "Raid Response"
4. Select "Evade Raid"
5. Expected: Progress bar (8 seconds) "Attempting to evade..."
6. Expected: Server rolls for success (70% success rate)
7. If success: Heat reduced -25, notification "Raid evaded! Heat reduced."
8. If fail: Heat increased +50, notification "Evasion failed! Heat increased."

**Status: PASS / FAIL**

---

## PHASE 5: DEA OPERATIONS

### Test 5.1: Open DEA Menu
**DEA Officer (grade 2+):**
1. Press F6 OR approach DEA command center
2. Expected: DEA Operations menu appears with:
   - Operations Dashboard
   - Surveillance Tools (grade 2+)
   - Raid Operations (grade 4+)
   - Make Arrest (grade 1+)

**Status: PASS / FAIL**

### Test 5.2: Surveillance - Drug Test
**DEA Officer (grade 2+):**
1. F6 → "Surveillance Tools" → "Drug Test Kit"
2. Select drug type
3. Expected: Progress bar (10 seconds) "Testing substance..."
4. Expected: Notification "Test Results - Substance identified as [drug]"

**Event Flow:**
- Client: `dea-cartel:server:testDrug` triggered
- Server: Validates DEA permission
- Client: Shows progress bar with ox_lib
- Client: Displays test results

**Status: PASS / FAIL**

### Test 5.3: Surveillance - Deploy Drone
**DEA Officer (grade 2+):**
1. F6 → "Surveillance Tools" → "Deploy Drone"
2. Enter target player ID
3. Expected: Notification "Drone Active - Flight time: 10 minutes"
4. Expected: Monitor shows drone active for duration
5. After duration: Notification "Flight time expired"

**Event Flow:**
- Client: `dea-cartel:server:startDroneSurveillance` triggered
- Server: Creates drone surveillance record
- Server: Broadcasts `dea-cartel:client:startDroneSurveillance` to operator
- Client: Countdown thread monitors flight time

**Status: PASS / FAIL**

### Test 5.4: Raid Initiation
**DEA Officer (grade 4+):**
1. Increase target criminal's heat to 85+
2. F6 → "Raid Operations" → "Initiate Raid"
3. Enter target player ID
4. Expected: Progress bar (15 seconds) "Raid in progress..."
5. Expected: Alert dialog "Raid Initiated - Raid on Player [ID] in progress"
6. Expected: Criminal receives warning "RAID IN PROGRESS"
7. Criminal gets radar blip at raid location

**Event Flow:**
- Client: `dea-cartel:server:initiateRaid` triggered
- Server: Validates minimum heat (85+), validates DEA permission
- Server: Creates raid record in DEAOperations
- Server: Broadcasts raid alert to all clients: `dea-cartel:client:radarRaidAlert`
- Criminal receives alert with blip

**Status: PASS / FAIL**

### Test 5.5: Make Arrest
**DEA Officer (grade 1+):**
1. Approach criminal player or use ID input
2. F6 → "Make Arrest"
3. Select charge (Possession, Manufacturing, Distribution, Money Laundering)
4. Enter target player ID
5. Expected: Progress bar (5 seconds) "Processing arrest..."
6. Expected: Alert dialog with charge details and bail amount
7. Expected: Criminal receives notification "ARRESTED - You have been arrested for [charge]"
8. Criminal sees jail screen fade
9. Verify DEA officer receives payment

**Event Flow:**
- Client: `dea-cartel:server:arrestPlayer` triggered
- Server: Validates arrest permission
- Server: Creates arrest record
- Server: Removes cash from criminal (seizure)
- Server: Broadcasts `dea-cartel:client:arrested` to criminal
- Criminal: Screen fades for jail time duration
- DEA: Receives arrest bonus ($500)

**Status: PASS / FAIL**

---

## PHASE 6: PRODUCTION OPERATIONS

### Test 6.1: Start Bulk Sale
**Criminal Player (with 500g+ drugs):**
1. F6 → "Market" → "Bulk Delivery"
2. Select route (Downtown to Harbor, etc.)
3. Expected: Vehicle spawns with player inside
4. Expected: GPS waypoint to destination
5. Drive to destination
6. Expected: Notification "Delivery Zone Reached - Park vehicle to complete"
7. Park at destination
8. Expected: Progress bar (5 seconds) "Completing delivery..."
9. Expected: Notification "Delivery Complete - Bulk sale completed successfully"
10. Verify: Vehicle deleted, money added to player

**Event Flow:**
- Client: `dea-cartel:client:startBulkSale` triggered from server
- Client: SpawnBulkSaleVehicle spawns rumpo/pounder model
- Client: Monitor thread checks distance to destination
- Client: `dea-cartel:server:completeBulkSale` triggered at destination
- Server: Validates location, calculates payout, removes items
- Client: Displays completion notification

**Status: PASS / FAIL**

---

## PHASE 7: INTEGRATION TESTS

### Test 7.1: Complete Criminal Journey
**Criminal Player:**
1. Plant seed in grow house (5s progress)
2. Wait for growth (simulated via timestamps)
3. Harvest plant (8s progress)
4. Sell to black market (6s progress)
5. Launder money (8s progress)
6. Bribe DEA agent (3s progress) 
7. Check heat level (should show progress from activities)
8. Enter safe house (heat reduces)
9. Exit safe house

**Expected: All progress bars, notifications, and state changes work smoothly**

**Status: PASS / FAIL**

### Test 7.2: Complete DEA Journey
**DEA Officer:**
1. Test drug substance (10s progress)
2. Deploy drone on suspect (activates, monitors)
3. Initiate raid (15s progress)
4. Make arrest (5s progress)
5. Verify criminal receives consequences
6. Verify officer receives payouts

**Expected: All raid mechanics function, criminal experiences full consequences**

**Status: PASS / FAIL**

### Test 7.3: Conflict Scenario
**Two Players:**
1. Criminal does suspicious activity (increases heat)
2. DEA officer monitors heat levels
3. Criminal heat hits 85+, DEA initiates raid
4. Criminal attempts evasion (8s progress)
5. Raid either succeeds (seizure) or fails (criminal escapes)
6. Aftermath: Heat/money changes verified

**Expected: Full raid loop works, consequences apply correctly**

**Status: PASS / FAIL**

---

## PHASE 8: STRESS TESTING

### Test 8.1: Multiple Operations
1. Spawn 5+ criminals
2. All doing different operations simultaneously
3. All using progress bars at same time
4. All triggering server events

**Expected: No lag, all progress bars work independently, server handles load**

**Status: PASS / FAIL**

### Test 8.2: Heat System Under Load
1. Multiple criminals accumulating heat from different sources
2. DEA tracking multiple targets
3. Multiple raids triggering simultaneously
4. Bribery/informant events happening concurrently

**Expected: Heat decay, raid triggers, and evasion mechanics work reliably**

**Status: PASS / FAIL**

---

## PHASE 9: CLIENT VALIDATION

### Test 9.1: Progress Bar Cancellation
1. Start any operation (plant, harvest, arrest, raid)
2. Press ESC or move during progress bar
3. Verify: Progress cancels properly (only cancel=true operations)
4. Verify: No double-processing of events

**Expected: Cancellable operations cancel, non-cancellable operations can't be interrupted**

**Status: PASS / FAIL**

### Test 9.2: Menu Navigation
1. Open F6 menu
2. Navigate through all submenus
3. Test back navigation
4. Switch between menus quickly
5. Verify: No menu overlap, proper context switching

**Expected: All menus navigate cleanly, no graphical glitches**

**Status: PASS / FAIL**

---

## ISSUE LOG

| Phase | Test | Status | Issue | Severity | Fix Applied |
|-------|------|--------|-------|----------|------------|
| | | | | | |
| | | | | | |

---

## SIGN-OFF

- All phases tested: ☐
- Critical issues resolved: ☐
- Ready for production: ☐

**Tester:** _______________
**Date:** _______________
**Notes:** _______________
