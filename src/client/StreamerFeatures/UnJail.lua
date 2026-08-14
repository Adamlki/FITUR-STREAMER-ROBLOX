
local Feature = {}

function Feature.Trigger(player, duration)
    local jailTime = player:FindFirstChild("JailTime")
    if jailTime then
        jailTime.Value = jailTime.Value - duration
        if jailTime.Value <= 0 then
            jailTime.Value = 0
        end
    end
end

return Feature

