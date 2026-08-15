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
local CONFIG = {
    DEFAULT_DURATION = 15,                          -- Waktu default efek mabuk (detik)
    BLUR_SIZE = 15,                                 -- Tingkat keburaman layar (blur)
    SWAY_INTENSITY = 0.5                            -- Tingkat goyangan kamera
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Feature = {}
local isDrunk = false
local blurEffect = nil

function Feature.TriggerJeky(player, duration)
    local timeAdded = (duration and type(duration) == "number" and duration > 0) and duration or CONFIG.DEFAULT_DURATION
    local drunkTime = player:FindFirstChild("DrunkTime")
    if not drunkTime then
        drunkTime = Instance.new("NumberValue")
        drunkTime.Name = "DrunkTime"
        drunkTime.Value = 0
        drunkTime.Parent = player
    end
    
    drunkTime.Value = drunkTime.Value + timeAdded
end

function Feature.UpdateJeky(deltaTime)
    local player = Players.LocalPlayer
    if not player then return end
    
    local drunkTime = player:FindFirstChild("DrunkTime")
    if drunkTime and drunkTime.Value > 0 then
        drunkTime.Value = drunkTime.Value - deltaTime
        
        if not isDrunk then
            isDrunk = true
            blurEffect = Instance.new("BlurEffect")
            blurEffect.Size = 0
            blurEffect.Parent = Lighting
            TweenService:Create(blurEffect, TweenInfo.new(1), {Size = CONFIG.BLUR_SIZE}):Play()
        end
        
        local camera = workspace.CurrentCamera
        if camera then
            local t = tick()
            local swayX = math.sin(t * 3) * CONFIG.SWAY_INTENSITY
            local swayY = math.cos(t * 4) * CONFIG.SWAY_INTENSITY
            local swayZ = math.sin(t * 2) * CONFIG.SWAY_INTENSITY
            
            -- Apply subtle sway to camera
            camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(swayX), math.rad(swayY), math.rad(swayZ))
        end
        
        if drunkTime.Value <= 0 then
            drunkTime.Value = 0
            isDrunk = false
            if blurEffect then
                TweenService:Create(blurEffect, TweenInfo.new(1), {Size = 0}):Play()
                game:GetService("Debris"):AddItem(blurEffect, 1.1)
                blurEffect = nil
            end
        end
    end
end

return Feature
