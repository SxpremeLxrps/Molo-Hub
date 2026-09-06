-- [[ SERVICES ]]

local Player: Player = game:GetService("Players").LocalPlayer
local Players: Players = game:GetService("Players")
local RS: RunService= game:GetService("RunService")
local Mouse: Mouse = Player:GetMouse()
local MouseTarget: Instance? = Mouse.Target
local MouseHit: CFrame = Mouse.Hit
local UIS: UserInputService = game:GetService("UserInputService")
local Camera: Camera = workspace:WaitForChild("Camera")
local TweenService: TweenService = game:GetService("TweenService") 
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")
local Stats: Stats = game:GetService("Stats")
local SilentAim: boolean = true
local ESPEnabled: boolean = false
local FOVCircleRunning: boolean = false

-- [[ MODULES ]]

local Drawing: {any} = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/MoloAPI"))()
local Ping: number = Player:GetNetworkPing()
local VelocityHistory: {any} = {}  


-- [[ ENVIRONMENT ]]

getgenv().FOV = 150
getgenv().AimKey = "C"
getgenv().ESPKey = "M"
getgenv().DontShootThesePeople = {}
getgenv().BasePrediction = 0.18
getgenv().MinPrediction = 0.08
getgenv().MaxPrediction = 0.35


-- [[ CONSTANTS & UI CREATION VIA @ MOLOAPI ]]

-- // Container
local ScreenGui: ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoloHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Container: Frame = Instance.new("Frame")
Container.Name = "Container"
Container.AnchorPoint = Vector2.new(0.5, 0.5)
Container.Position = UDim2.new(0.5, 0, 0.15, 0)
Container.Size = UDim2.fromOffset(560, 140)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

local Cog: ImageLabel = Instance.new("ImageLabel")
Cog.Name = "Cog"
Cog.AnchorPoint = Vector2.new(0.5, 0.5)
Cog.Position = UDim2.new(0, 44, 0.5, 0)
Cog.Size = UDim2.fromOffset(56, 56)
Cog.BackgroundTransparency = 1
Cog.Image = "rbxassetid://3926305904"
Cog.ImageRectOffset = Vector2.new(884, 764)
Cog.ImageRectSize = Vector2.new(36, 36)
Cog.ImageTransparency = 1
Cog.ImageColor3 = Color3.fromRGB(255, 255, 255)
Cog.Parent = Container

local TitleLabel: TextLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
TitleLabel.Position = UDim2.new(0, 100, 0, 34)
TitleLabel.Size = UDim2.new(1, -110, 0, 46)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Welcome to Molo Hub"
TitleLabel.TextTransparency = 1
TitleLabel.TextStrokeTransparency = 1
TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Container

local SubtitleLabel: TextLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.AnchorPoint = Vector2.new(0, 0.5)
SubtitleLabel.Position = UDim2.new(0, 100, 0, 74)
SubtitleLabel.Size = UDim2.new(1, -110, 0, 28)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = string.format("Logged in as %s", Player.DisplayName)
SubtitleLabel.TextTransparency = 1
SubtitleLabel.TextStrokeTransparency = 1
SubtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
SubtitleLabel.TextScaled = true
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = Container

local AccentLine: Frame = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.AnchorPoint = Vector2.new(0, 0.5)
AccentLine.Position = UDim2.new(0, 100, 0, 104)
AccentLine.Size = UDim2.fromOffset(0, 2)
AccentLine.BorderSizePixel = 0
AccentLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
AccentLine.BackgroundTransparency = 0.2
AccentLine.Parent = Container

local AccentGradient: UIGradient = Instance.new("UIGradient")
AccentGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 90, 255)),
})
AccentGradient.Parent = AccentLine

local FadeInInfo: TweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FadeOutInfo: TweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local LineGrowInfo: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CogFadeIn: Tween = TweenService:Create(Cog, FadeInInfo, {
	ImageTransparency = 0,
})

local TitleFadeIn: Tween = TweenService:Create(TitleLabel, FadeInInfo, {
	TextTransparency = 0,
	TextStrokeTransparency = 0.5,
})

local SubtitleFadeIn: Tween = TweenService:Create(SubtitleLabel, FadeInInfo, {
	TextTransparency = 0,
	TextStrokeTransparency = 0.6,
})

local LineGrow: Tween = TweenService:Create(AccentLine, LineGrowInfo, {
	Size = UDim2.fromOffset(360, 2),
})

local CogFadeOut: Tween = TweenService:Create(Cog, FadeOutInfo, {
	ImageTransparency = 1,
})

local TitleFadeOut: Tween = TweenService:Create(TitleLabel, FadeOutInfo, {
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})

local SubtitleFadeOut: Tween = TweenService:Create(SubtitleLabel, FadeOutInfo, {
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})

local LineShrink: Tween = TweenService:Create(AccentLine, FadeOutInfo, {
	Size = UDim2.fromOffset(0, 2),
})

local IsSpinning: boolean = true

local function SpinCog(): ()
	while IsSpinning do
		Cog.Rotation = (Cog.Rotation + 4) % 360
		task.wait()
	end
end

task.spawn(SpinCog)

-- // Sequence

CogFadeIn:Play()
TitleFadeIn:Play()
CogFadeIn.Completed:Wait()
task.wait(0.1)
SubtitleFadeIn:Play()
LineGrow:Play()
LineGrow.Completed:Wait()
task.wait(1.5)
CogFadeOut:Play()
TitleFadeOut:Play()
SubtitleFadeOut:Play()
LineShrink:Play()
TitleFadeOut.Completed:Wait()
IsSpinning = false
ScreenGui:Destroy()

local FOV_Circle: Drawing = Drawing.new("Circle")
FOV_Circle.Visible = true
FOV_Circle.Color = Color3.fromRGB(255, 8, 169)
FOV_Circle.Thickness = 1.5
FOV_Circle.Transparency = 1
FOV_Circle.Radius = getgenv().FOV
FOV_Circle.Filled = false
FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local Options: {any} = {
	Torso = "HumanoidRootPart",
	Head = "HumanoidRootPart"
}

-- [[ LOCAL FUNCTIONS ]]

local function CalculateDynamicPrediction(HumanoidRootPart: BasePart): Vector3
	local CurrentVelocity: Vector3 = HumanoidRootPart.AssemblyLinearVelocity

	table.insert(VelocityHistory, CurrentVelocity)

	if #VelocityHistory > 5 then
		table.remove(VelocityHistory, 1)
	end

	local SmoothedVelocity: Vector3 = Vector3.zero

	for _, Velocity: Vector3 in ipairs(VelocityHistory) do
		SmoothedVelocity += Velocity
	end

	SmoothedVelocity /= #VelocityHistory

	local Ping: number = Player:GetNetworkPing()

	local PredictionTime: number = math.clamp(
		getgenv().BasePrediction + Ping,
		getgenv().MinPrediction,
		getgenv().MaxPrediction
	)

	return SmoothedVelocity * PredictionTime
end

local function MoveFOVCircle(): ()

	if FOVCircleRunning then
		return
	end

	FOVCircleRunning = true

	task.spawn(function()
		while FOVCircleRunning do
			local MousePosition: Vector2 = UIS:GetMouseLocation()

			FOV_Circle.Position = MousePosition
			task.wait()
		end
	end)
end

local function StopFOVCircle(): ()
	FOVCircleRunning = false
end

UIS.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
	if GameProcessed then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	local Key: string = Input.KeyCode.Name:lower()

	if Key == getgenv().ESPKey:lower() then
		ESPEnabled = not ESPEnabled
		if ESPEnabled then
			for _, V: Player in Players:GetPlayers() do
				local Character: Model? = V.Character or V.CharacterAdded:Wait()

				if Character and not Character:FindFirstChild("MoloHubHighlight") then
					local Highlight: Highlight = Instance.new("Highlight")
					Highlight.Name = "MoloHubHighlight"
					Highlight.Adornee = Character
					Highlight.FillColor = Color3.fromRGB(255, 0, 0)
					Highlight.Parent = Character
				end
			end
		else
			for _, V: Player in Players:GetPlayers() do
				local Character: Model? = V.Character

				if Character then
					for _, Object: Instance in Character:GetChildren() do
						if Object:IsA("Highlight") and Object.Name == "MoloHubHighlight" then
							Object:Destroy()
						end
					end
				end
			end
		end
	end

	if Key == getgenv().AimKey:lower() then
		SilentAim = not SilentAim

		if SilentAim then
			FOV_Circle.Color = Color3.fromRGB(255, 255, 255)
		else
			FOV_Circle.Color = Color3.fromRGB(255, 8, 169)
		end
	end
end)

local OriginalIndex: (Self: Instance, Index: string) -> any  

OriginalIndex = hookmetamethod(game, "__index", function(Self: Instance, Index: string): any  
	if Self == Mouse and Index == "Target" then  
		return MouseTarget  
	end

	if Self == Mouse and Index == "Hit" and SilentAim then  
		local Distance: number = 9e9  
		local Target: Instance? = nil

		for _, PlayerInstance: Player in pairs(Players:GetPlayers()) do  
			if not table.find(getgenv().DontShootThesePeople, PlayerInstance.Name) then  
				if PlayerInstance ~= Player and PlayerInstance.Character then  
					local Humanoid: Humanoid? = PlayerInstance.Character:FindFirstChild("Humanoid")  
					local HumanoidRootPart: BasePart? = PlayerInstance.Character:FindFirstChild("HumanoidRootPart")

					if Humanoid and HumanoidRootPart and Humanoid.Health > 0 then  
						local CastingFrom: CFrame = CFrame.new(  
							Camera.CFrame.Position,  
							HumanoidRootPart.CFrame.Position  
						) * CFrame.new(0, 0, -4)

						local RayCast: Ray = Ray.new(  
							CastingFrom.Position,  
							CastingFrom.LookVector * 9000  
						)

						local PartPosition: Vector3, OnScreen: boolean = Camera:WorldToScreenPoint(HumanoidRootPart.Position)

						if OnScreen then  
							local Magnitude: number = (  
								Vector2.new(Mouse.X, Mouse.Y) -   
									Vector2.new(PartPosition.X, PartPosition.Y)  
							).Magnitude

							if Magnitude < Distance and Magnitude < FOV_Circle.Radius then  
								Distance = Magnitude  
								Target = PlayerInstance.Character  
							end  
						end  
					end  
				end  
			end  
		end

		if Target then  
			local HumanoidRootPart: BasePart? = Target:FindFirstChild("HumanoidRootPart")  
			if HumanoidRootPart then  
				local PredictionOffset: Vector3 = CalculateDynamicPrediction(HumanoidRootPart)  
				return CFrame.new(  
					HumanoidRootPart.CFrame.Position +   
						PredictionOffset +   
						Vector3.new(0, -1, 0)  
				)  
			end  
		end  
	end

	return OriginalIndex(Self, Index)  
end)
MoveFOVCircle()
