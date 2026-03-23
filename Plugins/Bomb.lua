baseDirectionAwayFromWall = Vector3.new(0,0,1) end

    local cameraLook = camera.CFrame.LookVector
    local horizontalCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    if horizontalCameraLook.Magnitude < 0.1 then horizontalCameraLook = baseDirectionAwayFromWall end

    local dot = math.clamp(baseDirectionAwayFromWall:Dot(horizontalCameraLook), -1, 1)
    local angleBetween = math.acos(dot)
    local cross = baseDirectionAwayFromWall:Cross(horizontalCameraLook)
    local rotationSign = -math.sign(cross.Y)
    if rotationSign == 0 then angleBetween = 0 end

    local actualInfluenceAngle
    if rotationSign == 1 then
        actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleRight)
    elseif rotationSign == -1 then
        actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleLeft)
    else
        actualInfluenceAngle = 0
    end

    local adjustmentRotation = CFrame.Angles(0, actualInfluenceAngle * rotationSign, 0)
    local initialTargetLookDirection = adjustmentRotation * baseDirectionAwayFromWall

    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + initialTargetLookDirection)
    RunService.Heartbeat:Wait()

    local didJump = false
    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
         humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
         didJump = true
    end

    if didJump then
         local directionTowardsWall = -baseDirectionAwayFromWall
         task.wait(0.05)
         rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + directionTowardsWall)
    end

    task.wait(0.1)
    InfiniteJumpEnabled = true
end

local function SetupWallhop()
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    if wallhopEnabled then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if not wallhopEnabled then return end
            
            local wallRayResult = getWallRaycastResult()
            if wallRayResult then
                executeWallJump(wallRayResult)
            end
        end)
    end
end

local function applyHeadless(char)
    if not headlessEnabled or not char then return end
    
    if not char:FindFirstChild("Head") then
        local success, result = pcall(function()
            return char:WaitForChild("Head", 2)
        end)
        if not success then return end
    end
    
    
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") then
                v.Transparency = 1
            end
        end
    end


    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
            local handle = acc.Handle
            local weld = handle:FindFirstChildWhichIsA("Weld") or handle:FindFirstChildWhichIsA("Motor6D")
            if weld and ((weld.Part0 and weld.Part0.Name == "Head") or (weld.Part1 and weld.Part1.Name == "Head")) then
                handle.Transparency = 1
                for _, c in ipairs(handle:GetChildren()) do
                    if c:IsA("SpecialMesh") or c:IsA("Mesh") then
                        c.Transparency = 1
                    end
                end
            end
        end
    end

    
    local rightLower = char:FindFirstChild("RightLowerLeg")
    local rightUpper = char:FindFirstChild("RightUpperLeg")
    local rightFoot  = char:FindFirstChild("RightFoot")

    if rightLower then
        rightLower.MeshId = "rbxassetid://902942093"
        rightLower.Transparency = 1
    end

    if rightUpper then
        rightUpper.MeshId = "rbxassetid://902942096"
        rightUpper.TextureID = "rbxassetid://902843398"
    end

    if rightFoot then
        rightFoot.MeshId = "rbxassetid://902942089"
        rightFoot.Transparency = 1
    end
end

local function removeHeadless(char)
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") then
                v.Transparency = 0
            end
        end
    end

    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
            local handle = acc.Handle
            local weld = handle:FindFirstChildWhichIsA("Weld") or handle:FindFirstChildWhichIsA("Motor6D")
            if weld and ((weld.Part0 and weld.Part0.Name == "Head") or (weld.Part1 and weld.Part1.Name == "Head")) then
                handle.Transparency = 0
                for _, c in ipairs(handle:GetChildren()) do
                    if c:IsA("SpecialMesh") or c:IsA("Mesh") then
                        c.Transparency = 0
                    end
                end
            end
        end
    end

    local rightLower = char:FindFirstChild("RightLowerLeg")
    local rightUpper = char:FindFirstChild("RightUpperLeg")
    local rightFoot  = char:FindFirstChild("RightFoot")

    if rightLower then
        rightLower.MeshId = ""
        rightLower.Transparency = 0
    end

    if rightUpper then
        rightUpper.MeshId = ""
        rightUpper.TextureID = ""
    end

    if rightFoot then
        rightFoot.MeshId = ""
        rightFoot.Transparency = 0
    end
end

local function SetupHeadless()
    
    for _, connection in pairs(headlessConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    headlessConnections = {}
    
    if headlessEnabled then

        if LocalPlayer.Character then
            applyHeadless(LocalPlayer.Character)
        end
        

        local charAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            if headlessEnabled then
                char:WaitForChild("HumanoidRootPart")
                applyHeadless(char)
            end
        end)
        table.insert(headlessConnections, charAddedConnection)
        

        local humanoidAddedConnection
        humanoidAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            local diedConnection = humanoid.Died:Connect(function()
                task.wait(0.5) -- Small delay after death
                if headlessEnabled and LocalPlayer.Character then
                    applyHeadless(LocalPlayer.Character)
                end
            end)
            table.insert(headlessConnections, diedConnection)
        end)
        table.insert(headlessConnections, humanoidAddedConnection)
    else
        
        if LocalPlayer.Character then
            removeHeadless(LocalPlayer.Character)
        end
    end
end

local function SaveOriginalLighting()
    originalLightingSettings = {
        Brightness = Lighting.Brightness,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        ExposureCompensation = Lighting.ExposureCompensation,
        ShadowSoftness = Lighting.ShadowSoftness,
        Ambient = Lighting.Ambient
    }
end

local function RestoreOriginalLighting()
    for setting, value in pairs(originalLightingSettings) do
        if Lighting[setting] ~= nil then
            Lighting[setting] = value
        end
    end
end

local function CreateAllEffects()
    for _, effect in pairs(shaderEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    shaderEffects = {}
    
    local Bloom = Instance.new("BloomEffect")
    Bloom.Intensity = 0.1
    Bloom.Threshold = 0
    Bloom.Size = 100
    Bloom.Name = "RTX_Bloom1"
    Bloom.Parent = Lighting
    shaderEffects["Bloom1"] = Bloom
    
    -- Tropic Sky
    local Tropic = Instance.new("Sky")
    Tropic.Name = "Tropic"
    Tropic.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
    Tropic.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
    Tropic.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
    Tropic.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
    Tropic.StarCount = 100
    Tropic.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
    Tropic.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
    Tropic.Parent = Lighting
    shaderEffects["TropicSky"] = Tropic
    
    -- Second Sky
    local Sky = Instance.new("Sky")
    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=196263782"
    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=196263721"
    Sky.SkyboxBk = "http://www.roblox.com/asset/?id=196263721"
    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=196263721"
    Sky.CelestialBodiesShown = false
    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=196263643"
    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=196263721"
    Sky.Parent = Lighting
    shaderEffects["NightSky"] = Sky
    
    -- Second Bloom Effect
    local Bloom2 = Instance.new("BloomEffect")
    Bloom2.Enabled = false
    Bloom2.Intensity = 0.35
    Bloom2.Threshold = 0.2
    Bloom2.Size = 56
    Bloom2.Name = "RTX_Bloom2"
    Bloom2.Parent = Lighting
    shaderEffects["Bloom2"] = Bloom2
    
    -- Blur Effect
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 2
    Blur.Name = "RTX_Blur"
    Blur.Parent = Lighting
    shaderEffects["Blur"] = Blur
    
    -- Color Correction Effects
    local Inaritaisha = Instance.new("ColorCorrectionEffect")
    Inaritaisha.Name = "Inari taisha"
    Inaritaisha.Saturation = 0.05
    Inaritaisha.TintColor = Color3.fromRGB(255, 224, 219)
    Inaritaisha.Parent = Lighting
    shaderEffects["Inari"] = Inaritaisha
    
    local SunRays = Instance.new("SunRaysEffect")
    SunRays.Intensity = 0.05
    SunRays.Name = "RTX_SunRays"
    SunRays.Parent = Lighting
    shaderEffects["SunRays"] = SunRays
    
    -- Sunset Sky
    local Sunset = Instance.new("Sky")
    Sunset.Name = "Sunset"
    Sunset.SkyboxUp = "rbxassetid://323493360"
    Sunset.SkyboxLf = "rbxassetid://323494252"
    Sunset.SkyboxBk = "rbxassetid://323494035"
    Sunset.SkyboxFt = "rbxassetid://323494130"
    Sunset.SkyboxDn = "rbxassetid://323494368"
    Sunset.SunAngularSize = 14
    Sunset.SkyboxRt = "rbxassetid://323494067"
    Sunset.Parent = Lighting
    shaderEffects["SunsetSky"] = Sunset
    
    local Takayama = Instance.new("ColorCorrectionEffect")
    Takayama.Name = "Takayama"
    Takayama.Saturation = -0.3
    Takayama.Contrast = 0.1
    Takayama.TintColor = Color3.fromRGB(235, 214, 204)
    Takayama.Parent = Lighting
    shaderEffects["Takayama"] = Takayama
    
    Lighting.Brightness = 2.14
    Lighting.ColorShift_Bottom = Color3.fromRGB(11, 0, 20)
    Lighting.ColorShift_Top = Color3.fromRGB(240, 127, 14)
    Lighting.OutdoorAmbient = Color3.fromRGB(34, 0, 49)
    Lighting.ClockTime = 6.7
    Lighting.FogColor = Color3.fromRGB(94, 76, 106)
    Lighting.FogEnd = 1000
    Lighting.FogStart = 0
    Lighting.ExposureCompensation = 0.24
    Lighting.ShadowSoftness = 0
    Lighting.Ambient = Color3.fromRGB(59, 33, 27)
end

local function RemoveAllEffects()
    for _, effect in pairs(shaderEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    shaderEffects = {}
    

    RestoreOriginalLighting()
end

local function EnableSunsetMode()
    RemoveAllEffects()
    
    local Sunset = Instance.new("Sky")
    Sunset.Name = "Sunset"
    Sunset.SkyboxUp = "rbxassetid://323493360"
    Sunset.SkyboxLf = "rbxassetid://323494252"
    Sunset.SkyboxBk = "rbxassetid://323494035"
    Sunset.SkyboxFt = "rbxassetid://323494130"
    Sunset.SkyboxDn = "rbxassetid://323494368"
    Sunset.SunAngularSize = 14
    Sunset.SkyboxRt = "rbxassetid://323494067"
    Sunset.Parent = Lighting
    shaderEffects["SunsetSky"] = Sunset
    
    -- Sunset lighting
    Lighting.Brightness = 2.14
    Lighting.ClockTime = 18.5
    Lighting.FogColor = Color3.fromRGB(94, 76, 106)
    Lighting.FogEnd = 1000
    
    print("Sunset mode enabled")
end

local function EnableTropicMode()
    RemoveAllEffects()
    
    -- Tropic Sky
    local Tropic = Instance.new("Sky")
    Tropic.Name = "Tropic"
    Tropic.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
    Tropic.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
    Tropic.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
    Tropic.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
    Tropic.StarCount = 100
    Tropic.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
    Tropic.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
    Tropic.Parent = Lighting
    shaderEffects["TropicSky"] = Tropic
    
    -- Tropic lighting
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogColor = Color3.fromRGB(140, 180, 200)
    
    print("Tropic mode enabled")
end

local function EnableNightMode()
    RemoveAllEffects()
    
    -- Night Sky
    local Sky = Instance.new("Sky")
    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=196263782"
    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=196263721"
    Sky.SkyboxBk = "http://www.roblox.com/asset/?id=196263721"
    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=196263721"
    Sky.CelestialBodiesShown = true
    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=196263643"
    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=196263721"
    Sky.Parent = Lighting
    shaderEffects["NightSky"] = Sky
    
    -- Night lighting
    Lighting.Brightness = 1.5
    Lighting.ClockTime = 0
    Lighting.FogColor = Color3.fromRGB(20, 20, 40)
    
    print("Night mode enabled")
end

local function EnableBloomMode()
    RemoveAllEffects()
    
    -- Bloom Effect
    local Bloom = Instance.new("BloomEffect")
    Bloom.Intensity = 0.2
    Bloom.Threshold = 0.15
    Bloom.Size = 80
    Bloom.Name = "Bloom"
    Bloom.Parent = Lighting
    shaderEffects["Bloom"] = Bloom
    
    -- Blur Effect
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 2
    Blur.Name = "Blur"
    Blur.Parent = Lighting
    shaderEffects["Blur"] = Blur
    
    print("Bloom mode enabled")
end

local function EnableRTXMode()
    RemoveAllEffects()
    CreateAllEffects()
    print("Full RTX mode enabled")
end

local function DisableShaders()
    RemoveAllEffects()
    print("All shaders disabled")
end

-- Main toggles
section:AddToggle("Fake Bomb Clutch", function(bool)
    pluginEnabled = bool
    if bool then
        CreateGUI()
        SetupInputSystem()
    else
        if ScreenGui then
            ScreenGui:Destroy()
            ScreenGui = nil
        end
        ResetCooldown()
    end
end)

section:AddToggle("WallHop", function(bool)
    wallhopEnabled = bool
    SetupWallhop()
end)

section:AddToggle("Headless", function(bool)
    headlessEnabled = bool
    SetupHeadless()
end)

section:AddButton("Sunset Mode", function()
    EnableSunsetMode()
end)

section:AddButton("Tropic Mode", function()
    EnableTropicMode()
end)

section:AddButton("Night Mode", function()
    EnableNightMode()
end)

section:AddButton("Bloom Mode", function()
    EnableBloomMode()
end)

section:AddButton("FULL RTX Mode", function()
    EnableRTXMode()
end)

section:AddButton("Disable Shaders", function()
    DisableShaders()
end)

section:AddButton("Reset clutch button", function()
    if MainFrame and pluginEnabled then
        MainFrame.Position = UDim2.new(0, 20, 0, 20)
    end
end)

section:AddKeybind("Fake Bomb keybind", "E", function()
    if pluginEnabled and not onCooldown and not debounce then
        FastBombJump()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    ResetCooldown()
    InfiniteJumpEnabled = true
    if headlessEnabled and LocalPlayer.Character then
        task.wait(0.1) 
        applyHeadless(LocalPlayer.Character)
    end
end)

local function Cleanup()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    

    for _, connection in pairs(headlessConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    headlessConnections = {}
    
    if LocalPlayer.Character then
        removeHeadless(LocalPlayer.Character)
    end
    
    DisableShaders()
    
    ResetCooldown()
    pluginEnabled = false
    wallhopEnabled = false
    headlessEnabled = false
end
