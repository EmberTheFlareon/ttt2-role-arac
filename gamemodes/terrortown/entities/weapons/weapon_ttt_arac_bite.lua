if SERVER then
  AddCSLuaFile()
  resource.AddFile("models/spider_web/spider_web.vmt")
  util.AddNetworkString("WebTimerHUD")
  util.AddNetworkString("StopWebTimerHUD")
end

if CLIENT then
  SWEP.PrintName = "Spider Bite"

  SWEP.ViewModelFlip = false
  SWEP.ViewModelFOV = 54
  SWEP.DrawCrosshair = true

  SWEP.EquipMenuData = {
    type = "item_weapon",
    desc = "knife_desc"
  }

  SWEP.Icon = "vgui/ttt/icon_knife"
  SWEP.IconLetter = "j"
end

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "knife"
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.UseHands = true

SWEP.Primary.Damage = 30
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 5

SWEP.Kind = WEAPON_SPECIAL
SWEP.CanBuy = false
SWEP.HitDistance = 64

SWEP.AutoSpawnable         = false
SWEP.AdminSpawnable	=	false


SWEP.AllowDrop = false
SWEP.IsSilent = true

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2

local sound_single = Sound("Weapon_Crowbar.Single")

if SERVER then
  function SWEP:Initialize()
    self:SetHoldType("knife")
  end
end

function SWEP:Deploy()
  local owner = self:GetOwner()
  owner:SetNWBool("Knife_Out", true)
  return true
end

function SWEP:Holster(weapon)
  local owner = self:GetOwner()
  owner:SetNWBool("Knife_Out", false)
  return true
end

function SWEP:OnDrop()
  self:GetOwner():SetNWBool("Knife_Out", false)
  self:Remove()
end


function SWEP:PrimaryAttack()
  self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

  if not IsValid(self:GetOwner()) then return end

  self:GetOwner():LagCompensation(true)

  local spos = self:GetOwner():GetShootPos()
  local sdest = spos + (self:GetOwner():GetAimVector() * 70)

  local kmins = Vector(1, 1, 1) * -10
  local kmaxs = Vector(1, 1, 1) * 10

  local tr = util.TraceHull({
      start = spos,
      endpos = sdest,
      filter = self:GetOwner(),
      mask = MASK_SHOT_HULL,
      mins = kmins,
      maxs = kmaxs
  })

  if not IsValid(tr.Entity) then
    tr = util.TraceLine({
        start = spos,
        endpos = sdest,
        filter = self:GetOwner(),
        mask = MASK_SHOT_HULL
    })
  end

  local hitEnt = tr.Entity

  self:EmitSound(sound_single)

  if IsValid(hitEnt) then
    self:SendWeaponAnim(ACT_VM_HITCENTER)

    local edata = EffectData()
    edata:SetStart(spos)
    edata:SetOrigin(tr.HitPos)
    edata:SetNormal(tr.Normal)
    edata:SetEntity(hitEnt)

    if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
      self:GetOwner():SetAnimation(PLAYER_ATTACK1)

      self:SendWeaponAnim(ACT_VM_MISSCENTER)

      util.Effect("BloodImpact", edata)
    end

  else
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
  end

  if SERVER then
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
  end

  if SERVER and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) and hitEnt:IsPlayer() then
      local dmg = DamageInfo()
      dmg:SetDamage(self.Primary.Damage)
      dmg:SetAttacker(self:GetOwner())
      dmg:SetInflictor(self)
      dmg:SetDamageForce(self:GetOwner():GetAimVector() * 5)
      dmg:SetDamagePosition(self:GetOwner():GetPos())
      dmg:SetDamageType(DMG_SLASH, DMG_POISON)

      hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
      local dmg_dealt = dmg:GetDamage()
  end

  self:GetOwner():LagCompensation(false)
end


function SWEP:Error()

end


hook.Add("TTTCanIdentifyCorpse","WebbingObscuresCorpse", function(ply, ent, corpse, isCovert, isLongRange)
  if ent.IsWebbed == true then
    return false 
  elseif ent.IsWebbed == false then
    return true
  end
end)

hook.Add("TTTCanSearchCorpse","WebObscuresCorpse", function(ply, ent, corpse, isCovert, isLongRange)
  if ent.IsWebbed == true then
    return false 
  elseif ent.IsWebbed == false then
    return true
  end
end)

hook.Add("EntityTakeDamage", "TryToBurnWeb", function(ent, dmg)
  if ent.IsWebbed == true and dmg:GetDamageType(DMG_BURN) then
    ent:SetMaterial("")
    ent.IsWebbed = false
  end
end)


if SERVER then
   

  local function WrapInWebbing(ent)
    ent:SetMaterial("models/spider_web/spider_web.vmt")
    ent.IsWebbed = true
  end

  local function WrapTimer(ent, owner)
      timer.Create("WebTimer", 1, 1, function()
        WrapInWebbing(ent)
      end)
  end
  hook.Add("Initialize", "WebTimerHook", WebTimer )

 
	function SWEP:SecondaryAttack()
    local owner = self:GetOwner()
	
		local trace = owner:GetEyeTrace(MASK_SHOT_HULL)
		local distance = trace.StartPos:Distance(trace.HitPos)
		local ent = trace.Entity
	
		if distance > 100 or not IsValid(ent)
		or ent:GetClass() ~= "prop_ragdoll"
		or not CORPSE.IsValidBody(ent)
		then return end
  
		if distance <= 100 or IsValid(ent)
		or ent:GetClass() ~= "prop_ragdoll"
		or CORPSE.IsValidBody(ent) then
      WrapTimer(ent, owner)
      net.Start("WebTimerHUD")
      net.Send(owner)
    end
  end

  local function StopWrap(owner)
    timer.Remove("WebTimer")
    net.Start("StopWebTimerHUD")
    net.Send(owner)
  end

  function SWEP:Think()
    local owner = self:GetOwner()
    if not owner:KeyDown(IN_ATTACK2)  then
      StopWrap(owner)
    end
  end


end


if CLIENT then

  local colorRed = Color(196, 35, 35)

  net.Receive("WebTimerHUD", function()
    timer.Create("AHUDTimer", 1, 1, function()
    end)
  end)

  net.Receive("StopWebTimerHUD", function()
    timer.Remove("AHUDTimer")
  end)

  hook.Add("TTTRenderEntityInfo", "ttt2_arac_wrap_display_info", function(tData)
    local ent = tData:GetEntity()
    local client = LocalPlayer()
    local activeWeapon = client:GetActiveWeapon()
    if ent:GetClass() ~= "prop_ragdoll" or not CORPSE.IsValidBody(ent) then return end
    if not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "weapon_ttt_arac_bite" then return end
    if tData:GetEntityDistance() > 100 then return end

    tData:AddDescriptionLine(
      LANG.GetParamTranslation("arac_hold_to_wrap", {key = Key("+attack2", "RIGHT MOUSE")}),
      colorRed
    )
    if timer.Exists("AHUDTimer") then


      local progress = math.min(timer.TimeLeft("AHUDTimer"), 1.0)

      local x = 0.5 * ScrW()
      local y = 0.5 * ScrH()
      local w, h = 0.2 * ScrW(), 0.025 * ScrH()

      y = 0.95 * y
      surface.SetDrawColor(50, 50, 50, 220)
      surface.DrawRect(x - 0.5 * w, y - h, w, h)
      surface.SetDrawColor(clr(colorRed))
      surface.DrawOutlinedRect(x - 0.5 * w, y - h, w, h)
      surface.SetDrawColor(clr(ColorAlpha(colorRed, (0.5 + 0.15 * math.sin(CurTime() * 4)) * 255)))
      surface.DrawRect(x - 0.5 * w + 2, y - h + 2, w * progress, h - 4)
      tData:AddDescriptionLine(
        LANG.GetParamTranslation("arac_wrap_progress", {time = math.Round(timer.TimeLeft("AHUDTimer"))}),
       colorRed
      )
      tData:SetOutlineColor(colorRed)
    end
  end)

end




