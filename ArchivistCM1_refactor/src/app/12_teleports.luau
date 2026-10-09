-- ============================================================
-- TELEPORT TAB
-- ============================================================
local TeleportTab = Window:CreateTab("Teleports", 10726204364)

do
    local OverworldTeleports = {
        ["A Sentenza"]           = CFrame.new(443,-7,440),
        ["B Docks Quest"]        = CFrame.new(-1253,-11,915),
        ["C Syndicate Office"]   = CFrame.new(-708,-8,958),
        ["D Hana Association"]   = CFrame.new(247,28,600),
        ["E Darius"]             = CFrame.new(51,30,855),
        ["F Hobo Of Life"]       = CFrame.new(291,64,-149),
        ["G Everything Workshop"]= CFrame.new(158,64,87),
        ["H Tower of Gloom"]     = CFrame.new(764,770,-37),
        ["I Refraction Railway"] = CFrame.new(48,0,681),
        ["J Top of Tower"]       = CFrame.new(-1003,698,1424),
        ["K The Halls"]          = CFrame.new(-536,-24,1945),
        ["L Warp Train Quest"]   = CFrame.new(624,-7,408),
        ["L Corp Quest"]         = CFrame.new(991,27,1152),
    }

    TeleportTab:CreateSection("Overworld")
    for name, cf in pairs(OverworldTeleports) do
        TeleportTab:CreateButton({
            Name = name,
            Callback = function()
                local c = LP.Character; if not c then return end
                local r = root(c); if r then r.CFrame = cf end
            end,
        })
    end

    TeleportTab:CreateSection("NPCs")
    TeleportTab:CreateButton({
        Name = "Teleport to Traveling Pawner",
        Callback = function()
            local npcs = Workspace:FindFirstChild("NPCS")
            if not npcs then return end
            local pw = npcs:FindFirstChild("Traveling Pawner"); if not pw then return end
            local pr = root(pw); if not pr then return end
            local c = LP.Character; if not c then return end
            local r = root(c); if r then r.CFrame = pr.CFrame * CFrame.new(0,0,3) end
        end,
    })

    TeleportTab:CreateSection("Refraction Railway")
    for name, cf in pairs({Exit=CFrame.new(38,1495,249), ["Safe Zone"]=CFrame.new(153,1514,508)}) do
        TeleportTab:CreateButton({
            Name = name,
            Callback = function()
                local c = LP.Character; if not c then return end
                local r = root(c); if r then r.CFrame = cf end
            end,
        })
    end
end

