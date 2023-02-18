#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"
#include "tdmp/chat.lua"
#include "tdmp/teams.lua"
#include "tdmp/json.lua"
#include "tdmp/ballistics.lua"

function startGame()
    if not TDMP_IsServer() then return end


     
    for _, gun in ipairs (MapGetPickups()) do
        sv_spawnGun(gun[2], gun[1])
    end
    for _, pl in ipairs (TDMP_GetPlayers()) do
        SetTeam(pl, TEAM_PREPARE)
    end
    prepareFinish = GetTime() + 10
    gameSetState("STATE_PREPARE")
end



prepareFinish = 0
function startGameActive()
    if not TDMP_IsServer() then return end
    local shuffled = shuffleTable(TDMP_GetPlayers())
    local no_detective = true
    for _, pl in ipairs(shuffled) do
        if #TeamGetPlayers(TEAM_TRAITOR) < max_traitors then
            SetTeam(pl, TEAM_TRAITOR)
        else
            if #TeamGetPlayers(TEAM_DETECTIVE) < max_detectives then
                SetTeam(pl, TEAM_DETECTIVE)
            else
                SetTeam(pl, TEAM_INNOCENT)
            end
        end
        --DebugPrint(GetTeam(pl))
       -- tdmp_setplayerpos(pl.steamId,  getdriverworldpos(TEAM_SPAWNS[GetTeam(pl)]))
    end
    gameSetState("STATE_ACTIVE")
    TDMP_ServerStartEvent("changeteamMessage", {
        Receiver = TDMP.Enums.Receiver.All,
        Reliable = true,
        DontPack = true,
        Data = ""
    })
end
function prepare()
    if not TDMP_IsServer() then return end
    if GetString("game.level.state") ~= "STATE_PREPARE" then return end

    if GetTime() > prepareFinish then
        startGameActive()
    end
end


function iswinningsone()
    if not TDMP_IsServer() then return end
    --if true then return end -------------------------------------------------------------------------------------------------------- COMMENT OUT
    if #TDMP_GetPlayers() <= 1 then return end 
    if GetString("game.level.state") ~= "STATE_ACTIVE" then return end 
    if gameOver then 
        if gameRestart < GetTime() then
            Restart()
        end
        return 
    end
    if #TeamGetPlayers(TEAM_DETECTIVE) + #TeamGetPlayers(TEAM_INNOCENT) <= 0 then
        TDMP_BroadcastChatMessage({1,0.2,0}, "Traitors" , {1,1,1}, " wins! Game will restart shortly")
        gameRestart = GetTime() + 10
        gameOver = true
        TDMP_ServerStartEvent("teamWinMessage", {
            Receiver = TDMP.Enums.Receiver.All,
            Reliable = true,
            DontPack = true,
            Data = tostring(TEAM_TRAITOR)
        })
    end
    if #TeamGetPlayers(TEAM_TRAITOR) <= 0 then
        TDMP_BroadcastChatMessage({0,1,0}, "Innocents" , {1,1,1}, " wins! Game will restart shortly")
        gameRestart = GetTime() + 10
        gameOver = true
        TDMP_ServerStartEvent("teamWinMessage", {
            Receiver = TDMP.Enums.Receiver.All,
            Reliable = true,
            DontPack = true,
            Data = tostring(TEAM_INNOCENT)
        })
    end
end