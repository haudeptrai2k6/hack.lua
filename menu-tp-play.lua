local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- GIAO DIỆN (UI) AUTO TP
-- ==========================================
-- Xóa GUI cũ nếu đã tồn tại
pcall(function()
    if CoreGui:FindFirstChild("AutoTpGUI") then
        CoreGui.AutoTpGUI:Destroy()
    end
end)
if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("AutoTpGUI") then
    LocalPlayer.PlayerGui.AutoTpGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTpGUI"
ScreenGui.ResetOnSpawn = false 

local success = pcall(function() 
    ScreenGui.Parent = CoreGui 
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 275)
MainFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Nút Đóng [X]
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame

-- Nút Thu nhỏ / Phóng to [-]
local MinMaxBtn = Instance.new("TextButton")
MinMaxBtn.Size = UDim2.new(0, 30, 0, 30)
MinMaxBtn.Position = UDim2.new(1, -60, 0, 0)
MinMaxBtn.BackgroundTransparency = 1
MinMaxBtn.Text = "-"
MinMaxBtn.Font = Enum.Font.GothamBold
MinMaxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinMaxBtn.TextSize = 18
MinMaxBtn.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TELEPORT PLAYER"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Nơi chứa danh sách người chơi
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 0, 150)
ScrollFrame.Position = UDim2.new(0, 10, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 4)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -20, 0, 25)
RefreshBtn.Position = UDim2.new(0, 10, 0, 195)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RefreshBtn.Text = "CẬP NHẬT DANH SÁCH"
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextColor3 = Color3.new(1, 1, 1)
RefreshBtn.TextSize = 12
RefreshBtn.Parent = MainFrame
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

local TpOnceBtn = Instance.new("TextButton")
TpOnceBtn.Size = UDim2.new(0.5, -15, 0, 35)
TpOnceBtn.Position = UDim2.new(0, 10, 0, 230)
TpOnceBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
TpOnceBtn.Text = "TP 1 LẦN"
TpOnceBtn.Font = Enum.Font.GothamBold
TpOnceBtn.TextColor3 = Color3.new(1, 1, 1)
TpOnceBtn.TextSize = 12
TpOnceBtn.Parent = MainFrame
Instance.new("UICorner", TpOnceBtn).CornerRadius = UDim.new(0, 4)

local AutoTpBtn = Instance.new("TextButton")
AutoTpBtn.Size = UDim2.new(0.5, -15, 0, 35)
AutoTpBtn.Position = UDim2.new(0.5, 5, 0, 230)
AutoTpBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
AutoTpBtn.Text = "AUTO TP [TẮT]"
AutoTpBtn.Font = Enum.Font.GothamBold
AutoTpBtn.TextColor3 = Color3.new(1, 1, 1)
AutoTpBtn.TextSize = 12
AutoTpBtn.Parent = MainFrame
Instance.new("UICorner", AutoTpBtn).CornerRadius = UDim.new(0, 4)

-- ==========================================
-- LOGIC XỬ LÝ (TÍNH NĂNG)
-- ==========================================
local targetPlayer = nil
local autoTpEnabled = false
local heartbeatConnection = nil
local playerAddedConn = nil
local playerRemovingConn = nil
local isMinimized = false

-- Cập nhật Text cho Tiêu đề
local function updateTitleText()
    if isMinimized then
        if targetPlayer then
            Title.Text = targetPlayer.DisplayName
            Title.TextColor3 = Color3.fromRGB(0, 255, 150)
        else
            Title.Text = "Chưa chọn ai"
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    else
        Title.Text = "TELEPORT PLAYER"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- Hàm tạo danh sách người chơi
local function populateList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            
            if targetPlayer == p then
                btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            else
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            
            btn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
            btn.Font = Enum.Font.Gotham
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 11
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.Parent = ScrollFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                targetPlayer = p
                
                for _, childBtn in pairs(ScrollFrame:GetChildren()) do
                    if childBtn:IsA("TextButton") then
                        childBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    end
                end
                
                btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
                updateTitleText()
            end)
        end
    end
end

populateList()

-- Hàm Dịch chuyển an toàn
local function teleportToTarget()
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChild("Humanoid")
    
    if targetHRP and targetHum and targetHum.Health > 0 and myHRP and myHum and myHum.Health > 0 then
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    end
end

-- ==========================================
-- SỰ KIỆN NÚT BẤM
-- ==========================================

MinMaxBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MinMaxBtn.Text = "+"
        ScrollFrame.Visible = false
        RefreshBtn.Visible = false
        
        TpOnceBtn.Position = UDim2.new(0, 10, 0, 35)
        AutoTpBtn.Position = UDim2.new(0.5, 5, 0, 35)
        
        MainFrame.Size = UDim2.new(0, 220, 0, 80)
    else
        MinMaxBtn.Text = "-"
        ScrollFrame.Visible = true
        RefreshBtn.Visible = true
        
        TpOnceBtn.Position = UDim2.new(0, 10, 0, 230)
        AutoTpBtn.Position = UDim2.new(0.5, 5, 0, 230)
        
        MainFrame.Size = UDim2.new(0, 220, 0, 275)
    end
    updateTitleText()
end)

CloseBtn.MouseButton1Click:Connect(function()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    if playerAddedConn then playerAddedConn:Disconnect() end
    if playerRemovingConn then playerRemovingConn:Disconnect() end
    ScreenGui:Destroy()
end)

RefreshBtn.MouseButton1Click:Connect(populateList)

TpOnceBtn.MouseButton1Click:Connect(function()
    if targetPlayer then
        teleportToTarget()
    else
        Title.Text = "CHƯA CHỌN AI!"
        Title.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(1.5)
        updateTitleText()
    end
end)

AutoTpBtn.MouseButton1Click:Connect(function()
    if not targetPlayer then
        Title.Text = "CHƯA CHỌN AI!"
        Title.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(1.5)
        updateTitleText()
        return
    end
    
    autoTpEnabled = not autoTpEnabled
    if autoTpEnabled then
        AutoTpBtn.Text = "AUTO TP [BẬT]"
        AutoTpBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        AutoTpBtn.Text = "AUTO TP [TẮT]"
        AutoTpBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end)

heartbeatConnection = RunService.Heartbeat:Connect(function()
    if autoTpEnabled and targetPlayer then
        teleportToTarget()
    end
end)

-- ==========================================
-- TỰ ĐỘNG CẬP NHẬT KHI CÓ NGƯỜI VÀO / RA
-- ==========================================

playerAddedConn = Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    populateList()
end)

playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
    if player == targetPlayer then
        targetPlayer = nil
        autoTpEnabled = false
        AutoTpBtn.Text = "AUTO TP [TẮT]"
        AutoTpBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        updateTitleText()
    end
    populateList()
end)
