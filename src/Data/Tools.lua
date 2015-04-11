return function()
	-- Fix recipe check for move/bild
local Instinct = _G.Instinct
local Tool = Instinct.Class.Tool
local ToolService = Instinct.Services.ToolService
local ObjectService = Instinct.Services.ObjectService
local Knapping = Instinct.Libraries.Knapping
 
local Mover
local NormalMover
if game.Players.LocalPlayer then
	local CMover = Instinct.Libraries.Mover
	Mover = Instinct.Create(CMover)
	Mover.MoverType = "Build"
	Mover:CreateBuilder()
	CMover.Builder = Mover
	NormalMover = Instinct:Create(CMover)
	NormalMover.MoverType = "Move"
	CMover.Mover = NormalMover
	NormalMover:CreateMover()
	ToolTip = Instinct.UI.ToolTip
	NutritionService = Instinct.Services.NutritionService
end

local Eat = Instinct:Create(Tool)
Eat.Type = "NonPhysical"
Eat.Name = "Eat"

function Eat:Create() end

function Eat:OnEquip()
	Instinct.Services.KeyService.State = "Eating"
	self.Gui = Instinct.Create(ToolTip)
	self.Cache = {}
	--self.Gui:Hide()
	delay(0, function()
		local Mouse = game.Players.LocalPlayer:GetMouse()
		while Instinct.Services.KeyService.State == "Eating" do
			local targ = Mouse.Target
			if targ and NutritionService:IsEdible(targ) then
				local data = NutritionService:GetNutritionInfo(targ)
				local use = {}
				for i,v in pairs(data) do
					local val = ((math.floor(v*100 + 0.5)-0.5)/ 100) 
					table.insert(use, {"info", i..": "..val})
				end
				table.insert(use,{"info", "Left click to eat!"})
				self.Gui:Show(targ, {}, use)
			--	warn('show')
				self.Cache[targ] = data
			else 
				self.Gui:Hide()
			--	warn('hide')
			end
			wait()		
			if targ then
				self.Cache[targ] = nil -- GC last targ [ifexist]
			end
		end
	end)
end

function Eat:OnUnequip()
	Instinct.Services.KeyService.State = "Default"
	self.Cache = {}
	self.Gui:Destroy()
end

function Eat:DoAction(mbutton)
	if mbutton == "m1" then
		local Mouse = game.Players.LocalPlayer:GetMouse()
		local targ = Mouse.Target
		if self.Cache[targ or ""] then
			NutritionService:Eat(targ, self.Cache[targ])
		end
	end
end

ToolService:RegisterTool("Eat", Eat)


local Move = Instinct:Create(Tool)
Move.Type = "NonPhysical"
Move.Name = "Move"

function Move:Create() end

function Move:OnEquip()
	Instinct.Services.KeyService.State = "Moving"
end

function Move:OnUnequip()
	Instinct.Services.KeyService.State = "Default"
	if NormalMover.MoveRoot then
		-- should not abort but just move.
		NormalMover:Confirm()
	end

end

function Move:DoDBCAction(key)
	 NormalMover:DoubleClicked(key)
end

function Move:DoAction(mbutton, ActionName)
	-- ActionName is always "Move" here.
	print(mbutton, mbutton == "m1")
	if mbutton == "m1" then
		print(NormalMover.MoveRoot)
		if NormalMover.MoveRoot == nil then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local targ = Mouse.Target
			local usetarg = Instinct.Services.ObjectService:GetMainPart(targ)
			local o = Instinct.Services.ObjectService:GetObject((usetarg and usetarg.Name) or "")
			print(usetarg)
			local Char = game.Players.LocalPlayer.Character
			if Char then 
				if Char:FindFirstChild("Torso") then
					if (Char.Torso.Position - Mouse.Hit.p).magnitude > 20 then
						return
					end
				end
			end
			if usetarg and o then 
				-- LOL!?
				if _G.Instinct.Services.IntentionService:CanGather(usetarg).Move.Possible then
						local omg = usetarg
						if omg then
							if not NormalMover.GettingMoveRoot then
								print(omg:GetFullName())
								NormalMover:SelectTarget(omg)
								NormalMover:ToMoveMode()
							end
						end
				else 
					-- not ok to build with this resource!
				end
			end
		else
			print("->clicked")
			NormalMover:Clicked(mbutton)
		end
	end
end

-- LOL? Via current implementation, IntentionService already caches
-- Which means we don't have to cache here!? OK 
-- Hrm.

-- Cache action;
-- return action identifer, can be retrieved via IntentionService:GetAction()
function Move:CacheAction() 
	if _G.Instinct.Services.IntentionService:GetOptions()
end 
ToolService:RegisterTool("Move", Move)


local Build = Instinct:Create(Tool)
Build.Type = "NonPhysical"
Build.Name = "Build"

function Build:Create()
	
end

function Build:OnEquip()
	if Instinct.UI and Instinct.UI.SideBar then 
		Instinct.UI.SideBar:ForceClose()
	end
	Instinct.Services.KeyService.State = "Building"
	Mover.UI.BuildGui.Visible = true
end

function Build:OnUnequip()
	if Instinct.UI and Instinct.UI.SideBar then 
		Instinct.UI.SideBar:EnableOpen()
	end
	Instinct.Services.KeyService.State = "Default"
	if Mover.MoveRoot then
		Mover:Abort()
	end
	Mover.Gui.BuildGui.Visible=false
end

function Build:DoDBCAction(key)
	Mover:DoubleClicked(key)
end

function Build:DoAction(mbutton)
	print(mbutton, mbutton == "m1")
	if mbutton == "m1" then
		print(Mover.MoveRoot)
		if Mover.MoveRoot == nil then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local targ = Mouse.Target
			local usetarg = Instinct.Services.ObjectService:GetMainPart(targ)
			local o = Instinct.Services.ObjectService:GetObject((usetarg and usetarg.Name) or "")
			print(usetarg)
			local Char = game.Players.LocalPlayer.Character
			if Char then 
				if Char:FindFirstChild("Torso") then
					if (Char.Torso.Position - Mouse.Hit.p).magnitude > 20 then
						return
					end
				end
			end
			if usetarg and o then 
					if _G.Instinct.Services.IntentionService:GetOptions() then
						local omg = Instinct.Services.ObjectService:GetMainPartRoot(targ)
						if omg then
							if not Mover.GettingMoveRoot then
								print(omg:GetFullName())
								print("SELECTING TARGET")
								Mover:SelectTarget(omg)
								Mover:ToMoveMode()
							end
						end
					end

			end
		else
			print("->clicked")
			Mover:Clicked(mbutton)
		end
	end
end
ToolService:RegisterTool("Build", Build)

-- Start of ugly tool API - fix pls

local DefaultTool = Instinct:Create(Tool)

local function inrange()	
	local center = game.Players.LocalPlayer.Character:FindFirstChild("Torso")
	return (center.Position - game.Players.LocalPlayer:GetMouse().Hit.p).magnitude < 10
end
function DefaultTool:Create(TRoot, ObjData)
	local find
	print('scan')
	for objname, objdata in pairs(ObjData) do
		print(objname, objdata)
		for i, item in pairs(objdata) do
			print(i,item)
			find = item
			break
		end
		if find then
			break
		end
	end
	if find then
		local this = find:Clone()
		this.Parent = TRoot
	end
	
	return self -- always
end

-- Change how tools get and do actions.
-- Should be documented!!
-- Actions are inside intentserv;
-- Tools provide a list of actions to check
-- Cache checks if move is possible
-- Run executes it
-- RunServer executes server code
-- 

function DefaultTool:DoAction(button)
	print(self.Tool.Name)
	local o = ObjectService:GetObject(self.Tool.Name)
	print(o)
	if o and inrange() then
		local mat = o:GetConstant("Material")
		print(mat)
		if mat[1] == "Stone" then
			-- is a hammerstone. 
			print("IS HAMMERSOTNE")
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target and Mouse.Target:IsDescendantOf(game.Workspace.Resources) then 
				local target = ObjectService:GetObject(Mouse.Target.Name)
				if target then 
					local mat = target:GetConstant("Material")
					if mat[1] == "Stone" then
						-- omg
						Knapping:Knap(Mouse.Target)
					end
				end
			end
		elseif self.Tool.Name == "Apple" then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target and Mouse.Target.Name == "FertileGround" then 
					Instinct.Communicator:Send("Plant", self.Tool, self.ToolRoot, Mouse.Hit, Mouse.Target)
			end
				
		elseif self.Tool.Name == "Axe" then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target then 
				local target = ObjectService:GetObject(Mouse.Target.Name)
				if target then 
					local c = target:GetContext(Mouse.Target, "ChoppedDown")
					if c == nil or c == 1 then 
						Instinct.Communicator:Send("ChopTree", Mouse.Target)
					end
				end
			end
		end 
	end
end

function DefaultTool:CacheAction()
	--	print(self.Tool.Name)
	local o = ObjectService:GetObject(self.Tool.Name)
--	print(o)
	if o then
		local mat = o:GetConstant("Material")
		--print(mat)
		if mat[1] == "Stone" then
			-- is a hammerstone. 
			print("IS HAMMERSOTNE")
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target then 
				local target = ObjectService:GetObject(Mouse.Target.Name)
				if target then 
					local mat = target:GetConstant("Material")
					if mat[1] == "Stone" then
						-- omg
						return "Knap"
					end
				end
			end
		elseif self.Tool.Name == "Apple" then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target and Mouse.Target.Name == "FertileGround" then 
					return "Plant"
			end
				
		elseif self.Tool.Name == "Axe" then
			local Mouse = game.Players.LocalPlayer:GetMouse()
			if Mouse.Target then 
				local target = ObjectService:GetObject(Mouse.Target.Name)
				if target and target.Name == "Wood" then 
					local c = target:GetContext(Mouse.Target, "ChoppedDown")
					if c == nil or c == 1 then 
						return "Chop"
					end
				end
			end
		end
	end
end

-- OVERRIDE
-- Cache action returns an ACTION NAME
-- Cache action for target;
function DefaultTool:CacheAction(Target)
	if self.Cached then 
		return self.Cached[Target]
	end 
end

function DefaultTool:DoAction(MouseButton, Action)
	self.Cached[]
end

function DefaultTool:GetGrip()
	print('get grip')
	local norm = self.Tool
	local other = CFrame.new()
	if norm then
		other = CFrame.new(0, -0.5, 0)
	end
	return CFrame.new(0, -1, 0) * CFrame.Angles(math.pi/2,0,0) * other
end

ToolService:RegisterTool("DefaultTool", DefaultTool)

end