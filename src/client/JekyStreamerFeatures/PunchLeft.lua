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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    MODEL_NAME = "Nailong",                         -- Nama Model yang mukul di ReplicatedStorage.Models
    ANIMATION_ID = "rbxassetid://126264342780589",  -- Animasi memukul
    SOUND_ID = "rbxassetid://46153268",             -- Suara pukulan (Hit)
    SOUND_VOLUME = 1.5,                             -- Volume suara pukulan
    PUSH_FORCE = 100000,                            -- MaxForce dorongan
    PUSH_VELOCITY = 30,                             -- Kecepatan dorongan sliding (kecilkan jika terlalu jauh)
}

local Feature = {}

function Feature.TriggerJeky(player, duration)
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
    local nailongTemplate = modelsFolder and (modelsFolder:FindFirstChild(CONFIG.MODEL_NAME) or modelsFolder:FindFirstChild("Nilong"))
    
    if nailongTemplate then
        local nailong = nailongTemplate:Clone()
        
        local spawnOffset = CFrame.new(3, 0, -2) -- 3 studs right, 2 studs forward
        local spawnPos = (hrp.CFrame * spawnOffset).Position
        
        nailong:PivotTo(CFrame.new(spawnPos, hrp.Position))
        nailong.Parent = workspace
        
        local nailongHRP = nailong:FindFirstChild("HumanoidRootPart")
        if nailongHRP then
            nailongHRP.Anchored = true
        end
        
        for _, obj in ipairs(nailong:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
            end
        end
        
        local nHumanoid = nailong:FindFirstChildOfClass("Humanoid")
        if nHumanoid then
            local animator = nHumanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = nHumanoid
            end
            
            local anim = Instance.new("Animation")
            anim.AnimationId = CONFIG.ANIMATION_ID
            
            local animTrack = animator:LoadAnimation(anim)
            animTrack:Play()
        end
        
        task.delay(0.5, function()
            if nailong then nailong:Destroy() end
        end)
    else
        warn("Model '" .. CONFIG.MODEL_NAME .. "' not found in ReplicatedStorage.Models! Continuing without visual.")
    end
    
    local direction = -hrp.CFrame.RightVector
    
    local hitSound = Instance.new("Sound")
    hitSound.SoundId = CONFIG.SOUND_ID
    hitSound.Volume = CONFIG.SOUND_VOLUME
    hitSound.Parent = hrp
    hitSound:Play()
    game:GetService("Debris"):AddItem(hitSound, 2)
    
    local hitFlash = Instance.new("Part")
    hitFlash.Size = Vector3.new(2, 2, 2)
    hitFlash.CFrame = hrp.CFrame
    hitFlash.Anchored = true
    hitFlash.CanCollide = false
    hitFlash.Shape = Enum.PartType.Ball
    hitFlash.Material = Enum.Material.Neon
    hitFlash.Color = Color3.fromRGB(255, 255, 255) -- Starts white
    hitFlash.Parent = workspace
    
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hitFlash, tweenInfo, {
        Size = Vector3.new(12, 12, 12), -- Expands very large
        Transparency = 1,
        Color = Color3.fromRGB(255, 50, 0) -- Fades to fiery orange/red
    })
    tween:Play()
    game:GetService("Debris"):AddItem(hitFlash, 0.5)
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp
    
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = attachment
    linearVelocity.MaxForce = CONFIG.PUSH_FORCE
    linearVelocity.VectorVelocity = direction * CONFIG.PUSH_VELOCITY
    linearVelocity.Parent = hrp
    
    task.delay(0.10, function()
        if linearVelocity then linearVelocity:Destroy() end
        if attachment then attachment:Destroy() end
    end)
end

return Feature

