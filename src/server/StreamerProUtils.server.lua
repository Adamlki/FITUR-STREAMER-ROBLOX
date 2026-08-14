local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local eventName = "StreamerProUtilEvent"
local remoteEvent = ReplicatedStorage:FindFirstChild(eventName)

if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = eventName
    remoteEvent.Parent = ReplicatedStorage
end

remoteEvent.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}
    
    if action == "SetSlimScale" then
        local width = args[1]
        local depth = args[2]
        local head = args[3]
        
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
                local widthScale = humanoid:FindFirstChild("BodyWidthScale") or Instance.new("NumberValue", humanoid)
                widthScale.Name = "BodyWidthScale"
                widthScale.Value = width
                
                local depthScale = humanoid:FindFirstChild("BodyDepthScale") or Instance.new("NumberValue", humanoid)
                depthScale.Name = "BodyDepthScale"
                depthScale.Value = depth
                
                local headScale = humanoid:FindFirstChild("HeadScale") or Instance.new("NumberValue", humanoid)
                headScale.Name = "HeadScale"
                headScale.Value = head
            end
        end
    end
end)
