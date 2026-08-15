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
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    DEFAULT_DURATION = 5,                           -- Durasi waktu digebuk jika durasi tidak diset
    MODEL_NAME = "Nailong",                         -- Nama Model yang mukul di ReplicatedStorage.Models
    ANIMATION_ID = "rbxassetid://126264342780589",  -- Animasi memukul
    SOUND_ID = "rbxassetid://46153268",             -- Suara pukulan (Hit)
    SOUND_VOLUME = 1.5,                             -- Volume suara pukulan
    HIT_COOLDOWN = 0.15,                            -- Kecepatan spam pukulan per detik (makin kecil makin cepat)
    PUSH_FORCE = 30,                                -- Kekuatan dorongan ke player setiap dipukul
}

local Feature = {}

local function DoBeatdownHit(player, nailong)
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local randomAngle = math.rad(math.random(0, 360))
    local distance = 3
    local offsetX = math.sin(randomAngle) * distance
    local offsetZ = math.cos(randomAngle) * distance
    local spawnPos = hrp.Position + Vector3.new(offsetX, -1, offsetZ)
    
    nailong:PivotTo(CFrame.new(spawnPos, hrp.Position))
    
    local nHum = nailong:FindFirstChildOfClass("Humanoid") or nailong:FindFirstChildOfClass("AnimationController")
    if nHum then
        local animator = nHum:FindFirstChildOfClass("Animator")
        if animator then
            local anim = Instance.new("Animation")
            anim.AnimationId = CONFIG.ANIMATION_ID
            local animTrack = animator:LoadAnimation(anim)
            animTrack:Play()
        end
    end
    
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
    hitFlash.Color = Color3.fromRGB(255, 255, 255)
    hitFlash.Parent = workspace
    
    local flashTween = TweenService:Create(hitFlash, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = Vector3.new(12, 12, 12),
        Transparency = 1,
        Color = Color3.fromRGB(255, 50, 0)
    })
    flashTween:Play()
    game:GetService("Debris"):AddItem(hitFlash, 0.5)
    
    local pushDirection = nailong:GetPivot().LookVector
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp
    
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = attachment
    linearVelocity.MaxForce = 100000 
    linearVelocity.VectorVelocity = pushDirection * CONFIG.PUSH_FORCE 
    linearVelocity.Parent = hrp
    
    task.delay(0.1, function()
        if linearVelocity then linearVelocity:Destroy() end
        if attachment then attachment:Destroy() end
    end)
end

function Feature.TriggerJeky(player, duration)
    local timeAdded = (duration and type(duration) == "number" and duration > 0) and duration or CONFIG.DEFAULT_DURATION
    
    local beatdownTime = player:FindFirstChild("BeatdownTime")
    if not beatdownTime then
        beatdownTime = Instance.new("NumberValue")
        beatdownTime.Name = "BeatdownTime"
        beatdownTime.Value = 0
        beatdownTime.Parent = player
    end
    
    beatdownTime.Value = beatdownTime.Value + timeAdded
end

function Feature.UpdateJeky(deltaTime)
    for _, player in ipairs({Players.LocalPlayer}) do
        local beatdownTime = player:FindFirstChild("BeatdownTime")
        if beatdownTime and beatdownTime.Value > 0 then
            beatdownTime.Value = beatdownTime.Value - deltaTime
            
            local nailongName = "BeatdownNailong_" .. player.Name
            local existingNailong = workspace:FindFirstChild(nailongName)
            
            if beatdownTime.Value <= 0 then
                beatdownTime.Value = 0
                if existingNailong then
                    existingNailong:Destroy()
                end
            else
                if not existingNailong then
                    local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
                    local nailongTemplate = modelsFolder and modelsFolder:FindFirstChild(CONFIG.MODEL_NAME)
                    if nailongTemplate then
                        existingNailong = nailongTemplate:Clone()
                        existingNailong.Name = nailongName
                        for _, part in ipairs(existingNailong:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                                part.Anchored = true
                            end
                        end
                        local nHum = existingNailong:FindFirstChildOfClass("Humanoid") or existingNailong:FindFirstChildOfClass("AnimationController")
                        if not nHum then nHum = Instance.new("AnimationController", existingNailong) end
                        local animator = nHum:FindFirstChildOfClass("Animator")
                        if not animator then animator = Instance.new("Animator", nHum) end
                        existingNailong.Parent = workspace
                    end
                end
                
                local now = tick()
                local nextSlap = player:GetAttribute("NextSlapTime") or 0
                if now >= nextSlap then
                    if existingNailong then
                        DoBeatdownHit(player, existingNailong)
                    end
                    player:SetAttribute("NextSlapTime", now + CONFIG.HIT_COOLDOWN) 
                end
            end
        else
            local nailongName = "BeatdownNailong_" .. player.Name
            local existingNailong = workspace:FindFirstChild(nailongName)
            if existingNailong then
                existingNailong:Destroy()
            end
        end
    end
end

return Feature


