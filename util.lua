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

function dropAllWeapons()
    for _, wep in ipairs(ListKeys("game.tool")) do
    if GetBool("game.tool." .. wep .. ".enabled") then
    TDMP_ClientStartEvent("tdmp_dropweapon", {
        Reliable = true,
        DontPack = true,
        Data = wep
    })
    SetBool("game.tool." .. wep .. ".enabled", false)
end
    end
end

function math_round(num)
    return num + (2^52 + 2^51) - (2^52 + 2^51)
end
function formatTime(time)
  --  local days = floor(time/86400)
    local remaining = time % 86400
    local hours = math_round(math.floor(remaining/3600))
    remaining = remaining % 3600
    local minutes = math_round(math.floor(remaining/60))
    remaining = remaining % 60
    local seconds = math_round(remaining)
    if (hours < 10) then
      hours = "0" .. tostring(hours)
    end
    if (minutes < 10) then
      minutes = "0" .. tostring(minutes)
    end
    if (seconds < 10) then
      seconds = "0" .. tostring(seconds)
    end
    answer = --[[tostring(days)..':'..hours..':'..]] minutes..':'..seconds
    return answer
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

TDMP_RegisterEvent("ttt_restart", function()
    if TDMP_IsServer() then return end
    
    Restart()
end)
TDMP_RegisterEvent("teamWinMessage", function(data)
    winningTeam = tonumber(data)
    teamWinActive = GetTime() + 5
end)

TDMP_RegisterEvent("Roundendtimeupadte", function(data)
    local data = json.decode(data)
    roundStaleMate = tonumber(data[1])
    serverTime = tonumber(data[2])
    serverTimeOffset = serverTime - GetTime()
end)
TDMP_RegisterEvent("Prepareendtimeupadte", function(data)
    local data = json.decode(data)
    prepareFinish = tonumber(data[1])
    serverTime = tonumber(data[2])
    serverTimeOffset = serverTime - GetTime()
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
