#include "tdmp/utilities.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"
#include "tdmp/networking.lua"
Hook_AddListener("tdmp_spawn_gunPickup", "Spawn", TDMP_ReceiveSpawn) 
TDMP_DefaultTools = TDMP_DefaultTools or {}
TDMP_DefaultTools["tdmp_gun"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/gun.vox"/></body>',-- scale="0.5"/></body>',
    offset = Vec(-.25, .3, .4),

    leftElbowBias = Transform(Vec(.5, 1, .3)),
    useBothHands = true,
}
TDMP_DefaultTools["tdmp_sledge"] = {
    xml = "<body><vox pos='0.0 -0.0 0.1' file='tool/sledge.vox'/></body>",-- scale='0.4'/></body>",
}
TDMP_DefaultTools["tdmp_bomb"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/bomb.vox"/></body>',
}
TDMP_DefaultTools["tdmp_booster"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/booster.vox"/></body>',
}
TDMP_DefaultTools["tdmp_explosive"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/explosive.vox"/></body>',
}
TDMP_DefaultTools["tdmp_extinguisher"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/extinguisher.vox"/></body>',
}
TDMP_DefaultTools["tdmp_leafblower"] = {
    xml = '<body><vox pos="0.0 0.075 -0.3" file="tool/leafblower.vox"/></body>',
}
TDMP_DefaultTools["tdmp_pipebomb"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/pipebomb.vox"/></body>',
}
TDMP_DefaultTools["tdmp_plank"] = {
    xml = '<body><vox pos="0.0 0.0 0.0" file="tool/plank.vox"/></body>',
}
TDMP_DefaultTools["tdmp_rifle"] = {
    xml = '<body><vox pos="0.0 0.7 -0.2" file="tool/rifle.vox"/></body>',
}
TDMP_DefaultTools["tdmp_rocket"] = {
    xml = '<body><vox pos="0.0 -0.0 0.2" file="tool/rocket.vox"/></body>',
}
TDMP_DefaultTools["tdmp_shotgun"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/shotgun.vox"/></body>',
}
TDMP_DefaultTools["tdmp_spraycan"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/spraycan.vox"/></body>',
}
TDMP_DefaultTools["steroid"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/steroid.vox"/></body>',
}
TDMP_DefaultTools["tdmp_turbo"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/turbo.vox"/></body>',
}
TDMP_DefaultTools["tdmp_blowtorch"] = {
    xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/blowtorch.vox"/></body>',
}
local debug = false

local valid_pickupweapons = {} -- make sure they dont delete everything!
TDMP_RegisterEvent("tdmp_setbodytagnw", function(data, sender)
    local unpacked = json.decode(data)
    if debug then DebugPrint(data) end
    local body = TDMP_GetBodyByNetworkId(tonumber(unpacked[1]))
    local shapes = GetBodyShapes(body)
    for _, s in ipairs(shapes) do
        SetTag( s  , unpacked[2], unpacked[3])
    end
end)
TDMP_RegisterEvent("tdmp_bodyremove", function(data, sender)
    local unpacked = json.decode(data)
    local body = TDMP_GetBodyByNetworkId( tonumber(unpacked[1]))
    
    local shapes = GetBodyShapes(body)
    for _, s in ipairs(shapes) do
        if debug then DebugPrint(s) end
        Delete(s)
    end
    if debug then DebugPrint(body) end
    valid_pickupweapons[body] = nil
    Delete(body)
end)

TDMP_RegisterEvent("tdmp_dropweapon", function(data, sender)
    if TDMP_IsServer() then 
        sender = Player(sender)
        sv_spawnGun(data, sender:GetPos())
    end
end)

TDMP_RegisterEvent("tdmp_bodyremoveClient", function(data, sender)
    local unpacked = json.decode(data)
    local body = TDMP_GetBodyByNetworkId(tonumber(unpacked[1]))
    local valid = false 
    if valid_pickupweapons[body] then valid = true; end
    for _, s in ipairs(GetBodyShapes(body)) do
        if valid_pickupweapons[s] then valid = true; break end
    end
    if not valid then return end
    TDMP_ServerStartEvent("tdmp_bodyremove", {
        Receiver = TDMP.Enums.Receiver.All,
        Reliable = true,
        DontPack = true, 
        Data = data
    })
end)
function sv_setTag(body, tag, value)
    if not body then return end
    if not TDMP_GetBodyNetworkId(body) then return end
    local nwid = tostring(TDMP_GetBodyNetworkId(body))
    local data = {nwid, tag, value}

    local packed = json.encode(data)
    if debug then  DebugPrint(packed) end
  --  SetTag(body, tag, value)

    TDMP_ServerStartEvent("tdmp_setbodytagnw", {
		Receiver = TDMP.Enums.Receiver.All,
		Reliable = true,
		DontPack = true, 
		Data = packed
	})
end

function sv_spawnGun(id,pos)
    if not TDMP_IsServer() then return end
    if debug then  DebugPrint(id) end
    if debug then  DebugPrint(json.encode(pos)) end
    if not TDMP_DefaultTools[id] then return end
    local ents = TDMP_Spawn("tdmp_spawn_gunPickup", TDMP_DefaultTools[id].xml,  Transform(VecAdd(pos, Vec(0.0,1.0,0.0))))
    local shape = ents[1]
    valid_pickupweapons[shape] = true
    sv_setTag(shape, "interact", "Pickup")
    sv_setTag(shape, "gunPickup", id)
end

function sv_spawnAmmo(id, pos) -- do later when not spaweftrnawefpeawf
    local ents = TDMP_Spawn("tdmp_spawn_gunPickup", TDMP_DefaultTools[id].xml, Transform(VecAdd(pos, Vec(0,1,0))))
    local shape = ents[1]
    sv_setTag(shape, "interact", "Pickup")
    sv_setTag(shape, "ammoPickup", "gun")
end

Hook_AddListener("TDMP_ChatSuppressMessage", "TDMP_SpawnGunCmmand", function(msgData)
    msgData = json.decode(msgData)

    local msg = msgData[1]
    if msg == "!sgall" then
        local ply = Player(msgData[2])
        for _, gun in pairs (TDMP_DefaultTools) do 
         sv_spawnGun(_, ply:GetPos())
        end
        return ""
    end
    if msg:sub(1, 3) == "!sg" then
        local ply = Player(msgData[2])
        local result = sv_spawnGun(ply:CurrentTool(), ply:GetPos())
        return ""
    end
end)


function pickupLogic()
    if GetPlayerHealth() == 0 then return end

    if InputPressed('g') then
        local wep =GetString("game.player.tool")
        if  TDMP_DefaultTools[wep] and GetBool("game.tool." ..wep .. ".enabled") then
            TDMP_ClientStartEvent("tdmp_dropweapon", {
                Reliable = true,
                DontPack = true,
                Data = wep
            })
            SetBool("game.tool." ..wep .. ".enabled", false)
            local tools = ListKeys("game.tool")
            local found = false
            for _, tools in ipairs(tools) do
                if GetBool("game.tool." ..wep .. ".enabled") then
                    SetString("game.player.tool", tools[1])
                    found = true
                    break
                end
            end
            if not found then
                 SetString("game.player.tool", "tdmp_hands")
            end
        end
    end
    local body = GetPlayerInteractShape()
    if IsShapeBroken(body) and GetTagValue(body, "gunPickup") ~= "" and GetTagValue(body, "interact") == "Pickup" then
        RemoveTag(body,'interact')
        RemoveTag(body, 'gunPickup')
    end
    if body ~= 0 and InputPressed("interact") then
        
        if GetTagValue(body, "gunPickup") ~= "" and GetTagValue(body, "interact") == "Pickup" and not GetBool( "game.tool.".. GetTagValue(body, "gunPickup") .. ".enabled") then
            SetBool("game.tool." .. GetTagValue(body, "gunPickup") .. ".enabled", true)
            SetString("game.player.tool",  GetTagValue(body, "gunPickup"))

     

        local getBody = GetShapeBody(body)

        local packed = {TDMP_GetBodyNetworkId(getBody)}
    
        TDMP_ClientStartEvent("tdmp_bodyremoveClient", {
            Reliable = true,
            DontPack = false, 
            Data = packed
        })

    end

    end


end