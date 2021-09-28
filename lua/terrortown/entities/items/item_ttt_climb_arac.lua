-- ttt climb2 swep by "Jonascone" and "Alf21"
if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/icon_climb.vmt")
	resource.AddFile("materials/vgui/ttt/perks/hud_climb.png")
end

ITEM.hud = Material("vgui/ttt/perks/hud_climb.png")
ITEM.EquipMenuData = {
	type = "item_passive",
	name = "Climb",
	desc = "Let's Jump n' Run!"
}
ITEM.material = "vgui/ttt/icon_climb"
ITEM.credits = 2
ITEM.CanBuy = false

-- Falling & Roll Effect for Climb SWEP2
if CLIENT then
	local curPitch = 0
	local deg = 0
	local inRoll = false

	local function rollTo()
		deg = net.ReadInt(16)
		inRoll = true
		curPitch = deg - 360
	end
	net.Receive("ClimbRoll", rollTo)

	hook.Add("CalcView", "ClimbRollEffect", function(ply, pos, ang, fov)
		if not inRoll then return end

		local view = GAMEMODE:CalcView(ply, pos, ang, fov)

		curPitch = math.Approach(curPitch, deg, FrameTime() * 625)

		if curPitch == deg then
			inRoll = false
		end

		view.angles.p = curPitch

		return view
	end)

	-- fall effect
	CreateClientConVar("climbswep2_windsound", 1, true, false)

	local PrevCurT = 0
	local CurAngles, Snd2

	hook.Add("CreateMove", "ClimbFall", function(cmd)
		local Ply = LocalPlayer()

		if not Snd2 then
			Snd2 = CreateSound(Ply, Sound("ambient/ambience/Wind_Light02_loop.wav"))
			Snd2:Play()
			Snd2:ChangeVolume(0, 0)
		end

		if not IsValid(Ply) or not Ply:HasEquipmentItem("item_ttt_climb") then return end

		if Ply:GetVelocity().z > - 900
		or not Ply:HasEquipmentItem("item_ttt_climb")
		or not Ply:Alive()
		or Ply:GetMoveType() ~= MOVETYPE_WALK
		then
			if PrevCurT > 0 then
				cmd:SetViewAngles(Angle(CurAngles.p, CurAngles.y, 0))

				CurAngles = nil

				Snd2:ChangeVolume(0, 0)

				hook.Remove("RenderScreenspaceEffects", "ClimbFallBlur")

				PrevCurT = 0
			end

			return
		end

		if PrevCurT == 0 then
			PrevCurT = CurTime()

			local function DrawEffect()
				--DrawMotionBlur(0.1, Time/5, 0.01)
				local Time = CurTime() - PrevCurT

				local Colour = {
					["$pp_colour_addr"] = 0,
					["$pp_colour_addg"] = 0,
					["$pp_colour_addb"] = 0,
					["$pp_colour_brightness"] = 0,
					["$pp_colour_contrast"] = 1 - Time / 7.5,
					["$pp_colour_colour"] = 1 - Time / 7.5,
					["$pp_colour_mulr"] = 0,
					["$pp_colour_mulg"] = 0,
					["$pp_colour_mulb"] = 0
				}

				DrawColorModify(Colour)
				DrawMotionBlur(math.Clamp(0.75 - Time * 0.01, 0.25, 1), math.Clamp(Time / 10, 0, 0.75), 0.05)
			end

			hook.Add("RenderScreenspaceEffects", "ClimbFallBlur", DrawEffect)
		end

		if not IsValid(CurAngles) then
			CurAngles = cmd:GetViewAngles()
		end

		local Time = (CurTime() - PrevCurT) * (8 + (CurTime() - PrevCurT) * 2)

		if Time < 101 then
			if GetConVar("climbswep2_windsound"):GetBool() then
				Snd2:ChangeVolume(Time / 100, 0)
			else
				Snd2:ChangeVolume(0, 0)
			end
		end

		CurAngles.p = math.Round(CurAngles.p) < 75 and math.Round(CurAngles.p) + 0.5 or math.Round(CurAngles.p) - 0.5

		cmd:SetViewAngles(Angle(CurAngles.p, CurAngles.y + math.sin(Time) * 1.25, 0))
	end)
end

-- mechanics
local climbswep2_wallrun_minheight = CreateConVar("climbswep2_wallrun_minheight", "250", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local climbswep2_maxjumps = CreateConVar("climbswep2_maxjumps", "3", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

if CLIENT then
	CreateClientConVar("climbswep2_showhud", 1, true, false)
end

function ITEM:Reset(owner)
	owner.ClimbJumps = 0
	owner.ClimbCanWallRun = true
	owner.ClimbReleased = false
	owner.ClimbMFC = "male"
	owner.ClimbWallJumpTrace = nil
	owner.ClimbWallRunAnim = 0
	owner.ClimbNextThink = CurTime()

	owner:SetNWBool("ClimbWallJump", false)
	owner:SetNWBool("ClimbFalling", false)
	owner:SetNWBool("ClimbWallRun", false)
end

function ITEM:Equip(owner)
	owner.ClimbJumps = 0
	owner.ClimbCanWallRun = true
	owner.ClimbReleased = false

	if string.find(owner:GetModel(), "female") or string.find(owner:GetModel(), "alyx") or string.find(owner:GetModel(), "mossman") then
		owner.ClimbMFC = "female"
	elseif string.find(owner:GetModel(), "combine") or string.find(owner:GetModel(), "metro") then
		owner.ClimbMFC = "combine"
	else
		owner.ClimbMFC = "male"
	end

	owner.ClimbWallJumpTrace = nil
	owner.ClimbWallRunAnim = 0
	owner.ClimbNextThink = CurTime()

	owner:SetNWBool("ClimbWallJump", false)
	owner:SetNWBool("ClimbFalling", false)
	owner:SetNWBool("ClimbWallRun", false)
end

local MatList = {
	[67] = "concrete",
	[68] = "dirt",
	[71] = "chainlink",
	[76] = "tile",
	[77] = "metal",
	[78] = "dirt",
	[84] = "tile",
	[86] = "duct",
	[87] = "wood"
}

if SERVER then
	hook.Add("KeyRelease", "ClimbingClicked", function(ply, key)
		ply.pressedClimbJump = nil
	end)

	hook.Add("KeyPress", "ClimbingClicked", function(ply, key)
		if ply.pressedClimbJump then return end

		if ply:HasEquipmentItem("item_ttt_climb") and key == IN_JUMP and ply.ClimbNextThink <= CurTime() then
			ply.pressedClimbJump = true

			if ply:GetNWBool("ClimbWallRun") then
				return true
			end

			-- We'll use this trace for determining whether we're looking at a Wallnot
			local ShootPos = ply:GetShootPos()
			local AimVector = ply:GetAimVector()

			local tracedata = {}
			tracedata.start = ShootPos
			tracedata.endpos = ShootPos + AimVector * 45
			tracedata.filter = ply

			local trace = util.TraceLine(tracedata)

			-- We'll have to be off the ground to start climbing!
			if ply:OnGround() then return end

			-- Wall Jumping. (Code in Think due to HUD Implementation)
			if ply:GetNWBool("ClimbWallJump") then

				-- We can Wall Jump!
				ply.ClimbCanWallRun = true
				ply.ClimbJumps = 0

				ply:SetLocalVelocity(ply:GetAimVector() * 300)
				ply:EmitSound(Sound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav"), 75, math.random(95, 105))
				ply:ViewPunch(Angle(-7.5, 0, 0))

				return
			end

			-- Are we close enough to start climbing?
			if (ply.ClimbJumps == 0 and trace.HitPos:Distance(ShootPos) > 40) or ply.ClimbJumps > (climbswep2_maxjumps:GetInt() - 1) or trace.HitSky then return end

			-- If we've mysteriously lost the wall we'll want to stop climbing!
			if not trace.Hit then return end

			-- Add some effects.
			if trace.MatType == MAT_GLASS then
				ply:EmitSound(Sound("physics/glass/glass_sheet_step" .. math.random(1, 4) .. ".wav"), 75, math.random(95, 105))
			elseif trace.MatType and MatList[trace.MatType] then
				ply:EmitSound(Sound("player/footsteps/" .. MatList[trace.MatType] .. math.random(1, 4) .. ".wav"), 75, math.random(95, 105))
			else
				ply:EmitSound(Sound("npc/fast_zombie/claw_miss" .. math.random(1, 2) .. ".wav"), 75, math.random(95, 105))
			end

			-- Climb the wall and modify our jump count.
			local vel = ply:GetVelocity()

			ply:SetVelocity(Vector(0, 0, 325 - vel.z))

			ply.ClimbNextThink = CurTime() + 0.15
			ply.ClimbJumps = ply.ClimbJumps + 1
		end
	end)
end

local function ThinkClimb()
	for _, owner in ipairs(player.GetAll()) do
		if CLIENT or not IsValid(owner) or not owner:Alive() then continue end

		if owner:HasEquipmentItem("item_ttt_climb") then
			if owner.ClimbJumps ~= owner:GetNWInt("ClimbJumps") then
				owner:SetNWInt("ClimbJumps", owner.ClimbJumps)
			end

			if owner:OnGround() and (owner.ClimbJumps > 0 or not owner.ClimbCanWallRun) or owner:GetNWBool("ClimbFalling") then
				owner.ClimbJumps = 0
				owner.ClimbCanWallRun = true

				owner:SetNWBool("ClimbWallJump", false)
				owner:SetNWBool("ClimbFalling", false)
			elseif owner:GetNWBool("ClimbWallRun") and not owner.Grab then
				local traceData = {}
				traceData.start = owner:GetPos() + Vector(0, 0, 20)
				traceData.endpos = traceData.start + owner:GetForward() * 70
				traceData.filter = owner

				local trace = util.TraceLine(traceData)
				local vel = owner:GetVelocity()

				if not owner:OnGround() and trace.Hit and owner:KeyDown(IN_FORWARD) and math.abs(vel:Length()) > 100 then
					local vel2 = owner:GetVelocity() + owner:GetForward()
					vel2.z = 0

					if CurTime() > owner.ClimbWallRunAnim then
						owner.ClimbWallRunAnim = CurTime() + (0.2 - vel2:Length() / 10000)
						owner:ViewPunch(Angle(10, 0, 0))

						if trace.MatType == MAT_GLASS then
							owner:EmitSound(Sound("physics/glass/glass_sheet_step" .. math.random(1, 4) .. ".wav"), 75, math.random(95, 105))
						elseif trace.MatType and MatList[trace.MatType] then
							owner:EmitSound(Sound("player/footsteps/" .. MatList[trace.MatType] .. math.random(1, 4) .. ".wav"), 75, math.random(95, 105))
						end

						vel2.z = -(100 + vel2:Length())
					end

					owner:SetLocalVelocity(vel2)
				else
					owner:SetNWBool("ClimbWallRun", false)

					owner.ClimbCanWallRun = false
				end
			elseif owner:KeyDown(IN_FORWARD) then
				if owner:KeyDown(IN_USE) and not owner:OnGround() and owner.ClimbCanWallRun and owner.ClimbJumps < climbswep2_maxjumps:GetInt() and not owner.Grab then
					local traceData = {}
					traceData.start = owner:GetPos()
					traceData.endpos = traceData.start - Vector(0, 0, climbswep2_wallrun_minheight:GetInt())

					if not util.TraceLine(traceData).Hit then
						owner:SetNWBool("ClimbWallRun", true)
						owner.ClimbJumps = owner.ClimbJumps + 1

						local vel = owner:GetVelocity() + owner:GetForward() * 100
						vel.z = 0

						owner:SetLocalVelocity(vel)
					end
				end
			end

			if CurTime() < owner.ClimbNextThink then continue end

			if owner:GetNWBool("ClimbFalling") then
				owner:SetNWBool("ClimbFalling", false)
			end

			-- Are we grabbing a ledge?
			if owner.Grab then
				if not owner:KeyDown(IN_FORWARD) and not owner:KeyDown(IN_MOVELEFT) and not owner:KeyDown(IN_MOVERIGHT) then
					continue
				elseif owner:KeyDown(IN_FORWARD) then
					if owner:KeyDown(IN_JUMP) then
						owner:EmitSound(Sound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav"), 75, math.random(95, 105))
						owner:ViewPunch(Angle(-7.5, 0, 0))
						owner:SetLocalVelocity(owner:GetAimVector() * 400)
					end

					continue
				end
			end

			-- Wall Jumping. (In Think due to HUD Implementation)
			if owner.ClimbJumps > 0 then

				-- Are we actually against a wall?
				local ShootPos = owner:GetShootPos()
				local AimVector = owner:GetAimVector()

				local tracedata = {}
				tracedata.start = ShootPos
				tracedata.endpos = ShootPos - AimVector * 45
				tracedata.filter = owner

				local trace = util.TraceLine(tracedata)

				if trace.Hit and not trace.HitSky and not owner:GetNWBool("ClimbWallJump") then
					owner:SetNWBool("ClimbWallJump", true)
				end
			elseif owner:GetNWBool("ClimbWallJump") then
				owner:SetNWBool("ClimbWallJump", false)
			end
		end
	end
end
hook.Add("Think", "ClimbThink", ThinkClimb)

-- Rolling
if SERVER then
	util.AddNetworkString("ClimbRoll")

	hook.Add("OnPlayerHitGround", "ClimbRoll", function(ply, inWater, idc, fallSpeed)
		if inWater or fallSpeed < 450 or not IsValid(ply) or ply:Health() <= 0 or not ply:HasEquipmentItem("item_ttt_climb") or ply:GetNWBool("ClimbFalling") then return end

		net.Start("ClimbRoll")
		net.WriteInt(math.Round(ply:EyeAngles().p), 16)
		net.Send(ply)

		ply:EmitSound("physics/cardboard/cardboard_box_break1.wav", 100, 100)
		ply:SetVelocity(ply:GetVelocity() + ply:GetForward() * (100 + fallSpeed))
	end)

	hook.Add("EntityTakeDamage", "ClimbPreventDamage", function(target, dmginfo)
		if IsValid(target) and target:IsPlayer() and target:HasEquipmentItem("item_ttt_climb") and dmginfo:IsFallDamage() then
			dmginfo:SetDamage(0)
		end
	end)
end
