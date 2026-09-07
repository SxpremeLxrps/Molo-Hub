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
local ESPEnabled: boolean = false  
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


-- [[ DRAWING FALLBACK ]]

local Drawing: {any}  
local ESP: {any} = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/ESP"))()
local DrawingSuccess: boolean = false

local function InitializeDrawing(): ()  
	DrawingSuccess = pcall(function()  
		Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/SxpremeLxrps/Molo-Hub/main/MoloAPI"))()  
	end)

	if not DrawingSuccess then  
		Drawing = {  
			new = function(ShapeType: string): any  
				if ShapeType == "Circle" then  
					local Circle = Instance.new("ImageLabel")  
					Circle.Name = "FOVCircle"  
					Circle.Parent = PlayerGui  
					Circle.Position = UDim2.new(0.5, 0, 0.5, 0)  
					Circle.Size = UDim2.new(0, 300, 0, 300)  
					Circle.BackgroundTransparency = 1  
					Circle.Image = "rbxasset://textures/ui/Cursors/StarCursor.png"  
					Circle.ImageTransparency = 0.3

					return {  
						Visible = true,  
						Color = Color3.new(1, 0, 0),  
						Thickness = 1.5,  
						Transparency = 0.5,  
						Radius = 150,  
						Filled = false,  
						Position = Vector2.new(0, 0),  
						Remove = function()  
							Circle:Destroy()  
						end  
					}  
				end  
			end  
		}  
	end  
end

InitializeDrawing()

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
