-- manages tool equipping / unequipping, etc

-- ToolService rewrite 
-- Following definitions defined into ResourceApi
-- Main changes; Tools are not instances anymore but are now Instinct Objects
-- Also added the hooks as defined in Resource API



local ToolService = {}

--EL ER NP tool equipped pointers, general purpose
ToolService.EquippedLeft = nil
ToolService.EquippedRight = nil
ToolService.EquippedNP = nil -- nonphysical equipped

-- Maximal physical tools. Can be used later for upgrades to a tool belt
ToolService.MaxTools = 10

-- Hotkeys because UserInputService currently is acting strange
ToolService.PossibleHotkeys = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
	Enum.KeyCode.M,
	Enum.KeyCode.B,
	Enum.KeyCode.E, -- very hackihs.
}

-- Prepare data; ( in order as of above, tostring doesn't work as "Zero" isnt a nice GUI name)
ToolService.HotkeyNames = {
	 "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "M", "B", "E"
}

for i,v in ipairs(ToolService.HotkeyNames) do
	local enum = ToolService.PossibleHotkeys[i]
	print(i)
	ToolService.HotkeyNames[enum] = v
end

local DataManager
local KeyService 
local ObjectService 
local Object
local ToolGui

local IsLocal = (game.Players.LocalPlayer ~= nil)


function ToolService:Constructor()
	if not IsLocal then
		DataManager = _G.Instinct.Player.DataManager
	else 
		ToolGui = _G.Instinct.UI.ToolGui
	end
	KeyService = _G.Instinct.Services.KeyService
	ObjectService = _G.Instinct.Services.ObjectService
	Object = _G.Instinct.Class.Object
	self.Tools = {}
	self.RegisteredTools = {}
	-- self.DefaultTool is IMPORANT!!	
--	setmetatable(self.RegisteredTools,{__index = function() return self.DefaultTool end})
end

function ToolService:RegisterTool(Name, Tool)
	if not Tool.Type then
		error("didnt register tool because no type.")
	elseif Tool.Type == "Normal" then
		if Tool.Create and Tool.DoAction then
			self.RegisteredTools[Name] = Tool
		else
			error("didnt register because tool doesnt have a create and action funciton")
		end
	elseif Tool.Type == "NonPhysical" then
		if Tool.DoAction then
			self.RegisteredTools[Name] = Tool
		else
			error("tool doenst have create func")
		end
	else
		error("tool doesnt have type")
	end
end

function ToolService:ChangeHand(tool)
	if tool.Type == "Normal" then
		local waseq = tool.IsEquipped
		if tool.Hand == "Left" then
			if self.EquippedRight then
				self:GeneralUnequip(self.EquippedRight)
			end
			tool.Hand = "Right"
		else
			if self.EquippedLeft then
				self:GeneralUnequip(self.EquippedLeft)
			end
			tool.Hand = "Left"
		end
		if waseq then
			self:GeneralUnequip(tool)
			self:GeneralEquip(tool)
		end
	end 
end

-- setups st00f
-- Could be made shorter by adding helper functions to auto-update the data for equipped tools.
function ToolService:GeneralEquip(tool)
	
	if tool.IsEquipped then
		self:GeneralUnequip(tool)
		return
	end
	print("equipping a tool")
	if tool.Type == "Normal" then
		if tool.Hand == "Left" then
			if self.EquippedLeft then 
				self:GeneralUnequip(self.EquippedLeft)
			end			
			self.EquippedLeft = tool
			tool.Other = self.EquippedRight
			tool.OtherNP = self.EquippedNP
			if self.EquippedNP then
				self.EquippedNP.OtherLeft = tool
			end
			if self.EquippedRight then
				self.EquippedRight.Other = tool
			end
			tool:Equip()
		elseif tool.Hand == "Right" then
			if self.EquippedRight then
				self:GeneralUnequip(self.EquippedRight)
			end
			self.EquippedRight = tool
			tool.Other = self.EquippedLeft
			tool.OtherNP = self.EquippedNP
			if self.EquippedNP then
				self.EquippedNP.OtherRight = tool
			end
			if self.EquippedLeft then
				self.EquippedLeft.Other = tool
			end
			tool:Equip()
		end
	elseif tool.Type == "NonPhysical" then
		if self.EquippedNP then
			self:GeneralUnequip(self.EquippedNP)
		end
		self.EquippedNP = tool
		tool.OtherLeft = self.EquippedLeft
		tool.OtherRight = self.EquippedRight
		if self.EquippedLeft then
			self.EquippedLeft.OtherNP = tool
		end
		if self.EquippedRight then
			self.EquippedRight.OtherNP = tool
		end
		tool:Equip()
	end
	tool.IsEquipped = true
	ToolGui:UpdatePositions()	
end

-- Bug: self.EquippedNP does /not/ get updated when unequpped. Fixed as of TSv2
function ToolService:GeneralUnequip(tool)
	print("unequipping a tool")
	tool.IsEquipped = false
	tool:Unequip()
	if tool.Type == "Normal" then
		if tool.Hand == "Left" then
			if self.EquippedRight then
				self.EquippedRight.Other = nil
			end
			if self.EquippedNP then 
				self.EquippedNP.OtherLeft = nil
			end 
			self.EquippedLeft = nil
		elseif tool.Hand == "Right" then
			if self.EquippedLeft then
				self.EquippedLeft.Other = nil
			end
			if self.EquippedNP then 
				self.EquippedNP.OtherRight = nil 
			end 
			self.EquippedRight = nil
		end
	elseif tool.Type == "NonPhysical" then
		if self.EquippedRight then
			self.EquippedRight.OtherNP = nil
		end
		if self.EquippedLeft then
			self.EquippedLeft.OtherNP = nil
		end
		self.EquippedNP = nil
	end
	ToolGui:UpdatePositions()
end

function ToolService:Enable()
	KeyService.KeyDown:connect(function(key, state)
		if key then 
			if key == "m1" or key == "m2" then
				if not self.EquippedNP then
					if key == "m1" and self.EquippedLeft then
						self.EquippedLeft:DoAction(key)
					elseif key == "m2" and self.EquippedRight then
						self.EquippedRight:DoAction(key)
					end
				else
					self.EquippedNP:DoAction(key)
				end
			else 
				for _, tool in pairs(self.Tools) do

						if tool.Hotkey == key then
							self:GeneralEquip(tool)
						end

				end
			end
		end
	end)
	
	KeyService.DoubleClick:connect(function(key, state)
		if key then 
			if key == "m1" or key == "m2" then
				if not self.EquippedNP then
					if key == "m1" and self.EquippedLeft and self.EquippedLeft.DoDBCAction then
						self.EquippedLeft:DoDBCAction(key)
					elseif key == "m2" and self.EquippedRight and self.EquippedRight.DoDBCAction then
						self.EquippedRight:DoDBCAction(key)
					end
				elseif self.EquippedNP.DoDBCAction then
					self.EquippedNP:DoDBCAction(key)
				end
			end
		end
	end)
	
	
	self.ToolRoot = DataManager:GetContainer(game.Players.LocalPlayer, "Tools")
	if not self.ToolRoot then
		repeat
			self.ToolRoot = DataManager:GetContainer(game.Players.LocalPlayer, "Tools")
			wait()
		until self.ToolRoot
	end
	self.ToolRoot.ChildAdded:connect(function(toolroot)
		self:AddTool(toolroot,true)
	end)
	self.ToolRoot.ChildRemoved:connect(function(toolroot)
		self:RemoveTool(toolroot)
	end)
	for i,v in pairs(self.ToolRoot:GetChildren()) do
		self:AddTool(v,false)
	end
end



-- Provide roblox instance to load
-- TODO: ADD HOOKS FOR TOOL CONTEXT
-- Should equip if tthe context equip is set to true
-- Else, also equip it if picked up.
function ToolService:AddTool(ToolInstance,PickedUp)
	local ToolName = ToolInstance.Name 
	local UsedTool = self.RegisteredTools[ToolName]
	-- Create a new tool 
	local Tool = _G.Instinct:Create(UsedTool) or _G.Instinct:Create(self.RegisteredTools.DefaultTool)
	Tool.Tool = ToolInstance 
	-- Assign hotkey to tool
	self:SetHotkey(Tool, self:GetNewHotkey(Tool))
	-- If it is a PhysicalTool
	-- WHich is picked up; equip it.
	if Tool.Type ~= "NonPhysical" and PickedUp then 
		self:GeneralEquip(Tool)
	end 

	-- Call UI hook
	ToolGui:AddTool(Tool)
end 


function ToolService:RemoveTool(ToolInstance)
	-- remove from self.Tools
	local tool
	for i,v in pairs(self.Tools) do
		if v.Tool == ToolInstance then
			tool = v
			table.remove(self.Tools, i)
			break
		end
	end
	function scanl(tab, which)
		if tab and tab[which] and tab[which] == tool then
			tab[which] = nil
		end
	end
	scanl(self, "EquippedLeft")
	scanl(self, "EquippedRight")
	scanl(self.EquippedLeft, "Other")
	scanl(self.EquippedRight, "Other")
	-- cannot drop nonphysical tools so, thats not a porblem
	ToolGui:RemoveTool(tool)
end

-- serversided!
-- ty..?
-- nevertheless should be removed RIGHT HERE
function ToolService:DropTool(tool)
	
end

function ToolService:RequestToolCreation(Name, ObjectList, IsDefault)
	if _G.Instinct.Communicator then
		_G.Instinct.Communicator:Send("RequestToolCreation", Name, ObjectList, IsDefault)
	end
end

function ToolService:GetHotkey(tool)
	return tool.Hotkey
end

function ToolService:SetHotkey(tool, hotkey)
	print("SET HOTKEY", hotkey)
	if tool and hotkey then 
		tool.Hotkey = hotkey
		-- and a setcontext
	end
end

-- sets the first available hotkey to the tool
function ToolService:GetNewHotkey(tool)
	print("tool type: " .. tool.Type)
	if tool.Type == "NonPhysical" then
		
		if tool.Name == "Build" then
			return Enum.KeyCode.B
		elseif tool.Name == "Move" then
			return Enum.KeyCode.M 
		elseif tool.Name == "Eat" then
			return Enum.KeyCode.E 
		else 
			-- custom building tool.
		end
	end
	local cp = {}
	for i,v in pairs(self.PossibleHotkeys) do
		cp[v] = true
	end
	for i, tool in pairs(self.Tools) do

		cp[tool.Hotkey] = false
	end
	for i,v in pairs(self.PossibleHotkeys) do
		if cp[v] == true then
			return v
		end
	end
end

-- Converts normal resource to a tool. not a big deal
-- just put it in a model, if it isn't in there yet.
-- Model is provided as of Insv2, so no problem with naming arises.
function ToolService:CreateNormalTool(Player, Resource)
	
	-- lets first create a root container
	if not IsLocal then 
		local ToolContainer = DataManager:GetContainer("Tools", Player)
		-- Check for too many tools 
		if #(ToolContainer:GetChildren()) >= self.MaxTools then 
			-- Cannot add a tool , too many tools 
			-- Note: problems arise with this setup for tool belt game mechanic. No work.
			-- Send over chat? 
			-- This, too, should be sent as notification via some service.			
			local Chat = _G.Instinct.Mechanics.Chat 
			Chat:Send("You cannot equip this " .. Resource.Name ..", because you already have " .. self.MaxTools .. " tools available!", Player)
			
		else 
			-- CreateNormal tool implies this is a physical tool 
			-- Must we first run a Move operation via ObjectService?
			-- Or does this always imply that this already happened..?
			-- No it doesn't.
			ObjectService:ApplyRules(Resource, "MoveRuleList", "Move")
			-- to equip; GetChildren()[1]. Everything is put in a model. 
			local Mod = Instance.new("Model", ToolContainer)
			Mod.Name = Resource.Name 
			Resource.Parent = Mod 
			Mod.Parent = ToolContainer -- Fires @AddTool at client

			-- Optional context stuff here --

			-- Equip, hotkey, blabla
		end 
	else 
		error("This is a server-sided function")	
	end 

end

function ToolService:ToSaveData(ToolRoot)
	-- well
	local ResourceName = ToolRoot.Name 
	--local 


	local out = {} -- q data
	out.Name = ToolRoot.Name
	-- gewd
	out.Items = {}
	local items = ToolRoot:FindFirstChild("Items")
	if items then
		for i, container in pairs(items:GetChildren()) do
			out.Items[container.Name] = {}
			for id, item in pairs(container:GetChildren()) do 
				table.insert(out.Items[container.Name], ObjectService:GetSaveData(item))
			end
		end
	end
	return out
end

function ToolService:FromSaveData(Data)
	local Name = Data.Name
	local root = {}
	for ItemName, ItemList in pairs(Data.Items) do
		root[ItemName] = {}
		print("ItemName: " .. ItemName)
		for i, itemd in pairs(ItemList) do
			local data = ObjectService:CreateObjectFromSaveData(itemd)
			print(data)
			table.insert(root[ItemName], data)
		end
	end
	print(Name, root, "from toolservice")
	return Name, root
end

function ToolService:SetCooldown(Hand, Time)
	-- set cooldown, also in GUI
end


return ToolService