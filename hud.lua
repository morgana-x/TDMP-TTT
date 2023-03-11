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
       -- UiTranslate(0,-UiFontHeight())
       -- UiText( "Ang: " .. json.encode(GetPlayerTransform(false)["rot"]) )
        UiTranslate(0,-UiFontHeight())
        UiText( "Map: " .. GetLevelId())
    UiPop()
end

function drawTimeLeft(seconds)
    UiFont("bold.ttf", 20)
    local time = formatTime(seconds)
    local tx, ty = UiGetTextSize(time)
    UiColor(0,0,0,0.8)
    UiTranslate(0, 0)
    UiTranslate(5,-ty)
    UiImageBox("ui/common/box-solid-shadow-50.png", tx, ty, -40, -45) 
    UiTranslate(3, ty - 5)
    UiColor(1,1,1,1)
    UiText( time)
end

function drawHudCore()
    UiPush()
        UiFont("bold.ttf", 40)
        local col = TeamColor(GetTeam(TDMP_LocalSteamID)) or {1,1,1}
        UiColor(col[1],col[2],col[3])
        UiTranslate(20, UiHeight() - UiFontHeight())
        local name = TeamName(GetTeam(TDMP_LocalSteamID))
        local sx, sy = UiGetTextSize(name)
        UiText(name )
        if GetString("game.level.state") == "STATE_PREPARE" then
            UiTranslate(sx, 0)
            drawTimeLeft( prepareFinish - (GetTime() + serverTimeOffset) )
        end
        if GetString("game.level.state") == "STATE_ACTIVE" then
            --UiTranslate(20, UiHeight() - UiFontHeight())
            UiTranslate(sx, 0)
            drawTimeLeft(roundStaleMate - (GetTime() + serverTimeOffset))
        end
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
            UiText("The " .. TeamName(team) .. "s win!")
        UiPop()
    end
end


local bw = 500
local bh = 250
function drawBodyInvestigation()
    if not currentCorpse then return end
    UiPush()
    UiMakeInteractive()
    UiTranslate(  (UiWidth()/2 ) - (bw/2),  (UiHeight() / 2) - (bh/2))
    UiColor(0,0,0,0.8)
    UiImageBox("ui/common/box-solid-shadow-50.png", bw, bh, -50, -50) 
    UiColor(1,1,1,1)
    UiFont("bold.ttf", 40)



    local text = {}
    text[1] = { {1,1,0.5}, "Name: ", {1,1,1},  currentCorpse.nick}
    text[2] = { {1,1,0.5}, "Team: ", TeamColor(currentCorpse.team), TeamName(currentCorpse.team)}
    text[3] = {{1,1,0.5}, "Cause of Death: ", {1,1,1}, currentCorpse.causeofDeath }
    text[4] = {{1,1,0.5}, "Time of death: ", {1,1,1},  tostring(math.floor( serverTime - currentCorpse.timeofDeath)) .. " seconds ago" }
    UiFont("bold.ttf", 25)
    UiTranslate(0, 20)
    UiText( currentCorpse.nick ..  "'s body.")
    UiColor(1,0,0,1)
    local closewidth = UiGetTextSize("Close")
    UiTranslate(bw - closewidth)
    local close = UiTextButton("Close")

    UiTranslate(-(bw - closewidth))
    for _, t in ipairs(text) do
        UiTranslate(0,UiFontHeight() * 1.1)
        UiColor(t[1][1],t[1][2],t[1][3],1)
        UiText(t[2])
        local tw, th = UiGetTextSize(t[2])
        UiTranslate(tw,0)
        UiColor(t[3][1], t[3][2], t[3][3])
        UiText(t[4])
        local tw2, th2 = UiGetTextSize(t[2])
        UiTranslate(-tw,0)
    end


    if close then currentCorpse = nil  end
    UiPop()
end