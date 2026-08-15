-- =================================================================================
--  ██████╗ ███╗   ███╗███████╗    ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ 
--  ██╔══██╗████╗ ████║██╔════╝    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
--  ██║  ██║██╔████╔██║███████╗    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
--  ██║  ██║██║╚██╔╝██║╚════██║    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
--  ██████╔╝██║ ╚═╝ ██║███████║    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
--  ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ 
-- 
--                    T I K T O K  :  j e k y c h e n 0 1
-- =================================================================================
local Debris = game:GetService("Debris")

local CONFIG = {
    BLAST_RADIUS = 10,                          -- Radius ledakan visual
    SOUND_ID = "rbxassetid://12222084",         -- Suara ledakan (Boom)
    SOUND_VOLUME = 3,                           -- Volume suara ledakan
    DAMAGE_PERCENT = 0.2,                       -- Persentase darah yang berkurang (0.2 = 20%)
    CHARRED_COLOR = Color3.fromRGB(25, 25, 25), -- Warna hangus kulit dan pakaian
}

local Feature = {}

function Feature.TriggerJeky(player, duration)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character.HumanoidRootPart
        local targetPos = hrp.Position
        
        local explosion = Instance.new("Explosion")
        explosion.Position = targetPos
        explosion.BlastRadius = CONFIG.BLAST_RADIUS 
        explosion.BlastPressure = 0 -- Don't fling them far away, just visual
        explosion.DestroyJointRadiusPercent = 0 -- Don't break the map
        explosion.Parent = workspace
        
        local explodeSound = Instance.new("Sound")
        explodeSound.SoundId = CONFIG.SOUND_ID
        explodeSound.Volume = CONFIG.SOUND_VOLUME
        explodeSound.Parent = hrp
        explodeSound:Play()
        Debris:AddItem(explodeSound, 3)
        
        if humanoid then
            local damageAmount = humanoid.MaxHealth * CONFIG.DAMAGE_PERCENT
            humanoid:TakeDamage(damageAmount)
        end
        
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Color = CONFIG.CHARRED_COLOR
                if obj:IsA("MeshPart") then
                    obj.TextureID = ""
                end
            elseif obj:IsA("SpecialMesh") then
                obj.TextureId = ""
            elseif obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("Decal") then
                obj.Color3 = CONFIG.CHARRED_COLOR
            end
        end
    end
end

return Feature

