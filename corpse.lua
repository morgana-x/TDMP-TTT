#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"
#include "tdmp/chat.lua"
#include "tdmp/teams.lua"
#include "tdmp/json.lua"
#include "tdmp/ballistics.lua"
PlayerBodies = {}

function PlayerBody(steamid, playermodel, force)
	if not force and Player(steamid):IsDead() then return end

	local PlayerBody = {Parts = {}}

	playermodel = playermodel or 1

	if not PlayerModels.Paths[playermodel] then
		playermodel = 1
	end

	PlayerBody.Model = playermodel
	PlayerBody.BounceTransition = .9
	PlayerBody.CrouchTransition = 0
	PlayerBody.Bounce = Vec()
	PlayerBody.Transform = Transform()
	PlayerBody.Hip = Transform(Vec(0, .2 + .9))
	PlayerBody.LastTransform = Transform()
	PlayerBody.Velocity = Vec()
	PlayerBody.LocalVelocity = Vec()
	PlayerBody.Speed = 0

	local spawned = Spawn(PlayerModels.Paths[playermodel].xml, PlayerBody.Transform)
	if #spawned == 0 then
		DebugPrint("Unable to spawn player model! (" .. tostring(playermodel) .. " / " .. tostring(PlayerModels.Paths[playermodel] and PlayerModels.Paths[playermodel].xml or "Invalid XML path!") .. ")")

		return
	end

	PlayerBody.Transform.pos = Vec()
	PlayerBody.LeftArmBias = Transform(Vec(.5, 1, -.4))
	PlayerBody.RightArmBias = Transform(Vec(-.5, 1, -.4))
	PlayerBody.LeftLegBias = Transform(Vec(.2, .9 - .5, .3 + .2))
	PlayerBody.RightLegBias = Transform(Vec(-.1, .9 - .5, .3 + .2))

	PlayerBody.LeftStep = true
	PlayerBody.RightStep = true

	PlayerBody.FirstTick = true

	for i, ent in ipairs(spawned) do
		local tagSteamId = GetTagValue(ent, "SteamId")
		
		if tagSteamId == "none" then
			SetTag(ent, "SteamId", steamid)

			local tr = GetBodyTransform(ent)
			local lTr = TransformToLocalTransform(PlayerBody.Hip, tr)

			if HasTag(ent, "playerBody_torso") then
				PlayerBody.Parts.Torso = {
					hnd = ent,
					localTransform = lTr
				}
			elseif HasTag(ent, "playerBody_head") then
				PlayerBody.Parts.Head = {
					hnd = ent,
					localTransform = lTr
				}

			elseif HasTag(ent, "playerBody_right_leg_top") then
				PlayerBody.Parts.LegTopR = {
					hnd = ent,
					localTransform = lTr
				}
			elseif HasTag(ent, "playerBody_right_leg_bot") then
				PlayerBody.Parts.LegBottomR = {
					hnd = ent,
					localTransform = lTr
				}

			elseif HasTag(ent, "playerBody_left_leg_top") then
				PlayerBody.Parts.LegTopL = {
					hnd = ent,
					localTransform = lTr
				}
			elseif HasTag(ent, "playerBody_left_leg_bot") then
				PlayerBody.Parts.LegBottomL = {
					hnd = ent,
					localTransform = lTr
				}

			elseif HasTag(ent, "playerBody_right_arm_top") then
				PlayerBody.Parts.ArmTopR = {
					hnd = ent,
					localTransform = lTr
				}
			elseif HasTag(ent, "playerBody_right_arm_bot") then
				PlayerBody.Parts.ArmBottomR = {
					hnd = ent,
					localTransform = lTr
				}

			elseif HasTag(ent, "playerBody_left_arm_top") then
				PlayerBody.Parts.ArmTopL = {
					hnd = ent,
					localTransform = lTr
				}
			elseif HasTag(ent, "playerBody_left_arm_bot") then
				PlayerBody.Parts.ArmBottomL = {
					hnd = ent,
					localTransform = lTr
				}
			end
		end
	end

	for k, v in pairs(PlayerBody.Parts) do
		v.GetTransform = function(self)
			return GetBodyTransform(self.hnd)
		end

		v.GetWorldTransform = function(self)
			return TransformToParentTransform(PlayerBody:GetHipWorldTransform(), self.localTransform)
		end
	end

	PlayerBody.GetHipWorldTransform = function(self)
		return TransformToParentTransform(self.Transform, self.Hip)
	end

	PlayerBodies[steamid] = PlayerBody

	Hook_Run("PlayerBodyCreated", {steamid, playermodel})
end
function customCorpse()
 --[[   if not GetBool("savegame.mod.tdmp.disabledeathsound") or GetBool("tdmp.forcedisabledeathsound") then
        PlaySound(PlayerDeathSound, ply:GetPos())
    end

    Hook_Run("PlayerDied", {ply:SteamID(), ply.id})]]

    if TDMP_IsServer() then
        local steamid = ply:SteamID()

   --     if (not ply.veh or ply.veh == 0) and not GetBool("savegame.mod.tdmp.disablecorpse") and not GetBool("tdmp.forcedisablecorpse") then
            if not PlayerBodies[ply:SteamID()] then
                PlayerBody(ply:SteamID(), PlayerModels.Selected[ply:SteamID()] or 1, true)

                --for i=1,10 do
                --    PlayerBodyUpdate(ply:SteamID(), PlayerBodies[ply:SteamID()], 1, GetTime())
               -- end
            end

            local body = PlayerBodies[ply:SteamID()]

            local spawned = Spawn(PlayerModels.Paths[body.Model].xmlRag, body.Transform)
            if #spawned > 0 then
                local netIds = {}
                local t = GetTime()
                for i, ent in ipairs(spawned) do
                    local steamid = GetTagValue(ent, "SteamId")

                    local type = GetEntityType(ent)
                    if type == "body" and not HasTag(ent, "tdmpIgnore") then
                        netIds[tostring(i)] = TDMP_RegisterNetworkBody(ent)
                    end
                    
                    SetTag(ent, "tdmp_ballisticsIgnore", tostring(t + .5))
                    if steamid == "none" then
                        SetTag(ent, "SteamId", ply:SteamID())

                        if HasTag(ent, "playerBody_torso") then
                            SetBodyTransform(ent, body.Parts.Torso:GetWorldTransform())
                            SetBodyVelocity(ent, VecScale(body.Velocity, 400))

                        elseif HasTag(ent, "playerBody_head") then
                            SetBodyTransform(ent, body.Parts.Head:GetWorldTransform())

                        elseif HasTag(ent, "playerBody_right_leg_top") then
                            local tr = body.Parts.LegTopR:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent, tr)

                        elseif HasTag(ent, "playerBody_right_leg_bot") then
                            local tr = body.Parts.LegBottomR:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent, tr)

                        elseif HasTag(ent, "playerBody_left_leg_top") then
                            local tr =  body.Parts.LegTopL:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)

                        elseif HasTag(ent, "playerBody_left_leg_bot") then
                            local tr = body.Parts.LegBottomL:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)

                        elseif HasTag(ent, "playerBody_right_arm_top") then
                            local tr = body.Parts.ArmTopR:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)

                        elseif HasTag(ent, "playerBody_right_arm_bot") then
                            local tr = body.Parts.ArmBottomR:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)

                        elseif HasTag(ent, "playerBody_left_arm_top") then
                            local tr = body.Parts.ArmTopL:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)

                        elseif HasTag(ent, "playerBody_left_arm_bot") then
                            local tr = body.Parts.ArmBottomL:GetWorldTransform()
                            tr.rot = QuatRotateQuat(tr.rot, rot90)

                            SetBodyTransform(ent,tr)
                        end
                    end
                end

                TDMP_ServerStartEvent("SpawnPlayerCorpse", {
                    Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
                    Reliable = true,

                    DontPack = false,
                    Data = {body.Transform, ply:SteamID(), body.Model, netIds}
                })

                Hook_Run("PlayerCorpseCreated", {steamid, spawned})
            else
                DebugPrint("Unable to spawn player corpse model! (" .. tostring(body.Model) .. " / " .. tostring(PlayerModels.Paths[body.Model] and PlayerModels.Paths[body.Model].xmlRag or "Invalid XML path!") .. ")")
            end
        end

        if (PlayerBodies[steamid] and PlayerBodies[steamid].Parts) then
            for k, v in pairs(PlayerBodies[steamid].Parts) do
                Delete(v.hnd)
            end
        end

        if (PlayerBodies[steamid] and PlayerBodies[steamid].Flashlight) then
            for i, v in ipairs(PlayerBodies[steamid].Flashlight) do
                Delete(v)
            end
        end

        PlayerBodies[ply:SteamID()] = nil

    elseif PlayerBodies[ply:SteamID()] then
        for k, v in pairs(PlayerBodies[ply:SteamID()].Parts) do
            Delete(v.hnd)
        end

        if PlayerBodies[ply:SteamID()].Flashlight then
            for i, v in ipairs(PlayerBodies[ply:SteamID()].Flashlight) do
                Delete(v)
            end
        end

        PlayerBodies[ply:SteamID()] = nil

    end
end