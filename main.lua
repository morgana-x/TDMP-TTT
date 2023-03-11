#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"
#include "tdmp/chat.lua"
#include "tdmp/teams.lua"
#include "tdmp/json.lua"
#include "tdmp/ballistics.lua"

#include "teams.lua"
#include "util.lua"
#include "map.lua"
#include "pickups.lua"
#include "logic.lua"
#include "hud.lua"
#include "corpse.lua"
#include "spectator.lua"


--local SPAWNS = MapGetSpawns()

teamDescriptionActive = 0
winningTeam = TEAM_SPECTATOR
teamWinActive = 0

causeofDeath = {}
gameOver = false;
gameRestart = 0;

 max_traitors = 1
 max_detectives = 1
 round_preparetime = 30
 round_stalematetime = 500

 currentCorpse = nil
 lastDiedPos = Vec(0,0,0)
camTransform = Transform(Vec(0,0,0))

serverTime = 0
serverTimeOffset = 0
--[[
    G to drop weapon

    Type !t message to send a team message as traitor

]]

function init()
    --SetBool("tdmp.forcedisablecorpse", true) -- need custom corpses
    for _, weapon in ipairs(ListKeys("game.tool")) do
        if weapon ~= "tdmp_sledge" then 
            SetBool("game.tool." .. weapon .. ".enabled", false)
        else
            SetBool("game.tool." .. weapon .. ".enabled", true)
        end
    end
   --[[ for _, weapon in ipairs(ListKeys("game.mod")) do 
        DebugPrint(_)
        DebugPrint(weapon)
        DebugPrint(GetString("game.mod." .. weapon))
    end]]
    SetDefaultTeam(TEAM_SPECTATOR)


    Hook_AddListener("tdmp_playerchangedteam", "TDMP_TTT_ChangeTeam", function(data)
        data = data:gsub('"', '')
        
      
        if (data == TDMP_LocalSteamID) and ( (GetTeam(TDMP_LocalSteamID) == TEAM_PREPARE) or GetTeam(TDMP_LocalSteamID) == TEAM_SPECTATOR) then
            RespawnPlayer()
        end
        --[[if (data == TDMP_LocalSteamID) and  (GetTeam(TDMP_LocalSteamID) == TEAM_DETECTIVE) then
            SetBool("game.tool." .. "tdmp_gun" .. ".enabled", true)
        end--]]
        if data == TDMP_LocalSteamID then
            SetCameraTransform(GetPlayerCameraTransform())
        end
        local pl = Player(data)
        local col = TeamColor(GetTeam(data))
        local coli = TeamColor(TEAM_INNOCENT)
        pl:SetColor(col[1], col[2], col[3])
        if GetTeam(pl) == TEAM_TRAITOR and GetTeam(TDMP_LocalSteamID) ~= TEAM_TRAITOR then
            pl:SetColor(coli[1], coli[2], coli[3])
        end


    end)
    if TDMP_IsServer() then

        gameSetState("STATE_LOBBY")
      
    
        Hook_AddListener("PlayerConnected", "tdmp_tttsetteam", function(steamid)
    
    
            TDMP_ServerStartEvent("tdmp_setstate", {
                Receiver = steamid,
                Reliable = true,
                DontPack = false,
                Data = GetString("game.level.state")
            })
         --[[  if GetString("game.level.state") == "STATE_ACTIVE" then 
                SetTeam(steamid, TEAM_SPECTATOR)
                return
            end]]
    
            if GetString("game.level.state" == "STATE_PREPARE") then
                SetTeam(steamid, TEAM_PREPARE)
                return
            end
            SetTeam(steamid, TEAM_SPECTATOR)
        end)
    
    
    
        Hook_AddListener("PlayerRespawned", "tdmp_tttrespawend", function(steamid)
        end)
    
       
    end
end
Hook_AddListener("TDMP_ChatSuppressMessage", "TTT_Team_chat", function(msgData)
    msgData = json.decode(msgData)

    local msg = msgData[1]
    local white = {1,1,1}
    if msg:sub(1,2) == "!t" then
        local ply = Player(msgData[2])
        local team = GetTeam(ply)
        local teamcolor = TeamColor(team)
        if (team == TEAM_TRAITOR) then
            for _, pl in ipairs (TDMP_GetPlayers()) do 
                if GetTeam(pl) == team then
                    TDMP_SendChatMessageToPlayer( pl.steamId,  teamcolor, "(TEAM) ", ply:GetColor(true), ply:Nick(), {1,1,1}, ": " ..  msg:sub(3, #msg))
                end
            end
        end
        return ""
    end

    if (GetTeam(msgData[2]) == TEAM_SPECTATOR) then
        local ply = Player(msgData[2])
        local team = GetTeam(ply)
        local teamcolor = TeamColor(team)
        for _, pl in ipairs (TDMP_GetPlayers()) do 
            if GetTeam(pl) == team then
                TDMP_SendChatMessageToPlayer( pl.steamId,  teamcolor, "(DEAD) ", ply:GetColor(true), ply:Nick(), {1,1,1}, ": " ..  msg)
            end
        end
        return ""
    end
end)
function draw()
    drawPlayerInfo()
    drawHudLobby()
    drawHudCore()
    drawHudDebug()
    drawTeamDescription()
    drawTeamWin()
    drawBodyInvestigation()
end

function debugInput()
    if InputPressed("k") then currentCorpse = {
		nick = "morgana",
		team = TEAM_TRAITOR,
		causeofDeath = "falling",
		timeofDeath = GetTime(),
	}
	serverTime = GetTime() + 10
	return end

	if InputPressed("l") then
		TDMP_ClientStartEvent("ttt_requestPlayerDeathInfo",
	{
		Reliable = true,
		DontPack = true,
		Data = TDMP_LocalSteamID
	})
	return
end
end

local localplayerDead = false
function tick()


    if  GetPlayerHealth() <= 0 then localplayerDead = true; camTransform = GetPlayerCameraTransform(); 
        if GetTeam(TDMP_LocalSteamID) ~= TEAM_SPECTATOR then
            dropAllWeapons(); 
        end
    end
    if localplayerDead and GetPlayerHealth() > 0 then 
        localplayerDead = false;
        TDMP_ClientStartEvent("tdmp_playerrespawnhook", {
			Reliable = true,
			DontPack = true,
			Data = ""        
		})
    end


    if GetTeam(TDMP_LocalSteamID) ~= TEAM_SPECTATOR  then
        pickupLogic()
        Investigate_Input()
    else
        SetPlayerTransform(Transform(Vec(0,999,0)))
        for _, weapon in ipairs(ListKeys("game.tool")) do
            SetBool("game.tool." .. weapon .. ".enabled", false)
        end
        SetCameraTransform(camTransform)
        spectatorInput()

    end

    debugInput()
    if GetString("game.level.state") == "STATE_PREPARE" then
        SetPlayerHealth(1)
    end
    if TDMP_IsServer() then
        prepare()
        iswinningsone()
        if GetString("game.level.state") == "STATE_ACTIVE" then
            for _, pl in ipairs(TDMP_GetPlayers()) do
                if pl.hp <= 0 and GetTeam(pl) ~= TEAM_SPECTATOR then
                    SetTeam(pl, TEAM_SPECTATOR)
                    --pl:SetVisible(false)
                end
            end
        end
    end
end

