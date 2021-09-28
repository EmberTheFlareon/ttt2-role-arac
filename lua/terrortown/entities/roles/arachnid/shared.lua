-- ROLE.Base = "ttt_role_base"
--
-- ROLE.index = ROLE_TRAITOR

if SERVER then
  AddCSLuaFile()

  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_arac.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(255, 0, 0)

  self.abbr = "arac" -- abbreviation
  self.surviveBonus = 0.5 -- bonus multiplier for every survive while another player was killed
  self.scoreKillsMultiplier = 5 -- multiplier for kill of player of another team
  self.scoreTeamKillsMultiplier = -16 -- multiplier for teamkill
  self.preventFindCredits = false
  self.preventKillCredits = false
  self.preventTraitorAloneCredits = false

  self.defaultEquipment = SPECIAL_EQUIPMENT -- here you can set up your own default equipment, though Arachnid does not have acces to a shop.
  self.defaultTeam = TEAM_TRAITOR

  self.conVarData = {
    pct = 0.17, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 6, -- minimum amount of players until this role is able to get selected
    credits = 0, -- the starting credits of a specific role
    togglable = true, -- option to toggle a role for a client if possible (F1 menu)
    random = 50,
    traitorButton = 1, -- can use traitor buttons
  }
end

-- now link this subrole with its baserole
function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_TRAITOR)
end

if SERVER then

  function ROLE:GiveRoleLoadout(ply, isRoleChange)
    ply:GiveEquipmentWeapon("weapon_ttt_arac_bite")
    ply:GiveEquipmentItem("item_ttt_climb_arac")
  end

  function ROLE:RemoveRoleLoadout(ply, isRoleChange)
      ply:StripWeapon("weapon_ttt_arac_bite")
      ply:RemoveEquipmentItem("item_ttt_climb_arac")
  end
end
