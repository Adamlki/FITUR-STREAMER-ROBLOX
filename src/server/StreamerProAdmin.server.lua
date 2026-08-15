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
local DataStoreService = game:GetService("DataStoreService")

local StreamerAccessDS = DataStoreService:GetDataStore("StreamerPro_AccessStore_v1")
local StreamerConfigDS = DataStoreService:GetDataStore("StreamerPro_ConfigStore_v1")

-- ==========================================
-- CONFIGURATION
-- ==========================================
-- Masukkan UserId pemain yang boleh menjadi Admin (Bisa lebih dari 1)
local CONFIG = {
    ADMIN_USER_IDS = {
        [8978185974] = true, -- Contoh
        [12345678] = true, -- Contoh
    }
}

local function getOrCreateRemoteJeky(className, name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local AdminFunc = getOrCreateRemoteJeky("RemoteFunction", "StreamerProAdminFunction")
local AccessEvent = getOrCreateRemoteJeky("RemoteEvent", "StreamerProAccessEvent")
local SaveConfigEvent = getOrCreateRemoteJeky("RemoteEvent", "StreamerProSaveConfigEvent") 
local UtilEvent = getOrCreateRemoteJeky("RemoteEvent", "StreamerProUtilEvent")

local playerAccessCache = {}
local saveConfigCooldown = {}

local function IsAdminJeky(player)
    return CONFIG.ADMIN_USER_IDS[player.UserId] == true or player.UserId == game.CreatorId
end

-- Mengecek akses player dan memberi tahu Client UI-nya
local function CheckPlayerAccessJeky(player)
    local hasAccess = false
    local success, accessData = pcall(function()
        return StreamerAccessDS:GetAsync(tostring(player.UserId))
    end)
    
    if success and accessData then
        if accessData.Expiration == -1 or accessData.Expiration > os.time() then
            hasAccess = true
        else
            pcall(function() StreamerAccessDS:RemoveAsync(tostring(player.UserId)) end)
            pcall(function() StreamerConfigDS:RemoveAsync(tostring(player.UserId)) end)
        end
    end
    
    local loadedConfig = nil
    if hasAccess then
        pcall(function()
            loadedConfig = StreamerConfigDS:GetAsync(tostring(player.UserId))
        end)
    end
    
    playerAccessCache[player.UserId] = hasAccess
    AccessEvent:FireClient(player, hasAccess, IsAdminJeky(player), loadedConfig)
end

Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    CheckPlayerAccessJeky(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playerAccessCache[player.UserId] = nil
    saveConfigCooldown[player.UserId] = nil
end)

SaveConfigEvent.OnServerEvent:Connect(function(player, configData)
    if playerAccessCache[player.UserId] then
        local lastSave = saveConfigCooldown[player.UserId] or 0
        if os.time() - lastSave < 10 then return end
        
        saveConfigCooldown[player.UserId] = os.time()
        
        pcall(function()
            StreamerConfigDS:SetAsync(tostring(player.UserId), configData)
        end)
    end
end)

UtilEvent.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}
    
    if not playerAccessCache[player.UserId] then return end
    
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

AdminFunc.OnServerInvoke = function(player, action, data)
    if not IsAdminJeky(player) then 
        return {success = false, message = "Not Authorized"} 
    end
    
    if action == "GetServerPlayers" then
        local pList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(pList, {
                UserId = p.UserId,
                Name = p.Name,
                DisplayName = p.DisplayName
            })
        end
        return {success = true, data = pList}
        
    elseif action == "SearchPlayer" then
        local username = data.Username
        local success, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        
        if success and userId then
            local thumb = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
            
            local displayName = username
            pcall(function()
                local UserService = game:GetService("UserService")
                local userInfo = UserService:GetUserInfosByUserIdsAsync({userId})
                if userInfo and userInfo[1] then
                    displayName = userInfo[1].DisplayName
                end
            end)
            
            return {
                success = true, 
                data = {
                    UserId = userId,
                    Name = username,
                    DisplayName = displayName,
                    Thumb = thumb
                }
            }
        else
            return {success = false, message = "Player tidak ditemukan!"}
        end
        
    elseif action == "GrantAccess" then
        local targetUserId = data.UserId
        local durationDays = data.DurationDays
        
        local expiration = -1
        if durationDays > 0 then
            expiration = os.time() + (durationDays * 24 * 60 * 60)
        end
        
        local success, err = pcall(function()
            StreamerAccessDS:SetAsync(tostring(targetUserId), {
                Expiration = expiration,
                GrantedBy = player.UserId,
                GrantTime = os.time()
            })
        end)
        
        if success then
            local targetPlayer = Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                CheckPlayerAccessJeky(targetPlayer)
            end
            
            pcall(function()
                StreamerAccessDS:UpdateAsync("GlobalActiveList", function(oldValue)
                    local activeList = oldValue or {}
                    local exists = false
                    for _, entry in ipairs(activeList) do
                        if entry.UserId == targetUserId then
                            entry.Expiration = expiration
                            entry.Username = data.Username or (targetPlayer and targetPlayer.Name) or tostring(targetUserId)
                            exists = true
                            break
                        end
                    end
                    
                    if not exists then
                        table.insert(activeList, {
                            UserId = targetUserId,
                            Username = data.Username or (targetPlayer and targetPlayer.Name) or tostring(targetUserId),
                            Expiration = expiration
                        })
                    end
                    return activeList
                end)
            end)
            
            return {success = true, message = "Akses berhasil diberikan!"}
        else
            return {success = false, message = "Gagal menyimpan: " .. tostring(err)}
        end
        
    elseif action == "RevokeAccess" then
        local targetUserId = data.UserId
        local success, err = pcall(function()
            StreamerAccessDS:RemoveAsync(tostring(targetUserId))
            StreamerConfigDS:RemoveAsync(tostring(targetUserId))
        end)
        
        if success then
            local targetPlayer = Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                CheckPlayerAccessJeky(targetPlayer)
            end
            
            pcall(function()
                StreamerAccessDS:UpdateAsync("GlobalActiveList", function(oldValue)
                    local activeList = oldValue or {}
                    local newList = {}
                    for _, entry in ipairs(activeList) do
                        if entry.UserId ~= targetUserId then
                            table.insert(newList, entry)
                        end
                    end
                    return newList
                end)
            end)
            
            return {success = true, message = "Akses berhasil dicabut!"}
        else
            return {success = false, message = "Gagal menghapus: " .. tostring(err)}
        end
        
    elseif action == "GetActiveStreamers" then
        local success, activeList = pcall(function()
            return StreamerAccessDS:GetAsync("GlobalActiveList") or {}
        end)
        
        if success then
            local cleanedList = {}
            local changed = false
            for _, entry in ipairs(activeList) do
                if entry.Expiration == -1 or entry.Expiration > os.time() then
                    entry.Thumb = "rbxthumb://type=AvatarHeadShot&id=" .. entry.UserId .. "&w=150&h=150"
                    
                    if entry.Expiration == -1 then
                        entry.ExpString = "Permanent"
                    else
                        local remaining = entry.Expiration - os.time()
                        local days = math.floor(remaining / (24 * 60 * 60))
                        entry.ExpString = days .. " Hari Lagi"
                    end
                    
                    table.insert(cleanedList, entry)
                else
                    changed = true
                end
            end
            
            if changed then
                pcall(function() StreamerAccessDS:SetAsync("GlobalActiveList", cleanedList) end)
            end
            
            return {success = true, data = cleanedList}
        else
            return {success = false, message = "Gagal memuat daftar: " .. tostring(activeList)}
        end
    end
end
