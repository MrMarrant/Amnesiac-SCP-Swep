AddCSLuaFile()

game.AddAmmoType( {
	name = "AmnesiacSyringeE",
	dmgtype = DMG_BULLET,
	tracer = TRACER_NONE,
	plydmg = 0,
	npcdmg = 0,
	force = 0,
	minsplash = 0,
	maxsplash = 0
} )

SWEP.Author = "BIBI"
SWEP.Purpose = "Une seringue amnésiante de classe E qui paralyse le joueur et lui fais oublier son identité."
SWEP.Instructions = "Appuyer sur le clic gauche pour amnésier un joueur (RP). Le clic droit amnésiera vous même."
SWEP.Category = "BIBI weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/syringe/v_syringe.mdl"
SWEP.WorldModel = "models/syringe/w_syringe.mdl"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "Amnésique Classe E"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "AmnesiacSyringeE"
SWEP.Secondary.Ammo = "none"

SWEP.AllowDrop = false
SWEP.Range = 200
SWEP.HoldType = "slam"

local JobNotAffected = {---- Jobs that cannot be tranquilising.
-- TODO Voir les jobs qui peuvent être tranquilisé (Not Used anymore)
"IAA",
"UIAA",
"SCP 999",
"SCP 131",
"SCP 049",
"SCP 096",
"SCP 457",
"SCP 966",
"SCP 079",
"SCP 205",
"SCP 173",
"SCP 106",
"SCP 682",
"SCP 939",
"SCP 1983pro",
"SCP 1048",
}

local BlurryVision = "BlurryVision"

if SERVER then
    util.AddNetworkString( BlurryVision )
end

local function Stunning(victim, ent, number, delay)
    -- Go to autorun/cl_amnesique.lua
    net.Start(BlurryVision)
	net.WriteFloat(delay)
	net.Send(victim)
    AmnesiaEffect(victim, ent, number, delay)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:DefaultReload( ACT_RELOAD )
    return true
end

-- Render amnesia to the targeted player.
function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    local tr = util.TraceHull {
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * self.Range,
        filter = ply,
        mins = Vector(-10, -10, -10),
        maxs = Vector(10, 10, 10)
    }

    local victim = tr.Entity
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    if !victim:IsPlayer() then return end
	-- if table.HasValue(JobNotAffected, team.GetName( victim:Team() )) then return end
    if !timer.Exists("amnesia_effect"..victim:SteamID()) then
        ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)
        if CLIENT then return end

        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        Stunning(victim, self, 4, 10)
    else
        ply:PrintMessage(HUD_PRINTTALK, TranslateAmnesiac( "player_already_affected" ))
    end
end

-- Render amnesia yourself.
function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
	
	if CLIENT then return end
    if (self:Clip1() > 0) then
        if !timer.Exists("amnesia_effect"..ply:SteamID()) then
            ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)
            self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
            if table.HasValue(JobNotAffected, team.GetName( ply:Team() )) then return end
            Stunning(ply, self, 4, 10)
        else
            ply:PrintMessage(HUD_PRINTTALK, TranslateAmnesiac( "self_already_affected" ))
        end
    else
        ply:PrintMessage(HUD_PRINTTALK, TranslateAmnesiac( "no_more_load" ))
    end
end