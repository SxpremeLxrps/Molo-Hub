-- [[ SERVICES ]]

local Player: Player = game:GetService("Players").LocalPlayer  
local Players: Players = game:GetService("Players")  
local ReplicatedStorage: Instance = game:GetService("ReplicatedStorage")  
local Mouse: Mouse = Player:GetMouse()  
local UIS: UserInputService = game:GetService("UserInputService")  
local Camera: Camera = workspace:WaitForChild("Camera")  
local TweenService: TweenService = game:GetService("TweenService")  
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")  
local Stats: Stats = game:GetService("Stats")

-- [[ VARIABLES ]]

local SilentAim: boolean = true  
local FOVCircleRunning: boolean = false  
local ScriptVarLib: {any}? = nil  
local CurrentTarget: Model? = nil  
local CurrentTargetPlayer: Player? = nil  
local InjectionAttempted: boolean = false  
local VelocityHistory: {[Player]: {{Velocity: Vector3, Time: number}}} = {}
local LastTargetUpdate: number = 0  
local TargetUpdateInterval: number = 0.05
local CurrentTargetBodyPart: BasePart? = nil
local CurrentTargetScore: number = -math.huge

-- [[ ENVIRONMENT ]]

getgenv().FOV = 150  
getgenv().AimKey = "C"  
getgenv().ESPKey = "M"  
getgenv().DontShootThesePeople = {}  
getgenv().BasePrediction = 0.18  
getgenv().MinPrediction = 0.08  
getgenv().MaxPrediction = 0.35  
getgenv().TargetBodyParts = {"HumanoidRootPart", "Head", "UpperTorso"} :: {string}


-- [[ UI SETUP ]]


local TweenService: TweenService = game:GetService("TweenService")
local Players: Players = game:GetService("Players")
local Player: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")

-- // Root

local ScreenGui: ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoloHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Container: Frame = Instance.new("Frame")
Container.Name = "Container"
Container.AnchorPoint = Vector2.new(0.5, 0.5)
Container.Position = UDim2.new(0.5, 0, 0.15, -12) -- starts slightly higher, slides down
Container.Size = UDim2.fromOffset(560, 154)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

-- // Glass card behind everything

local Card: Frame = Instance.new("Frame")
Card.Name = "Card"
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.Position = UDim2.new(0.5, 0, 0.5, 0)
Card.Size = UDim2.fromScale(1, 1)
Card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Card.BackgroundTransparency = 1 -- animated in
Card.BorderSizePixel = 0
Card.Parent = Container

local CardCorner: UICorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 20)
CardCorner.Parent = Card

local CardStroke: UIStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1
CardStroke.Transparency = 1 -- animated in
CardStroke.Color = Color3.fromRGB(255, 255, 255)
CardStroke.Parent = Card

local CardStrokeGradient: UIGradient = Instance.new("UIGradient")
CardStrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 170, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 170, 255)),
})
CardStrokeGradient.Rotation = 90
CardStrokeGradient.Parent = CardStroke

-- // Glow behind the cog (circular gradient blob)

local Glow: Frame = Instance.new("Frame")
Glow.Name = "Glow"
Glow.AnchorPoint = Vector2.new(0.5, 0.5)
Glow.Position = UDim2.new(0, 44, 0.5, 0)
Glow.Size = UDim2.fromOffset(70, 70)
Glow.BackgroundColor3 = Color3.fromRGB(140, 130, 255)
Glow.BackgroundTransparency = 1 -- animated in
Glow.BorderSizePixel = 0
Glow.ZIndex = 1
Glow.Parent = Container

local GlowCorner: UICorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(1, 0)
GlowCorner.Parent = Glow

local GlowGradient: UIGradient = Instance.new("UIGradient")
GlowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 90, 255)),
})
GlowGradient.Parent = Glow

-- // Cog

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
Cog.ZIndex = 2
Cog.Parent = Container

-- // Title / subtitle

local TitleLabel: TextLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
TitleLabel.Position = UDim2.new(0, 100, 0, 34)
TitleLabel.Size = UDim2.new(1, -120, 0, 46)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Welcome to Molo Hub"
TitleLabel.TextTransparency = 1
TitleLabel.TextStrokeTransparency = 1
TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 2
TitleLabel.Parent = Container

local SubtitleLabel: TextLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.AnchorPoint = Vector2.new(0, 0.5)
SubtitleLabel.Position = UDim2.new(0, 100, 0, 76)
SubtitleLabel.Size = UDim2.new(1, -120, 0, 26)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = string.format("Logged in as %s", Player.DisplayName)
SubtitleLabel.TextTransparency = 1
SubtitleLabel.TextStrokeTransparency = 1
SubtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
SubtitleLabel.TextScaled = true
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 2
SubtitleLabel.Parent = Container

-- // Accent line

local AccentLine: Frame = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.AnchorPoint = Vector2.new(0, 0.5)
AccentLine.Position = UDim2.new(0, 100, 0, 104)
AccentLine.Size = UDim2.fromOffset(0, 2)
AccentLine.BorderSizePixel = 0
AccentLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AccentLine.BackgroundTransparency = 0.2
AccentLine.ZIndex = 2
AccentLine.Parent = Container

local AccentCorner: UICorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(1, 0)
AccentCorner.Parent = AccentLine

local AccentGradient: UIGradient = Instance.new("UIGradient")
AccentGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 90, 255)),
})
AccentGradient.Parent = AccentLine

-- // Loading indicator

local LoadingLabel: TextLabel = Instance.new("TextLabel")
LoadingLabel.Name = "LoadingLabel"
LoadingLabel.AnchorPoint = Vector2.new(0, 0.5)
LoadingLabel.Position = UDim2.new(0, 100, 0, 122)
LoadingLabel.Size = UDim2.new(1, -120, 0, 20)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.Text = "Loading Da Aim Trainer Lock"
LoadingLabel.TextTransparency = 1
LoadingLabel.TextStrokeTransparency = 1
LoadingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
LoadingLabel.TextScaled = true
LoadingLabel.Font = Enum.Font.GothamMedium
LoadingLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
LoadingLabel.TextXAlignment = Enum.TextXAlignment.Left
LoadingLabel.ZIndex = 2
LoadingLabel.Parent = Container

local IsLoadingTextActive: boolean = true

local function AnimateLoadingText(): ()
	local Dots: number = 0
	while IsLoadingTextActive do
		LoadingLabel.Text = "Loading" .. string.rep(".", Dots)
		Dots = (Dots + 1) % 4
		task.wait(0.4)
	end
end

local EntranceSound: Sound = Instance.new("Sound")
EntranceSound.Name = "EntranceSound"
EntranceSound.SoundId = "rbxassetid://4883181281"
EntranceSound.Volume = 0.6
EntranceSound.Parent = Container

local ExitSound: Sound = Instance.new("Sound")
ExitSound.Name = "ExitSound"
ExitSound.SoundId = "rbxassetid://9125661989" -- placeholder: soft UI whoosh
ExitSound.Volume = 0.4
ExitSound.Parent = Container

local EntranceInfo: TweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FadeInInfo: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FadeOutInfo: TweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local LineGrowInfo: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SpinInfo: TweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local ContainerSlideIn: Tween = TweenService:Create(Container, EntranceInfo, {
	Position = UDim2.new(0.5, 0, 0.15, 0),
})

local CardFadeIn: Tween = TweenService:Create(Card, FadeInInfo, {
	BackgroundTransparency = 0.15,
})

local CardStrokeFadeIn: Tween = TweenService:Create(CardStroke, FadeInInfo, {
	Transparency = 0.3,
})

local GlowFadeIn: Tween = TweenService:Create(Glow, FadeInInfo, {
	BackgroundTransparency = 0.75,
})

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

local LoadingFadeIn: Tween = TweenService:Create(LoadingLabel, FadeInInfo, {
	TextTransparency = 0.3,
	TextStrokeTransparency = 0.7,
})

local LineGrow: Tween = TweenService:Create(AccentLine, LineGrowInfo, {
	Size = UDim2.fromOffset(360, 2),
})

-- // Exit tweens

local CardFadeOut: Tween = TweenService:Create(Card, FadeOutInfo, { BackgroundTransparency = 1 })
local CardStrokeFadeOut: Tween = TweenService:Create(CardStroke, FadeOutInfo, { Transparency = 1 })
local GlowFadeOut: Tween = TweenService:Create(Glow, FadeOutInfo, { BackgroundTransparency = 1 })
local CogFadeOut: Tween = TweenService:Create(Cog, FadeOutInfo, { ImageTransparency = 1 })
local TitleFadeOut: Tween = TweenService:Create(TitleLabel, FadeOutInfo, {
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})
local SubtitleFadeOut: Tween = TweenService:Create(SubtitleLabel, FadeOutInfo, {
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})
local LoadingFadeOut: Tween = TweenService:Create(LoadingLabel, FadeOutInfo, {
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})
local LineShrink: Tween = TweenService:Create(AccentLine, FadeOutInfo, {
	Size = UDim2.fromOffset(0, 2),
})

local SpinTween: Tween = TweenService:Create(Cog, SpinInfo, {
	Rotation = 360,
})

-- // Sequence

EntranceSound:Play()
ContainerSlideIn:Play()
CardFadeIn:Play()
CardStrokeFadeIn:Play()
GlowFadeIn:Play()
CogFadeIn:Play()
TitleFadeIn:Play()
SpinTween:Play()
task.spawn(AnimateLoadingText)

CogFadeIn.Completed:Wait()
task.wait(0.1)

SubtitleFadeIn:Play()
LoadingFadeIn:Play()
LineGrow:Play()
LineGrow.Completed:Wait()

task.wait(1.5)

ExitSound:Play()
IsLoadingTextActive = false
CardFadeOut:Play()
CardStrokeFadeOut:Play()
GlowFadeOut:Play()
CogFadeOut:Play()
TitleFadeOut:Play()
SubtitleFadeOut:Play()
LoadingFadeOut:Play()
LineShrink:Play()
TitleFadeOut.Completed:Wait()
SpinTween:Cancel()


if EntranceSound.IsPlaying then
	EntranceSound.Ended:Wait()
end
if ExitSound.IsPlaying then
	ExitSound.Ended:Wait()
end

ScreenGui:Destroy()


-- [[ DRAWING FALLBACK ]]

local Drawing: {any} = {}
local DrawingSuccess: boolean = false

local Success: boolean, Result: any = pcall(function()
	return loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/MoloAPI" 
		))() 
end) 
 
if Success and Result then 
	Drawing = Result 
	DrawingSuccess = true 
	print("[MoloHub] MoloAPI loaded successfully") 
else 
	warn("[MoloHub] MoloAPI failed:", Result) 
end 
 
if not DrawingSuccess then 
	error("[MoloHub] Could not initialize Drawing API") 
end 
 
print("[MoloHub] About to create FOV circle") 
 
local FOV_Circle: any = Drawing.new("Circle") 
 
print("[MoloHub] FOV circle created:", FOV_Circle) 
 
FOV_Circle.Visible = true 
FOV_Circle.Color = Color3.fromRGB(255, 8, 169) 
FOV_Circle.Thickness = 1.5 
FOV_Circle.Transparency = 0.5 
FOV_Circle.Radius = getgenv().FOV 
FOV_Circle.Filled = false 
FOV_Circle.Position = UIS:GetMouseLocation() 
 
print("[MoloHub] FOV circle configured") 
 
-- [[ FOV CIRCLE ]] 
 
local FOV_Circle: Drawing = Drawing.new("Circle")   
FOV_Circle.Visible = true   
FOV_Circle.Color = Color3.fromRGB(255, 8, 169)   
FOV_Circle.Thickness = 1.5   
FOV_Circle.Transparency = 0.5   
FOV_Circle.Radius = getgenv().FOV   
FOV_Circle.Filled = false   
FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) 
 
-- [[ LOCAL FUNCTIONS ]] 
 
local function CalculateDynamicPrediction(TargetPlayer: Player, TargetPart: BasePart): Vector3 
	local CurrentTime: number = os.clock() 
	local CurrentVelocity: Vector3 = TargetPart.AssemblyLinearVelocity 
 
	local History = VelocityHistory[TargetPlayer] 
 
	if not History then 
		History = {} 
		VelocityHistory[TargetPlayer] = History 
	end 
 
	table.insert(History, { 
		Velocity = CurrentVelocity, 
		Time = CurrentTime, 
	}) 
 
	while #History > 5 do 
		table.remove(History, 1) 
	end 
 
	local SmoothedVelocity: Vector3 = Vector3.zero 
 
	for _, Sample in ipairs(History) do 
		SmoothedVelocity += Sample.Velocity 
	end 
 
	if #History > 0 then 
		SmoothedVelocity /= #History 
	end 
 
	local Acceleration: Vector3 = Vector3.zero 
 
	if #History >= 2 then 
		local Previous = History[#History - 1] 
		local DeltaTime: number = CurrentTime - Previous.Time 
 
		if DeltaTime > 0 then 
			Acceleration = (CurrentVelocity - Previous.Velocity) / DeltaTime 
		end 
	end 
 
	local Ping: number = Player:GetNetworkPing() 
 
	local Distance: number = 
		(TargetPart.Position - Camera.CFrame.Position).Magnitude 
 
	local DistanceFactor: number = Distance / 100 
 
	local PredictionTime: number = math.clamp( 
		getgenv().BasePrediction 
			+ Ping 
			+ (DistanceFactor * 0.001), 
		getgenv().MinPrediction, 
		getgenv().MaxPrediction 
	) 
 
	return (SmoothedVelocity * PredictionTime) + (Acceleration * PredictionTime ^ 2 * 0.5) 
end 
 
local function HasLineOfSight(StartPosition: Vector3, EndPosition: Vector3, TargetCharacter: Model, IgnoreList: {Instance}): boolean 
	local RaycastParams: RaycastParams = RaycastParams.new() 
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude 
	RaycastParams.FilterDescendantsInstances = IgnoreList 
 
	local Direction: Vector3 = EndPosition - StartPosition 
 
	if Direction.Magnitude <= 0 then 
		return true 
	end 
 
	local Result: RaycastResult? = workspace:Raycast( 
		StartPosition, 
		Direction, 
		RaycastParams 
	) 
 
	if not Result then 
		return true 
	end 
 
	return Result.Instance:IsDescendantOf(TargetCharacter) 
end 
 
local function GetBestTarget(): (Player?, Model?, BasePart?, number)   
	local CurrentTime: number = os.clock()  
	 
	if CurrentTime - LastTargetUpdate < TargetUpdateInterval then 
		return CurrentTargetPlayer, CurrentTarget, CurrentTargetBodyPart, CurrentTargetScore 
	end 
 
	LastTargetUpdate = CurrentTime 
 
	local Character: Model? = Player.Character   
	local CameraPosition: Vector3 = Camera.CFrame.Position 
 
	local BestPlayer: Player? = nil   
	local BestCharacter: Model? = nil   
	local BestBodyPart: BasePart? = nil   
	local BestScore: number = -math.huge 
 
	for _, PlayerInstance: Player in Players:GetPlayers() do   
		if PlayerInstance == Player   
			or table.find(getgenv().DontShootThesePeople, PlayerInstance.Name) then   
			continue   
		end 
 
		local TargetCharacter: Model? = PlayerInstance.Character   
		if not TargetCharacter then   
			continue   
		end 
 
		local Humanoid: Humanoid? = TargetCharacter:FindFirstChildOfClass("Humanoid")   
		if not Humanoid or Humanoid.Health <= 0 then   
			continue   
		end 
 
		local BestPartScore: number = -math.huge   
		local BestPart: BasePart? = nil 
 
		for _, BodyPartName: string in ipairs(getgenv().TargetBodyParts) do   
			local BodyPart: BasePart? = TargetCharacter:FindFirstChild(BodyPartName)   
			if not BodyPart then   
				continue   
			end 
 
			local ScreenPosition: Vector3, OnScreen: boolean = Camera:WorldToScreenPoint(BodyPart.Position)   
			if not OnScreen then   
				continue   
			end 
 
			local MousePosition: Vector2 = Vector2.new(Mouse.X, Mouse.Y)   
			local TargetPosition: Vector2 = Vector2.new(ScreenPosition.X, ScreenPosition.Y)   
			local DistanceToScreen: number = (MousePosition - TargetPosition).Magnitude 
 
			if DistanceToScreen > FOV_Circle.Radius then   
				continue   
			end 
 
			local Distance3D: number = (BodyPart.Position - CameraPosition).Magnitude   
			local FOVDistanceRatio: number = DistanceToScreen / FOV_Circle.Radius   
			local DistanceScore: number = 1000 / (Distance3D + 1)   
			local FOVScore: number = (1 - FOVDistanceRatio) * 500   
			local PartScore: number = DistanceScore + FOVScore 
 
			if BodyPartName == "Head" then   
				PartScore = PartScore * 1.5   
			elseif BodyPartName == "HumanoidRootPart" then   
				PartScore = PartScore * 1.2   
			end 
 
			if HasLineOfSight(CameraPosition, BodyPart.Position, TargetCharacter, {Character}) then 
				PartScore *= 2 
			end 
 
			if PartScore > BestPartScore then   
				BestPartScore = PartScore   
				BestPart = BodyPart   
			end   
		end 
 
		if BestPartScore > BestScore then   
			BestScore = BestPartScore   
			BestPlayer = PlayerInstance   
			BestCharacter = TargetCharacter   
			BestBodyPart = BestPart   
		end   
	end 
 
	CurrentTargetPlayer = BestPlayer 
	CurrentTarget = BestCharacter 
	CurrentTargetBodyPart = BestBodyPart 
	CurrentTargetScore = BestScore 
 
	return BestPlayer, BestCharacter, BestBodyPart, BestScore   
end 
 
local function GetTargetPosition(): Vector3?   
	local TargetPlayer: Player?   
	local TargetCharacter: Model?   
	local TargetBodyPart: BasePart?   
	local Score: number 
 
	TargetPlayer, TargetCharacter, TargetBodyPart, Score = GetBestTarget() 
 
	if not TargetPlayer or not TargetCharacter or not TargetBodyPart then   
		return nil   
	end 
 
	local PredictionOffset: Vector3 = CalculateDynamicPrediction(TargetPlayer, TargetBodyPart) 
	 
	return TargetBodyPart.Position + PredictionOffset   
end 
 
local function InjectGameHooks(): ()   
	if InjectionAttempted then   
		return   
	end 
 
	InjectionAttempted = true 
 
	local CharacterScript: Instance? = Player.Character and Player.Character:FindFirstChildWhichIsA("Script")   
	if not CharacterScript then   
		repeat task.wait() until Player.Character   
		CharacterScript = Player.Character:FindFirstChildWhichIsA("Script")   
	end 
 
	if CharacterScript and CharacterScript:FindFirstChild("VarLib") then   
		local Success: boolean, ModuleResult: {any} = pcall(function()   
			ScriptVarLib = require(CharacterScript.VarLib)   
		end) 
 
		if Success and ScriptVarLib and ScriptVarLib.inv then   
			local OriginalInv: (any, any) -> any = ScriptVarLib.inv.OnClientInvoke 
 
			ScriptVarLib.inv.OnClientInvoke = function(Param1: any, Param2: any): any   
				if Param2 == "mouse" and SilentAim then   
					local TargetPosition: Vector3? = GetTargetPosition()   
					if TargetPosition then   
						return TargetPosition 
					end   
				end   
				return OriginalInv(Param1, Param2)   
			end 
		end   
	end 
 
	local MainEvent: RemoteEvent? = ReplicatedStorage:FindFirstChild("MAINEVENT")   
	if MainEvent then   
		local OriginalFireServer: (any, any, ...any) -> any = MainEvent.FireServer 
 
		MainEvent.FireServer = function(Self: any, EventType: any, EventData: any, ...): any   
			if EventType == "MOUSE" and SilentAim then   
				local TargetPosition: Vector3? = GetTargetPosition()   
				if TargetPosition then   
					EventData = TargetPosition   
				end   
			end   
			return OriginalFireServer(Self, EventType, EventData, ...)   
		end 
	end 
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
 
-- [[ INPUT HANDLING ]] 
 
UIS.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean) 
	if GameProcessed then 
		return 
	end 
 
	if Input.UserInputType ~= Enum.UserInputType.Keyboard then 
		return 
	end 
 
	local Key: string = Input.KeyCode.Name:lower() 
 
	if Key == getgenv().ESPKey:lower() then 
		ESP:Toggle() 
	end 
 
	if Key == getgenv().AimKey:lower() then   
		SilentAim = not SilentAim   
		InjectGameHooks() 
 
		if SilentAim then   
			FOV_Circle.Color = Color3.fromRGB(255, 255, 255)   
		else   
			FOV_Circle.Color = Color3.fromRGB(255, 8, 169)   
		end   
	end   
end) 
 
-- [[ METAMETHOD HOOK ]] 
 
local OriginalIndex: (Self: Instance, Index: string) -> any   
OriginalIndex = hookmetamethod(game, "__index", function(Self: Instance, Index: string): any   
	if Self == Mouse and Index == "Hit" and SilentAim then   
		local TargetPosition: Vector3? = GetTargetPosition()   
		if TargetPosition then   
			return CFrame.new(TargetPosition)   
		end   
	end   
	return OriginalIndex(Self, Index)   
end) 
 
-- [[ INITIALIZATION ]] 
 
MoveFOVCircle()   
InjectGameHooks() 
 
Player.CharacterAdded:Connect(function()   
	InjectionAttempted = false   
	task.wait(2)   
	InjectGameHooks()   
end) 
 
Players.PlayerRemoving:Connect(function(PlayerInstance: Player)   
	VelocityHistory[PlayerInstance] = nil   
end) 
