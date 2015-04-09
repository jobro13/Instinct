return function()

local Tool = Instinct.Include "Action/Tool"
local ToolService = Instinct.Include "Services/ToolService"
local ObjectService = Instinct.Include "Services/ObjectService"
local Knapping = Instinct.Include "Action/Knapping"
 
local Mover
local NormalMover
if game.Players.LocalPlayer then
	local CMover = Instinct.Include "Action/Mover"
	Mover = Instinct.Create(CMover)
	Mover.MoverType = "Build"
	Mover:CreateBuilder()
	CMover.Builder = Mover
	NormalMover = Instinct.Create(CMover)
	NormalMover.MoverType = "Move"
	CMover.Mover = NormalMover
	NormalMover:CreateMover()
	ToolTip = Instinct.Include "Gui/ToolTip"
	NutritionService = Instinct.Include "Services/NutritionService"
end

local Eat = Instinct.Create(Tool)
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


local Move = Instinct.Create(Tool)
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

function Move:DoAction(mbutton)
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
				local rec = Instinct.Services.RecipeService.Categories.Gather[1]
				local warns = Instinct.Services.RecipeService:CheckRecipe(rec, {Target=usetarg}, {})
				local ok = true 
				for i,v in pairs(warns) do
					if v[1] == "CANNOTGATHER" or v[1] == "ISTOOL" then
						print(v[1], "cannot move because")
						ok=false
						break
					end
				end
				if ok then				
					local usewarn = warns.WarningMessages
					if #usewarn == 0 then
						
					else
						print("not 0")
						for i,v in pairs(usewarn) do
							print(v)
							if v == "Too large to gather" then
								-- no prob
								
							else 
								ok = false
								break
							end
						end
					end
					print("ok?" , ok)
					if ok then
						local omg = Instinct.Services.ObjectService:GetMainPartRoot(targ)
						if omg then
							if not NormalMover.GettingMoveRoot then
								print(omg:GetFullName())
								NormalMover:SelectTarget(omg)
								NormalMover:ToMoveMode()
							end
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
ToolService:RegisterTool("Move", Move)


local Build = Instinct.Create(Tool)
Build.Type = "NonPhysical"
Build.Name = "Build"

function Build:Create()
	
end

function Build:OnEquip()
	if Instinct.Gui and Instinct.Gui.SideBar then 
		Instinct.Gui.SideBar:ForceClose()
	end
	Instinct.Services.KeyService.State = "Building"
	Mover.Gui.BuildGui.Visible = true
end

function Build:OnUnequip()
	if Instinct.Gui and Instinct.Gui.SideBar then 
		Instinct.Gui.SideBar:EnableOpen()
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
				local rec = Instinct.Services.RecipeService.Categories.Gather[1]
				local warns = Instinct.Services.RecipeService:CheckRecipe(rec, {Target=usetarg}, {})
				local ok = true 
				for i,v in pairs(warns) do
					if v[1] == "CANNOTGATHER" or v[1] == "ISTOOL" then
						ok=false
						break
					end
				end
				if ok then				
					local usewarn = warns.WarningMessages
					if #usewarn == 0 then
						
					else
						for i,v in pairs(usewarn) do
							if v == "Too large to gather" then
								-- no prob
								
							else 
								ok = false
								break
							end
						end
					end
					print("ok?" , ok)
					if ok then
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
				else 
					-- not ok to build with this resource!
				end
			end
		else
			print("->clicked")
			Mover:Clicked(mbutton)
		end
	end
end
ToolService:RegisterTool("Build", Build)

local DefaultTool = Instinct.Create(Tool)

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