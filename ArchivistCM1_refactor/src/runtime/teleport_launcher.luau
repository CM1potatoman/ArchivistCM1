
-- Return a launcher with explicit access to its embedded source and handoff.
return function(__ARCH_SOURCE, __ARCH_HANDOFF, __ARCH_CORE)
-- Reloads the embedded script on the current server and arms the next teleport.
local services = game:GetService("Players")
local http = game:GetService("HttpService")
if not game:IsLoaded() then game.Loaded:Wait() end
while not services.LocalPlayer do task.wait(0.1) end
local player = services.LocalPlayer
local sharedEnv = type(getgenv) == "function" and getgenv() or _G
local serverKey = tostring(game.PlaceId) .. ":" .. tostring(game.JobId)
local previous = sharedEnv.__ArchivistTPContext
if type(previous) == "table" then
    if previous.running and previous.serverKey == serverKey then
        warn("[Archivist TP] Already loaded on this server; skipping duplicate execution")
        return
    end
    if previous.connection then
        pcall(function() previous.connection:Disconnect() end)
    end
end
local handoff = {running = true, serverKey = serverKey}
sharedEnv.__ArchivistTPContext = handoff
if type(__ARCH_HANDOFF) == "string" and #__ARCH_HANDOFF > 0 then
    local ok, decoded = pcall(http.JSONDecode, http, __ARCH_HANDOFF)
    if ok and type(decoded) == "table" then
        handoff.pending = decoded
    else
        warn("[Archivist TP] Invalid session handoff; trying saved YSL profile")
    end
end
local compiled, compileError = loadstring(__ARCH_SOURCE)
if not compiled then
    handoff.running = false
    error("[Archivist TP] Archivist compilation failed: " .. tostring(compileError))
end
local ok, execError = pcall(compiled)
if not ok then
    handoff.running = false
    error("[Archivist TP] Archivist startup failed: " .. tostring(execError))
end
local queueFunction = type(queue_on_teleport) == "function" and queue_on_teleport
    or type(queueonteleport) == "function" and queueonteleport
    or (type(syn) == "table" and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
if not queueFunction then
    warn("[Archivist TP] Executor has no teleport queue function; auto-reload unavailable")
    return
end
local queued = false
handoff.connection = player.OnTeleport:Connect(function(state)
    if state ~= Enum.TeleportState.Started or queued then return end
    -- TPReload defaults to true when its UI toggle is unavailable.
    local flags = nil
    if type(handoff.capture) == "function" then
        local captured, result = pcall(handoff.capture)
        if captured then flags = result else warn("[Archivist TP] Snapshot failed: " .. tostring(result)) end
    end
    if flags and flags.toggles and flags.toggles.TPReload == false then return end
    queued = true

    local transfer = ""
    if type(flags) == "table" then
        local success, encoded = pcall(http.JSONEncode, http, flags)
        if success then transfer = encoded else warn("[Archivist TP] Failed to encode live settings; saved profile will be used") end
    end

    -- Include the loader and source in the queued chunk. No URL/file dependency.
    local queuedChunk = string.format(
        "local __ARCH_SOURCE = %q\nlocal __ARCH_HANDOFF = %q\nlocal __ARCH_CORE = %q\nlocal factory, err = loadstring(__ARCH_CORE); if not factory then error('Archivist TP bootstrap compile failed: ' .. tostring(err)) end\nlocal run = factory(); if type(run) == 'function' then run(__ARCH_SOURCE, __ARCH_HANDOFF, __ARCH_CORE) else error('Archivist TP bootstrap returned no runner') end",
        __ARCH_SOURCE, transfer, __ARCH_CORE
    )
    local success, err = pcall(queueFunction, queuedChunk)
    if not success then
        queued = false
        warn("[Archivist TP] Queue failed: " .. tostring(err))
    else
        print("[Archivist TP] Next-server reload queued")
    end
end)
end
