AddCSLuaFile()

game.AddAmmoType( {
	name = "AmnesiacAGaz",
	dmgtype = DMG_BULLET,
	tracer = TRACER_NONE,
	plydmg = 0,
	npcdmg = 0,
	force = 0,
	minsplash = 0,
	maxsplash = 0
} )

SWEP.Author = "BIBI"
SWEP.Purpose = "Une bombe aérosol contenant un amnésique A"
SWEP.Instructions = "Appuyer sur le clic gauche pour générer un spray amnésiant."
SWEP.Category = "BIBI weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/spray_can/v_lavender_spray.mdl" 
SWEP.WorldModel = "models/spray_can/w_lavender_spray.mdl"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "Amnésique Classe A"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = 250
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AmnesiacAGaz"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.AllowDrop = false
SWEP.Range = 150
SWEP.HoldType = ""
SWEP.TimeEffect = math.random(5, 10)

local DrawMotionAmnesiacA = "DrawMotionAmnesiacA"
local ResetDrawMotionAmnesiacA = "ResetDrawMotionAmnesiacA"

if (SERVER) then
    util.AddNetworkString( DrawMotionAmnesiacA )
    util.AddNetworkString( ResetDrawMotionAmnesiacA )
end

local JobNotAffected = {---- Jobs that cannot be peppered.
-- TODO Voir les jobs qui peuvent être tranquilisé (Not Used anymore)
"IAA",
"UIAA",
}


function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- Checks if the player has released the left click, if so, decreases the spray volume.
function SWEP:Think()
	if (self:GetOwner():KeyReleased(IN_ATTACK) and self.SoundSpray) or (self.SoundSpray and self:Clip1() <= 0) then
        self.SoundSpray:ChangeVolume(0, 0.1)
	end
end

-- Generates a spray via an effect and loops a spray sound, calls the function EffectOnHit if it hits a player.
function SWEP:PrimaryAttack()
    if self:Clip1() > 0 then
        if !self.SoundSpray then
            self.SoundSpray = CreateSound(self:GetOwner(), "ambient/gas/cannister_loop.wav")
            self.SoundSpray:Play()
        else
            self.SoundSpray:ChangeVolume(1, 0.1)
        end
        
        self:SetNextPrimaryFire(CurTime() + 0.01)
        local ef = EffectData()
        ef:SetEntity(self.Weapon)
        ef:SetAttachment(1)
        ef:SetOrigin(self:GetOwner():GetShootPos())
        ef:SetStart(Vector(255, 255, 255))
        ef:SetNormal(self:GetOwner():GetAimVector())
        util.Effect("effect_spray", ef)
        self:EffectOnHit()
        if(self:Clip1() > 0) then
            self:SetClip1(self:Clip1() - 1)
        end
    end
end

function SWEP:SecondaryAttack()
end

-- Reloads the ammunition of the weapon and lowers the sound of the spray if the player reloads.
function SWEP:Reload()
    if self.SoundSpray then
        self.SoundSpray:ChangeVolume(0, 0.1)
    end
    self:DefaultReload( ACT_RELOAD )
end

-- Check if a player is not affected, and if not, it decrease its speedwalking and make a blurry vision.
function SWEP:EffectOnHit()
    if SERVER then
        local ply = self:GetOwner()
        local tr = util.TraceHull {
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * self.Range,
            filter = ply,
            mins = Vector(-10, -10, -10),
            maxs = Vector(10, 10, 10)
        }

        local victim = tr.Entity
        local vm = self:GetOwner():GetViewModel()
        if !IsValid(vm) or !victim:IsPlayer() or victim.AffectByAmnesiacA then return end
        -- if table.HasValue(JobNotAffected, team.GetName( victim:Team() )) then return end
        if table.HasValue(GuthSCP.Config.guthscpbase.scp_teams, victim:Team()) then return end
        victim.AffectByAmnesiacA = true
        victim:Say("/me "..TranslateAmnesiac( "amnesiac_effect_a" ))
        victim:EmitSound("ambient/voices/cough"..math.random(1,4)..".wav")

        self:SendDrawMotionAmnesiacA(victim)
        timer.Create("affected_by_amnesiac_a_"..victim:SteamID(),self.TimeEffect + 30,1,function()
            if (IsValid(victim)) then
                victim.AffectByAmnesiacA = false
            end
        end)

    end
end

-- Function called to display an blurry vision on the client side.
function SWEP:SendDrawMotionAmnesiacA(victim)
	net.Start(DrawMotionAmnesiacA)
	net.WriteFloat(self.TimeEffect)
	net.Send(victim)
end

-- Function called to remove an blurry vision on the client side.
local function SendResetDrawMotionAmnesiacA(victim)
	net.Start(ResetDrawMotionAmnesiacA)
	net.WriteBool(true)
	net.Send(victim)
end


if (CLIENT) then
    net.Receive(DrawMotionAmnesiacA, function ( )
        TimeEffect = net.ReadFloat()
        local ply = LocalPlayer()
        ply.IsAmnesiacA = true
        timer.Simple(TimeEffect, function ()
            if !IsValid(ply) then return end
            ply.IsAmnesiacA = false
        end)
    end)

    net.Receive(ResetDrawMotionAmnesiacA, function ( )
        Check = net.ReadBool()
        local ply = LocalPlayer()
        if (Check and ply.IsAmnesiacA) then
            ply.IsAmnesiacA = nil
        end
    end)

    -- Make a blurry vision on the screen of the player if it is affect by amnesiac.
    function EffectScreenAmnesiacA()
        local ply = LocalPlayer()
        local curTime = FrameTime()
        if !ply.AddAlphaPepper then ply.AddAlphaPepper = 1 end
        if !ply.DrawAlphaPepper then ply.DrawAlphaPepper = 0 end
        if !ply.DelayPepper then ply.DelayPepper = 0 end
        if !ply.ColorDrain then ply.ColorDrain = 1 end
            
        if ply.IsAmnesiacA then 
            ply.AddAlphaPepper = 0.2
            ply.DrawAlphaPepper = 0.5
            ply.DelayPepper = 0.05
            ply.ColorDrain = 0
        else
            ply.AddAlphaPepper = math.Clamp(ply.AddAlphaPepper + curTime * 0.4, 0.2, 1)
            ply.DrawAlphaPepper = math.Clamp(ply.DrawAlphaPepper - curTime * 0.4, 0, 0.99)
            ply.DelayPepper = math.Clamp(ply.DelayPepper - curTime * 0.4, 0, 0.05)
            ply.ColorDrain = math.Clamp(ply.ColorDrain + curTime * 0.4, 0.66, 1)
        end
        
        DrawMotionBlur( ply.AddAlphaPepper, ply.DrawAlphaPepper, ply.DelayPepper )

                local Color = {}
        Color[ "$pp_colour_addr" ] = 0
        Color[ "$pp_colour_brightness" ] = 0
        Color[ "$pp_colour_mulg" ] = 0
        Color[ "$pp_colour_colour" ] = ply.ColorDrain
        Color[ "$pp_colour_addg" ] = 0
        Color[ "$pp_colour_addb" ] = 0
        Color[ "$pp_colour_mulr" ] = 0
        Color[ "$pp_colour_mulb" ] = 0
        Color[ "$pp_colour_contrast" ] = 1
        DrawColorModify( Color )
    end

    -- Hook called every tick who call the function EffectScreenAmnesiacA().
    hook.Add("RenderScreenspaceEffects","EffectScreenAmnesiacA",EffectScreenAmnesiacA)
end

-- Function called to remove all effect on death or changed team
function RemoveEffectAmnesiacA(victim)
    victim.AffectByAmnesiacA = nil
    if timer.Exists("affected_by_amnesiac_a_"..victim:SteamID()) then
		timer.Remove("affected_by_amnesiac_a_"..victim:SteamID())
	end
    SendResetDrawMotionAmnesiacA(victim)
end

hook.Add( "PlayerDeath", "PlayerDeath.remove_effect_amnesiac_a", RemoveEffectAmnesiacA )
hook.Add( "PlayerChangedTeam", "PlayerChangedTeam.remove_effect_amnesiac_a", RemoveEffectAmnesiacA )