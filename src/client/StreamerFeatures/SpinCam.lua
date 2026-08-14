local CONFIG = {
    DEFAULT_DURATION = 10,                          -- Waktu default berputar (detik)
    SPIN_SPEED = 180,                               -- Kecepatan putaran (derajat per detik)
    ORBIT_DISTANCE = 10,                            -- Jarak kamera dari kepala
    ORBIT_HEIGHT = 2                                -- Tinggi kamera dari kepala (stud)
}

local Players = game:GetService("Players")

local Feature = {}
local spinAngle = 0
local isSpinning = false
local originalCameraType = nil

function Feature.Trigger(player, duration)
    local timeAdded = (duration and type(duration) == "number" and duration > 0) and duration or CONFIG.DEFAULT_DURATION
    local spinTime = player:FindFirstChild("SpinCamTime")
    if not spinTime then
        spinTime = Instance.new("NumberValue")
        spinTime.Name = "SpinCamTime"
        spinTime.Value = 0
        spinTime.Parent = player
    end
    
    spinTime.Value = spinTime.Value + timeAdded
end

function Feature.Update(deltaTime)
    local player = Players.LocalPlayer
    if not player then return end
    
    local spinTime = player:FindFirstChild("SpinCamTime")
    if spinTime and spinTime.Value > 0 then
        spinTime.Value = spinTime.Value - deltaTime
        
        local camera = workspace.CurrentCamera
        local character = player.Character
        local head = character and character:FindFirstChild("Head")
        
        if camera and head then
            if not isSpinning then
                isSpinning = true
                spinAngle = 0
                originalCameraType = camera.CameraType
                camera.CameraType = Enum.CameraType.Scriptable
            end
            
            spinAngle = spinAngle + math.rad(CONFIG.SPIN_SPEED * deltaTime)
            
            local headPos = head.Position
            local camPos = headPos + Vector3.new(math.sin(spinAngle) * CONFIG.ORBIT_DISTANCE, CONFIG.ORBIT_HEIGHT, math.cos(spinAngle) * CONFIG.ORBIT_DISTANCE)
            
            camera.CFrame = CFrame.new(camPos, headPos)
        end
        
        if spinTime.Value <= 0 then
            spinTime.Value = 0
            if isSpinning then
                isSpinning = false
                if camera and originalCameraType then
                    camera.CameraType = originalCameraType
                end
            end
        end
    end
end

return Feature
