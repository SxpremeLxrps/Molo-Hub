-- [[ SERVICES ]]

local Player: Player = game:GetService("Players").LocalPlayer  
local Players: Players = game:GetService("Players")  
local RS: RunService = game:GetService("RunService")  
local ReplicatedStorage: Instance = game:GetService("ReplicatedStorage")  
local Mouse: Mouse = Player:GetMouse()  
local MouseTarget: Instance? = Mouse.Target  
local MouseHit: CFrame = Mouse.Hit  
local UIS: UserInputService = game:GetService("UserInputService")  
local Camera: Camera = workspace:WaitForChild("Camera")  
local TweenService: TweenService = game:GetService("TweenService")  
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")  
local Stats: Stats = game:GetService("Stats")

-- [[ VARIABLES ]]

local SilentAim: boolean = true  
local ESPEnabled: boolean = false  
local FOVCircleRunning: boolean = false  
local ScriptVarLib: {any}? = nil  
local CurrentTarget: Instance? = nil  
local InjectionAttempted: boolean = false  
local Ping: number = Player:GetNetworkPing()  
local VelocityHistory: {Vector3} = {}

-- [[ ENVIRONMENT ]]

getgenv().FOV = 150  
getgenv().AimKey = "C"  
getgenv().ESPKey = "M"  
getgenv().DontShootThesePeople = {}  
getgenv().BasePrediction = 0.18  
getgenv().MinPrediction = 0.08  
getgenv().MaxPrediction = 0.35

-- [[ DRAWING MODULE FALLBACK ]]

local Drawing: {any}  
local DrawingSuccess: boolean = pcall(function()  
	Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/MoloAPI"))()  
end)

if not DrawingSuccess then  
	Drawing = {  
		new = function(ShapeType: string): any  
			if ShapeType == "Circle" then  
				return {  
					Visible = true,  
					Color = Color3.new(1, 0, 0),  
					Thickness = 1.5,  
					Transparency = 0.5,  
					Radius = 150,  
					Filled = false,  
					Position = Vector2.new(0, 0),  
					Remove = function() end  
				}  
			else  
				return {  
					Visible = false,  
					Remove = function() end  
				}  
			end  
		end  
	}  
end

-- [[ FOV CIRCLE ]]

local FOV_Circle: Drawing = Drawing.new("Circle")  
FOV_Circle.Visible = true  
FOV_Circle.Color = Color3.fromRGB(255, 8, 169)  
FOV_Circle.Thickness = 1.5  
FOV_Circle.Transparency = 0.5  
FOV_Circle.Radius = getgenv().FOV  
FOV_Circle.Filled = false  
FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local Options: {[string]: string} = {  
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

	local CurrentPing: number = Player:GetNetworkPing()  
	local PredictionTime: number = math.clamp(  
		getgenv().BasePrediction + (CurrentPing / 1000),  
		getgenv().MinPrediction,  
		getgenv().MaxPrediction  
	)

	return SmoothedVelocity * PredictionTime  
end

local function GetBestTarget(): (Instance?, number)  
	local BestDistance: number = math.huge  
	local BestTarget: Instance? = nil

	for _, PlayerInstance: Player in pairs(Players:GetPlayers()) do  
		if not table.find(getgenv().DontShootThesePeople, PlayerInstance.Name) then  
			if PlayerInstance ~= Player and PlayerInstance.Character then  
				local Humanoid: Humanoid? = PlayerInstance.Character:FindFirstChild("Humanoid")  
				local HumanoidRootPart: BasePart? = PlayerInstance.Character:FindFirstChild("HumanoidRootPart")

				if Humanoid and HumanoidRootPart and Humanoid.Health > 0 then  
					local ScreenPosition: Vector3, OnScreen: boolean = Camera:WorldToScreenPoint(HumanoidRootPart.Position)  
					if OnScreen then  
						local MousePosition: Vector2 = Vector2.new(Mouse.X, Mouse.Y)  
						local TargetPosition: Vector2 = Vector2.new(ScreenPosition.X, ScreenPosition.Y)  
						local DistanceMagnitude: number = (MousePosition - TargetPosition).Magnitude

						if DistanceMagnitude < BestDistance and DistanceMagnitude < FOV_Circle.Radius then  
							BestDistance = DistanceMagnitude  
							BestTarget = PlayerInstance.Character  
						end  
					end  
				end  
			end  
		end  
	end

	return BestTarget, BestDistance  
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
				if Param2 == "mouse" and SilentAim and CurrentTarget then  
					local HumanoidRootPart: BasePart? = CurrentTarget:FindFirstChild("HumanoidRootPart")  
					if HumanoidRootPart then  
						local PredictionOffset: Vector3 = CalculateDynamicPrediction(HumanoidRootPart)  
						return HumanoidRootPart.Position + PredictionOffset + Vector3.new(0, -1, 0)  
					end  
				end  
				return OriginalInv(Param1, Param2)  
			end

			local MainEvent: RemoteEvent? = ReplicatedStorage:FindFirstChild("MAINEVENT")

			if MainEvent then  
				local OriginalFireServer: (any, any, ...any) -> any = MainEvent.FireServer

				MainEvent.FireServer = function(Self: any, EventType: any, EventData: any, ...): any  
					if EventType == "MOUSE" and SilentAim and CurrentTarget then  
						local HumanoidRootPart: BasePart? = CurrentTarget:FindFirstChild("HumanoidRootPart")  
						if HumanoidRootPart then  
							local PredictionOffset: Vector3 = CalculateDynamicPrediction(HumanoidRootPart)  
							EventData = HumanoidRootPart.Position + PredictionOffset  
						end  
					end  
					return OriginalFireServer(Self, EventType, EventData, ...)  
				end  
			end  
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

local function StopFOVCircle(): ()  
	FOVCircleRunning = false  
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
		ESPEnabled = not ESPEnabled  
		if ESPEnabled then  
			for _, PlayerInstance: Player in Players:GetPlayers() do  
				local Character: Model? = PlayerInstance.Character or PlayerInstance.CharacterAdded:Wait()  
				if Character and not Character:FindFirstChild("MoloHubHighlight") then  
					local Highlight: Highlight = Instance.new("Highlight")  
					Highlight.Name = "MoloHubHighlight"  
					Highlight.Adornee = Character  
					Highlight.FillColor = Color3.fromRGB(255, 0, 0)  
					Highlight.Parent = Character  
				end  
			end  
		else  
			for _, PlayerInstance: Player in Players:GetPlayers() do  
				local Character: Model? = PlayerInstance.Character  
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

-- [[ METAMETHOD HOOK ]]

local OriginalIndex: (Self: Instance, Index: string) -> any

OriginalIndex = hookmetamethod(game, "__index", function(Self: Instance, Index: string): any  
	if Self == Mouse and Index == "Target" then  
		return MouseTarget  
	end

	if Self == Mouse and Index == "Hit" and SilentAim then  
		local TargetCandidate: Instance?  
		local TargetDistance: number  
		TargetCandidate, TargetDistance = GetBestTarget()

		if TargetCandidate then  
			CurrentTarget = TargetCandidate  
			local HumanoidRootPart: BasePart? = TargetCandidate:FindFirstChild("HumanoidRootPart")  
			if HumanoidRootPart then  
				local PredictionOffset: Vector3 = CalculateDynamicPrediction(HumanoidRootPart)  
				return CFrame.new(HumanoidRootPart.CFrame.Position + PredictionOffset + Vector3.new(0, -1, 0))  
			end  
		else  
			CurrentTarget = nil  
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
