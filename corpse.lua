#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"
#include "tdmp/chat.lua"
#include "tdmp/teams.lua"
#include "tdmp/json.lua"
#include "tdmp/ballistics.lua"
PlayerDeath = {}
Hook_AddListener("PlayerCorpseCreated", "tdmp_tttcorpse", function(data)
	--DebugPrint(data)
	local unpacked = json.decode(data)
	local steamid = unpacked[1]
	local bodyshapes = unpacked[2]

		SetTag( bodyshapes[1], "interact", "Investigate")
		SetTag( bodyshapes[1], "playerBody", steamid)
end)

TDMP_RegisterEvent("ttt_SendDeathInfo", function(data)
	--DebugPrint(data)
	local unpacked = json.decode(data) -- OPEN MENU LOGIC HERE
	local corpseData = unpacked[1]
	serverTime = unpacked[2]
	currentCorpse = corpseData
end)


TDMP_RegisterEvent("ttt_requestPlayerDeathInfo", function(data, sender)
	if not TDMP_IsServer() then return end
	if not PlayerDeath[data] then return end
	local pl = Player(sender)
	if not PlayerDeath[data].discovered then
		 PlayerDeath[data].discovered = true;
		 local team = tonumber(PlayerDeath[data].team)
		 TDMP_BroadcastChatMessage( pl:GetColor(true), pl:Nick(), {1,1,1}, " has discovered the body of ",  TeamColor( team), PlayerDeath[data].nick, {1,1,1}, ".")
		 TDMP_BroadcastChatMessage({1,1,1}, "They were a ", TeamColor( team), TeamName( team), {1,1,1}, "!")
	end

	TDMP_ServerStartEvent("ttt_SendDeathInfo", {
		Receiver = sender,
		Reliable = true,
		DontPack = false,
		Data = {PlayerDeath[data], GetTime()}
	})

end)

Hook_AddListener("TDMP_PlayerDamaged", "TTT_PlayerDeathHook", function(data)
	if not TDMP_IsServer() then return end
	--DebugPrint(data)
	local unpacked = json.decode(data)

end)

Hook_AddListener("PlayerDied", "TTT_PlayerDeathHookTwo", function(data)
	if not TDMP_IsServer() then return end
	local unpacked = json.decode(data)
	local pl = Player(unpacked[1])
	if PlayerDeath[unpacked[1]] then return end
	PlayerDeath[unpacked[1]] = {
		nick = pl:Nick(),
		team = GetTeam(unpacked[1]),
		causeofDeath = "Unknown",
		timeofDeath = GetTime(),
	}
end)
function Investigate_Input()
	local body = GetPlayerInteractBody()

	if not InputPressed("interact") then return end
	if not HasTag(body,'playerBody') then return end
	TDMP_ClientStartEvent("ttt_requestPlayerDeathInfo",
	{
		Reliable = true,
		DontPack = true,
		Data = GetTagValue(body, 'playerBody')
	})
end