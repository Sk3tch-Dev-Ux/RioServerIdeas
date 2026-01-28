Config = {}

-- Production Types: Configure what can be produced
Config.ProductionTypes = {
    marijuana = {
        label = 'Marijuana',
        setupCost = 5000,
        supplies = {
            seeds = { label = 'Cannabis Seeds', cost = 500, perBatch = 5 },
            nutrients = { label = 'Nutrients', cost = 300, perBatch = 2 }
        },
        growTime = 300000, -- 5 minutes (ms) - adjust for testing
        productionTime = 120000, -- 2 minutes
        baseYield = 10, -- base grams per cycle
        qualityMultiplier = 1.0,
        icon = 'fas fa-leaf'
    },
    cocaine = {
        label = 'Cocaine',
        setupCost = 15000,
        supplies = {
            leafPaste = { label = 'Coca Leaf Paste', cost = 2000, perBatch = 3 },
            chemicals = { label = 'Production Chemicals', cost = 1500, perBatch = 2 },
            fuel = { label = 'Fuel', cost = 300, perBatch = 1 }
        },
        growTime = 0, -- No grow phase
        productionTime = 180000, -- 3 minutes
        baseYield = 25, -- base grams per cycle
        qualityMultiplier = 0.85,
        icon = 'fas fa-flask'
    },
    methamphetamine = {
        label = 'Methamphetamine',
        setupCost = 20000,
        supplies = {
            precursor = { label = 'Precursor Chemicals', cost = 2500, perBatch = 3 },
            catalyst = { label = 'Catalyst', cost = 1200, perBatch = 1 },
            solvent = { label = 'Solvent', cost = 400, perBatch = 2 }
        },
        growTime = 0,
        productionTime = 240000, -- 4 minutes
        baseYield = 15, -- base grams per cycle
        qualityMultiplier = 0.75,
        icon = 'fas fa-flask-vial'
    }
}

-- Grow House/Lab Types by faction
Config.OperationTypes = {
    growhouse = {
        label = 'Grow House',
        productionTypes = { 'marijuana' },
        icon = 'fas fa-cannabis',
        raids = true
    },
    lab = {
        label = 'Production Lab',
        productionTypes = { 'cocaine', 'methamphetamine' },
        icon = 'fas fa-flask',
        raids = true
    }
}

-- Operation Zones (for territory expansion in Phase 2)
Config.AvailableZones = {
    { name = 'Downtown Warehouse', coords = vector3(425.5, -979.8, 29.4), blip = true },
    { name = 'Harbor Stash House', coords = vector3(1185.2, -804.3, 57.6), blip = true },
    { name = 'Desert Lab', coords = vector3(1385.4, 3608.2, 34.9), blip = true },
    { name = 'Industrial Site', coords = vector3(2746.2, 1409.3, 24.5), blip = true }
}

-- Quality factors
Config.Quality = {
    minQuality = 0.5,
    maxQuality = 1.5,
    suppliesEffectQuality = true
}

-- Market prices (base value per gram)
Config.MarketPrices = {
    marijuana = 80,
    cocaine = 300,
    methamphetamine = 250
}

-- Dealer Locations (NPC buyers for street sales)
Config.Dealers = {
    {
        name = 'Street Dealer - Downtown',
        coords = vector3(425.5, -979.8, 29.4),
        heading = 0.0,
        model = 'a_m_m_business_1',
        
        -- Tier 1: Marijuana only, any quantity
        tiers = {
            {
                drugType = 'marijuana',
                maxQuantity = 50,
                minPayment = 0.8,  -- 80% of market price
                maxPayment = 0.95
            }
        }
    },
    {
        name = 'Street Dealer - Harbor',
        coords = vector3(1185.2, -804.3, 57.6),
        heading = 90.0,
        model = 'a_m_m_business_1',
        
        -- Tier 2: All drugs, but small quantities
        tiers = {
            {
                drugType = 'marijuana',
                maxQuantity = 100,
                minPayment = 0.85,
                maxPayment = 0.98
            },
            {
                drugType = 'cocaine',
                maxQuantity = 30,
                minPayment = 0.80,
                maxPayment = 0.93
            },
            {
                drugType = 'methamphetamine',
                maxQuantity = 25,
                minPayment = 0.82,
                maxPayment = 0.94
            }
        }
    },
    {
        name = 'Street Dealer - Desert',
        coords = vector3(1385.4, 3608.2, 34.9),
        heading = 180.0,
        model = 'a_m_m_business_2',
        
        -- Tier 1: Marijuana only
        tiers = {
            {
                drugType = 'marijuana',
                maxQuantity = 75,
                minPayment = 0.85,
                maxPayment = 0.96
            }
        }
    }
}

-- Bulk Sale Routes (for large quantities via vehicle transport)
Config.BulkSaleRoutes = {
    {
        id = 'route_downtown_harbor',
        name = 'Downtown to Harbor',
        startCoords = vector3(425.5, -979.8, 29.4),
        endCoords = vector3(1185.2, -804.3, 57.6),
        vehicleType = 'van',  -- van or semi
        reward = 5000,  -- Base reward
        timeout = 600000,  -- 10 minutes
        minQuantity = 500  -- Minimum grams to qualify as bulk
    },
    {
        id = 'route_harbor_desert',
        name = 'Harbor to Desert',
        startCoords = vector3(1185.2, -804.3, 57.6),
        endCoords = vector3(1385.4, 3608.2, 34.9),
        vehicleType = 'semi',
        reward = 8000,
        timeout = 900000,  -- 15 minutes
        minQuantity = 750
    },
    {
        id = 'route_industrial_downtown',
        name = 'Industrial to Downtown',
        startCoords = vector3(2746.2, 1409.3, 24.5),
        endCoords = vector3(425.5, -979.8, 29.4),
        vehicleType = 'van',
        reward = 6000,
        timeout = 720000,  -- 12 minutes
        minQuantity = 600
    }
}

-- Vehicle Models for Bulk Sales
Config.BulkVehicles = {
    van = 'rumpo',      -- Delivery van
    semi = 'pounder'    -- Semi truck
}

-- Bulk Sale Payment Tiers (based on quantity and drug type)
Config.BulkPaymentMultipliers = {
    marijuana = 1.0,
    cocaine = 1.5,
    methamphetamine = 1.4
}

-- Police/DEA Settings (Phase 2)
Config.DEA = {
    arrestedMoneySeizure = 0.75,
    propertySeizureChance = 0.3,
    minArrests = 5
}

-- ========== GROWTH SYSTEM ==========

-- Seed Spawn Locations (random drops, garbage, forests)
Config.SeedSpawns = {
    garbage = {
        chance = 0.15,  -- 15% chance per garbage bin
        amount = { min = 1, max = 3 },
        label = 'Garbage'
    },
    forest = {
        chance = 0.25,  -- 25% chance per forest area
        amount = { min = 2, max = 5 },
        label = 'Forest Floor'
    },
    random = {
        chance = 0.05,  -- 5% chance random drops
        amount = { min = 1, max = 2 },
        label = 'Random Drop'
    }
}

-- Grow house configuration details
Config.GrowSystem = {
    -- Growth stages for marijuana
    marijuana = {
        stages = {
            {
                name = 'seedling',
                duration = 120000,  -- 2 minutes
                model = 'prop_plant_cactus_01',
                scale = 0.4,
                yieldPercentage = 10
            },
            {
                name = 'vegetative',
                duration = 180000,  -- 3 minutes
                model = 'prop_plant_cactus_01',
                scale = 0.7,
                yieldPercentage = 50
            },
            {
                name = 'flowering',
                duration = 240000,  -- 4 minutes
                model = 'prop_plant_cactus_01',
                scale = 1.0,
                yieldPercentage = 100
            }
        },
        maxPlants = 20,
        baseYield = 15  -- grams per plant
    },
    -- Processing stages for cocaine/meth
    cocaine = {
        processTime = 180000,  -- 3 minutes
        maxBatches = 10,
        baseYield = 25,
        riskFactor = 0.7  -- 70% base risk
    },
    methamphetamine = {
        processTime = 240000,  -- 4 minutes
        maxBatches = 8,
        baseYield = 20,
        riskFactor = 0.85  -- 85% base risk
    }
}

-- Grow op Upgrades
Config.Upgrades = {
    lighting = {
        name = 'Advanced Lighting',
        description = 'Improves plant growth speed & quality',
        cost = 8000,
        yieldBonus = 1.3,  -- 30% yield increase
        speedBonus = 0.8,  -- 20% faster growth
        quality = 1.2,  -- 20% quality increase
        icon = 'fas fa-lightbulb'
    },
    hydroponics = {
        name = 'Hydroponic System',
        description = 'Water efficiency & nutrient control',
        cost = 12000,
        yieldBonus = 1.5,  -- 50% yield increase
        speedBonus = 0.7,  -- 30% faster growth
        quality = 1.4,  -- 40% quality increase
        icon = 'fas fa-droplet'
    },
    ventilation = {
        name = 'Climate Control',
        description = 'Optimal temperature & CO2 levels',
        cost = 10000,
        yieldBonus = 1.25,
        speedBonus = 0.75,
        quality = 1.15,
        icon = 'fas fa-fan'
    },
    security = {
        name = 'Security System',
        description = 'Reduces raid detection chance',
        cost = 15000,
        raidDetectionReduction = 0.5,  -- 50% less likely to be detected
        icon = 'fas fa-camera'
    }
}

-- Processing locations (for cocaine/meth labs)
Config.ProcessingLocations = {
    {
        id = 'lab_downtown',
        name = 'Downtown Lab',
        coords = vector3(425.5, -979.8, 29.4),
        type = 'lab',  -- lab or garage
        capacity = 500,  -- grams max processing
        riskBase = 0.6  -- 60% base risk of detection
    },
    {
        id = 'garage_harbor',
        name = 'Harbor Garage',
        coords = vector3(1185.2, -804.3, 57.6),
        type = 'garage',
        capacity = 300,
        riskBase = 0.4  -- 40% base risk (garages safer)
    }
}

-- Risk Factors (detection by police)
Config.RiskFactors = {
    baseRisk = 0.1,  -- 10% chance per minute
    operationMultiplier = 1.5,  -- 50% more risk per active operation
    populationMultiplier = 2.0,  -- Risk increases with nearby players
    upgradeReduction = {  -- How much upgrades reduce risk
        security = 0.5
    },
    raidConsequences = {
        moneySeizure = 0.8,  -- Seize 80% of cash
        plantSeizure = 1.0,  -- Seize all plants
        operationDestroyed = true
    }
}

-- Performance optimization settings
Config.Performance = {
    plantRenderDistance = 100,  -- Only render plants within 100m
    updateInterval = 5000,  -- Update plant states every 5 seconds
    maxActiveOperations = 50,  -- Max operations before optimization kicks in
    plantGeometryLOD = true,  -- Use lower LOD for distant plants
    seedSpawnCooldown = 30000  -- 30 seconds between seed spawn checks
}

-- ========== SALES & LAUNDERING SYSTEM ==========

-- Dynamic Market Pricing (affected by supply/demand)
Config.MarketDynamics = {
    baseFluctuation = 0.2,  -- ±20% price variation
    demandMultiplier = 1.3,  -- High demand increases price by 30%
    oversupplyMultiplier = 0.7,  -- Oversupply decreases price by 30%
    updateInterval = 60000,  -- Recalculate prices every 60 seconds
    priceMemory = {}  -- Stores current market prices
}

-- Black Market Moving Vans (high-risk mobile sales)
Config.BlackMarketVans = {
    {
        id = 'van_route_1',
        name = 'Mobile Supply - Downtown Circle',
        vehicleModel = 'rumpo',
        spawn = vector3(425.5, -979.8, 29.4),
        route = {
            vector3(425.5, -979.8, 29.4),
            vector3(500.0, -1000.0, 30.0),
            vector3(550.0, -950.0, 30.0),
            vector3(475.0, -900.0, 29.0)
        },
        speed = 20.0,  -- mph
        active = false,
        spawnChance = 0.3,  -- 30% chance to spawn
        duration = 600000,  -- 10 minutes active
        riskMultiplier = 2.0  -- 2x surveillance risk
    },
    {
        id = 'van_route_2',
        name = 'Mobile Supply - Harbor Run',
        vehicleModel = 'rumpo',
        spawn = vector3(1185.2, -804.3, 57.6),
        route = {
            vector3(1185.2, -804.3, 57.6),
            vector3(1250.0, -800.0, 60.0),
            vector3(1300.0, -750.0, 60.0),
            vector3(1200.0, -700.0, 58.0)
        },
        speed = 22.0,
        active = false,
        spawnChance = 0.35,
        duration = 720000,  -- 12 minutes
        riskMultiplier = 2.2
    }
}

-- Laundering Businesses (convert dirty cash to clean)
Config.LaunderingBusinesses = {
    {
        id = 'carwash_downtown',
        name = 'Splash Car Wash',
        coords = vector3(425.5, -979.8, 29.4),
        type = 'carwash',
        interiorModel = 'v_carshowroom',
        conversionRate = 0.85,  -- 85% of dirty money becomes clean (15% fee)
        maxTransaction = 50000,  -- Max $50k per transaction
        riskBase = 0.15,  -- 15% base risk per transaction
        capacity = { current = 0, max = 500000 },  -- Can hold $500k dirty money
        icon = 'fas fa-spray-can'
    },
    {
        id = 'nightclub_harbor',
        name = 'Velvet Lounge Club',
        coords = vector3(1185.2, -804.3, 57.6),
        type = 'nightclub',
        interiorModel = 'v_nightclub',
        conversionRate = 0.80,  -- 80% conversion (20% fee)
        maxTransaction = 75000,
        riskBase = 0.20,  -- Clubs have higher risk
        capacity = { current = 0, max = 750000 },
        icon = 'fas fa-champagne-glasses'
    },
    {
        id = 'barbershop_desert',
        name = 'Lucky Cuts Barbershop',
        coords = vector3(1385.4, 3608.2, 34.9),
        type = 'barbershop',
        interiorModel = 'v_barbershop',
        conversionRate = 0.88,  -- 88% conversion (safer)
        maxTransaction = 40000,
        riskBase = 0.10,  -- Lowest risk operation
        capacity = { current = 0, max = 400000 },
        icon = 'fas fa-scissors'
    }
}

-- Surveillance & Detection System
Config.Surveillance = {
    enabled = true,
    baseDetectionChance = 0.05,  -- 5% per minute base
    launderingMultiplier = 1.5,  -- 50% more risk for laundering
    blackMarketMultiplier = 2.5,  -- 2.5x risk for black market sales
    consecutiveLaunderingRisk = 0.02,  -- +2% per transaction in short time
    maxConsecutiveTransactions = 5,  -- After 5 transactions, risk increases
    transactionWindow = 300000,  -- 5 minute window to count consecutive
    detectionConsequences = {
        moneySeizure = 0.5,  -- Seize 50% of money at business
        businessSeizure = false,  -- Don't permanently seize business
        raidChance = 0.7,  -- 70% chance DEA raids operation
        suspicionLevel = 100  -- Increases wanted level
    }
}

-- Wanted Level System (for DEA/Police)
Config.WantedSystem = {
    smugglingDetection = 10,
    launderingDetection = 15,
    blackMarketBusted = 25,
    manufacturingBusted = 50
}

-- NPC Dealer Enhancement (Dynamic Pricing)
Config.DealerPricingFactors = {
    -- Demand affects what dealers will pay
    highDemand = 1.2,  -- Pay 20% more
    normalDemand = 1.0,
    lowDemand = 0.8,  -- Pay 20% less
    
    -- Risk premium
    highRiskArea = 1.15,  -- Pay 15% more for risk
    normalRiskArea = 1.0,
    lowRiskArea = 0.85,
    
    -- Quantity discounts
    bulkDiscount = 1.05,  -- 5% bonus for 50g+
    massDiscount = 1.10  -- 10% bonus for 100g+
}

-- Time-based Pricing Multipliers
Config.TimePricing = {
    -- Drug prices vary by time of day
    morning = { start = 6, endTime = 12, multiplier = 0.9 },   -- 10% cheaper
    afternoon = { start = 12, endTime = 18, multiplier = 1.0 }, -- Normal
    evening = { start = 18, endTime = 23, multiplier = 1.15 },  -- 15% more
    night = { start = 23, endTime = 6, multiplier = 1.25 }      -- 25% more
}

-- Black Market Prices (higher than street dealers but riskier)
Config.BlackMarketPrices = {
    marijuana = 120,   -- vs $80 street price
    cocaine = 450,     -- vs $300 street price
    methamphetamine = 375  -- vs $250 street price
}

-- ========== DEA SYSTEM ==========

-- DEA Job Configuration
Config.DEA = {
    jobName = 'police',  -- Job name for DEA agents
    jobGrade = 5,  -- Minimum grade to access DEA tools (grade 5+)
    requiredLicense = 'dea_badge',  -- Required item to use tools
    
    -- Rank-based permissions
    ranks = {
        trainee = { grade = 0, canArrest = false, canSurveillance = false, canRaid = false },
        officer = { grade = 1, canArrest = true, canSurveillance = false, canRaid = false },
        agent = { grade = 2, canArrest = true, canSurveillance = true, canRaid = false },
        specialist = { grade = 3, canArrest = true, canSurveillance = true, canRaid = false },
        supervisor = { grade = 4, canArrest = true, canSurveillance = true, canRaid = true },
        commander = { grade = 5, canArrest = true, canSurveillance = true, canRaid = true }
    },
    
    -- DEA Payouts
    payouts = {
        arrest = 500,  -- Base per arrest
        seizure = 0.1,  -- 10% of seized money
        raidSuccess = 5000,  -- Bonus for successful raid
        evidence = 100  -- Per drug gram evidence collected
    }
}

-- Surveillance Tools Available to DEA
Config.SurveillanceTools = {
    drone = {
        name = 'DEA Surveillance Drone',
        description = 'Aerial reconnaissance device',
        cost = 0,  -- Free (provided by DEA)
        flightTime = 600000,  -- 10 minutes flight time
        viewDistance = 300,  -- 300m view range
        detectionAccuracy = 0.95,  -- 95% accurate
        icon = 'fas fa-plane',
        charge = { consume = true, rate = 100, duration = 600000 }  -- 100 per 10 min
    },
    gpsTracker = {
        name = 'GPS Vehicle Tracker',
        description = 'Plant on vehicles to track',
        cost = 0,
        duration = 3600000,  -- 1 hour tracking
        accuracy = 50,  -- 50m accuracy (blip updates every 5 seconds)
        detectionChance = 0.3,  -- 30% chance player finds it
        icon = 'fas fa-location-dot',
        maxActive = 5  -- Max 5 trackers per agent
    },
    drugTest = {
        name = 'Mobile Drug Test Kit',
        description = 'Test drugs at location',
        cost = 0,
        testTime = 10000,  -- 10 seconds per test
        accuracy = 0.98,  -- 98% accurate
        icon = 'fas fa-vial',
        maxTests = 20  -- 20 tests before reload
    },
    wiretap = {
        name = 'Wiretap Device',
        description = 'Monitor communications',
        cost = 0,
        installTime = 30000,  -- 30 seconds to install
        duration = 7200000,  -- 2 hours
        interceptChance = 0.7,  -- 70% catch messages
        icon = 'fas fa-phone'
    }
}

-- Heat Level System (per player and per property)
Config.HeatSystem = {
    -- Player heat accumulation
    playerHeat = {
        maxHeat = 100,
        decayRate = 0.5,  -- Decay 0.5 per minute
        decayInterval = 60000,  -- Check every minute
        
        events = {
            launderingDetected = 10,
            blackMarketBusted = 25,
            raidSurvived = 15,
            operationDestroyed = 5,
            drugPossession = 3,
            suspiciousActivity = 2
        }
    },
    
    -- Property heat accumulation
    propertyHeat = {
        maxHeat = 100,
        decayRate = 1.0,  -- Faster decay than player
        decayInterval = 60000,
        
        events = {
            plantDiscovered = 20,
            productionDetected = 15,
            customerVisit = 5,
            suspiciousVehicle = 8
        }
    },
    
    -- Heat thresholds for DEA action
    thresholds = {
        warning = 30,  -- Send warning
        observation = 50,  -- Increase surveillance
        investigation = 70,  -- Active investigation
        raid = 85  -- Ready for raid
    }
}

-- Raid Mechanics Configuration
Config.RaidMechanics = {
    -- Preparation
    requireEvidence = true,  -- Must have evidence before raid
    minHeatForRaid = 85,  -- Minimum heat level
    preparationTime = 300000,  -- 5 minutes prep before raid
    
    -- Raid execution
    entryTypes = {
        forcedEntry = { time = 15000, damage = true, alarm = true },  -- Battering ram
        breachEntry = { time = 10000, damage = true, alarm = true },  -- Explosive entry
        subtleEntry = { time = 20000, damage = false, alarm = false }  -- Lockpicking
    },
    
    -- Consequences
    seizures = {
        cash = 1.0,  -- Seize 100% of cash found
        drugs = 1.0,  -- Seize all drugs
        equipment = 0.9,  -- Seize 90% of equipment
        vehicles = false  -- Don't seize owned vehicles
    },
    
    resistanceModifiers = {
        armed = 2.0,  -- 2x heat for armed resistance
        fleeing = 1.5,  -- 1.5x heat for fleeing
        cooperation = 0.5  -- 0.5x heat for cooperation
    },
    
    -- Raid rewards/penalties
    rewards = {
        raidBonus = 5000,
        perDrugGram = 1,  -- $1 per gram evidence
        propertyBonus = 2500
    }
}

-- DEA Command Center Locations
Config.DEACommandCenters = {
    {
        id = 'dea_hq_downtown',
        name = 'DEA Headquarters - Downtown',
        coords = vector3(425.5, -979.8, 29.4),
        interior = 'v_office',
        locker = vector3(425.5, -980.0, 30.0),
        briefing = vector3(425.5, -978.0, 30.0)
    },
    {
        id = 'dea_station_harbor',
        name = 'DEA Station - Harbor',
        coords = vector3(1185.2, -804.3, 57.6),
        interior = 'v_police_station',
        locker = vector3(1185.2, -804.5, 58.0),
        briefing = vector3(1185.2, -802.5, 58.0)
    }
}

-- Evidence System
Config.Evidence = {
    collectRadius = 5.0,  -- 5m radius to collect
    photoQuality = 0.9,  -- Quality of evidence photos
    seizureReceipt = true,  -- Document all seizures
    chainOfCustody = true  -- Track evidence chain
}

-- Arrest Mechanics
Config.Arrests = {
    restraintItem = 'handcuffs',
    transportTime = 300000,  -- 5 minutes to transport
    bookingTime = 60000,  -- 1 minute at station
    bailAmount = 5000,  -- Base bail amount
    
    charges = {
        possession = { bail = 5000, jail = 60000 },  -- 1 minute
        manufacturing = { bail = 15000, jail = 180000 },  -- 3 minutes
        distribution = { bail = 25000, jail = 300000 },  -- 5 minutes
        moneyLaundering = { bail = 20000, jail = 240000 }  -- 4 minutes
    }
}

-- ========== DEALER vs DEA DYNAMICS ==========

-- Bribery System (Pay off DEA agents to look the other way)
Config.Bribery = {
    enabled = true,
    minimumHeat = 50,  -- Need this heat to bribe
    
    -- Cost scales with agent rank and evidence
    baseCost = 2500,  -- Base bribery cost
    rankMultipliers = {
        1,      -- Officer: 1x
        1.2,    -- Agent: 1.2x
        1.5,    -- Specialist: 1.5x
        2.0,    -- Supervisor: 2x
        3.0     -- Commander: 3x
    },
    evidenceMultiplier = 0.5,  -- +0.5x per evidence item
    
    -- Betrayal mechanics
    betrayalChance = 0.2,  -- 20% agent might betray you
    betrayalPenalty = 25,  -- +25 heat if betrayed
    trustBuilding = 0.05,  -- Decrease betrayal chance 5% per successful bribe
    
    -- Bribed agent duration
    duration = 1800000,  -- 30 minutes of protection
    effects = {
        heatReduction = 0.2,  -- 20% reduced heat gain
        raidImmunity = true,  -- No raids while protected
        alertBypass = 0.3  -- 30% chance to bypass alerts
    }
}

-- Informant System (recruit undercover agents)
Config.Informants = {
    enabled = true,
    maxPerPlayer = 3,
    
    types = {
        street_dealer = {
            label = 'Street Dealer',
            cost = 5000,
            intel = { traffic = 0.8, movements = 0.6 },
            reliability = 0.7
        },
        police_officer = {
            label = 'Police Officer',
            cost = 15000,
            intel = { raids = 0.95, surveillance = 0.8 },
            reliability = 0.9
        },
        launderer = {
            label = 'Money Launderer',
            cost = 8000,
            intel = { laundering = 0.9, financial = 0.7 },
            reliability = 0.6
        }
    },
    
    -- Informant betrayal
    betrayalChance = 0.15,  -- 15% chance to betray
    betrayalReward = 25000,  -- DEA pays informants $25k to betray
    informantProtection = 300000  -- Can't be arrested 5 minutes after betrayal
}

-- Hideouts & Safe Houses
Config.Hideouts = {
    {
        id = 'bunker_downtown',
        name = 'Downtown Bunker',
        coords = vector3(425.5, -979.8, 29.4),
        capacity = 3,  -- Max players
        heatReduction = 0.15,  -- 15% reduced heat in hideout
        detectChance = 0.3,  -- 30% chance DEA finds location
        icon = 'fas fa-fort'
    },
    {
        id = 'penthouse_harbor',
        name = 'Harbor Penthouse',
        coords = vector3(1185.2, -804.3, 57.6),
        capacity = 5,
        heatReduction = 0.10,
        detectChance = 0.25,
        icon = 'fas fa-city'
    },
    {
        id = 'warehouse_industrial',
        name = 'Industrial Warehouse',
        coords = vector3(2746.2, 1409.3, 24.5),
        capacity = 4,
        heatReduction = 0.20,
        detectChance = 0.35,
        icon = 'fas fa-warehouse'
    }
}

-- Defense Systems for Hideouts
Config.DefenseSystems = {
    alarm = {
        name = 'Alarm System',
        description = 'Alerts occupants of raid',
        cost = 5000,
        raidAlertTime = 30000,  -- 30 seconds warning
        icon = 'fas fa-bell'
    },
    jammer = {
        name = 'Signal Jammer',
        description = 'Blocks DEA surveillance 50%',
        cost = 12000,
        surveilanceBlockChance = 0.5,  -- 50% chance to block tracking
        icon = 'fas fa-wifi-slash'
    },
    reinforced = {
        name = 'Reinforced Door',
        description = 'Slows down forced entry',
        cost = 8000,
        entryDelayMultiplier = 1.5,  -- 50% slower entry
        icon = 'fas fa-door-closed'
    },
    safe = {
        name = 'Hidden Safe',
        description = 'Protects 50% of drugs from seizure',
        cost = 10000,
        seizureProtection = 0.5,  -- Save half from raids
        icon = 'fas fa-vault'
    },
    cctv = {
        name = 'CCTV System',
        description = 'Monitor approaching raids',
        cost = 7000,
        raidWarningTime = 60000,  -- 60 seconds warning
        icon = 'fas fa-camera'
    }
}

-- Dynamic DEA Raid Events
Config.DEARaidEvents = {
    enabled = true,
    minHeatForRandom = 60,  -- Minimum heat for random raid
    randomRaidChance = 0.02,  -- 2% chance per minute
    checkInterval = 60000,  -- Check every minute
    
    raidTypes = {
        standard = {
            name = 'Standard Raid',
            agents = 3,
            equipment = { 'pistol', 'armor' },
            duration = 600000,  -- 10 minutes
            weight = 0.5
        },
        swat = {
            name = 'SWAT Team Raid',
            agents = 6,
            equipment = { 'rifle', 'heavy_armor' },
            duration = 480000,  -- 8 minutes
            weight = 0.3,
            aggressive = true
        },
        sting = {
            name = 'Undercover Sting',
            agents = 2,
            equipment = { 'disguise' },
            duration = 1200000,  -- 20 minutes
            weight = 0.2,
            covert = true
        }
    },
    
    -- Raid consequences
    consequences = {
        standard = {
            seizureRate = 0.8,  -- Seize 80% of items
            arrestChance = 0.6,  -- 60% chance to arrest
            propertyDamage = 0.3  -- 30% property damage
        },
        swat = {
            seizureRate = 1.0,  -- Seize everything
            arrestChance = 0.9,  -- 90% chance to arrest
            propertyDamage = 0.7  -- 70% property damage
        }
    }
}

-- Evasion & Escape Mechanics
Config.EvasionMechanics = {
    -- Escape routes to safety
    safeHouses = {
        {
            id = 'safe_forest',
            coords = vector3(385.5, -979.8, 29.4),
            name = 'Forest Hideout',
            heatReduction = 50,  -- Reduces heat by 50
            duration = 300000  -- 5 minute cooldown
        },
        {
            id = 'safe_desert',
            coords = vector3(1385.4, 3608.2, 34.9),
            name = 'Desert Shelter',
            heatReduction = 40,
            duration = 300000
        }
    },
    
    -- Evade mechanics
    evadeCost = 5000,  -- Cost to pay off local cops
    evasionSuccessRate = 0.7,  -- 70% success rate
    failurePenalty = 50,  -- +50 heat on failure
    
    -- Distraction tactics
    distractions = {
        { name = 'Throwable Cash', cost = 2500, duration = 30000 },
        { name = 'Smoke Bomb', cost = 3000, duration = 20000 },
        { name = 'Vehicle Smoke', cost = 2000, duration = 15000 }
    }
}

-- Raid Reward/Punishment System
Config.RaidOutcomes = {
    -- Cartel rewards for successful evasion
    cartelRewards = {
        evadedRaid = {
            money = 10000,
            respect = 50,
            heatReduction = 25
        },
        capturedPrisoner = {
            money = 5000,
            respect = 25
        },
        defendedHideout = {
            money = 7500,
            respect = 35,
            heatReduction = 15
        }
    },
    
    -- DEA rewards for successful raids
    deaRewards = {
        successfulRaid = {
            money = 8000,
            experience = 100
        },
        arrest = {
            money = 2000,
            experience = 25
        },
        evidenceCollected = {
            money = 500,
            experience = 10
        }
    },
    
    -- Punishment for capture
    punishments = {
        captured = {
            heatIncrease = 100,
            propertySeizure = 0.9,
            moneySeizure = 1.0,
            heatBuildupOnSpawn = 200000  -- 200000ms in prison = heat
        }
    }
}

-- ========== BLACK MARKET AUCTIONS ==========

Config.BlackMarketAuctions = {
    enabled = true,
    auctionDuration = 600000,   -- 10 minute auctions
    minBidIncrement = 1000,     -- Minimum bid increase
    refreshInterval = 60000,    -- New auctions every minute
    maxAuctionsActive = 5,      -- Max 5 auctions at once
    
    -- Rare items available in auctions
    rareSeeds = {
        {
            id = 'legendary_sativa',
            name = 'Legendary Sativa',
            description = 'Exotic strain with 2x yield',
            baseValue = 50000,
            yield_multiplier = 2.0,
            growTime_multiplier = 1.2,
            rarity = 'legendary',
            icon = 'fas fa-leaf'
        },
        {
            id = 'golden_hybrid',
            name = 'Golden Hybrid',
            description = '1.5x yield, 20% faster growth',
            baseValue = 30000,
            yield_multiplier = 1.5,
            growTime_multiplier = 0.8,
            rarity = 'epic',
            icon = 'fas fa-leaf'
        },
        {
            id = 'night_bloom',
            name = 'Night Bloom',
            description = '1.3x yield, stealth growth',
            baseValue = 20000,
            yield_multiplier = 1.3,
            growTime_multiplier = 1.0,
            detection_reduction = 0.2,
            rarity = 'rare',
            icon = 'fas fa-leaf'
        },
        {
            id = 'industrial_strain',
            name = 'Industrial Strain',
            description = 'Standard strain, always available',
            baseValue = 5000,
            yield_multiplier = 1.0,
            growTime_multiplier = 1.0,
            rarity = 'common',
            icon = 'fas fa-leaf'
        }
    },
    
    -- Rare equipment
    rareEquipment = {
        {
            id = 'quantum_lamp',
            name = 'Quantum LED',
            description = '+30% yield, 2x brightness efficiency',
            baseValue = 40000,
            yield_bonus = 0.3,
            rarity = 'epic',
            icon = 'fas fa-lightbulb'
        },
        {
            id = 'advanced_system',
            name = 'Advanced Hydro System',
            description = '+20% yield, auto watering',
            baseValue = 25000,
            yield_bonus = 0.2,
            rarity = 'rare',
            icon = 'fas fa-water'
        },
        {
            id = 'detection_jammer',
            name = 'Detection Jammer',
            description = 'Reduce detection chance by 25%',
            baseValue = 35000,
            detection_reduction = 0.25,
            rarity = 'epic',
            icon = 'fas fa-satellite'
        },
        {
            id = 'thermal_cloaker',
            name = 'Thermal Cloaker',
            description = 'Hide heat signature from DEA',
            baseValue = 30000,
            heat_reduction = 0.15,
            rarity = 'epic',
            icon = 'fas fa-thermometer'
        }
    },
    
    -- Auction starting prices (discounted from base value)
    startingPriceMultiplier = 0.6,  -- Start auctions at 60% of value
    
    -- Auction commission (tax for using auction house)
    commissionRate = 0.05  -- 5% of winning bid goes to house
}

-- ========== TURF WARS & GANG TERRITORIES ==========

Config.GangTerritories = {
    enabled = true,
    
    -- Territory claim system
    territories = {
        {
            id = 'downtown_zone',
            name = 'Downtown District',
            coords = vector3(150.0, -900.0, 20.0),
            radius = 300,
            blipSprite = 227,
            blipColor = 0,
            
            -- Bonuses for controlling this territory
            bonuses = {
                dealer_payout_boost = 0.15,     -- +15% dealer payouts
                heat_reduction = 10,            -- -10 heat/minute
                operation_speed = 1.2,          -- 20% faster operations
                detection_reduction = 0.1       -- -10% detection chance
            },
            
            claimCost = 50000,  -- Cost to claim territory
            defenseDuration = 3600000  -- 1 hour control before vulnerable
        },
        {
            id = 'harbor_zone',
            name = 'Harbor District',
            coords = vector3(1100.0, -800.0, 50.0),
            radius = 300,
            blipSprite = 227,
            blipColor = 0,
            
            bonuses = {
                bulk_sale_bonus = 0.2,          -- +20% bulk sale prices
                heat_reduction = 15,
                operation_speed = 1.15,
                detection_reduction = 0.15
            },
            
            claimCost = 60000,
            defenseDuration = 3600000
        },
        {
            id = 'desert_zone',
            name = 'Desert Territory',
            coords = vector3(1300.0, 3600.0, 35.0),
            radius = 400,
            blipSprite = 227,
            blipColor = 0,
            
            bonuses = {
                laundering_reduction = 0.1,    -- -10% laundering fee
                heat_reduction = 20,
                operation_speed = 1.1,
                detection_reduction = 0.2
            },
            
            claimCost = 70000,
            defenseDuration = 3600000
        },
        {
            id = 'industrial_zone',
            name = 'Industrial Complex',
            coords = vector3(2700.0, 1400.0, 25.0),
            radius = 350,
            blipSprite = 227,
            blipColor = 0,
            
            bonuses = {
                production_speed = 1.25,        -- 25% faster cocaine/meth production
                yield_bonus = 0.15,             -- +15% yield
                heat_reduction = 12,
                detection_reduction = 0.12
            },
            
            claimCost = 55000,
            defenseDuration = 3600000
        }
    },
    
    -- Turf war mechanics
    turfWar = {
        enabled = true,
        challengeWindow = 300000,   -- 5 minute challenge period
        preparationTime = 180000,   -- 3 minutes to defend
        
        -- Challenger bonuses
        challengerAdvantage = {
            agentsRequired = 3,     -- Challenger needs 3+ players
            defendersRequired = 2,  -- Defenders need 2+ players
            challengeSuccessPayout = 100000,
            defenseSuccessPayout = 150000
        },
        
        -- Rewards for winning territory
        victoryBonuses = {
            reputation = 150,
            money = 200000,
            heat_reduction = 30  -- 30 second burst of heat reduction
        }
    },
    
    -- Gang affiliation system
    gangs = {
        {
            id = 'cartel',
            name = 'Cartel',
            color = 1,  -- Red
            label = 'Cartel'
        },
        {
            id = 'street_crew',
            name = 'Street Crew',
            color = 2,  -- Blue
            label = 'Street Crew'
        },
        {
            id = 'smugglers',
            name = 'Smugglers',
            color = 3,  -- Green
            label = 'Smugglers'
        },
        {
            id = 'dealers',
            name = 'Dealers Network',
            color = 4,  -- Yellow
            label = 'Dealers Network'
        }
    }
}

-- ========== DASHBOARD & INTEL SYSTEM ==========

Config.Dashboards = {
    enabled = true,
    
    -- Grow ops dashboard
    growOpsUI = {
        enabled = true,
        showPlantStatus = true,
        showUpgradeStatus = true,
        showSecurityStatus = true,
        refreshInterval = 5000,  -- Update every 5 seconds
        
        alerts = {
            plantReady = true,      -- Notify when ready to harvest
            plantDying = true,      -- Notify when plant health low
            securityBreach = true,  -- Notify when DEA detected
            upgradeComplete = true  -- Notify when upgrade ready
        }
    },
    
    -- DEA intel dashboard
    deaUI = {
        enabled = true,
        showHeatLevel = true,
        showRaidProbability = true,
        showAgentLocations = false,  -- Hidden from players for balance
        showRaidHistory = true,
        refreshInterval = 10000,
        
        alerts = {
            heatWarning = 50,       -- Alert when heat > 50
            raidImminent = 80,      -- Alert when heat > 80
            raidInProgress = 100,   -- Alert during raid
        }
    },
    
    -- Auction house UI
    auctionUI = {
        enabled = true,
        showBidHistory = true,
        showItemRarity = true,
        refreshInterval = 3000,
        
        categories = {
            'seeds',
            'equipment',
            'consumables',
            'services'
        }
    },
    
    -- Territory map UI
    territoryUI = {
        enabled = true,
        showOwner = true,
        showControlStatus = true,
        showBonuses = true,
        refreshInterval = 15000,
        
        mapCenter = vector3(500.0, 0.0, 0.0),
        mapRadius = 5000
    }
}

-- ========== PERFORMANCE OPTIMIZATION CONFIG ==========

-- ========== SERVER LAUNCH & DISCORD INTEGRATION ==========

Config.ServerInfo = {
    name = 'DEA vs Cartel',
    version = '1.0.0',
    description = 'Criminal Empire Building RPG',
    website = 'https://your-server.com',  -- Update this
    discord = 'https://discord.gg/your-server',  -- Update this
    
    launchStatus = 'CLOSED_BETA',  -- CLOSED_BETA | OPEN_BETA | LAUNCH | LIVE
    whitelist = true,
    
    -- Server features
    features = {
        drugProduction = true,
        turf_wars = true,
        auctions = true,
        progressionSystem = true,
        deaMechanics = true
    },
    
    -- Current phase
    phase = 'Engagement & Polish',
    estimatedLaunchDate = 'TBA',
    maxPlayers = 32
}

-- ========== DISCORD INTEGRATION ==========

Config.Discord = {
    enabled = true,
    
    -- Webhook URLs (set in your Discord server)
    webhooks = {
        majorEvents = 'https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
        raids = 'https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
        territoryWars = 'https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
        feedback = 'https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
        errors = 'https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN'
    },
    
    -- What to log to Discord
    logging = {
        majorRaids = true,          -- Raids with heat > 80
        territoryConquests = true,  -- Territory changes
        auctionMilestones = true,   -- High-value auctions
        playerMilestones = true,    -- Tier ups, major achievements
        criticalErrors = true,      -- Script errors
        playerFeedback = true       -- In-game feedback submissions
    },
    
    -- Embed colors (Discord color codes)
    colors = {
        raid = 15158332,      -- Red
        conquest = 16776960,  -- Gold
        auction = 3447003,    -- Blue
        achievement = 3066993, -- Green
        error = 15158332,     -- Red
        feedback = 9807270    -- Purple
    }
}

-- ========== SERVER RULES & GUIDELINES ==========

Config.ServerRules = {
    enabled = true,
    
    rules = {
        {
            title = 'No Griefing',
            description = 'Do not intentionally ruin other players\' operations without legitimate IC reason.',
            severity = 'HIGH'
        },
        {
            title = 'Respect DEA Players',
            description = 'DEA is a legitimate opposing faction. Use proper RP when raiding or engaging.',
            severity = 'HIGH'
        },
        {
            title = 'No Metagaming',
            description = 'Do not use out-of-character knowledge in-character. Each operation should be separate.',
            severity = 'MEDIUM'
        },
        {
            title = 'No Pay-to-Win',
            description = 'Auction items are convenience only. Progression requires gameplay.',
            severity = 'HIGH'
        },
        {
            title = 'Report Exploits',
            description = 'If you find a bug or exploit, report it instead of using it.',
            severity = 'HIGH'
        },
        {
            title = 'Respect Whitelist',
            description = 'Only play if whitelisted. Do not help non-whitelisted players.',
            severity = 'MEDIUM'
        },
        {
            title = 'No Spamming',
            description = 'Do not spam /dice, commands, or events to break economy.',
            severity = 'LOW'
        },
        {
            title = 'RP Your Character',
            description = 'Be immersive. No OOC conversations in /local chat.',
            severity = 'MEDIUM'
        }
    },
    
    guidelines = {
        cartel = {
            name = 'Cartel Operations',
            description = 'You are part of a criminal organization focused on drug production and sales.',
            responsibilities = {
                'Maintain operations (grow houses, labs)',
                'Supply product to dealers',
                'Manage gang members and relationships',
                'Control territory and expand influence',
                'Evade DEA detection'
            },
            restrictions = {
                'Cannot give operations locations to DEA',
                'Must invest in territory control',
                'Subject to DEA raids',
                'Dealer payments subject to market conditions'
            }
        },
        dea = {
            name = 'DEA Operations',
            description = 'You are federal agents tasked with dismantling criminal operations.',
            responsibilities = {
                'Investigate and raid operations',
                'Build cases against cartel members',
                'Gather intelligence on gang activities',
                'Control territory to block operations',
                'Manage undercover informants'
            },
            restrictions = {
                'Cannot accept bribes (rule violations)',
                'Must follow legal procedures (RP-based)',
                'Need probable cause for raids',
                'Limited resources (heat system)',
                'Must coordinate with team'
            }
        },
        neutral = {
            name = 'Independent Operations',
            description = 'You operate independently without gang affiliation.',
            responsibilities = {
                'Build your own operations',
                'Manage relationships with dealers',
                'Decide when to join factions',
                'Manage personal reputation'
            },
            restrictions = {
                'Cannot use faction-exclusive benefits',
                'Must establish dealer relationships',
                'Limited to personal operations',
                'Subject to both cartel and DEA interference'
            }
        }
    }
}

-- ========== BETA TESTING MODE ==========

Config.BetaMode = {
    enabled = true,
    
    -- Features in beta (can be toggled)
    betaFeatures = {
        auctions = { active = true, startDate = '2024-01-15', feedback = '' },
        turftWars = { active = true, startDate = '2024-01-15', feedback = '' },
        progressionSystem = { active = true, startDate = '2024-01-08', feedback = '' },
        advancedDEA = { active = true, startDate = '2024-01-08', feedback = '' }
    },
    
    -- Testing utilities
    testing = {
        allowAdminBypass = false,      -- Admin can bypass cooldowns
        fastTimeScale = false,         -- 5x time for testing
        unlimitedMoney = false,        -- Admin infinite money
        noDeathPenalty = false,        -- Don't lose operations on death
        instantProduction = false,     -- Operations complete instantly
        noHeatDecay = false           -- Heat stays constant
    },
    
    -- Data collection
    analytics = {
        trackPlayerActions = true,     -- Track what players do
        trackEconomyEvents = true,     -- Track money flow
        trackCombat = false,           -- Track PvP events
        trackBugs = true              -- Auto-report bugs
    },
    
    -- Feedback submission
    feedback = {
        enabled = true,
        categories = {
            'balance',
            'bugs',
            'features',
            'difficulty',
            'UI/UX',
            'performance',
            'other'
        }
    }
}

-- ========== LAUNCH CHECKLIST ==========

Config.LaunchChecklist = {
    -- Pre-launch tasks
    infrastructure = {
        database_ready = false,
        server_hardware_tested = false,
        backup_system_ready = false,
        monitoring_setup = false,
        security_configured = false
    },
    
    features = {
        production_system = true,
        sales_system = true,
        dea_mechanics = true,
        progression_system = true,
        auction_house = true,
        territory_wars = true,
        dashboards = true
    },
    
    testing = {
        unit_tests_passed = false,
        integration_tests_passed = false,
        performance_tests_passed = false,
        balance_verified = false,
        security_audited = false
    },
    
    documentation = {
        user_guide_ready = true,
        admin_guide_ready = false,
        rules_published = false,
        discord_setup = false,
        announcement_ready = false
    },
    
    community = {
        whitelist_setup = false,
        discord_created = false,
        mods_trained = false,
        support_ready = false,
        launch_date_announced = false
    }
}

-- ========== FEEDBACK SYSTEM ==========

Config.FeedbackSystem = {
    enabled = true,
    
    -- Where feedback is stored
    storage = 'database',  -- 'database' or 'file'
    filePath = 'resources/dea-cartel/feedback/',  -- If using file storage
    
    -- Feedback collection
    collection = {
        allowAnonymous = false,
        requireReason = true,
        maxLength = 500,
        characterLimit = true,
        
        -- Auto-categorization
        keywords = {
            balance = { 'balance', 'op', 'weak', 'OP', 'broken', 'unfair' },
            bugs = { 'bug', 'crash', 'error', 'broken', 'doesn\'t work', 'glitch' },
            features = { 'feature', 'add', 'please add', 'would be cool', 'suggestion' },
            difficulty = { 'hard', 'easy', 'difficult', 'too easy', 'impossible' },
            ui = { 'ui', 'menu', 'interface', 'button', 'hard to use', 'confusing' },
            performance = { 'lag', 'fps', 'slow', 'stuttering', 'freeze' },
            other = {}
        }
    },
    
    -- Moderation
    moderation = {
        requireApproval = false,
        flagSpam = true,
        flagOffensive = true,
        maxSubmissionsPerPlayer = 5,
        cooldownBetweenSubmissions = 300000  -- 5 minutes
    }
}

Config.Performance = {
    -- Script optimization
    scriptOptimization = {
        -- Reduce event frequency for distant players
        distanceOptimization = true,
        maxRenderDistance = 500,  -- Only render UI for players within 500m
        
        -- Batch processing for database operations
        batchSize = 10,
        batchInterval = 1000,
        
        -- Memory cleanup
        cleanupInterval = 300000,  -- Every 5 minutes
        maxMemoryUsage = 50,       -- MB before cleanup
        
        -- Thread management
        maxConcurrentThreads = 20,
        threadCleanupInterval = 60000
    },
    
    -- Network optimization
    networkOptimization = {
        -- Reduce network traffic
        syncInterval = 5000,      -- Sync every 5 seconds
        maxPlayersPerSync = 32,   -- Batch updates
        compressionEnabled = true,
        
        -- Event rate limiting
        rateLimitEvents = true,
        maxEventsPerSecond = 100
    },
    
    -- Prop/entity optimization
    propOptimization = {
        enabled = true,
        
        -- Pool props instead of spawning/despawning
        usePooling = true,
        maxPoolSize = 50,
        
        -- LOD system for props
        lodDistance = {
            high = 100,   -- High detail within 100m
            medium = 300, -- Medium detail 100-300m
            low = 500     -- Low detail 300-500m
        },
        
        -- Cleanup distant props
        autoCleanup = true,
        cleanupDistance = 1000  -- Remove props >1km away
    },
    
    -- DEA optimization
    deaOptimization = {
        -- Reduce agent checks for distant operations
        maxAgentDistance = 1000,
        agentUpdateInterval = 5000,
        
        -- Raid batching
        maxRaidsConcurrent = 2,
        
        -- Heat decay optimization (don't update every frame)
        heatUpdateInterval = 60000  -- Update every minute
    }
}


-- Progression Tiers (Reputation-based unlocks)
Config.ProgressionTiers = {
    -- Tier 1: Street Soldier (0-150 reputation)
    street_soldier = {
        level = 1,
        minReputation = 0,
        maxReputation = 150,
        label = 'Street Soldier',
        description = 'Fresh recruit, limited operations',
        icon = 'fas fa-person',
        
        -- Unlocks
        maxOperations = 2,  -- Can own max 2 operations
        maxUpgrades = 1,    -- Can install 1 upgrade per operation
        maxPlants = 10,     -- Grow house capacity
        maxBribes = 1,      -- Can bribe 1 agent
        maxInformants = 1,  -- Can recruit 1 informant
        canLaunder = false, -- Can't launder money
        
        -- Economy multipliers
        dealerPayoutMultiplier = 0.85,  -- Get 85% market price
        bribeCostMultiplier = 1.2,      -- Bribery costs 120%
        upgradesCostMultiplier = 1.1,   -- Upgrades cost 110%
        heatAccumulation = 1.2,         -- Gain 120% more heat
        
        -- Operation limits
        maxLaunderingAmount = 0,        -- Can't launder
        maxBulkSaleQuantity = 250,      -- Limited bulk sales
        blackMarketDetectionChance = 0.35,  -- 35% more likely to be detected
        
        perks = {
            'basic_dealer_network',
            'street_operation'
        }
    },
    
    -- Tier 2: Lieutenant (150-400 reputation)
    lieutenant = {
        level = 2,
        minReputation = 150,
        maxReputation = 400,
        label = 'Lieutenant',
        description = 'Experienced operator, expanded operations',
        icon = 'fas fa-person-military-pointing',
        
        maxOperations = 4,
        maxUpgrades = 2,
        maxPlants = 20,
        maxBribes = 2,
        maxInformants = 2,
        canLaunder = true,  -- Can start laundering
        
        dealerPayoutMultiplier = 0.92,
        bribeCostMultiplier = 1.0,      -- Normal cost
        upgradesCostMultiplier = 1.0,
        heatAccumulation = 1.0,
        
        maxLaunderingAmount = 25000,    -- Max $25k per transaction
        maxBulkSaleQuantity = 500,
        blackMarketDetectionChance = 0.20,
        
        perks = {
            'basic_dealer_network',
            'street_operation',
            'money_laundering',
            'bribery_discount'
        }
    },
    
    -- Tier 3: Boss (400-750 reputation)
    boss = {
        level = 3,
        minReputation = 400,
        maxReputation = 750,
        label = 'Boss',
        description = 'Cartel leader, full operation control',
        icon = 'fas fa-crown',
        
        maxOperations = 6,
        maxUpgrades = 3,
        maxPlants = 30,
        maxBribes = 4,
        maxInformants = 3,
        canLaunder = true,
        
        dealerPayoutMultiplier = 1.0,   -- Full market price
        bribeCostMultiplier = 0.85,     -- 15% cheaper bribes
        upgradesCostMultiplier = 0.9,   -- 10% discount on upgrades
        heatAccumulation = 0.85,        -- Only gain 85% heat
        
        maxLaunderingAmount = 100000,   -- Max $100k per transaction
        maxBulkSaleQuantity = 1000,
        blackMarketDetectionChance = 0.10,
        
        perks = {
            'basic_dealer_network',
            'street_operation',
            'money_laundering',
            'bribery_discount',
            'heat_reduction_hideout',
            'rare_suppliers'
        }
    },
    
    -- Tier 4: Kingpin (750+ reputation)
    kingpin = {
        level = 4,
        minReputation = 750,
        maxReputation = 1000,
        label = 'Kingpin',
        description = 'Untouchable criminal overlord',
        icon = 'fas fa-chess-king',
        
        maxOperations = 10,
        maxUpgrades = 4,
        maxPlants = 50,
        maxBribes = 6,
        maxInformants = 5,
        canLaunder = true,
        
        dealerPayoutMultiplier = 1.15,  -- Get 15% more than market price
        bribeCostMultiplier = 0.70,     -- 30% cheaper bribes
        upgradesCostMultiplier = 0.75,  -- 25% discount on upgrades
        heatAccumulation = 0.60,        -- Only gain 60% heat
        
        maxLaunderingAmount = 500000,   -- Max $500k per transaction
        maxBulkSaleQuantity = 2500,
        blackMarketDetectionChance = 0.05,
        
        raidImmunityWindow = 30000,     -- 30 seconds after raid to prepare
        raidsPerWeek = 1,               -- Max 1 raid per week
        
        perks = {
            'basic_dealer_network',
            'street_operation',
            'money_laundering',
            'bribery_discount',
            'heat_reduction_hideout',
            'rare_suppliers',
            'raid_immunity_window',
            'elite_informants',
            'underworld_connections'
        }
    }
}

-- Gang Reputation System (Core reputation tracking)
Config.Reputation = {
    maxReputation = 1000,
    minReputation = 0,
    startingReputation = 0,
    
    -- Reputation gain/loss events
    events = {
        -- Criminal activities
        drugSale = 2,                   -- Per gram sold
        launderingSuccess = 5,          -- Per $1k laundered
        bulkSaleSuccess = 25,           -- Per successful route
        
        -- Interactions with DEA
        successfulRaidEvasion = 50,
        informantBetrayalAvenged = 100,
        hideoutDefended = 35,
        agentBribed = 10,
        
        -- Failures
        raidCaptured = -75,
        informantBetrayalDetected = -50,
        operationRaided = -20,
        arrestedByDEA = -100,
        launderingDetected = -30
    },
    
    -- Reputation-based benefits (tier-independent)
    benefits = {
        perReputation = {
            dealerPayoutBonus = 0.001,      -- +0.1% per reputation point
            heatReduction = 0.002,          -- -0.2% heat per reputation point
            briberySuccessBonus = 0.005     -- +0.5% success per reputation point
        }
    }
}

-- ========== ECONOMY BALANCING SYSTEM ==========

Config.EconomyBalance = {
    -- Supply/Demand dynamics
    supplyDemand = {
        enabled = true,
        updateInterval = 300000,    -- Update every 5 minutes
        demandFluctuation = 0.3,    -- ±30% price variation
        
        -- Base multipliers
        normalDemand = 1.0,
        highDemand = 1.3,           -- +30% during high demand
        lowDemand = 0.7,            -- -30% during low demand
        
        -- Track supply vs market
        targetSupplyPerPlayer = 100  -- Per active player
    },
    
    -- Price caps to prevent farming
    priceCaps = {
        marijuana = {
            minPrice = 50,           -- Can't fall below $50/g
            maxPrice = 150,          -- Can't exceed $150/g
            streetDealer = { min = 50, max = 100 },
            blackMarket = { min = 80, max = 150 }
        },
        cocaine = {
            minPrice = 200,
            maxPrice = 500,
            streetDealer = { min = 200, max = 350 },
            blackMarket = { min = 300, max = 500 }
        },
        methamphetamine = {
            minPrice = 150,
            maxPrice = 400,
            streetDealer = { min = 150, max = 300 },
            blackMarket = { min = 250, max = 400 }
        }
    },
    
    -- Laundering economy
    launderingBalance = {
        minimumTransaction = 5000,   -- Min $5k to launder
        maximumByTier = true,        -- Tier determines max
        conversionFeeProgression = {
            -- Fee increases with amount laundered
            { threshold = 10000, fee = 0.15 },  -- 15% fee under $10k
            { threshold = 50000, fee = 0.12 },  -- 12% fee under $50k
            { threshold = 100000, fee = 0.10 }, -- 10% fee under $100k
            { threshold = 500000, fee = 0.08 }  -- 8% fee under $500k
        },
        detectionRisk = {
            perTransaction = 0.05,   -- 5% base risk per transaction
            consecutiveMultiplier = 1.1,  -- 10% more risk each transaction
            maxConsecutive = 5,      -- Reset after 5 minutes
            timeWindow = 300000      -- 5 minute window
        }
    },
    
    -- Bulk sale scaling
    bulkSaleBalance = {
        minQuantity = 100,           -- Min 100g
        maxByTier = true,            -- Tier determines max
        quantityBonus = {
            -- More units = better price per gram
            { threshold = 500, bonus = 1.05 },   -- 5% bonus over 500g
            { threshold = 1000, bonus = 1.10 },  -- 10% bonus over 1000g
            { threshold = 2000, bonus = 1.15 },  -- 15% bonus over 2000g
            { threshold = 5000, bonus = 1.20 }   -- 20% bonus over 5000g
        },
        riskByQuantity = {
            { threshold = 500, risk = 0.15 },   -- 15% detection under 500g
            { threshold = 1000, risk = 0.25 },  -- 25% detection under 1000g
            { threshold = 2000, risk = 0.40 },  -- 40% detection under 2000g
            { threshold = 5000, risk = 0.60 }   -- 60% detection over 5000g
        }
    },
    
    -- Growth operation balance
    growthBalance = {
        yieldScaling = {
            -- Higher tier = better yields
            street_soldier = 0.80,   -- 80% base yield
            lieutenant = 1.0,        -- 100% base yield
            boss = 1.25,             -- 125% base yield
            kingpin = 1.50           -- 150% base yield
        },
        growthTimeScaling = {
            -- Same tiers = faster growth
            street_soldier = 1.2,    -- 20% slower
            lieutenant = 1.0,        -- Normal
            boss = 0.8,              -- 20% faster
            kingpin = 0.6            -- 40% faster
        }
    }
}

-- ========== COOLDOWN & ANTI-GRIND SYSTEM ==========

Config.CooldownSystem = {
    enabled = true,
    
    -- Operation cooldowns
    operationCooldowns = {
        plantSeed = {
            duration = 30000,           -- 30 seconds between plants
            byTier = {
                lieutenant = 20000,     -- Lieutenant: 20 seconds
                boss = 10000,           -- Boss: 10 seconds
                kingpin = 5000          -- Kingpin: 5 seconds
            }
        },
        
        harvestPlant = {
            duration = 60000,           -- 60 seconds between harvests
            byTier = {
                lieutenant = 45000,
                boss = 30000,
                kingpin = 15000
            }
        },
        
        blackMarketSale = {
            duration = 120000,          -- 2 minutes between sales
            byTier = {
                lieutenant = 90000,
                boss = 60000,
                kingpin = 30000
            }
        },
        
        bulkSale = {
            duration = 600000,          -- 10 minutes between bulk sales
            byTier = {
                lieutenant = 480000,    -- 8 minutes
                boss = 300000,          -- 5 minutes
                kingpin = 180000        -- 3 minutes
            }
        },
        
        launderingTransaction = {
            duration = 180000,          -- 3 minutes between transactions
            byTier = {
                lieutenant = 120000,    -- 2 minutes
                boss = 90000,           -- 1.5 minutes
                kingpin = 45000         -- 45 seconds
            }
        },
        
        bribery = {
            duration = 900000,          -- 15 minutes between bribes
            byTier = {
                lieutenant = 720000,
                boss = 600000,
                kingpin = 300000
            }
        },
        
        raiding = {
            duration = 1800000,         -- 30 minutes between raids
            byTier = {
                lieutenant = 1200000,
                boss = 600000,
                kingpin = 300000
            }
        }
    },
    
    -- Diminishing returns (gets harder to grind same activity)
    diminishingReturns = {
        enabled = true,
        trackingWindow = 3600000,   -- Track over 1 hour
        
        -- After N actions in time window, apply penalty
        drugSaleReturns = {
            -- After 5 sales in 1 hour, each sale gives 20% less
            thresholds = {
                { count = 5, multiplier = 0.80 },   -- 80% return
                { count = 10, multiplier = 0.60 },  -- 60% return
                { count = 15, multiplier = 0.40 }   -- 40% return
            }
        },
        
        bulkSaleReturns = {
            thresholds = {
                { count = 3, multiplier = 0.85 },
                { count = 5, multiplier = 0.65 },
                { count = 7, multiplier = 0.40 }
            }
        },
        
        launderingReturns = {
            thresholds = {
                { count = 5, multiplier = 0.75 },
                { count = 10, multiplier = 0.50 },
                { count = 15, multiplier = 0.25 }
            }
        },
        
        plantingReturns = {
            -- Planting too many without harvesting
            thresholds = {
                { count = 20, multiplier = 0.90 },
                { count = 40, multiplier = 0.70 },
                { count = 60, multiplier = 0.40 }
            }
        }
    },
    
    -- Daily/Weekly caps to prevent infinite farming
    activityCaps = {
        -- Max earnings per 24 hours
        maxEarningsPerDay = {
            street_soldier = 500000,    -- $500k max per day
            lieutenant = 1000000,       -- $1m max per day
            boss = 2500000,             -- $2.5m max per day
            kingpin = 5000000           -- $5m max per day
        },
        
        -- Max operations per 24 hours
        maxOperationsPerDay = {
            plantingSeed = {
                street_soldier = 10,
                lieutenant = 20,
                boss = 50,
                kingpin = 100
            },
            drugSales = {
                street_soldier = 5,
                lieutenant = 10,
                boss = 20,
                kingpin = 50
            },
            bulkSales = {
                street_soldier = 1,
                lieutenant = 2,
                boss = 3,
                kingpin = 5
            }
        }
    }
}

-- ========== DEA DIFFICULTY SCALING ==========

Config.DEADifficultyScaling = {
    -- Scale DEA operations based on player progression
    scalingFactors = {
        street_soldier = {
            raidFrequency = 0.5,        -- 50% normal raid frequency
            raidSeverity = 0.5,        -- Use weaker raid types
            agentSkill = 0.6,          -- Lower accuracy, slower
            detectionBonus = -0.3      -- 30% less likely to detect
        },
        
        lieutenant = {
            raidFrequency = 0.8,        -- 80% normal frequency
            raidSeverity = 0.8,
            agentSkill = 0.8,
            detectionBonus = -0.15     -- 15% less likely to detect
        },
        
        boss = {
            raidFrequency = 1.0,        -- Normal frequency
            raidSeverity = 1.0,        -- Normal severity
            agentSkill = 1.0,
            detectionBonus = 0.0       -- Normal detection
        },
        
        kingpin = {
            raidFrequency = 1.5,        -- 50% more raids
            raidSeverity = 1.5,        -- Harder raid types
            agentSkill = 1.3,          -- Higher accuracy, faster
            detectionBonus = 0.3       -- 30% more likely to detect
        }
    },
    
    -- DEA heat system scaling
    heatScaling = {
        street_soldier = {
            gainsMultiplier = 1.3,     -- Gain 30% more heat
            decayMultiplier = 0.8,     -- Decay 20% slower
            raidThreshold = 70         -- Can raid at 70 heat (easier)
        },
        
        lieutenant = {
            gainsMultiplier = 1.0,
            decayMultiplier = 1.0,
            raidThreshold = 85
        },
        
        boss = {
            gainsMultiplier = 0.8,     -- Gain 20% less heat
            decayMultiplier = 1.2,     -- Decay 20% faster
            raidThreshold = 90
        },
        
        kingpin = {
            gainsMultiplier = 0.5,     -- Gain 50% less heat
            decayMultiplier = 1.5,     -- Decay 50% faster
            raidThreshold = 95         -- Hard to get raided
        }
    },
    
    -- DEA budget/resources based on player threat level
    deaBudgetScaling = {
        street_soldier = 0.3,          -- 30% DEA budget
        lieutenant = 0.6,              -- 60% DEA budget
        boss = 1.0,                    -- 100% DEA budget (normal)
        kingpin = 1.5                  -- 150% DEA budget (DEA focuses on them)
    },
    
    -- Specific raid adjustments
    raidAdjustments = {
        street_soldier = {
            minAgents = 1,              -- Min 1 agent
            maxAgents = 2,              -- Max 2 agents
            preparationTime = 120000,   -- 2 min prep
            seizureRate = 0.50          -- Seize 50% of items
        },
        
        lieutenant = {
            minAgents = 2,
            maxAgents = 3,
            preparationTime = 300000,   -- 5 min prep
            seizureRate = 0.70
        },
        
        boss = {
            minAgents = 3,
            maxAgents = 6,
            preparationTime = 600000,   -- 10 min prep
            seizureRate = 0.85
        },
        
        kingpin = {
            minAgents = 4,
            maxAgents = 8,
            preparationTime = 900000,   -- 15 min prep
            seizureRate = 1.0           -- Seize everything
        }
    }
}


-- DEA Task Force Config
Config.DEATaskForce = {
    enabled = true,
    minAgentsForRaid = 2,  -- Min agents needed to initiate raid
    commanderAuthRequired = false,  -- Commander signature required
    
    -- Task force levels
    alertLevels = {
        green = { label = 'Green', raidsPerHour = 0 },
        yellow = { label = 'Yellow', raidsPerHour = 1 },
        orange = { label = 'Orange', raidsPerHour = 2 },
        red = { label = 'Red', raidsPerHour = 4 }
    },
    
    -- Coordinate multi-agent raids
    maxRaidTeamSize = 8,
    raidPreparationTime = 300000,  -- 5 minutes to assemble
    commRadiusKm = 2  -- Can only coordinate within 2km
}
