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
-- Change eat to work via default GUI
-- 
function Eat:OnEquip()
	Instinct.Services.KeyService.State = "Eating"
--	self.Gui = Instinct.Create(ToolTip)
--	self.Cache = {}
	--self.Gui:Hide()
	--[[delay(0, function()
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
	end)--]]
end

function Eat:OnUnequip()
	Instinct.Services.KeyService.State = "Default"
	--self.Cache = {}
--	self.Gui:Destroy()
end

function Eat:DoAction(Target, ActionName)
--	if mbutton == "m1" then
	if ActionName == "Eat" then 
		local Opt = IntentionService:GetOptStruct()
		local Cached = self:CacheAction(Opt, Target)
		if Cached == "Eat" then 
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local targ = Mouse.Target
			if self.Cache[targ or ""] then
				NutritionService:Eat(targ, self.Cache[targ])
			end
		end
	end
end

function Eat:CacheAction(Out, Target) 
	if NutritionService:IsEdible(Target) then 
		-- Yay!
		local Data = NutritionService:GetNutritionInfo(Target)
		for NutritionName, NutritionValue in pairs(Data) do 
			local NutrVal = ((math.floor(NutritionValue * 100 + 0.5)-0.5)/100)
			Out.Gather.InfoStrings:insert(NutritionName..": "..NutrVal)
		end


		return "Eat"
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

function Move:DoAction(Target, ActionName)
	-- ActionName is always "Move" here.
	--print(mbutton, mbutton == "m1")
	--if mbutton == "m1" then
	--	print(NormalMover.MoveRoot)
	if ActionName == "Move" then 
		if NormalMover.MoveRoot == nil then
			local targ = Target
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
				local omg = Target
							if not NormalMover.GettingMoveRoot then
						
								NormalMover:SelectTarget(omg)
								NormalMover:ToMoveMode()
							end
				

			end
		else
		--	print("->clicked")
			NormalMover:Clicked(mbutton)
		end
	end
end

-- LOL? Via current implementation, IntentionService already caches
-- Which means we don't have to cache here!? OK 
-- Hrm.

-- Cache action;
-- return action identifer, can be retrieved via IntentionService:GetAction()
function Move:CacheAction(OptList, Target) 
	if _G.Instinct.Services.IntentionService:GetOptions(Target,"","").Move.Possible then
		return "Move"
	end 
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

function Build:DoAction(Target, Action)
	if Action == "Build" then 
		if Mover.MoveRoot == nil then

			local targ = Target
			local usetarg = Instinct.Services.ObjectService:GetMainPart(targ)
			local o = Instinct.Services.ObjectService:GetObject((usetarg and usetarg.Name) or "")

			local Char = game.Players.LocalPlayer.Character
			if Char then 
				if Char:FindFirstChild("Torso") then
					if (Char.Torso.Position - Mouse.Hit.p).magnitude > 20 then
						return
					end
				end
			end
			if usetarg and o then 

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
			Mover:Clicked(mbutton)
		end
	end
end

function Build:CacheAction(OptList, Target) 
	local Obj = ObjectService:GetObject(Target.Name)
	if IntentionService:GetOptions(Target, "", "").Move.Possible and Obj.BuildingMaterial then 
		return "Building" 
	end 
end

ToolService:RegisterTool("Build", Build)

-- Start of ugly tool API - fix pls

local DefaultTool = Instinct:Create(Tool)

local function inrange()	
	local center = game.Players.LocalPlayer.Character:FindFirstChild("Torso")
	return (center.Position - game.Players.LocalPlayer:GetMouse().Hit.p).magnitude < 10
end

function DefaultTool:Create() end 

-- OVERRIDE
-- Cache action returns an ACTION NAME
-- Cache action for target;
function DefaultTool:CacheAction(OptList, Target)
	-- Check: AvailableACtions
	-- Get these actions from IntentionService form Tool namespace
	-- Call their :Cache field
	local Object = ObjectService:GetObject(Target.Name)
	if Object then 
		-- Hrm not sure, can add :GetAncestryProperties for inherited actions.
		local ActionTable = self.Object:GetAncestryProperties("AvailableActions", true) 
		if ActionTable then 
			for _, AName in pairs(ActionTable) do 
				local ActObj = IntentionService:GetAction(AName, "Tool")
				if ActObj then 
					if ActObj:Cache(OptList, Target, self) then 
						return AName  
					end 
				end 
			end 
		end 
		for _,Action in pairs(IntentionService.Actions.DefaultTools or {}) do 
			if Action:Cache(OptList, Target, self) then 
				return Action.Name 
			end
		end 
	end

end
-- Runs action ONLY if re-caching actions returns the same actionname
function DefaultTool:DoAction(Target, ActionName)
	if ActionName and self:CacheAction(IntentionService:GetOptStruct(), Target) == ActionName then 
		local Act = IntentionService:GetAction(ActionName)
		local ShRunOnServer = Act:Run(Target, self)
		if ShRunOnServer then 
			-- Communicate with server to run this on server
			_G.Instinct.Communicator:Send("ExecuteToolAction", self.Tool, Target, ActionName)
		end 
	end 
end

function DefaultTool:GetGrip()
	local other = CFrame.new()
	if not self.ToolGetGrip then
		other = CFrame.new(0, -0.5, 0)
	else 
		other = self:ToolGetGrip() 
	end 
	return CFrame.new(0, -1, 0) * CFrame.Angles(math.pi/2,0,0) * other
end

ToolService:RegisterTool("DefaultTool", DefaultTool)

end