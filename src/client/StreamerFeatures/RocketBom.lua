-- ==========================================================
-- FITUR BY DMS STUDIO - TIKTOK : jekychen01
-- ==========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CONFIG = {
    FLIGHT_ADDED = 2,                           -- Tambahan waktu terbang per spam klik (detik)
    ROCKET_MODEL_NAME = "Rocket",               -- Nama Model Roket di ReplicatedStorage.Models
    VELOCITY_BOOST = Vector3.new(0, 150, 0),    -- Kecepatan dorongan roket ke atas
    WHOOSH_SOUND_ID = "rbxassetid://12222065",  -- Suara lepas landas
    WHOOSH_VOLUME = 2,                          -- Volume lepas landas
    EXPLODE_SOUND_ID = "rbxassetid://12222084", -- Suara ledakan (Boom)
    EXPLODE_VOLUME = 3,                         -- Volume ledakan
    BLAST_RADIUS = 15,                          -- Radius ledakan visual
    BLAST_PRESSURE = 50000,                     -- Tekanan dorongan saat roket meledak
    CHARRED_COLOR = Color3.fromRGB(25, 25, 25), -- Warna hangus
}

local Feature = {}

function Feature.Trigger(player, duration)
    local rocketTime = player:FindFirstChild("RocketBomTime")
    if not rocketTime then
        rocketTime = Instance.new("NumberValue")
        rocketTime.Name = "RocketBomTime"
        rocketTime.Value = 0
        rocketTime.Parent = player
    end
    
    rocketTime.Value = rocketTime.Value + CONFIG.FLIGHT_ADDED
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    local existingRocket = character:FindFirstChild("StreamerRocket")
    
    if not existingRocket then
        local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
        local rocketTemplate = modelsFolder and modelsFolder:FindFirstChild(CONFIG.ROCKET_MODEL_NAME)
        
        if not rocketTemplate then
            warn("Rocket asset not found in ReplicatedStorage.Models!")
            return
        end
        
        local rocket = rocketTemplate:Clone()
        rocket.Name = "StreamerRocket"
        
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
        attachment.Name = "RocketAttachment"
        attachment.Parent = hrp
        
        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Name = "RocketVelocity"
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = math.huge
        linearVelocity.VectorVelocity = CONFIG.VELOCITY_BOOST
        linearVelocity.Parent = hrp
        
        local alignOrientation = Instance.new("AlignOrientation")
        alignOrientation.Name = "RocketOrientation"
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
        local linearVelocity = hrp:FindFirstChild("RocketVelocity")
        if linearVelocity then
            linearVelocity.VectorVelocity = linearVelocity.VectorVelocity + CONFIG.VELOCITY_BOOST
        end
    end
end

function Feature.Update(deltaTime)
    for _, player in ipairs({Players.LocalPlayer}) do
        local rocketTime = player:FindFirstChild("RocketBomTime")
        if rocketTime and rocketTime.Value > 0 then
            rocketTime.Value = rocketTime.Value - deltaTime
            
            if rocketTime.Value <= 0 then
                rocketTime.Value = 0
                local character = player.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    
                    if hrp then
                        local explosion = Instance.new("Explosion")
                        explosion.Position = hrp.Position
                        explosion.BlastRadius = CONFIG.BLAST_RADIUS
                        explosion.BlastPressure = CONFIG.BLAST_PRESSURE
                        explosion.DestroyJointRadiusPercent = 0
                        explosion.Parent = workspace
                        
                        local explodeSound = Instance.new("Sound")
                        explodeSound.SoundId = CONFIG.EXPLODE_SOUND_ID
                        explodeSound.Volume = CONFIG.EXPLODE_VOLUME
                        explodeSound.Parent = workspace -- Plays globally
                        explodeSound:Play()
                        game:GetService("Debris"):AddItem(explodeSound, 3)
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
                    
                    if humanoid then
                        humanoid.Health = 0
                        humanoid.PlatformStand = false
                    end
                    
                    if hrp then
                        local linearVelocity = hrp:FindFirstChild("RocketVelocity")
                        if linearVelocity then linearVelocity:Destroy() end
                        
                        local attachment = hrp:FindFirstChild("RocketAttachment")
                        if attachment then attachment:Destroy() end
                        
                        local alignOrientation = hrp:FindFirstChild("RocketOrientation")
                        if alignOrientation then alignOrientation:Destroy() end
                    end
                end
                
                if character then
                    local rocket = character:FindFirstChild("StreamerRocket")
                    if rocket then rocket:Destroy() end
                end
            end
        end
    end
end

return Feature

