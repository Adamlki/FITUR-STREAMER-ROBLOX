local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CONFIG = {
    FLIGHT_ADDED = 2,                           -- Tambahan waktu terbang per spam klik (detik)
    ROCKET_MODEL_NAME = "Rocket",               -- Nama Model Roket di ReplicatedStorage.Models
    VELOCITY_BOOST = Vector3.new(0, 150, 0),    -- Kecepatan dorongan roket ke atas
    WHOOSH_SOUND_ID = "rbxassetid://12222065",  -- Suara lepas landas
    WHOOSH_VOLUME = 2,                          -- Volume lepas landas
}

local Feature = {}

function Feature.Trigger(player, duration)
    local rocketTime = player:FindFirstChild("RocketTime")
    if not rocketTime then
        rocketTime = Instance.new("NumberValue")
        rocketTime.Name = "RocketTime"
        rocketTime.Value = 0
        rocketTime.Parent = player
    end
    
    rocketTime.Value = rocketTime.Value + CONFIG.FLIGHT_ADDED
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    local existingRocket = character:FindFirstChild("StreamerRocketNoBom")
    
    if not existingRocket then
        local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
        local rocketTemplate = modelsFolder and modelsFolder:FindFirstChild(CONFIG.ROCKET_MODEL_NAME)
        
        if not rocketTemplate then
            warn("Rocket asset not found in ReplicatedStorage.Models!")
            return
        end
        
        local rocket = rocketTemplate:Clone()
        rocket.Name = "StreamerRocketNoBom"
        
        local rocketMainPart = nil
        if rocket:IsA("Model") then
            rocketMainPart = rocket.PrimaryPart or rocket:FindFirstChildWhichIsA("BasePart")
        elseif rocket:IsA("BasePart") then
            rocketMainPart = rocket
        end
        
        if not rocketMainPart then return end
        
        for _, obj in ipairs(rocket:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Anchored = false
                obj.CanCollide = false
            end
        end
        if rocket:IsA("BasePart") then
            rocket.Anchored = false
            rocket.CanCollide = false
        end
        
        local backOffset = CFrame.new(0, 0.5, 1.2) * CFrame.Angles(math.rad(90), 0, 0)
        
        if rocket:IsA("Model") then
            rocket:PivotTo(hrp.CFrame * backOffset)
        else
            rocket.CFrame = hrp.CFrame * backOffset
        end
        
        rocket.Parent = character
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = hrp
        weld.Part1 = rocketMainPart
        weld.Parent = rocketMainPart
        
        if not rocketMainPart:FindFirstChildOfClass("Fire") then
            local fire = Instance.new("Fire")
            fire.Size = 3
            fire.Heat = 20
            fire.Parent = rocketMainPart
        end
        
        humanoid.PlatformStand = true
        
        local attachment = Instance.new("Attachment")
        attachment.Name = "RocketAttachmentNoBom"
        attachment.Parent = hrp
        
        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Name = "RocketVelocityNoBom"
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = math.huge
        linearVelocity.VectorVelocity = CONFIG.VELOCITY_BOOST
        linearVelocity.Parent = hrp
        
        local alignOrientation = Instance.new("AlignOrientation")
        alignOrientation.Name = "RocketOrientationNoBom"
        alignOrientation.Attachment0 = attachment
        alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOrientation.CFrame = hrp.CFrame.Rotation
        alignOrientation.MaxTorque = math.huge
        alignOrientation.Responsiveness = 200
        alignOrientation.Parent = hrp
        
        local whooshSound = Instance.new("Sound")
        whooshSound.SoundId = CONFIG.WHOOSH_SOUND_ID
        whooshSound.Volume = CONFIG.WHOOSH_VOLUME
        whooshSound.Parent = hrp
        whooshSound:Play()
        game:GetService("Debris"):AddItem(whooshSound, 2)
    else
        local linearVelocity = hrp:FindFirstChild("RocketVelocityNoBom")
        if linearVelocity then
            linearVelocity.VectorVelocity = linearVelocity.VectorVelocity + CONFIG.VELOCITY_BOOST
        end
    end
end

function Feature.Update(deltaTime)
    for _, player in ipairs({Players.LocalPlayer}) do
        local rocketTime = player:FindFirstChild("RocketTime")
        if rocketTime and rocketTime.Value > 0 then
            rocketTime.Value = rocketTime.Value - deltaTime
            
            if rocketTime.Value <= 0 then
                rocketTime.Value = 0
                local character = player.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    
                    if humanoid then
                        humanoid.PlatformStand = false
                    end
                    
                    if hrp then
                        local linearVelocity = hrp:FindFirstChild("RocketVelocityNoBom")
                        if linearVelocity then linearVelocity:Destroy() end
                        
                        local attachment = hrp:FindFirstChild("RocketAttachmentNoBom")
                        if attachment then attachment:Destroy() end
                        
                        local alignOrientation = hrp:FindFirstChild("RocketOrientationNoBom")
                        if alignOrientation then alignOrientation:Destroy() end
                    end
                end
                
                if character then
                    local rocket = character:FindFirstChild("StreamerRocketNoBom")
                    if rocket then rocket:Destroy() end
                end
            end
        end
    end
end

return Feature
