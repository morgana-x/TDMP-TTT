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

--#include "corpse.lua"


--local SPAWNS = MapGetSpawns()

teamDescriptionActive = 0
winningTeam = TEAM_SPECTATOR
teamWinActive = 0

causeofDeath = {}
gameOver = false;
gameRestart = 0;

 max_traitors = 1
 max_detectives = 1




function init()
    --SetBool("tdmp.forcedisablecorpse", true) -- need custom corpses
    for _, weapon in ipairs(ListKeys("game.tool")) do
        if weapon ~= "tdmp_sledge" then 
            SetBool("game.tool." .. weapon .. ".enabled", false)
        else
            SetBool("game.tool." .. weapon .. ".enabled", true)
        end
    end

    SetDefaultTeam(TEAM_SPECTATOR)
    if TDMP_IsServer() then

        gameSetState("STATE_LOBBY")
      
    
        Hook_AddListener("PlayerConnected", "tdmp_tttsetteam", function(steamid)
    
    
            TDMP_ServerStartEvent("tdmp_setstate", {
                Receiver = steamid,
                Reliable = true,
                DontPack = false,
                Data = GetString("game.level.state")
            })
            if GetString("game.level.state") == "STATE_ACTIVE" then 
                SetTeam(steamid, TEAM_SPECTATOR)
                return
            end
    
            if GetString("game.level.state" == "STATE_PREPARE") then
                SetTeam(steamid, TEAM_PREPARE)
            end
            SetTeam(steamid, TEAM_SPECTATOR)
        end)
    
    
    
        Hook_AddListener("PlayerRespawned", "tdmp_tttrespawend", function(steamid)
        end)
    
        Hook_AddListener("PlayerCorpseCreated", "tdmp_tttcorpse", function(steamid, body)
        end)
    end
end



function draw()
    drawPlayerInfo()
    drawHudLobby()
    drawHudCore()
    drawHudDebug()
    drawTeamDescription()
    drawTeamWin()
end


local localplayerDead = false
function tick()


    if  GetPlayerHealth() <= 0 then localplayerDead = true end
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
    else
        --SetPlayerTransform(Transform(Vec(0,999,0)))
        for _, weapon in ipairs(ListKeys("game.tool")) do
            SetBool("game.tool." .. weapon .. ".enabled", false)
        end
    end


    if TDMP_IsServer() then
        prepare()
        iswinningsone()
        if GetString("game.level.state") == "STATE_ACTIVE" then
            for _, pl in ipairs(TDMP_GetPlayers()) do
                if pl.hp <= 0 and GetTeam(pl) ~= TEAM_SPECTATOR then
                    SetTeam(pl, TEAM_SPECTATOR)
                end
            end
        end
    end
end
