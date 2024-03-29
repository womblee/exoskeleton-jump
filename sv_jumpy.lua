local default_amount = 40
local jumping_team = TEAM_JUMPER

hook.Add('PlayerSpawn', 'CPG_Jumps', function(ply)
    if IsValid(ply) then
        if ply:Team() ~= jumping_team then return end
        ply:SetNWInt('CPG_Jumps', default_amount)
    end
end)

hook.Add('PlayerDeath', 'CPG_Jumps', function(victim, weapon, killer)
    if IsValid(victim) and IsValid(killer) then
        if victim:Team() ~= jumping_team then return end
        victim:SetNWInt('CPG_Jumps', default_amount)
    end
end)

hook.Add('OnPlayerChangedTeam', 'CPG_Jumps', function(ply, from, after)
    if after ~= jumping_team then
        ply:SetNWInt('CPG_Jumps', 0)
    else
        ply:SetNWInt('CPG_Jumps', default_amount)
    end
end)

local bad_move_types = {MOVETYPE_NOCLIP, MOVETYPE_LADDER, MOVETYPE_OBSERVER, MOVETYPE_ISOMETRIC, MOVETYPE_FLY, MOVETYPE_FLYGRAVITY}

hook.Add('SetupMove', 'CPG_Jumps', function(ply, mv)
    if ply.ExoskeletonCooldown and ply.ExoskeletonCooldown > CurTime() then return end
    if not ply:Alive() then return end
    if table.HasValue(bad_move_types, ply:GetMoveType()) then return end
    if ply:IsFrozen() then return end
    -- Do nothing if we're not this job
    if ply:Team() ~= jumping_team then return end
    -- Check for jumps amount
    if ply:GetNWInt('CPG_Jumps') <= 0 then return end
    -- Let the engine handle movement from the ground
    if ply:OnGround() then return end
    -- Don't do anything if not jumping
    if not mv:KeyPressed(IN_JUMP) then return end

    if not ply:OnGround() then
        -- Absolute godly fix
        timer.Simple(0.5, function()
            ply.ExoskeletonJumping = true
        end)

        ply:EmitSound('player/suit_sprint.wav', 120)
        ply:SetVelocity(ply:GetUp() * 450)

        timer.Simple(0.2, function()
            local foot = {'L', 'R'}

            for k, v in pairs(foot) do
                local pos = ply:GetBonePosition(ply:LookupBone('ValveBiped.Bip01_' .. v .. '_Foot'))
                local effectdata = EffectData()
                effectdata:SetOrigin(pos)
                effectdata:SetMagnitude(0.6)
                util.Effect('cball_bounce', effectdata, true)
            end

            ply:EmitSound('ambient/machines/catapult_throw.wav', 120)
            ply:SetVelocity(ply:GetForward() * 590 + Vector(0, 0, ply:GetUp().x + 500))
        end)

        ply:SetNWInt('CPG_Jumps', ply:GetNWInt('CPG_Jumps') - 1)
        ply.ExoskeletonCooldown = CurTime() + 4
    end
end)

-- We don't want junkies abusing the no fall damage system, so let's just check if they're using the jump system.
hook.Add('Think', 'CPG_Jumps', function()
    for k, v in pairs(player.GetAll()) do
        if v:Team() ~= jumping_team then continue end

        if v.ExoskeletonJumping and v.ExoskeletonJumping == true and v:OnGround() then
            -- Let's be 100% sure that we get a stable experience, timer + bool = love
            local aaa = false

            timer.Simple(1, function()
                if aaa then return end
                v.ExoskeletonJumping = false
                aaa = true
            end)
        end
    end
end)

-- Refill
timer.Create('CPG_Refill', 45, 0, function()
    for k, v in pairs(player.GetAll()) do
        if not v:Alive() then continue end
        if v:Team() ~= jumping_team then continue end

        if v:GetNWInt('CPG_Jumps') < default_amount then
            v:SetNWInt('CPG_Jumps', v:GetNWInt('CPG_Jumps') + 1)
        end
    end
end)

-- Same here
hook.Add('GetFallDamage', 'CPG_Jumps', function(ply, speed)
    if ply:Team() ~= jumping_team then return end
    if ply.ExoskeletonJumping and ply.ExoskeletonJumping == true then return 0 end
end)
