function tdmp_setplayerpos(steamid, transform)
    --if true then return end
    if not TDMP_IsServer() then return end
    if type(steamid) ~= "string" then steamid = steamid.steamId end
    --if steamid == TDMP_LocalSteamID then SetPlayerTransform( Transform( transform) ) return end
    TDMP_ServerStartEvent("tdmp_setplayerpos", {
        Receiver = steamid,
        Reliable = true,
        DontPack = false,
        Data = transform
    })
end


function shuffleTable(x)
    shuffled = {}
    for i, v in ipairs(x) do
        local pos = math.random(1, #shuffled+1)
        table.insert(shuffled, pos, v)
    end
    return shuffled
end


function notify(str, t)
	SetString("hud.notification", str)
	SetInt("hud.notification.numicons", 0)
end

function gameSetState(str)
    if not TDMP_IsServer() then return end
    SetString("game.level.state", str)
    TDMP_ServerStartEvent("tdmp_setstate", {
        Receiver = TDMP.Enums.Receiver.All,
        Reliable = true,
        DontPack = true,
        Data = str
    })
end


TDMP_RegisterEvent("tdmp_setstate", function(state)
    SetString("game.level.state", state)
    if state == "STATE_PREPARE" then
        notify("Prepare for the game!")
        SetBool("game.tool.tdmp_sledge.enabled", true)
        SetBool("game.tool.tdmp_hands.enabled", true)
        SetString("game.player.tool", "tdmp_sledge")
    end
end)
TDMP_RegisterEvent("changeteamMessage", function()
    teamDescriptionActive = GetTime() + 5
end)
TDMP_RegisterEvent("teamWinMessage", function(data)
    winningTeam = tonumber(data)
    teamWinActive = GetTime() + 5
end)


TDMP_RegisterEvent("tdmp_setplayerpos", function(jsonData)
    local data = json.decode(jsonData)
    --DebugPrint(jsonData)
    SetPlayerTransform( Transform(Vec(data[1], data[2],data[3])))
end)


TDMP_RegisterEvent("tdmp_playerrespawnhook", function(data, steamid)
    Hook_Run("PlayerRespawned", steamid, true)
    TDMP_ServerStartEvent("tdmp_playerrespawnhook", {
        Receiver = TDMP.Enums.Receiver.ClientsOnly,
        Reliable = true,
        DontPack = true,
        Data = steamid
    })
end)
