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
local Players = game:GetService("Players")

local CONFIG = {
    MESH_NAME = "Jail",                         -- Nama Model Penjara di ReplicatedStorage.Models
    SOUND_ID = "rbxassetid://452267918",        -- Suara saat dipenjara
    SOUND_VOLUME = 2,                           -- Volume suara
}

local Feature = {}

function Feature.Trigger(player, duration)
    local jailTime = player:FindFirstChild("JailTime")
    if not jailTime then return end
    
    jailTime.Value = jailTime.Value + duration
    
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        if not character:FindFirstChild("StreamerJailMesh") then
            local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
            local originalMesh = modelsFolder and modelsFolder:FindFirstChild(CONFIG.MESH_NAME)
            
            if originalMesh then
                local clonedMesh = originalMesh:Clone()
                clonedMesh.Name = "StreamerJailMesh"
                
                local hrpCFrame = character.HumanoidRootPart.CFrame
                
                if clonedMesh:IsA("Model") then
                    clonedMesh:PivotTo(hrpCFrame)
                elseif clonedMesh:IsA("BasePart") then
                    clonedMesh.CFrame = hrpCFrame
                    clonedMesh.Anchored = true
                end
                
                clonedMesh.Parent = character
                
                character.HumanoidRootPart.Anchored = true
                character.HumanoidRootPart.CFrame = hrpCFrame
                
                task.delay(0.1, function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.Anchored = false
                    end
                end)
                
                local jailSound = Instance.new("Sound")
                jailSound.SoundId = CONFIG.SOUND_ID
                jailSound.Volume = CONFIG.SOUND_VOLUME
                jailSound.Parent = character.HumanoidRootPart
                jailSound:Play()
                game:GetService("Debris"):AddItem(jailSound, 3)
            else
                warn(CONFIG.MESH_NAME .. " mesh not found in ReplicatedStorage.Models!")
            end
        end
    end
end

function Feature.Update(deltaTime)
    for _, player in ipairs({Players.LocalPlayer}) do
        local jailTime = player:FindFirstChild("JailTime")
        if jailTime and jailTime.Value > 0 then
            jailTime.Value = jailTime.Value - deltaTime
            
            local character = player.Character
            if character then
                local jailMesh = character:FindFirstChild("StreamerJailMesh")
                local hrp = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if jailTime.Value <= 0 then
                    jailTime.Value = 0
                    if humanoid then
                        humanoid.WalkSpeed = 16
                        humanoid.JumpPower = 50
                    end
                    if jailMesh then
                        jailMesh:Destroy()
                    end
                elseif jailMesh and hrp then
                    local centerCFrame = jailMesh:GetPivot()
                    local hrpCFrame = hrp.CFrame
                    local localPosition = centerCFrame:PointToObjectSpace(hrpCFrame.Position)
                    
                    local extents = jailMesh:IsA("Model") and jailMesh:GetExtentsSize() or jailMesh.Size
                    
                    local maxX = math.max(extents.X / 2 - 1, 0.5)
                    local maxY = math.max(extents.Y / 2 - 0.5, 1)
                    local maxZ = math.max(extents.Z / 2 - 1, 0.5)
                    
                    if math.abs(localPosition.X) > maxX 
                       or math.abs(localPosition.Y) > maxY 
                       or math.abs(localPosition.Z) > maxZ then
                        
                        local safeLocal = Vector3.new(
                            math.clamp(localPosition.X, -maxX, maxX),
                            math.clamp(localPosition.Y, -maxY + 1.35, maxY),
                            math.clamp(localPosition.Z, -maxZ, maxZ)
                        )
                        
                        local safeWorld = centerCFrame:PointToWorldSpace(safeLocal)
                        local rotationOnly = hrpCFrame - hrpCFrame.Position
                        
                        hrp.CFrame = CFrame.new(safeWorld) * rotationOnly
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        else
            local character = player.Character
            if character then
                local jailMesh = character:FindFirstChild("StreamerJailMesh")
                if jailMesh then jailMesh:Destroy() end
            end
        end
    end
end

return Feature

