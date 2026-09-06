_G.Prediction = 0.18 -- | Ping will be affected by this, be aware
_G.FOV = 150
_G.AimKey = "C"
_G.ESPKey = "M"
_G.DontShootThesePeople = {}

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
local SilentAim: boolean = true
local ESPEnabled: boolean = false
local FOVCircleRunning: boolean = false

-- [[ MODULES ]]

local Drawing: {any} = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/MoloAPI"
))()
-- [[ CONSTANTS & UI CREATION VIA @ MOLOAPI ]]


local ScreenGui: ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoloHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
local WelcomeLabel: TextLabel = Instance.new("TextLabel")
WelcomeLabel.Name = "WelcomeLabel"
WelcomeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
WelcomeLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
WelcomeLabel.Size = UDim2.fromOffset(400, 60)
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Text = "Welcome to Molo Hub"
local OW: Sound = Instance.new("Sound")
OW.Parent = workspace
OW:Play()
OW.Volume = 1
WelcomeLabel.TextTransparency = 1
WelcomeLabel.TextStrokeTransparency = 1
WelcomeLabel.TextScaled = true
WelcomeLabel.Font = Enum.Font.GothamBold
WelcomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeLabel.Parent = ScreenGui

local FadeIn: Tween = TweenService:Create(
	WelcomeLabel,
	TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{
		TextTransparency = 0,
		TextStrokeTransparency = 0.5
	}
)

local FadeOut: Tween = TweenService:Create(
	WelcomeLabel,
	TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}
)

FadeIn:Play()
FadeIn.Completed:Wait()
task.wait(2)
FadeOut:Play()
FadeOut.Completed:Wait()
ScreenGui:Destroy()

local FOV_Circle: Drawing = Drawing.new("Circle")
FOV_Circle.Visible = true
FOV_Circle.Color = Color3.fromRGB(255, 8, 169)
FOV_Circle.Thickness = 1.5
FOV_Circle.Transparency = 1
FOV_Circle.Radius = _G.FOV
FOV_Circle.Filled = false
FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local Options: {any} = {
	Torso = "HumanoidRootPart",
	Head = "HumanoidRootPart"
}

-- [[ LOCAL FUNCTIONS ]]

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

	if Key == _G.ESPKey:lower() then
		ESPEnabled = not ESPEnabled
		if ESPEnabled then
			for _, V: Player in Players:GetPlayers() do
				local Character: Model? = V.Character or V.CharacterAdded:Wait()

				if Character and not Character:FindFirstChild("MoloHubHighlight") then
					local Highlight: Highlight = Instance.new("Highlight")
					Highlight.Name = "MoloHubHighlight"
					Highlight.Adornee = Character
					Highlight.FillColor = Color3.fromRGB(255, 51, 0)
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

	if Key == _G.AimKey:lower() then
		SilentAim = not SilentAim

		if SilentAim then
			FOV_Circle.Color = Color3.fromRGB(255, 255, 255)
		else
			FOV_Circle.Color = Color3.fromRGB(255, 8, 169)
		end
	end
end)

local __index: (Self: Instance, Index: string) -> any

__index = hookmetamethod(game, "__index", function(Self, Index)
	if Self == Mouse and Index == "Target" then
		return MouseTarget
	end

	if Self == Mouse and Index == "Hit" and SilentAim then
		local Distance: number = 9e9
		local Target: Instance = nil

		for _, V: Player in pairs(Players:GetPlayers()) do
			if not table.find(_G.DontShootThesePeople, V.Name) then
				if V ~= Player and V.Character then
					local Humanoid: Humanoid = V.Character:WaitForChild("Humanoid")
					local HumanoidRootPart: BasePart = V.Character:WaitForChild("HumanoidRootPart")

					if Humanoid and HumanoidRootPart and Humanoid.Health > 0 then
						local CastingFrom: CFrame = CFrame.new(Camera.CFrame.Position, HumanoidRootPart.CFrame.Position) * CFrame.new(0, 0, -4)

						local RayCast: Ray = Ray.new(
							CastingFrom.Position,
							CastingFrom.LookVector * 9000
						)

						local PartPosition: Vector3, OnScreen: boolean = Camera:WorldToScreenPoint(HumanoidRootPart.Position)

						if OnScreen then
							local Magnitude: number = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(PartPosition.X, PartPosition.Y)).Magnitude
							if Magnitude < Distance and Magnitude < FOV_Circle.Radius then
								Distance = Magnitude
								Target = V.Character
							end
						end
					end
				end
			end
		end

		if Target then
			local HumanoidRootPart: BasePart = Target:WaitForChild("HumanoidRootPart")

			if HumanoidRootPart then
				local PredictionOffset: Vector3 = HumanoidRootPart.AssemblyLinearVelocity * _G.Prediction
				
				return CFrame.new(HumanoidRootPart.CFrame.Position + PredictionOffset + Vector3.new(0, -1, 0))
			end
		end
	end
	
	return __index(Self, Index)
end)

MoveFOVCircle()
