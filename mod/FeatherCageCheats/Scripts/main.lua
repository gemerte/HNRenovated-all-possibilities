--[[
    FeatherCage Cheats - UE4SS Lua mod
    Game: Hello Neighbor / Project FeatherCage (UE 4.27.2, Shipping)

    Features:
      * Fly / Noclip / Speed
      * Spawn ANY Actor class (item) in any quantity
      * Full class catalog of the running game (+ file dump)
      * Level actor dump (study the game from inside)
      * Teleport, save/load position, god mode, inventory scanner

    Console:  fc help
    Hotkeys:  see fc help
--]]

local UEHelpers = require("UEHelpers")

local MODTAG = "[FeatherCage] "
local ActorClass = StaticFindObject("/Script/Engine.Actor")
local UClassClass = StaticFindObject("/Script/CoreUObject.Class")

local State = {
    fly = false,
    noclip = false,
    god = false,
    speed = 1500.0,
    spawnCount = 1,
    catalog = nil,
    catalogByName = nil,
    itemList = nil,
    itemIndex = 0,
    selected = nil,
    savedLoc = nil,
    savedRot = nil,
    spawned = {},
    autoDumpDone = false,
}

local ConsoleAr = nil

-- ---------------------------------------------------------------------------
-- utils
-- ---------------------------------------------------------------------------

local function log(msg)
    msg = tostring(msg)
    print(MODTAG .. msg .. "\n")
end

local function out(msg)
    msg = tostring(msg)
    print(MODTAG .. msg .. "\n")
    if ConsoleAr then
        pcall(function()
            if ConsoleAr:type() == "FOutputDevice" then
                ConsoleAr:Log(msg)
            end
        end)
    end
end

local function notify(msg, seconds)
    msg = tostring(msg)
    log(msg)
    local ok1, err1 = pcall(function()
        local engine = UEHelpers.GetEngine()
        if engine ~= nil then
            pcall(function() engine.bEnableOnScreenDebugMessages = true end)
            pcall(function() engine.bEnableOnScreenDebugMessagesDisplay = true end)
        end
        local world = UEHelpers.GetWorld()
        if not world or not world:IsValid() then return end
        local ksl = UEHelpers.GetKismetSystemLibrary()
        local color = { R = 0.2, G = 1.0, B = 0.2, A = 1.0 }
        ksl:PrintString(world, msg, true, true, color, seconds or 4.0)
    end)
    if not ok1 then log("notify PrintString error: " .. tostring(err1)) end
    -- fallback: PlayerController client message (works in shipping builds)
    local ok2, err2 = pcall(function()
        local pc = UEHelpers.GetPlayerController()
        if pc and pc:IsValid() then
            pc:ClientMessage(msg, FName("Event"), seconds or 4.0)
        end
    end)
    if not ok2 then log("notify ClientMessage error: " .. tostring(err2)) end
end

local function isValid(obj)
    if obj == nil then return false end
    local ok, res = pcall(function() return obj:IsValid() end)
    return ok and res
end

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        log("ERROR: " .. tostring(res))
        return nil
    end
    return res
end

local function getPC()
    local pc = UEHelpers.GetPlayerController()
    if isValid(pc) then return pc end
    return nil
end

local function getPawn()
    local pc = getPC()
    if not pc then return nil end
    local pawn = safe(function() return pc.Pawn end)
    if isValid(pawn) then return pawn end
    return nil
end

local function getMoveComp(pawn)
    if not pawn then return nil end
    local mv = safe(function() return pawn.CharacterMovement end)
    if isValid(mv) then return mv end
    return nil
end

local function getCamera()
    local pc = getPC()
    if not pc then return nil, nil end
    local cam = safe(function() return pc.PlayerCameraManager end)
    if not isValid(cam) then return nil, nil end
    local loc = safe(function() return cam:GetCameraLocation() end)
    local rot = safe(function() return cam:GetCameraRotation() end)
    return loc, rot
end

local function forwardVector(rot)
    local mathlib = UEHelpers.GetKismetMathLibrary()
    local fwd = safe(function() return mathlib:GetForwardVector(rot) end)
    if fwd then return fwd end
    return { X = 1.0, Y = 0.0, Z = 0.0 }
end

local function vecAdd(a, b, scale)
    scale = scale or 1.0
    return {
        X = a.X + b.X * scale,
        Y = a.Y + b.Y * scale,
        Z = a.Z + b.Z * scale,
    }
end

local function vecStr(v)
    if not v then return "nil" end
    return string.format("(%.1f, %.1f, %.1f)", v.X or 0, v.Y or 0, v.Z or 0)
end

-- ---------------------------------------------------------------------------
-- movement
-- ---------------------------------------------------------------------------

local function applyFly(pawn)
    local mv = getMoveComp(pawn)
    if not mv then return false, "pawn has no CharacterMovement" end
    pcall(function() mv.MaxFlySpeed = State.speed end)
    pcall(function() mv.MovementMode = 5 end) -- MOVE_Flying
    pcall(function() mv.bCheatFlying = true end)
    pcall(function() mv.BrakingDecelerationFlying = 4000.0 end)
    pcall(function() mv.Velocity = { X = 0.0, Y = 0.0, Z = 0.0 } end)
    local mode = safe(function() return mv.MovementMode end)
    log("applyFly: MovementMode=" .. tostring(mode))
    if mode ~= 5 then
        return false, "could not set MovementMode (got " .. tostring(mode) .. ")"
    end
    return true
end

local function restoreWalk(pawn)
    local mv = getMoveComp(pawn)
    if not mv then return false end
    pcall(function() mv.MovementMode = 1 end) -- MOVE_Walking
    pcall(function() mv.bCheatFlying = false end)
    return true
end

local function setFly(on)
    local pawn = getPawn()
    if not pawn then notify("No pawn (load into a level)") return end
    if on then
        local ok, err = applyFly(pawn)
        if not ok then notify("Fly: " .. tostring(err)) return end
        State.fly = true
        notify("Fly: ON (speed " .. math.floor(State.speed) .. ")")
    else
        if State.noclip then
            State.noclip = false
            pcall(function() pawn:SetActorEnableCollision(true) end)
        end
        restoreWalk(pawn)
        State.fly = false
        notify("Fly: OFF")
    end
end

local function setNoclip(on)
    local pawn = getPawn()
    if not pawn then notify("No pawn (load into a level)") return end
    if on then
        local ok, err = applyFly(pawn)
        if not ok then notify("Noclip: " .. tostring(err)) return end
        pcall(function() pawn:SetActorEnableCollision(false) end)
        State.noclip = true
        State.fly = true
        notify("Noclip: ON (collision off)")
    else
        pcall(function() pawn:SetActorEnableCollision(true) end)
        State.noclip = false
        restoreWalk(pawn)
        State.fly = false
        notify("Noclip: OFF")
    end
end

local function setSpeed(value)
    State.speed = value
    local pawn = getPawn()
    local mv = getMoveComp(pawn)
    if mv then
        pcall(function() mv.MaxFlySpeed = value end)
        pcall(function() mv.MaxWalkSpeed = value end)
    end
    notify("Speed: " .. math.floor(value))
end

local function teleport(loc, rot)
    local pawn = getPawn()
    if not pawn then notify("No pawn") return end
    local ok = safe(function()
        return pawn:K2_SetActorLocation(loc, false, {}, true)
    end)
    if ok == nil then
        safe(function() pawn.RootComponent.RelativeLocation = loc end)
    end
    if rot and isValid(pawn.Controller) then
        safe(function() pawn.Controller:SetControlRotation(rot) end)
    end
    notify("Teleported to " .. vecStr(loc))
end

local function teleportForward(distance)
    local loc, rot = getCamera()
    if not loc then notify("No camera") return end
    teleport(vecAdd(loc, forwardVector(rot), distance or 300.0), rot)
end

-- ---------------------------------------------------------------------------
-- class catalog / spawning
-- ---------------------------------------------------------------------------

local function isSkippableClassName(name)
    if not name or name == "" then return true end
    if name:sub(1, 5) == "SKEL_" then return true end
    if name:sub(1, 6) == "REINST" then return true end
    if name:sub(1, 9) == "Default__" then return true end
    if name:sub(1, 6) == "TRASH_" then return true end
    if name:sub(1, 2) == "SK_" then return true end
    return false
end

local function isActorClass(cls)
    local ok, res = pcall(function() return cls:IsChildOf(ActorClass) end)
    return ok and res
end

local function buildCatalog()
    local result, byName = {}, {}
    local classes = safe(function()
        return FindObjects(0, UClassClass, nil, nil, 0, false)
    end) or {}

    for _, cls in pairs(classes) do
        local name = safe(function() return cls:GetFName():ToString() end)
        if name and not isSkippableClassName(name) and isActorClass(cls) then
            local full = safe(function() return cls:GetFullName() end) or name
            local entry = { name = name, full = full, cls = cls }
            result[#result + 1] = entry
            local key = name:lower()
            byName[key] = byName[key] or entry
            byName[key:gsub("_c$", "")] = byName[key:gsub("_c$", "")] or entry
        end
    end

    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    State.catalog = result
    State.catalogByName = byName
    return result
end

local function ensureCatalog(force)
    if force or not State.catalog then buildCatalog() end
    return State.catalog
end

-- direct scan of all UClass objects (works even if catalog is stale)
local function findClassDirect(key)
    local classes = safe(function()
        return FindObjects(0, UClassClass, nil, nil, 0, false)
    end) or {}
    local keyShort = key:gsub("_c$", "")
    local fallback = nil
    for _, cls in pairs(classes) do
        local name = safe(function() return cls:GetFName():ToString() end)
        if name then
            local n = name:lower()
            local ns = n:gsub("_c$", "")
            if (n == key or ns == keyShort) and isActorClass(cls) then
                return cls
            end
            if not fallback and (n:find(key, 1, true) or ns:find(keyShort, 1, true)) and isActorClass(cls) then
                fallback = cls
            end
        end
    end
    return fallback
end

local function findClass(query)
    if not query or query == "" then return nil, "empty class name" end

    -- full object path, e.g. /Game/Logic/Item/BP_Item_Key.BP_Item_Key_C
    if query:find("/") then
        local cls = StaticFindObject(query)
        if isValid(cls) then return cls end
        cls = StaticFindObject(query .. "_C")
        if isValid(cls) then return cls end
    end

    local key = query:lower()

    -- direct scan first: always current, no stale catalog
    local direct = findClassDirect(key)
    if isValid(direct) then return direct end

    ensureCatalog(false)
    local entry = State.catalogByName[key] or State.catalogByName[key:gsub("_c$", "")]
    if entry then return entry.cls end

    local matches = {}
    for _, e in ipairs(State.catalog) do
        if e.name:lower():find(key, 1, true) then
            matches[#matches + 1] = e
            if #matches > 25 then break end
        end
    end
    if #matches == 1 then return matches[1].cls end
    if #matches == 0 then return nil, "class not found: " .. query end

    local names = {}
    for i = 1, math.min(#matches, 10) do names[#names + 1] = matches[i].name end
    return nil, "ambiguous (" .. #matches .. "): " .. table.concat(names, ", ")
end

local function spawnActor(cls, loc, rot)
    local world = UEHelpers.GetWorld()
    if not isValid(world) then return nil, "world not found" end

    local actor = safe(function() return world:SpawnActor(cls, loc, rot, {}) end)
    if isValid(actor) then return actor end

    local gs = UEHelpers.GetGameplayStatics()
    local transform = {
        Translation = loc,
        Rotation = rot,
        Scale3D = { X = 1.0, Y = 1.0, Z = 1.0 },
    }
    local deferred = safe(function()
        return gs:BeginDeferredActorSpawnFromClass(world, cls, transform, 0, nil)
    end)
    if isValid(deferred) then
        safe(function() gs:FinishSpawningActor(deferred, transform) end)
        return deferred
    end

    return nil, "SpawnActor returned nil"
end

local function spawnItem(query, count, distance, spread)
    count = math.max(1, math.floor(tonumber(count) or State.spawnCount or 1))
    if count > 500 then
        notify("Count capped to 500 (requested " .. count .. ")")
        count = 500
    end
    distance = tonumber(distance) or 160.0
    spread = tonumber(spread) or 70.0

    local cls, err = findClass(query)
    if not cls then notify("Spawn: " .. tostring(err)) return end

    local loc, rot = getCamera()
    if not loc then notify("Spawn: no camera/player") return end
    local fwd = forwardVector(rot)
    local base = vecAdd(loc, fwd, distance)

    local spawned = 0
    for i = 0, count - 1 do
        local col = i % 5
        local row = math.floor(i / 5)
        local p = {
            X = base.X + (col - 2) * spread,
            Y = base.Y + row * spread,
            Z = base.Z + 10.0,
        }
        local actor = spawnActor(cls, p, rot)
        if isValid(actor) then
            spawned = spawned + 1
            State.spawned[#State.spawned + 1] = actor
        end
    end

    State.selected = cls
    if spawned > 0 then
        notify(string.format("Spawn: %s x%d", cls:GetFName():ToString(), spawned))
    else
        notify("Spawn failed: " .. tostring(cls:GetFullName()))
    end
end

local function clearSpawned()
    local n = 0
    for _, a in ipairs(State.spawned) do
        if isValid(a) then
            pcall(function() a:K2_DestroyActor() end)
            n = n + 1
        end
    end
    State.spawned = {}
    notify("Destroyed spawned actors: " .. n)
end

-- ---------------------------------------------------------------------------
-- study helpers
-- ---------------------------------------------------------------------------

local function writeTextFile(path, text)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(text)
    f:close()
    return true
end

local function dumpCatalog()
    local cat = ensureCatalog(true)
    local lines = { "# FeatherCage actor classes: " .. #cat, "# name\tfullpath" }
    for _, e in ipairs(cat) do
        lines[#lines + 1] = e.name .. "\t" .. e.full
    end
    local text = table.concat(lines, "\n") .. "\n"
    local a = writeTextFile("ue4ss/Mods/FeatherCageCheats/actor_classes.txt", text)
    local b = writeTextFile("actor_classes.txt", text)
    out(string.format("Catalog: %d actor classes. Files: %s / %s", #cat, tostring(a), tostring(b)))
end

local ITEM_BASE_PATHS = { "/Script/HNRenovated.ItemHN", "/Script/ItemLogic.Item" }

local function collectItems()
    local cat = ensureCatalog(false)
    local bases = {}
    for _, path in ipairs(ITEM_BASE_PATHS) do
        local c = StaticFindObject(path)
        if isValid(c) then bases[#bases + 1] = c end
    end

    local found = {}
    -- preferred: real pickups inherit from the game's item base classes
    if #bases > 0 then
        for _, e in ipairs(cat) do
            for _, base in ipairs(bases) do
                local ok, isItem = pcall(function() return e.cls:IsChildOf(base) end)
                if ok and isItem then
                    found[#found + 1] = e
                    break
                end
            end
        end
    end

    -- fallback: blueprint items by name/path
    if #found < 5 then
        found = {}
        for _, e in ipairs(cat) do
            local n = e.name:lower()
            local f = e.full:lower()
            if n:sub(1, 7) == "bp_item" or f:find("/logic/item/", 1, true) then
                found[#found + 1] = e
            end
        end
    end

    State.itemList = found
    return found
end

local function dumpItems(filter)
    local found = collectItems()
    filter = (filter or ""):lower()
    local lines = {}
    local shown = 0
    for i, e in ipairs(found) do
        if filter == "" or e.name:lower():find(filter, 1, true) then
            shown = shown + 1
            local line = string.format("%3d  %-45s %s", i, e.name, e.full)
            lines[#lines + 1] = line
            if shown <= 80 then out(line) end
        end
    end
    local text = table.concat(lines, "\n") .. "\n"
    writeTextFile("ue4ss/Mods/FeatherCageCheats/item_candidates.txt", text)
    writeTextFile("item_candidates.txt", text)
    out(string.format("Item candidates: %d (shown %d). Use: fc item <index> [count]", #found, shown))
    if shown > 80 then out("... full list in item_candidates.txt") end
end

local function listKeys(filter)
    filter = (filter or ""):lower()
    local names = {}
    pcall(function()
        for k in pairs(Key) do
            local n = tostring(k)
            if filter == "" or n:lower():find(filter, 1, true) then
                names[#names + 1] = n
            end
        end
    end)
    table.sort(names)
    out("Keys (" .. #names .. "): " .. table.concat(names, ", "))
end

local function listClasses(filter)
    local cat = ensureCatalog(false)
    filter = (filter or ""):lower()
    local n = 0
    for _, e in ipairs(cat) do
        if filter == "" or e.name:lower():find(filter, 1, true) then
            n = n + 1
            out(string.format("%-45s %s", e.name, e.full))
            if n >= 120 then out("... (too many, narrow the filter)") break end
        end
    end
    out(string.format("Found (shown): %d of %d", n, #cat))
end

local function dumpWorld(filter)
    local actors = safe(function()
        return FindObjects(0, ActorClass, nil, nil, 0, true)
    end) or {}
    filter = (filter or ""):lower()
    local lines = { "# world actors" }
    local n = 0
    for _, a in pairs(actors) do
        local cls = safe(function() return a:GetClass():GetFName():ToString() end) or "?"
        local full = safe(function() return a:GetFullName() end) or "?"
        if filter == "" or full:lower():find(filter, 1, true) or cls:lower():find(filter, 1, true) then
            n = n + 1
            lines[#lines + 1] = cls .. "\t" .. full
            if n <= 100 then out(string.format("%-40s %s", cls, full)) end
        end
    end
    local text = table.concat(lines, "\n") .. "\n"
    writeTextFile("ue4ss/Mods/FeatherCageCheats/world_actors.txt", text)
    writeTextFile("world_actors.txt", text)
    out(string.format("World actors: %d -> world_actors.txt", n))
end

-- UStruct:ForEachFunction/ForEachProperty only iterate members declared on that
-- struct, so walk the SuperStruct chain to see inherited ones too.
local function eachFunction(cls, cb)
    local c = cls
    for _ = 1, 24 do
        if not isValid(c) then break end
        local ok = pcall(function() c:ForEachFunction(cb) end)
        if not ok then break end
        c = safe(function() return c:GetSuperStruct() end)
    end
end

local function eachProperty(cls, cb)
    local c = cls
    for _ = 1, 24 do
        if not isValid(c) then break end
        local ok = pcall(function() c:ForEachProperty(cb) end)
        if not ok then break end
        c = safe(function() return c:GetSuperStruct() end)
    end
end

local function describeObjectFunctions(obj, filter)
    if not isValid(obj) then return end
    filter = (filter or ""):lower()
    local cls = safe(function() return obj:GetClass() end)
    if not isValid(cls) then return end
    local seen = {}
    eachFunction(cls, function(fn)
        local name = safe(function() return fn:GetFName():ToString() end) or ""
        local key = name:lower()
        if not seen[key] and (filter == "" or key:find(filter, 1, true)) then
            seen[key] = true
            out("  fn " .. name)
        end
    end)
end

local function studyClass(query)
    local cls, err = findClass(query)
    if not cls then notify(tostring(err)) return end
    out("=== " .. cls:GetFullName() .. " ===")
    local sup = safe(function() return cls:GetSuperStruct() end)
    if isValid(sup) then out("SuperStruct: " .. sup:GetFullName()) end
    out("--- properties ---")
    local seen = {}
    eachProperty(cls, function(prop)
        local name = safe(function() return prop:GetFName():ToString() end) or "?"
        local pcls = safe(function() return prop:GetClass():GetFName():ToString() end) or "?"
        if not seen[name] then
            seen[name] = true
            out(string.format("  %-40s %s", name, pcls))
        end
    end)
    out("--- functions ---")
    describeObjectFunctions(cls, "")
end

local function scanInventory()
    local pawn = getPawn()
    if not pawn then notify("No pawn") return end
    out("=== Pawn properties/objects that look like inventory ===")
    local cls = safe(function() return pawn:GetClass() end)
    if isValid(cls) then
        local seen = {}
        eachProperty(cls, function(prop)
            local name = safe(function() return prop:GetFName():ToString() end) or ""
            local key = name:lower()
            if not seen[key] and (key:find("invent", 1, true) or key:find("item", 1, true)
                or key:find("storage", 1, true) or key:find("carry", 1, true)
                or key:find("held", 1, true) or key:find("hand", 1, true)) then
                seen[key] = true
                local val = safe(function() return pawn[name] end)
                out(string.format("  prop %s = %s", name, isValid(val) and val:GetFullName() or tostring(val)))
                if isValid(val) then describeObjectFunctions(val, "") end
            end
        end)
    end
    out("=== Pawn functions (add/give/item/pickup/hand) ===")
    describeObjectFunctions(pawn, "add")
    describeObjectFunctions(pawn, "give")
    describeObjectFunctions(pawn, "item")
    describeObjectFunctions(pawn, "pickup")
    describeObjectFunctions(pawn, "hand")
end

-- destroy every actor of a class in the current level
local function killClass(query)
    local cls, err = findClass(query)
    if not cls then notify("Kill: " .. tostring(err)) return end
    local actors = safe(function()
        return FindObjects(0, ActorClass, nil, nil, 0, false)
    end) or {}
    local n = 0
    for _, a in pairs(actors) do
        if isValid(a) then
            local ac = safe(function() return a:GetClass() end)
            local isInst = ac and safe(function() return ac:IsChildOf(cls) end)
            if isInst then
                pcall(function() a:K2_DestroyActor() end)
                n = n + 1
            end
        end
    end
    notify(string.format("Killed %d x %s", n, cls:GetFName():ToString()))
end

-- ---------------------------------------------------------------------------
-- CheatManager (the game ships with one; useful for study)
-- ---------------------------------------------------------------------------

local function getCheatManager()
    local pc = getPC()
    if not pc then return nil end
    local cm = safe(function() return pc.CheatManager end)
    if isValid(cm) then return cm end
end

local function cheatExec(name)
    local cm = getCheatManager()
    if not cm then return false, "no CheatManager" end
    local ok, err = pcall(function() cm[name](cm) end)
    if not ok then return false, tostring(err) end
    return true
end

local function listCheats()
    local cm = getCheatManager()
    if not cm then notify("No CheatManager") return end
    out("=== CheatManager: " .. cm:GetFullName() .. " ===")
    describeObjectFunctions(cm, "")
end

-- ---------------------------------------------------------------------------
-- console
-- ---------------------------------------------------------------------------

local function help()
    out("FeatherCage Cheats - console commands (open console: ~ or F10)")
    out("  fc fly                     toggle fly")
    out("  fc noclip                  toggle noclip (fly + no collision)")
    out("  fc speed <n>               fly/run speed (default 1500)")
    out("  fc tp <x> <y> <z>          teleport to coordinates")
    out("  fc tpf [dist]              teleport forward along camera")
    out("  fc spawn <class> [n] [dist] [spread]  spawn n items")
    out("  fc give <class> [n]        alias of spawn (inventory later)")
    out("  fc item <index> [count] [go]  pick/spawn from 'fc items' list")
    out("  fc next / fc prev          cycle through item list")
    out("  fc sel <class>             select class for F3/F11")
    out("  fc count <n>               quantity used by F3/F11")
    out("  fc items [filter]          item candidates + file")
    out("  fc list [filter]           all actor classes (spawnable)")
    out("  fc keys [filter]           available key names for keybinds")
    out("  fc actors [filter]         dump actors in the level")
    out("  fc dump                    dump class catalog to file")
    out("  fc study <class>           class properties + functions")
    out("  fc inv                     scan pawn inventory objects/functions")
    out("  fc kill <class>            destroy all actors of a class")
    out("  fc cheats                  list CheatManager functions (game internals)")
    out("  fc cheat <fn>              execute a CheatManager function")
    out("  fc save / fc load          save/load position")
    out("  fc god                     toggle god mode")
    out("  fc clear                   destroy actors spawned by this mod")
    out("  fc status                  current state")
    out("Hotkeys: F1 fly, F2 noclip, F3 spawn selected, F4 teleport forward,")
    out("         F5 save, F6 load, F7 dump, F8 items, F9 inv, F11 spawn selected,")
    out("         F12 next item, Ctrl+F12 prev item,")
    out("         PageUp/PageDown count +-1 (Ctrl = +-10), Ctrl+F3 count presets,")
    out("         Ctrl+F11 clear spawned")
    out("File queue: put commands (one per line) into")
    out("         ue4ss\\Mods\\FeatherCageCheats\\commands.txt")
end

local function godMode()
    local pawn = getPawn()
    if not pawn then notify("No pawn") return end
    State.god = not State.god
    pcall(function() pawn.bCanBeDamaged = not State.god end)
    notify("Godmode: " .. (State.god and "ON" or "OFF"))
end

local function status()
    local pawn = getPawn()
    local loc = pawn and safe(function() return pawn:K2_GetActorLocation() end)
    local mv = getMoveComp(pawn)
    local mode = mv and safe(function() return mv.MovementMode end)
    local coll = pawn and safe(function() return pawn:GetActorEnableCollision() end)
    local vel = pawn and safe(function() return pawn:GetVelocity() end)
    out(string.format("fly=%s noclip=%s speed=%d god=%s count=%d",
        tostring(State.fly), tostring(State.noclip), math.floor(State.speed),
        tostring(State.god), State.spawnCount))
    out(string.format("pawn=%s loc=%s", pawn and pawn:GetFullName() or "nil", vecStr(loc)))
    out(string.format("movementMode=%s collision=%s velocity=%s catalog=%s",
        tostring(mode), tostring(coll), vecStr(vel),
        State.catalog and tostring(#State.catalog) or "nil"))
end

-- ---------------------------------------------------------------------------
-- item picker helpers
-- ---------------------------------------------------------------------------

local function ensureItemList()
    if not State.itemList or #State.itemList == 0 then collectItems() end
    if not State.itemList or #State.itemList == 0 then return nil end
    return State.itemList
end

local function selectItemByIndex(idx)
    local list = ensureItemList()
    if not list then notify("Item list empty") return end
    idx = math.floor(tonumber(idx) or 1)
    if idx < 1 then idx = #list end
    if idx > #list then idx = 1 end
    State.itemIndex = idx
    local e = list[idx]
    State.selected = e.cls
    notify(string.format("Item %d/%d: %s  count=%d", idx, #list, e.name, State.spawnCount))
end

local function cycleItem(delta)
    local list = ensureItemList()
    if not list then notify("Item list empty") return end
    local idx
    if State.itemIndex == 0 then
        idx = (delta >= 0) and 1 or #list
    else
        idx = State.itemIndex + delta
    end
    selectItemByIndex(idx)
end

local COUNT_STEPS = { 1, 5, 10, 25, 50, 100, 250, 500 }
local function cycleCountSteps()
    local cur = State.spawnCount
    local nextVal = COUNT_STEPS[1]
    for _, v in ipairs(COUNT_STEPS) do
        nextVal = v
        if v > cur then break end
    end
    State.spawnCount = nextVal
    notify("Spawn count: " .. State.spawnCount)
end

-- ---------------------------------------------------------------------------
-- command dispatch (shared by the game console and the file queue)
-- ---------------------------------------------------------------------------

local function runCommand(args)
    local sub = (args[1] or "help"):lower()

    if sub == "help" then help()
    elseif sub == "fly" then setFly(not State.fly)
    elseif sub == "noclip" then setNoclip(not State.noclip)
    elseif sub == "speed" then setSpeed(tonumber(args[2]) or 1500)
    elseif sub == "tp" then
        local x, y, z = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
        if x and y and z then teleport({ X = x, Y = y, Z = z }) else out("fc tp <x> <y> <z>") end
    elseif sub == "tpf" then teleportForward(tonumber(args[2]) or 300)
    elseif sub == "spawn" or sub == "give" then
        if args[2] then spawnItem(args[2], args[3], args[4], args[5]) else out("fc spawn <class> [n]") end
    elseif sub == "item" then
        local idx = tonumber(args[2])
        if idx then
            selectItemByIndex(idx)
            if args[3] then State.spawnCount = math.max(1, math.floor(tonumber(args[3]) or 1)) end
            if args[4] == "go" then
                local list = ensureItemList()
                if list then spawnItem(list[State.itemIndex].name, State.spawnCount) end
            end
        else
            out("fc item <index> [count] [go]  (index from 'fc items')")
        end
    elseif sub == "next" then cycleItem(1)
    elseif sub == "prev" then cycleItem(-1)
    elseif sub == "sel" then
        local cls, err = findClass(args[2] or "")
        if cls then State.selected = cls; out("Selected: " .. cls:GetFullName())
        else out(tostring(err)) end
    elseif sub == "count" then
        State.spawnCount = math.max(1, math.min(500, math.floor(tonumber(args[2]) or 1)))
        out("Spawn count: " .. State.spawnCount)
    elseif sub == "items" then dumpItems(args[2])
    elseif sub == "list" then listClasses(args[2])
    elseif sub == "keys" then listKeys(args[2])
    elseif sub == "actors" then dumpWorld(args[2])
    elseif sub == "dump" then dumpCatalog()
    elseif sub == "study" then studyClass(args[2] or "")
    elseif sub == "inv" then scanInventory()
    elseif sub == "kill" then
        if args[2] then killClass(args[2]) else out("fc kill <class>") end
    elseif sub == "save" then
        local pawn = getPawn()
        if pawn then
            State.savedLoc = safe(function() return pawn:K2_GetActorLocation() end)
            local _, rot = getCamera()
            State.savedRot = rot
            notify("Position saved: " .. vecStr(State.savedLoc))
        end
    elseif sub == "load" then
        if State.savedLoc then teleport(State.savedLoc, State.savedRot) else notify("No saved position") end
    elseif sub == "god" then godMode()
    elseif sub == "clear" then clearSpawned()
    elseif sub == "cheats" then listCheats()
    elseif sub == "cheat" then
        if args[2] then
            local ok, err = cheatExec(args[2])
            out(ok and ("CheatManager." .. args[2] .. " executed") or ("Cheat error: " .. tostring(err)))
        else
            out("fc cheat <FunctionName>   (see fc cheats)")
        end
    elseif sub == "status" then status()
    elseif sub == "test" then notify("Test notification OK")
    else out("Unknown subcommand: " .. sub .. " (fc help)") end
end

RegisterConsoleCommandHandler("fc", function(FullCommand, Parameters, Ar)
    ConsoleAr = Ar
    local args = {}
    for i = 1, #Parameters do args[i] = Parameters[i] end
    runCommand(args)
    return true
end)

-- File-based command queue. Write one command per line into
--   ue4ss\Mods\FeatherCageCheats\commands.txt
-- and it is executed in game within ~1 second, then the file is deleted.
-- This is a reliable fallback for when the in-game console is unavailable.
local CMD_FILE = "ue4ss/Mods/FeatherCageCheats/commands.txt"

local function processCommandFile()
    local f = io.open(CMD_FILE, "r")
    if not f then return end
    local text = f:read("*a")
    f:close()
    if not text or text == "" then return end
    os.remove(CMD_FILE)
    for rawLine in text:gmatch("[^\r\n]+") do
        local line = rawLine:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            if line:sub(1, 3):lower() == "fc " then line = line:sub(4) end
            local args = {}
            for token in line:gmatch("%S+") do args[#args + 1] = token end
            out("> " .. line)
            local ok, err = pcall(runCommand, args)
            if not ok then out("command error: " .. tostring(err)) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- keybinds
-- ---------------------------------------------------------------------------

local function bind(key, fn)
    local ok, err = pcall(function() RegisterKeyBind(key, fn) end)
    if not ok then log("bind failed: " .. tostring(err)) end
end

local function bindMod(key, mods, fn)
    local ok, err = pcall(function() RegisterKeyBind(key, mods, fn) end)
    if not ok then log("mod bind failed: " .. tostring(err)) end
end

-- hotkeys must not auto-repeat while held
local lastHotSpawn = 0
local function spawnHotkey(query, count)
    local now = os.clock()
    if now - lastHotSpawn < 0.4 then return end
    lastHotSpawn = now
    if query then
        spawnItem(query, count)
    elseif State.selected then
        spawnItem(State.selected:GetFName():ToString(), State.spawnCount)
    else
        cycleItem(0)
        notify("Pick an item with F12 / Ctrl+F12, then F3 or F11 to spawn")
    end
end

local function cycleCount(delta)
    State.spawnCount = math.max(1, math.min(500, State.spawnCount + delta))
    notify("Spawn count: " .. State.spawnCount)
end

bind(Key.F1, function() setFly(not State.fly) end)
bind(Key.F2, function() setNoclip(not State.noclip) end)
bind(Key.F3, function()
    if State.selected then
        spawnHotkey(State.selected:GetFName():ToString(), State.spawnCount)
    else
        notify("Select an item first: fc sel <class> or fc items")
    end
end)
bind(Key.F4, function() teleportForward(300) end)
bind(Key.F5, function()
    local pawn = getPawn()
    if pawn then
        State.savedLoc = safe(function() return pawn:K2_GetActorLocation() end)
        local _, rot = getCamera()
        State.savedRot = rot
        notify("Position saved")
    end
end)
bind(Key.F6, function()
    if State.savedLoc then teleport(State.savedLoc, State.savedRot) else notify("No saved position") end
end)
bind(Key.F7, function() dumpCatalog() end)
bind(Key.F8, function() dumpItems() end)
bind(Key.F9, function() scanInventory() end)
bind(Key.F11, function() spawnHotkey(nil, nil) end)
bind(Key.F12, function() cycleItem(1) end)
bindMod(Key.F12, { ModifierKey.CONTROL }, function() cycleItem(-1) end)
bindMod(Key.F11, { ModifierKey.CONTROL }, function() clearSpawned() end)
bindMod(Key.F3, { ModifierKey.CONTROL }, function() cycleCountSteps() end)
bind(Key.PAGE_UP, function() cycleCount(1) end)
bind(Key.PAGE_DOWN, function() cycleCount(-1) end)
bindMod(Key.PAGE_UP, { ModifierKey.CONTROL }, function() cycleCount(10) end)
bindMod(Key.PAGE_DOWN, { ModifierKey.CONTROL }, function() cycleCount(-10) end)

-- ---------------------------------------------------------------------------
-- startup
-- ---------------------------------------------------------------------------

log("mod loaded")

local function tryAutoDump(force)
    if State.autoDumpDone then return end
    local pawn = getPawn()
    if not pawn and not force then return end
    State.autoDumpDone = true
    local ok, err = pcall(function()
        local cat = ensureCatalog(true)
        log(string.format("auto: catalog built, actor classes: %d", #cat))
        dumpCatalog()
        dumpItems()
    end)
    if not ok then log("auto dump error: " .. tostring(err)) end
end

local function schedule(fn, ms)
    if type(ExecuteInGameThreadWithDelay) == "function" then
        local ok = pcall(function() ExecuteInGameThreadWithDelay(ms, fn) end)
        if ok then return true end
    end
    return false
end

if not schedule(function() tryAutoDump(false) end, 8000) then
    -- fallback: no delayed API, dump immediately
    tryAutoDump(true)
end
schedule(function() tryAutoDump(false) end, 20000)
schedule(function() tryAutoDump(true) end, 45000)

-- rebuild catalog every time a new level is loaded
pcall(function()
    RegisterLoadMapPostHook(function()
        State.catalog = nil
        State.itemList = nil
        State.autoDumpDone = false
        log("level loaded: catalog invalidated")
        schedule(function() tryAutoDump(false) end, 4000)
        schedule(function() tryAutoDump(true) end, 12000)
    end)
end)

-- start the file command queue (poll every second)
pcall(function()
    if type(LoopInGameThreadWithDelay) == "function" then
        LoopInGameThreadWithDelay(1000, function()
            local ok, err = pcall(processCommandFile)
            if not ok then log("cmd file error: " .. tostring(err)) end
        end)
        log("command file queue started")
    elseif type(LoopAsync) == "function" then
        LoopAsync(1000, function()
            local ok, err = pcall(processCommandFile)
            if not ok then log("cmd file error: " .. tostring(err)) end
            return false
        end)
        log("command file queue started (LoopAsync)")
    end
end)
