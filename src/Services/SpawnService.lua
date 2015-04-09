local SpawnService = {}
-- spawnservice handles chcreate

local ClothingService,Communicator

function SpawnService:Constructor()
	ClothingService = _G.Instinct.Services.ClothingService
	Communicator = _G.Instinct.Communicator
end

function SpawnService:ConvertPlayer(Player, Data)
	warn("IN CV")
		-- first undo player of all nonsense.
	local char = Player.Character
	local rem = {
		CharacterAppearance = true; Hat = true; BodyColors = true;
	}
	local function Recurse(r)
		for _,child in pairs(r:GetChildren()) do
			for class in pairs(rem) do
				if child:IsA(class) then
					child:Destroy()
				end
			end
			Recurse(child)
		end
	end
	Recurse(char)
	-- strapped of.

	local function SetSkinColor(color)	
		for _,part in pairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				part.BrickColor = color
			end
		end
	end
	SetSkinColor(BrickColor.new "Pastel brown" )
	Communicator:Send(Player, "SetSkinColor", "Pastel brown")	
	
	local Backpack = ClothingService:GetCloth "Backpack"
	local RPants = ClothingService:GetCloth "RightPants"
	local LPants = ClothingService:GetCloth "LeftPants"
	local Shirt = ClothingService:GetCloth "Shirt"
	warn ( " --- " )
	print(Backpack, RPants, LPants, Shirt)
	
	for _, cloth in pairs {Backpack, RPants, LPants, Shirt} do
		local cl = cloth.Root:Clone()
		warn(cloth.Name)
		ClothingService:WearCloth(cloth.Name, cl, Player)
	end
end

function SpawnService:SpawnPlayer(Player)
	local SpawnLocations = {CFrame.new(103.624123, 16.1699066, -382.141144), CFrame.new(-216.283875, 16.1974716, -980.819397)}
	local loc = SpawnLocations[math.random(1, #SpawnLocations)]
	delay(0, function()
		for i = 1, 10 do 
			Player.Character.Torso.CFrame = loc
			wait()
		end
	end)
end



function SpawnService:CreateCorpse(Player)
	local Character = Player.Character 
	local clone = Instance.new("Model")
	clone.Name = Player.Name
	for i,v in pairs(Character:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			for ind, val in pairs(v:GetChildren()) do
				if val:IsA("JointInstance") then
					val:Destroy()
				end
			end
			local a = v:Clone()
			a.Parent = clone
			a.CanCollide = true
			a.Velocity = Vector3.new(0,0,0)
		end
	end
	local welds = {
		["Left Hip"] = {
			Part0 = "Torso",
			Part1 = "Left Leg"
		},
		["Left Shoulder"] = {
			Part0 = "Torso",
			Part1 = "Left Arm"
		},
		["Right Shoulder"] = {
			Part0 = "Torso",
			Part1 = "Right Arm"
		},
		["Right Hip"] = {
			Part0 = "Torso",
			Part1 = "Right Leg"
		},
		["Neck"] = {
			Part0 = "Torso",
			Part1 = "Head"
		}
	}	
	
	for i,v in pairs(welds) do
		local cpy = game:GetService("ServerStorage").WeldCache[i]
		local new = Instance.new("Rotate", clone.Torso)
		new.Part0 = clone[v.Part0]
		new.Part1 = clone[v.Part1]
		new.C0 = cpy.C0
		new.C1 = cpy.C1
	end
	-- hax start
	if Character:FindFirstChild("Clothing") then 
		for i,v in pairs(Character:FindFirstChild("Clothing"):GetChildren()	) do
			local cloth = ClothingService:GetCloth(v.Name)
			if cloth then
				ClothingService:WearCloth(cloth.Name, cloth.Root:Clone(), {Character = clone})
			end
		end
	end
	-- hax end
	Character:Destroy()
	wait(0.25)
	clone.Parent = game.Workspace.Corpses
	return clone
end

return SpawnService