#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"
#include "tdmp/chat.lua"
#include "tdmp/teams.lua"
#include "tdmp/json.lua"
#include "tdmp/ballistics.lua"
function GetAimDirection(cam)
	cam = cam or GetPlayerCameraTransform()
	local forward = TransformToParentPoint(cam, Vec(0, 0, -1))
	local dir = VecSub(forward, cam.pos)

	return VecNormalize(dir), VecLength(dir)
end
function drawHudDebug()
    UiPush()
        UiTranslate(20, UiHeight() - UiFontHeight())
        UiColor(1,1,1)
        UiFont("bold.ttf", 20)
        UiTranslate(0, -40 -(UiFontHeight() * 2))
        UiText( "Pos: " .. json.encode(GetPlayerTransform(false)["pos"]) )
        UiTranslate(0,-UiFontHeight())
        UiText( "Ang: " .. json.encode(GetPlayerTransform(false)["rot"]) )
        UiTranslate(0,-UiFontHeight())
        UiText( "Map: " .. GetString("game.levelid") )
    UiPop()
end

function drawHudCore()
    UiPush()
        UiFont("bold.ttf", 40)
        local col = TeamColor(GetTeam(TDMP_LocalSteamID)) or {1,1,1}
        UiColor(col[1],col[2],col[3])
        UiTranslate(20, UiHeight() - UiFontHeight())
        UiText( TeamName(GetTeam(TDMP_LocalSteamID)))
    UiPop()
end

function drawPlayerInfo() -- wow coloured names for teams???
    if  ( GetBool("savegame.mod.tdmp.disableplayernicks") or GetBool("tdmp.forcedisablenicks") ) then return end 
    local cam = GetPlayerCameraTransform()
    local dir = GetAimDirection(cam)

    Ballistics:RejectPlayerEntities()
    local ply = TDMP_RaycastPlayer(cam.pos, dir, false, 3)
    if not ( ply and Player(ply):IsVisible())  then return end
    local col = TeamColor(GetTeam(ply)) or {1,1,1}
    if GetTeam(ply) == TEAM_TRAITOR and GetTeam(TDMP_LocalSteamID) ~= TEAM_TRAITOR then
        col = TeamColor(TEAM_INNOCENT) or {1,1,1}
    end
    if not col then return end
    UiPush()
            UiAlign("center middle")
            UiTranslate(UiCenter(), UiMiddle() + 18)
            UiColor(col[1], col[2], col[3], 1)
            UiFont("bold.ttf", 18)
            UiText( ply.nick)
    UiPop()
end

function drawPlayerList(x, y, w, h, tbl)
    UiPush()
        UiTranslate(x,y)
        UiFont("bold.ttf", 24)
        UiColor(1,1,1)
        for _, pl in ipairs(tbl) do
            UiTranslate(0, -UiFontHeight())
            UiText(pl.nick)
        end
    UiPop()
end

function drawHudLobby()
    if GetString("game.level.state") ~= "STATE_LOBBY" then return end
    UiMakeInteractive()
    
    UiPush()
        UiAlign("left")
        UiColor(0,0,0)
        UiRect(UiWidth(), UiHeight())
    UiPop()

    notify("Waiting for host to start game...")

    drawPlayerList(UiWidth() - 120, 70, 100, 50, TDMP_GetPlayers())

    if not TDMP_IsServer() then return end
    UiPush()
        UiTranslate(UiWidth()/2, UiHeight() /2)
        UiColor(1,1,1)
        UiFont("bold.ttf", 40)
        UiTranslate(- UiGetTextSize("Start game") /2, 0)
        pressed = UiTextButton("Start game")
        UiColor(0,1,0)
    UiPop()
    if pressed then
        startGame()
    end
end




function drawTeamDescription()
    local team = GetTeam(TDMP_LocalSteamID)
    local col = TeamColor(team)
    if  ( teamDescriptionActive >= GetTime()) then
        UiPush()
            UiTranslate(UiWidth() /2, UiHeight() / 2)
            UiColor(col[1], col[2], col[3], 1)
            UiFont("bold.ttf", 40)
            UiAlign('center middle')
            UiText(TeamName(team))
            UiTranslate(0, UiFontHeight())
            UiColor(1,1,1, 1)
            UiText(TeamDescription(team))
        UiPop()
    end
end

function drawTeamWin()
    local team = winningTeam
    local col = TeamColor(team)
    if  ( teamWinActive >= GetTime()) then
        UiPush()
            UiTranslate(UiWidth() /2, UiHeight() / 2)
            UiColor(col[1], col[2], col[3], 1)
            UiFont("bold.ttf", 40)
            UiAlign('center middle')
            UiText(TeamName(team))
            UiTranslate(0, UiFontHeight())
            UiColor(1,1,1, 1)
            UiText("The " .. TeamName(team) .. "'s win!s")
        UiPop()
    end
end