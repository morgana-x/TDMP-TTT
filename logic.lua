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
    TDMP_BroadcastChatMessage({1,1,0.5},"The round starts in ", {1,1,1}, tostring(round_preparetime), {1,1,0.5}, " seconds!")
    TDMP_BroadcastChatMessage({1,1,0.5}, "[TIP] ", {1,1,1},"Press ", {1,1,0.5}, "G", {1,1,1}, " to drop your weapon!")
    prepareFinish = GetTime() + round_preparetime
    gameSetState("STATE_PREPARE")
    TDMP_ServerStartEvent("Prepareendtimeupadte", {
        Receiver = TDMP.Enums.Receiver.All, -- Clientsonly after test
        Reliable = true,
        DontPack = false,
        Data = {prepareFinish, GetTime()}
    })
end



prepareFinish = 0
roundStaleMate = 0
function startGameActive()
    if not TDMP_IsServer() then return end
    local shuffled = shuffleTable(TDMP_GetPlayers())
    local no_detective = true
    for _, pl in ipairs(shuffled) do
        if #TeamGetPlayers(TEAM_TRAITOR) < max_traitors then
            SetTeam(pl, TEAM_TRAITOR)
            TDMP_SendChatMessageToPlayer( pl.steamId, {1,1,0.5}, "[TIP] ",  TeamColor(TEAM_TRAITOR), "Type ", {1,1,1}, "\"!t (message)\"", TeamColor(TEAM_TRAITOR), " to team chat as a traitor")
           -- TDMP_SendChatMessageToPlayer( pl.steamId, {1,1,0.5}, "[TIP] ",  TeamColor(TEAM_TRAITOR), "You look like an ", TeamColor(TEAM_INNOCENT), TeamName(TEAM_INNOCENT), TeamColor(TEAM_TRAITOR), " to non ", TeamColor(TEAM_TRAITOR), TeamName(TEAM_TRAITOR), "s!")
        else
            if (#TeamGetPlayers(TEAM_DETECTIVE) < max_detectives) and (#TDMP_GetPlayers() > 5) then
                SetTeam(pl, TEAM_DETECTIVE)
            else
                SetTeam(pl, TEAM_INNOCENT)
            end
        end
        --DebugPrint(GetTeam(pl))
       -- tdmp_setplayerpos(pl.steamId,  getdriverworldpos(TEAM_SPAWNS[GetTeam(pl)]))
    end
    roundStaleMate = GetTime() + round_stalematetime
    gameSetState("STATE_ACTIVE")
    TDMP_ServerStartEvent("Roundendtimeupadte", {
        Receiver = TDMP.Enums.Receiver.All, -- Clientsonly after test
        Reliable = true,
        DontPack = false,
        Data = {roundStaleMate, GetTime()}
    })
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
   

    if GetString("game.level.state") ~= "STATE_ACTIVE" then return end 
    if gameOver then 
        if gameRestart < GetTime() then
            --[[TDMP_ServerStartEvent("tdmp_setstate", {
                Receiver = TDMP.Enums.Receiver.ClientsOnly,
                Reliable = true,
                DontPack = true,
                Data = ""
            })]]
            Restart()
        end
        return 
    end
    if GetTime() > roundStaleMate and not gameOver then
        TDMP_BroadcastChatMessage({1,1,1}, "Time ran out for the traitors!")
        TDMP_BroadcastChatMessage({0,1,0}, "Innocents" , {1,1,1}, " wins! Game will restart shortly")
        gameRestart = GetTime() + 10
        gameOver = true
        TDMP_ServerStartEvent("teamWinMessage", {
            Receiver = TDMP.Enums.Receiver.All,
            Reliable = true,
            DontPack = true,
            Data = tostring(TEAM_INNOCENT)
        })
        return
    end
    if #TDMP_GetPlayers() <= 1 then return end 

    if #TeamGetPlayers(TEAM_DETECTIVE) + #TeamGetPlayers(TEAM_INNOCENT) <= 0 then
        TDMP_BroadcastChatMessage({1,0.2,0}, "Traitors" , {1,1,1}, " win! Game will restart shortly")
        gameRestart = GetTime() + 10
        gameOver = true
        TDMP_ServerStartEvent("teamWinMessage", {
            Receiver = TDMP.Enums.Receiver.All,
            Reliable = true,
            DontPack = true,
            Data = tostring(TEAM_TRAITOR)
        })
        return
    end
    if #TeamGetPlayers(TEAM_TRAITOR) <= 0 then
        TDMP_BroadcastChatMessage({0,1,0}, "Innocents" , {1,1,1}, " win! Game will restart shortly")
        gameRestart = GetTime() + 10
        gameOver = true
        TDMP_ServerStartEvent("teamWinMessage", {
            Receiver = TDMP.Enums.Receiver.All,
            Reliable = true,
            DontPack = true,
            Data = tostring(TEAM_INNOCENT)
        })
        return
    end


end