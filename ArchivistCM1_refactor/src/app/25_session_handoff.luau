-- ============================================================
-- TELEPORT HANDOFF (in-memory, no filesystem API calls)
-- The wrapper installs __ArchivistTPContext before executing this chunk.
-- ============================================================
do
    local function configureTeleportHandoff()
        local sharedEnv = type(getgenv) == "function" and getgenv() or _G
        local handoff = sharedEnv and sharedEnv.__ArchivistTPContext
        if type(handoff) ~= "table" then return end

        local registry = YSLRuntime.Toggles
        local options = YSLRuntime.Options
        local guiLibrary = YSLRuntime.Library

        local function sanitize(value, depth)
            if depth > 7 then return nil end
            local kind = type(value)
            if kind == "boolean" or kind == "string" or (kind == "number" and value == value and math.abs(value) < math.huge) then
                return value
            end
            if kind ~= "table" then return nil end
            local result = {}
            for key, item in pairs(value) do
                if type(key) == "string" or type(key) == "number" then
                    local safeItem = sanitize(item, depth + 1)
                    if safeItem ~= nil then result[key] = safeItem end
                end
            end
            return result
        end

        handoff.capture = function()
            local snapshot = {toggles = {}, options = {}}
            for key, toggle in pairs(registry) do
                if toggle.Type == "Toggle" then
                    snapshot.toggles[key] = toggle.Value == true
                end
            end
            for key, option in pairs(options) do
                if option.Type then
                    local v
                    if option.Type == "ColorPicker" then
                        local ok, hex = pcall(function() return option.Value:ToHex() end)
                        if ok then v = {hex = hex, transparency = option.Transparency} end
                    elseif option.Type == "KeyPicker" then
                        v = {key = option.Value, mode = option.Mode}
                    else
                        v = sanitize(option.Value, 0)
                    end
                    if v ~= nil then snapshot.options[key] = {type = option.Type, value = v} end
                end
            end
            return snapshot
        end

        local incoming = handoff.pending
        if type(incoming) ~= "table" then return end
        handoff.pending = nil
        guiLibrary.ConfigLoading = true

        -- Restore configuration FIRST, then live toggles/automation workers.
        for key, item in pairs(incoming.options or {}) do
            local opt = options[key]
            if opt and type(item) == "table" and opt.Type == item.type then
                local ok, err = pcall(function()
                    if item.type == "ColorPicker" then
                        if item.value and item.value.hex then
                            opt:SetValueRGB(Color3.fromHex(item.value.hex), item.value.transparency)
                        end
                    elseif item.type == "KeyPicker" then
                        if item.value then opt:SetValue({item.value.key, item.value.mode}) end
                    elseif opt.SetValue then
                        opt:SetValue(item.value)
                    end
                end)
                if not ok then warn("[Archivist TP] Restore option " .. tostring(key) .. ": " .. tostring(err)) end
            end
        end

        for key, enabled in pairs(incoming.toggles or {}) do
            local toggle = registry[key]
            if toggle and toggle.Type == "Toggle" and type(enabled) == "boolean" and toggle.Value ~= enabled then
                local ok, err = pcall(function() toggle:SetValue(enabled) end)
                if not ok then warn("[Archivist TP] Restore toggle " .. tostring(key) .. ": " .. tostring(err)) end
            end
        end
        guiLibrary.ConfigLoading = false
        handoff.restored = true
        print("[Archivist TP] Recovered prior session settings and automations")
    end
    local ok, err = pcall(configureTeleportHandoff)
    if not ok then warn("[Archivist TP] Restore failed: " .. tostring(err)) end
end
