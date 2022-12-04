-- Displays a message to the targeted player according to the defined type, some types also change the player's walking/running speed over a period of time.
function AmnesiaEffect(victim, ent, typeAmnesia, delay)
    local ListAmnesiac = {
        [1] = TranslateAmnesiac( "amnesiac_effect_b" ),
        [2] = TranslateAmnesiac( "amnesiac_effect_c" ),
        [3] = TranslateAmnesiac( "amnesiac_effect_d" ),
        [4] = TranslateAmnesiac( "amnesiac_effect_e" ),
        [5] = TranslateAmnesiac( "amnesiac_effect_f" ),
    }
    local ClassAmnesic = {
        [1] = "b",
        [2] = "c",
        [3] = "d",
        [4] = "e",
        [5] = "f",
    }
    if victim:IsPlayer() then
        victim:PrintMessage( HUD_PRINTTALK, TranslateAmnesiac( "started_effetc" ) )
        ent:GetOwner():EmitSound( "physics/glass/glass_bottle_break1.wav" )
        ent:DefaultReload( ACT_RELOAD )
        if (typeAmnesia >= 3 or typeAmnesia <= 4) then
            victim.WalkSpeed = victim:GetWalkSpeed()
            victim.RunSpeed = victim:GetRunSpeed()
            if (typeAmnesia == 3) then
                victim:SetWalkSpeed(victim.WalkSpeed * 0.3)
                victim:SetRunSpeed(victim.RunSpeed * 0.3)
            elseif (typeAmnesia == 4) then
                victim:SetWalkSpeed(1)
                victim:SetRunSpeed(1)
            end
            timer.Create("amnesic_side_effect_"..victim:SteamID(), 20, 1, function()
                if (victim.WalkSpeed and victim.RunSpeed and IsValid(victim)) then
                    victim:SetWalkSpeed(victim.WalkSpeed)
                    victim:SetRunSpeed(victim.RunSpeed)
                end
            end )
        end
        timer.Create("amnesia_effect"..victim:SteamID(), delay/2, 1, function()
            if IsValid(victim) then
                victim:PrintMessage( HUD_PRINTTALK, ListAmnesiac[typeAmnesia] )
            end
        end )
        
        local ammo = ent:GetOwner():GetAmmoCount(ent:GetPrimaryAmmoType())
        ammo = ammo - 1
        if (ammo <= 0) then
            ent:GetOwner():StripWeapon( ent:GetClass() )
        else
            ent:GetOwner():SetAmmo(ammo, ent:GetPrimaryAmmoType())
        end
    end
end