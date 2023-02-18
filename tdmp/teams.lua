#include "hooks.lua"
#include "player.lua"
#include "networking.lua"
#include "utilities.lua"
#include "json.lua"
teams = teams or {}
player_team = player_team or {}
function createTeam(tbl)
    table.insert(teams, tbl)
    return #teams
end


if not GetBool("level.tdmp_teamsloaded") then

TEAM_SPECTATOR = createTeam({
    name = "Spectator",
    description = "You are dead!",
    color = {1,1,1},
    default = true
})

TDMP_RegisterEvent("setTeam", function(jsonData)
    if TDMP_IsServer() then return end
    local data = json.decode(jsonData)
    local steamid = data[1]
    local team = data[2]
    player_team[steamid] = team
    Player(steamid).team = team
end)

Hook_AddListener("PlayerConnected", "syncTeams", function(steamid)
    SetTeam(pl, GetDefaultTeam())
    SyncTeams(steamid)
end)
    SetBool("level.tdmp_teamsloaded", true)
end

--[[ -- EXAMPLE TEAMS, YOU CAN CREATE TEAMS IN THE FILEs YOU REQUIRE teams.lua IN
    TEAM_RED = createTeam({
    name = "Red",
    description = "",
    color = {1,0,0},
})

TEAM_BLUE = createTeam({
    name = "Blue",
    description = "",
    color = {0,0,1}
})
]]

function TeamValid(id)
    return teams[id] ~= nil
end


function GetDefaultTeam() -- gets id
    for _, team in ipairs(teams) do
        if team.default then return _ end
    end
    return 1
end

function SetDefaultTeam(id)
    for _, team in ipairs(teams) do
        team.default = false
    end
    if teams[id] then
        teams[id].default = true
    end
end

function GetTeam(pl)
    if not pl then return end
    if type(pl) == "string" then pl = Player(pl) end
    if not pl then return end
    if not player_team[pl.steamId ] then pl.team = GetDefaultTeam(); player_team[pl.steamId ] = GetDefaultTeam() end
    return player_team[pl.steamId ] 
end

function GetPlayerTeamTable(pl)
    if not pl then return end
    if type(pl) == "string" then pl = Player(pl) end
    if not pl then return end
    if not player_team[pl.steamId ] then pl.team = GetDefaultTeam(); player_team[pl.steamId ] = GetDefaultTeam() end
    return teams[GetTeam(pl)]
end

function GetTeamTable(id)
    if not TeamValid(id) then return {name = "NULL", description = "NULL", color = {0,0,0}} end
    return teams[id]
end




function SyncTeams(pl)
    if not TDMP_IsServer() then return end
    for steamid, teamid in pairs(player_team) do
        TDMP_ServerStartEvent("setTeam", {
            Receiver = pl, 
            Reliable = true,
    
            DontPack = false,
            Data = {steamid, teamid}
        })
    end
end

function SetTeam(pl, id)
    if not TDMP_IsServer() then return end
    if not TeamValid(id) then return end
    if not pl then return end
    if type(pl) == "table" then
        for _, p in ipairs(pl) do
            SetTeam(p, id)
        end
    end
    if type(pl) == "string" then pl = Player(pl) end
    if not pl then return end
   -- DebugPrint("Setting team")
    pl.team = id
    player_team[pl.steamId] = id
    TDMP_ServerStartEvent("setTeam", {
		Receiver = TDMP.Enums.Receiver.ClientsOnly, 
		Reliable = true,

		DontPack = false,
		Data = {pl.steamId, id}
	})
end

function TeamDescription(id)
    if not TeamValid(id) then return "Null" end
    return teams[id].description
end

function TeamName(id)
    if not TeamValid(id) then return "Null" end
    return teams[id].name
end

function TeamColor(id)
    if not TeamValid(id) then return {0,0,0} end
    return teams[id].color
end


function TeamGetPlayers(id)
    if not TeamValid(id) then return {} end
    local players = {}
    for _, pl in ipairs(TDMP_GetPlayers()) do
        if GetTeam(pl) == id then table.insert(players, pl) end
    end
    return players
end
