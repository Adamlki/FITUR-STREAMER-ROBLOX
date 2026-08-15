-- ==========================================================
-- FITUR BY DMS STUDIO - TIKTOK : jekychen01
-- ==========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Gunakan versi DataStore agar tidak bentrok
local StreamerAccessDS = DataStoreService:GetDataStore("StreamerPro_AccessStore_v1")

-- ==========================================
-- âš™ï¸ CONFIGURATION SETTINGS
-- ==========================================
local CONFIG = {
    -- Masukkan UserId pemain yang boleh menjadi Admin (Bisa lebih dari 1)
    ADMIN_USER_IDS = {
        [8978185974] = true, -- Contoh
        -- [12345678] = true,
    }
}
-- ==========================================

-- Fungsi pembuat Remote otomatis
local function getOrCreateRemote(className, name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local AdminFunc = getOrCreateRemote("RemoteFunction", "StreamerProAdminFunction")
local AccessEvent = getOrCreateRemote("RemoteEvent", "StreamerProAccessEvent")

local playerAccessCache = {}

local function IsAdmin(player)
    return CONFIG.ADMIN_USER_IDS[player.UserId] == true or player.UserId == game.CreatorId
end

-- Mengecek akses player dan memberi tahu Client UI-nya
local function CheckPlayerAccess(player)
    local hasAccess = false
    local success, accessData = pcall(function()
        return StreamerAccessDS:GetAsync(tostring(player.UserId))
    end)
    
    if success and accessData then
        if accessData.Expiration == -1 or accessData.Expiration > os.time() then
            hasAccess = true
        else
            -- Sudah kedaluwarsa
            pcall(function() StreamerAccessDS:RemoveAsync(tostring(player.UserId)) end)
        end
    end
    
    playerAccessCache[player.UserId] = hasAccess
    
    -- Kirim event ke client (bool hasAccess, bool isAdmin)
    AccessEvent:FireClient(player, hasAccess, IsAdmin(player))
end

-- Listener ketika pemain masuk server
Players.PlayerAdded:Connect(function(player)
    -- Tunggu sebentar memastikan client siap menerima event
    task.wait(2)
    CheckPlayerAccess(player)
end)

-- API untuk Admin Panel
AdminFunc.OnServerInvoke = function(player, action, data)
    if not IsAdmin(player) then 
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
            local thumb = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            pcall(function()
                thumb = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            
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
        local durationDays = data.DurationDays -- -1 untuk permanen
        
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
            -- Jika player yang diberi fitur sedang online, langsung update UI-nya!
            local targetPlayer = Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                CheckPlayerAccess(targetPlayer)
            end
            
            -- Simpan ke list global untuk keperluan Admin Panel
            pcall(function()
                local activeList = StreamerAccessDS:GetAsync("GlobalActiveList") or {}
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
                StreamerAccessDS:SetAsync("GlobalActiveList", activeList)
            end)
            
            return {success = true, message = "Akses berhasil diberikan!"}
        else
            return {success = false, message = "Gagal menyimpan: " .. tostring(err)}
        end
        
    elseif action == "RevokeAccess" then
        local targetUserId = data.UserId
        local success, err = pcall(function()
            StreamerAccessDS:RemoveAsync(tostring(targetUserId))
        end)
        
        if success then
            local targetPlayer = Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                CheckPlayerAccess(targetPlayer)
            end
            
            pcall(function()
                local activeList = StreamerAccessDS:GetAsync("GlobalActiveList") or {}
                local newList = {}
                for _, entry in ipairs(activeList) do
                    if entry.UserId ~= targetUserId then
                        table.insert(newList, entry)
                    end
                end
                StreamerAccessDS:SetAsync("GlobalActiveList", newList)
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
                    local thumb = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                    pcall(function()
                        thumb = Players:GetUserThumbnailAsync(entry.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    end)
                    entry.Thumb = thumb
                    
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
            
            -- Jika ada yang kedaluwarsa, update list
            if changed then
                pcall(function() StreamerAccessDS:SetAsync("GlobalActiveList", cleanedList) end)
            end
            
            return {success = true, data = cleanedList}
        else
            return {success = false, message = "Gagal memuat daftar: " .. tostring(activeList)}
        end
    end
end
