#include "script/common.lua"

local function aorb(a, b, d)
	return (a and d or 0) - (b and d or 0)
end

local function orientation(transform, sign)
	local fwd = VecNormalize(VecSub(TransformToParentPoint(transform, Vec(0, 0, -5)), transform.pos))
	local dir = Vec(0, 1*sign, 0)
	local orientationFactor = clamp(VecDot(dir, fwd) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
end
spectateSelectedPlayer = 1

function getSpectatablePlayers()
    local spectateable = {}
    for _, pl in ipairs(TDMP_GetPlayers()) do
        if GetTeam(pl.steamId) ~= TEAM_SPECTATOR then
            table.insert(spectateable, pl)
        end
    end
    return spectateable
end
function spectatorInput()
    
 
    local mx, my = InputValue("mousedx"), -InputValue("mousedy")
    local u, d, l, r, s = InputDown("up"), InputDown("down"), InputDown("left"), InputDown("right"), InputDown("space")
    local shift = InputDown("shift")

    local ct = GetCameraTransform()
    local pt = GetPlayerTransform()
    if InputPressed("usetool") then
        spectateable = getSpectatablePlayers()
        if #spectateable > 0 then 
            spectateSelectedPlayer = spectateSelectedPlayer + 1
            if spectateSelectedPlayer > #spectateable then
                spectateSelectedPlayer = 1
            end
            local pl = spectateable[spectateSelectedPlayer]
            ct = pl:GetCamera()
        end
    end

    if InputPressed("grab") then
        spectateable = getSpectatablePlayers()
        if #spectateable > 0 then 
            spectateSelectedPlayer = spectateSelectedPlayer - 1
            if spectateSelectedPlayer < 1 then
                spectateSelectedPlayer = #spectateable
            end
            local pl = spectateable[spectateSelectedPlayer]
            ct = pl:GetCamera()
        end
    end
    local upAngle = orientation(Transform(pt.pos, ct.rot), 1)
    local downAngle = orientation(Transform(pt.pos, ct.rot), -1)
    if ((upAngle > 0.98 and my > 0) or (downAngle > 0.98 and my < 0)) then
        my = 0
      end
      local flySpeed = shift and 0.5 or 0.25

      ct.pos = TransformToParentPoint(ct, Vec(aorb(l, r, -flySpeed), s and flySpeed or 0, aorb(u, d, -flySpeed)))

      local target = Vec(mx/750, my/750, -1)
      target = TransformToParentVec(ct, target)
      ct.rot = QuatLookAt(ct, target)
      SetCameraTransform(ct)


end