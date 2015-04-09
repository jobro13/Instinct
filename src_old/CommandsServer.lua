local Commands = {}

local ObjectService = Instinct.Include "Services/ObjectService"
local Chat = Instinct.Include "Chat"
local DiscoveryService = Instinct.Include "Services/DiscoveryService"
local Tool = Instinct.Include "Action/Tool"
local ToolService = Instinct.Include "Services/ToolService"
local Object = Instinct.Include "Action/Object"

function Commands.DoPlayerDamage(Data, Target, Damage, Critical)
	if Target then
		local p = game.Players:GetPlayerFromCharacter(Target)
		if p then
			local hval = game:GetService("ReplicatedStorage"):WaitForChild("LocalPlayerData"):WaitForChild(tostring(p.userId)):WaitForChild("Stats"):WaitForChild("Health")
			hval.Value = hval.Value - Damage
		end
	end
end

function Commands.Chat(Data, Message)
	if Message == "" or Message:match("%S") == nil then
		return -- wat dafaq
	end
	print("HELLO")
	local Communicator = Instinct.Communicator
	local Player = Data.Player
	local Torso = Player.Character and Player.Character:FindFirstChild("Torso")
	if not Torso then return end
	local EnergyTap, Range, Mode, Message = Chat:GetAttributes(Message)	
	local get = game:GetService("ReplicatedStorage")
	local loc = (get:FindFirstChild("LocalPlayerData") and get.LocalPlayerData:FindFirstChild(tostring(Player.userId)) and get.LocalPlayerData[tostring(Player.userId)]:FindFirstChild("Stats") and get.LocalPlayerData[tostring(Player.userId)]:FindFirstChild("Stats"):FindFirstChild("Energy"))
	if not loc then return end
	if loc.Value - EnergyTap < 0 then
		Chat:Send("You don't have enough energy to do that!", Player)
		return
	end
	loc.Value = loc.Value - EnergyTap
	for i,v in pairs(game.Players:GetPlayers()) do
		if v.Character and v.Character:FindFirstChild("Torso") then
			if (v.Character.Torso.Position - Torso.Position).magnitude <= Range then
				Communicator:Send(v, "Chat", Message, Mode, Player.Name)
			end
		end
	end
	
end

function Commands.AddToBackpack(Data, item)
	if not item:IsDescendantOf(game.Workspace) then
		return -- what in the world!?
	end
	print("INTOADD", item:GetFullName())
	local p = Data.Player
	local bp = game:GetService("ReplicatedStorage"):WaitForChild("LocalPlayerData"):WaitForChild(tostring(p.userId)):WaitForChild("Backpack")
	
	-- ERMAGEWD	

	ObjectService:ToBackpack(item, bp)
	DiscoveryService:SetDiscovery("Resource", Data.Player, item.Name)

end

function Commands.Drop(Data, item)
	local p = Data.Player
	local char = p.Character
	if item.Parent:IsDescendantOf(game:GetService("ReplicatedStorage").LocalPlayerData) then 
		if char then
			if char:FindFirstChild("Torso") then
				local cf = char.Torso.CFrame
				local move = cf * CFrame.new(0,4,0)
				ObjectService:DropItem(item, move.p)
			end
		end
	end
	
end

local ToolEquipData = {} 
local ToolDropContainer = {}

function Commands.EquipTool(Data, Root, Hand, Grip)
	if not Root or not Hand then return end
	print(Grip)
	local Grip  = Grip
	if not Grip then Grip = CFrame.new() end
	local c = Root:Clone()
	if not game.Workspace:FindFirstChild("Garbage") then 
		Instance.new("Model", game.Workspace).Name = "Garbage"
	end 
	if not game.Workspace.Garbage:FindFirstChild("Tools") then
		Instance.new("Model", game.Workspace.Garbage).Name = "Tools"
	end
	if not game.Workspace.Garbage.Tools:FindFirstChild(Data.Player.Name) then
		Instance.new("Model", game.Workspace.Garbage.Tools).Name = Data.Player.Name
	end
	local weldto
	if Data.Player.Character then
		if Hand == "Left" then
			weldto = Data.Player.Character:FindFirstChild("Left Arm")
		elseif Hand == "Right" then
			weldto = Data.Player.Character:FindFirstChild("Right Arm")
		end
		Tool:CreateWelds(c, weldto, Grip, false)
		c.Parent =  game.Workspace.Garbage.Tools[Data.Player.Name]
		ToolEquipData[Root] = c
	end
	
end

function Commands.UnequipTool(Data, Root)
	if ToolEquipData[Root] then
		ToolEquipData[Root]:Destroy()
	end
end

-- root is the toolroot
function Commands.DropTool(Data, Root, DestrRes)
	local itemroot = Root.Tool:GetChildren()[1]
	if ToolEquipData[itemroot] then
		ToolEquipData[itemroot]:Destroy()
	end
	if Root.Name == "DefaultTool" then -- drop inside resources
		local res = Root.Items:GetChildren()[1]:GetChildren()[1]
		Tool:CreateWelds(res, nil, nil, true)
		local head = Data.Player.Character:FindFirstChild("Head")
		if head and res then
			res.CFrame = head.CFrame * CFrame.new(0,2,0)
		
			res.Parent = game.Workspace.Resources
		end
		Root:Destroy()
		if DestrRes then res:Destroy() end
	else
		local clone = itemroot
		Tool:CreateWelds(clone, nil, nil, true)
		local head = Data.Player.Character:FindFirstChild("Head")
		if head then
			clone.CFrame = head.CFrame * CFrame.new(0,2,0)
		end
		clone.Parent = game.Workspace.Tools 
		ToolDropContainer[clone] = Root
		Root.Parent = game:GetService("ServerStorage")
		if DestrRes then Root:Destroy() end
	end
end
-- if a tool is dropped in workspace tools then readd it to player here
-- toolroot is physical root item
function Commands.ReaddTool(Data, ToolRoot)
	if not ( ToolRoot:IsDescendantOf(game.Workspace.Tools)) then
		return
	end
	local Player = Data.Player
	if ToolDropContainer[ToolRoot] then
		local troot = Instinct.DataManager:GetContainer(Player, "Tools")
		if #(troot:GetChildren()) >= ToolService.MaxTools then 
			local Container = ToolDropContainer[ToolRoot]
			ToolRoot.Parent = Container.Tool
			Container.Parent = troot
		else
			Instinct.Chat:Send("You cannot equip the tool: " .. ToolRoot.Name .. " because you already have " .. ToolService.MaxTools .. " tools!", Player)
		end
	end
end

function Commands.RequestToolCreation(Data, Name, ObjectList, IsDefault)
	print(IsDefault)
	if IsDefault then 
		local scan = nil
		for i,v in pairs(ObjectList) do
			for ind, val in pairs(v) do
				scan = v
				break
			end
			if scan then break end
		end
		print(scan[1])
		-- UGLY HACK --
		ObjectService:ToBackpack(scan[1])
	end

	ToolService:CreateNormalTool(Data.Player, Name, ObjectList)
end


function Commands.DestroyResource(Data, What, Reason)
	if not What then return end
	if Reason == "KnappingError" then
		What:Destroy()
	end
end

-- tries to lock a resource.

ResourceLocks = {}

local function unlockres(p,anchor,collide)
	local data = ResourceLocks[p] 
	if data then 
		local origp = data.Parent
		local origr = data.Resource
		origr.Parent = origp
	
		for i,v in pairs(data) do
			print(i)
			if type(i) == "userdata" then
				i.CanCollide = collide or v.CanCollide
				i.Anchored = anchor or v.Anchored
			end
		end
		ResourceLocks[p] = nil
	end
end

function Commands.CancelResourceLock(Data, Resource)
	local Player = Data.Player
	if ResourceLocks[Player] and ResourceLocks[Player].Resource == Resource then
		unlockres(Player)
	end
	return true
end

function Commands.RequestResourceLock(Data, Resource)
	local Player = Data.Player
	if not Resource or Resource.Parent == nil then return end
	if ResourceLocks[Player] then -- WAT
		unlockres(Player)
	end
	for i,v in pairs(ResourceLocks) do
		if i.Parent then -- player exists;
			if v == Resource then
				return false, i.Name .. " is using this resource."
			end
		else
			unlockres(i)
		end
	end
	local op = Resource.Parent
	ResourceLocks[Player] = {Parent = op, Resource = Resource, CF = Resource.CFrame}
	Instinct.Services.ObjectService:ToBackpack(Resource) -- HAX [tonil]

	function fd(p)
		if p:IsA("BasePart") then
			ResourceLocks[Player][p] = {CanCollide = p.CanCollide, Anchored = p.Anchored}
			p.CanCollide = false
			p.Anchored=true
		end
		for i,v in pairs(p:GetChildren()) do
			fd(v)
		end
	end
	fd(Resource)
	Resource.Parent=nil
	return true
end

function Commands.RequestMove(Data, Resource, CFrame)
	local Player = Data.Player

	if ResourceLocks[Player] and ResourceLocks[Player].Resource == Resource then
		Instinct.Services.ObjectService:SetResourceCFrame(Resource, CFrame)
	--	ResourceLocks[Player].Parent = game.Workspace.Buildings


		print(Resource:GetFullName())
	--	Resource.Parent = game.Workspace.Buildings
		unlockres(Player, false, true)
		return true
	else
		 return  true
	end
end

---- TODO -----
-- ROTATED REOSURCES DO NOT WELD TO WORLD!
-- to fix: raycast and weld @ ground
-- players will have to offset their buildings tho, but.. well, kinda kewl still :)

function Commands.Build(Data, Resource, CFrame, Size)
	-- first move;
	local Player = Data.Player
	print("eval", ResourceLocks[Player] and ResourceLocks[Player].Resource == Resource )
	if ResourceLocks[Player] and ResourceLocks[Player].Resource == Resource then
		if Size then
			Instinct.Services.ObjectService:ResizeResource(Resource, Size, ResourceLocks[Player].Parent)
		end
		Instinct.Services.ObjectService:SetResourceCFrame(Resource, CFrame)
		ResourceLocks[Player].Parent = game.Workspace.Buildings
		function fd(p,func)
			if p:IsA("BasePart") then
				func(p)
			end
			for i,v in pairs(p:GetChildren()) do
				fd(v,func)
			end
		end
		fd(Resource, function(p)
					p.FrontSurface = "Universal"
					p.BackSurface = "Universal"
					p.BottomSurface = "Universal"
					p.LeftSurface = "Universal"
					p.TopSurface = "Universal"
					p.RightSurface = "Universal"
					p.Velocity = Vector3.new()
					p.AngularVelocity = Vector3.new()
		end)	
		Resource.Parent = game.Workspace.Buildings	
		fd(Resource, function(p)
			p:MakeJoints() -- yeah.
		end)
		print(Resource:GetFullName())
	--	Resource.Parent = game.Workspace.Buildings
		unlockres(Player, false, true)
		return true
	else
		return true
	end
	
end

function Commands.CreateKnap(Data, Original, CreatedName)
	print("OMG REATED", Original, CreatedName)
	if not Original or not CreatedName then return end
	local mkName = Original.Name
	local stCopy = game:GetService("ServerStorage").Mining:FindFirstChild(mkName)
	print(mkName)
	if mkName then
		local created = game:GetService("ReplicatedStorage").NewTools:FindFirstChild(CreatedName)
		print(created)
		if created then
			local root = created:Clone()
			local propcpy = {"Material", "BrickColor", "Reflectance", "Transparency"}
			ObjectService:CopyStyle(stCopy, root, propcpy)
			ObjectService:WeldObject(root)			
			
			
			root.Parent = game.Workspace
			root.CFrame = Original.CFrame
			print(root.CFrame)
			--delay(0, function() while wait() do print(root.CFrame) end end)
			Object:SetContext(root, "Material", mkName)
			print("done")
			root.CFrame = Original.CFrame
			Original:Destroy()

			
		end
	end
end

-- really ugly code here Q

local growt = {}

delay(0, function()
while wait(1) do
	for i,v in pairs(growt) do
		v:Grow()
		wait(0.2)
	end
end
end)

function Commands.Plant(Data, Handle, ToolRoot, Hit, Part)
	if Handle and Handle.Name == "Apple" and ToolRoot and Hit and Part then
			print(Hit, Part)
			local new = Instinct.Create(Instinct.World.Tree)
			local ok = new:Initialize(Hit.p, Part)
			if ok then 
				table.insert(growt,new)
				Commands.DropTool(Data, ToolRoot, true)
			else 
				Instinct.Chat:Send("There is no room to place that!", Data.Player)
			end
			
	end
end

function Commands.ChopTree(Data, Tree)
	if Tree and Tree.Name == "Wood" and Tree:IsDescendantOf(game.Workspace.Life) then
		print(Instinct.Services.ObjectService)
		local o = Instinct.Services.ObjectService:GetObject("Wood")
		local val = o:GetContext(Tree, "ChoppedDown")
		print(val)
		if val then
			if val == 1 then
				o:SetContext(Tree, "ChoppedDown", 2)
				Tree.Parent = game.Workspace.Resources 
				for i,v in pairs(Tree:GetChildren()) do 
					if v:IsA("BasePart") then 
						for ind, val in pairs(v:GetChildren()) do 
							if val:IsA("BasePart") then 
								val.Parent = game.Workspace.Resources 
								val:BreakJoints()
							end 
						end 
						v.Parent = game.Workspace.Resources 
						v:BreakJoints()
					end 
				end
			end
		else 
			o:SetContext(Tree, "ChoppedDown", 1)
			local w = Tree:FindFirstChild("Weld")
			w:Destroy()
			Tree.RotVelocity = Vector3.new(4,0,0)

		end
		for i, tree in pairs(growt) do
			if tree.TreeBase == Tree then
				tree.Disabled = true -- disable grows.
				table.remove(growt, i)
			end
		end
	end
end

function Commands.SwapBackpack(Data, Res)
	local p = Data.Player
	local bp = game:GetService("ReplicatedStorage"):WaitForChild("LocalPlayerData"):WaitForChild(tostring(p.userId)):WaitForChild("Backpack")
	if Res:IsDescendantOf( game:GetService("ReplicatedStorage").DroppedBackpacks) then
		Res.Parent = bp
	end
end

function Commands.DoDamage(Data, Enemy, Damage)
	
end

return Commands