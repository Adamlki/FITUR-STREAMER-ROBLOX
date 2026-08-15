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
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CONFIG = {
    BOLT_COLOR = Color3.fromRGB(150, 220, 255), -- Warna petir (Biru keputihan)
    BOLT_HEIGHT = 1000,                         -- Tinggi tiang petir
    BLAST_RADIUS = 4,                           -- Radius ledakan visual
    SOUND_ID = "rbxassetid://112601622500056",  -- Suara sambaran petir
    SOUND_VOLUME = 3,                           -- Volume suara petir
    TWEEN_TIME = 0.4                            -- Kecepatan kilat menghilang (detik)
}

local Feature = {}

function Feature.Trigger(player, duration)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character.HumanoidRootPart
        local targetPos = hrp.Position
        
        local bolt = Instance.new("Part")
        bolt.Name = "SmiteBolt"
        bolt.Anchored = true
        bolt.CanCollide = false
        bolt.CanQuery = false
        bolt.CanTouch = false
        bolt.Material = Enum.Material.Neon
        bolt.Color = CONFIG.BOLT_COLOR
        
        bolt.Size = Vector3.new(4, CONFIG.BOLT_HEIGHT, 4)
        
        bolt.CFrame = CFrame.new(targetPos + Vector3.new(0, CONFIG.BOLT_HEIGHT/2, 0))
        bolt.Parent = workspace
        
        local explosion = Instance.new("Explosion")
        explosion.Position = targetPos
        explosion.BlastRadius = CONFIG.BLAST_RADIUS
        explosion.BlastPressure = 0 -- Don't fling parts
        explosion.DestroyJointRadiusPercent = 0 -- Don't break parts of the map
        explosion.Parent = workspace
        
        local thunderSound = Instance.new("Sound")
        thunderSound.SoundId = CONFIG.SOUND_ID
        thunderSound.Volume = CONFIG.SOUND_VOLUME
        thunderSound.TimePosition = 0.3 -- Skip 0.3 seconds to avoid delay/silence at the start
        thunderSound.Parent = hrp
        thunderSound:Play()
        Debris:AddItem(thunderSound, 5)
        
        if humanoid then
            humanoid.Health = 0
        end
        
        local tweenInfo = TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
        local tween = TweenService:Create(bolt, tweenInfo, {
            Transparency = 1, 
            Size = Vector3.new(0.1, CONFIG.BOLT_HEIGHT, 0.1)
        })
        tween:Play()
        
        Debris:AddItem(bolt, 0.5)
    end
end

return Feature

