-- manages tool equipping / unequipping, etc

local ToolService = {}

local DataManager = Instinct.Include "DataManager"
local KeyService = Instinct.Include "Services/KeyService"
local ObjectService = Instinct.Include "Services/ObjectService"
local Object = Instinct.Include "Action/Object"
local ToolGui

local IsLocal = (game.Players.LocalPlayer ~= nil)
if IsLocal then
	ToolGui = Instinct.Include "Gui/ToolGui"
end

ToolService.EquippedLeft = nil
ToolService.EquippedRight = nil
ToolService.EquippedNP = nil -- nonphysical equipped

ToolService.MaxTools = 10

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

ToolService.HotkeyNames = {
	 "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "M", "B", "E"
}

for i,v in ipairs(ToolService.HotkeyNames) do
	local enum = ToolService.PossibleHotkeys[i]
	print(i)
	ToolService.HotkeyNames[enum] = v
end

function ToolService:Constructor()
	self.Tools = {}
	self.RegisteredTools = {}
	-- self.DefaultTool is IMPORANT!!	
	setmetatable(self.RegisteredTools,{__index = function() return self.DefaultTool end})
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
		print(waseq, 'chke', tool.Hand)
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

function ToolService:GeneralUnequip(tool)
	print("unequipping a tool")
	tool.IsEquipped = false
	tool:Unequip()
	if tool.Type == "Normal" then
		if tool.Hand == "Left" then
			if self.EquippedRight then
				self.EquippedRight.Other = nil
			end
			self.EquippedLeft = nil
		elseif tool.Hand == "Right" then
			if self.EquippedLeft then
				self.EquippedLeft.Other = nil
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
		print('added tool kewl', toolroot.Name)
		self:AddTool(toolroot)
	end)
	self.ToolRoot.ChildRemoved:connect(function(toolroot)
		print('removing tool nu', toolroot.Name)
		self:RemoveTool(toolroot)
	end)
	for i,v in pairs(self.ToolRoot:GetChildren()) do
		self:AddTool(v)
	end
end

function ToolService:AddTool(root)
	wait()
	print("ADDED TOOL")
	local tname = root.Name
 	local tool = self.RegisteredTools[tname]
	print(tool)
	if tool then
		local new = tool:GetDelegate()
		self:SetHotkey(new, self:GetNewHotkey(new))
		if new.Type ~= "NonPhysical" then
			new.Tool = root:FindFirstChild("Tool"):GetChildren()[1]
			new.ToolRoot = root
		end
		table.insert(self.Tools, new)
		-- add a hotkey
		--print('call getnewhotkey', new)
	--	self:GetNewHotkey(new)
		-- call gui update
		if new.Type ~= "NonPhysical" then
			self:GeneralEquip(new)
		end
		ToolGui:AddTool(new)
		
		print("DONE")
	end
end

function ToolService:RemoveTool(root)
	-- remove from self.Tools
	local tool
	for i,v in pairs(self.Tools) do
		if v.ToolRoot == root then
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
function ToolService:DropTool(tool)
	
end

function ToolService:RequestToolCreation(Name, ObjectList, IsDefault)
	if Instinct.Communicator then
		Instinct.Communicator:Send("RequestToolCreation", Name, ObjectList, IsDefault)
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
	print("in gnh, ", tool)
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

-- {objname = {objectlist}}
function ToolService:CreateNormalTool(Player, ToolName, ObjectList)
	
	-- lets first create a root container
	if not IsLocal then
		local troot = DataManager:GetContainer(Player, "Tools")
		warn(tostring(troot))
		if troot then
			if #(troot:GetChildren()) >= self.MaxTools then
				if Instinct.Chat then
					Instinct.Chat:Send("You cannot create the tool: " .. ToolName .. " because you already have " .. self.MaxTools .. " tools!", Player)
				end
				return
			end
			warn(tostring(self.RegisteredTools[ToolName]))
			if self.RegisteredTools[ToolName] then
				local new = Instance.new("Model")
				new.Name = ToolName
				local Items = Instance.new("Model", new)
				Items.Name = "Items" -- where tool is built from
				local ToolModel = Instance.new("Model", new)
				ToolModel.Name = "Tool" -- where tool is put in later hue?
				for objname, objects in pairs(ObjectList) do
					local mod = Instance.new("Model", Items)
					mod.Name = objname
					for i, object in pairs(objects) do
						object.Parent = mod
					end
				end
				self.RegisteredTools[ToolName]:Create(ToolModel, ObjectList)				
				
				new.Parent = troot -- call ChildAdded on client ^_^
			end
		end
	end
end

function ToolService:ToSaveData(ToolRoot)
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