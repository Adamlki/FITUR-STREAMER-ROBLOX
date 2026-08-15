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

local CONFIG = {
    DEFAULT_DURATION = 15,                          -- Waktu default menjadi langsing (detik)
    SLIM_WIDTH = 0.2,                               -- Skala lebar badan saat langsing
    SLIM_DEPTH = 0.2,                               -- Skala tebal badan saat langsing
    SLIM_HEAD = 0.5,                                -- Skala kepala saat langsing
    SOUND_ID = "rbxassetid://132692232535882",      -- Suara lucu saat berubah
    SOUND_VOLUME = 1.5,                             -- Volume suara berubah
}

local Feature = {}

function Feature.TriggerJeky(player, duration)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local timeAdded = (duration and type(duration) == "number" and duration > 0) and duration or CONFIG.DEFAULT_DURATION
    local slimTime = player:FindFirstChild("SlimTime")
    if not slimTime then
        slimTime = Instance.new("NumberValue")
        slimTime.Name = "SlimTime"
        slimTime.Value = 0
        slimTime.Parent = player
    end
    
    slimTime.Value = slimTime.Value + timeAdded
    
    local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("StreamerProUtilEvent")
    
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        local widthScale = humanoid:FindFirstChild("BodyWidthScale")
        local depthScale = humanoid:FindFirstChild("BodyDepthScale")
        local headScale = humanoid:FindFirstChild("HeadScale")
        if not humanoid:GetAttribute("IsSlim") then
            humanoid:SetAttribute("IsSlim", true)
            humanoid:SetAttribute("OrigWidth", widthScale and widthScale.Value or 1)
            humanoid:SetAttribute("OrigDepth", depthScale and depthScale.Value or 1)
            humanoid:SetAttribute("OrigHead", headScale and headScale.Value or 1)
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sound = Instance.new("Sound")
                sound.SoundId = CONFIG.SOUND_ID
                sound.Volume = CONFIG.SOUND_VOLUME
                sound.Parent = hrp
                sound:Play()
                game:GetService("Debris"):AddItem(sound, 2)
            end
        end
        
        if remoteEvent then
            remoteEvent:FireServer("SetSlimScale", CONFIG.SLIM_WIDTH, CONFIG.SLIM_DEPTH, CONFIG.SLIM_HEAD)
        end
    else
        warn("Character must be R15 to use the Slim feature!")
    end
end

function Feature.UpdateJeky(deltaTime)
    for _, player in ipairs({Players.LocalPlayer}) do
        local slimTime = player:FindFirstChild("SlimTime")
        if slimTime and slimTime.Value > 0 then
            slimTime.Value = slimTime.Value - deltaTime
            
            if slimTime.Value <= 0 then
                slimTime.Value = 0
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid:GetAttribute("IsSlim") then
                        humanoid:SetAttribute("IsSlim", false)
                        
                        local origWidth = humanoid:GetAttribute("OrigWidth") or 1
                        local origDepth = humanoid:GetAttribute("OrigDepth") or 1
                        local origHead = humanoid:GetAttribute("OrigHead") or 1
                        
                        local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("StreamerProUtilEvent")
                        if remoteEvent then
                            remoteEvent:FireServer("SetSlimScale", origWidth, origDepth, origHead)
                        end
                    end
                end
            end
        end
    end
end

return Feature

