local ToolGui = {}

ToolGui.ToolWhitespace = 15; -- whitespace between tools
ToolGui.CategoryWhitespace = 50; -- whitespace between categories, left,right, etc.
ToolGui.UnequippedY = -70;
ToolGui.EquippedY = -130;
ToolGui.ExpandedDX = 30; -- how many pixels dem tool increases

ToolGui.CanUpdate = true

function ToolGui:Constructor()
	self.Root = game:GetService("ReplicatedStorage").ToolGui:Clone()
	self.Root.Parent = game.Players.LocalPlayer.PlayerGui
	local use = self.Root.ToolCardShadowed:Clone()
	self.Template = use
	self.XUnit = use.Size.X.Offset
	
	self.Root:ClearAllChildren()
	self.Tools = {
		Left = {},
		Right = {},
		NonPhysical = {},
	}
	self.GUIs = {} -- [tool] = gui
end

function ToolGui:UpdatePositions()
	if not self.CanUpdate then return end
	local TotalGUIs = #self.Tools.Left + #self.Tools.Right + #self.Tools.NonPhysical
	-- lets use a trick to make it simpler
	-- first build everything from 0, then actually place it offsetted to the middle.
	local cpos = 0 
	-- start with nonphysicla, then left, then right
	local newpos = {}	
	local gotother = false
	for index, tool in pairs(self.Tools.NonPhysical) do
		gotother = true
		local gui = self.GUIs[tool]
		if index  > 1 then
			cpos = cpos + self.ToolWhitespace
		end
		if gui then
			local y = self.UnequippedY
			local sizex = self.XUnit
			if tool.IsEquipped then
				y = self.EquippedY
				sizex = self.XUnit + self.ExpandedDX
			end
			newpos[gui] = {cpos, y, sizex}
			cpos = cpos + self.XUnit
		end
	end

	for i, tab in pairs {self.Tools.Left, self.Tools.Right} do
		for index, tool in pairs(tab) do
			
			if index == 1 and gotother then
				cpos = cpos + self.CategoryWhitespace
			else
				cpos = cpos + self.ToolWhitespace
			end
			gotother = true
			local gui = self.GUIs[tool]
			if gui then
				 local y = self.UnequippedY
				local sizex = self.XUnit
				if tool.IsEquipped then
					y = self.EquippedY
					sizex = self.XUnit + self.ExpandedDX
				end
				newpos[gui] = {cpos, y, sizex}
				cpos = cpos + self.XUnit
		
			end
		end
	end
	local sizeof = cpos -- LOL ok.
	local xmux = -sizeof/2
	
	for gui, data in pairs(newpos) do
		local xpos = data[1]
		local ypos = data[2]
		local sizex = data[3]
		if sizex > self.XUnit then -- is expanded
			xpos = xpos - self.ExpandedDX/2
		end
		gui:TweenSizeAndPosition(UDim2.new(0, sizex, 0, gui.Size.Y.Offset), UDim2.new(0.5, xpos + xmux, 1,ypos), "Out", "Quad", 1, true)
	end
end

function ToolGui:RemoveTool(toolobj)
	local ftab
	if toolobj.Type == "Normal" then
		if toolobj.Hand == "Left" then
			-- hakes
			ftab = self.Tools.Left
		elseif toolobj.Hand == "Right" then
			ftab = self.Tools.Right
		end
	elseif toolobj.Name == "NonPhysical" then
		ftab = self.Tools.NonPhysical
	end
	local fi 
	for i,v in pairs(ftab) do
		if v == toolobj then
			fi = i
			break
		end
	end
	local ToolService = _G.Instinct.Services.ToolService
	local function getkeystr(enum)
		return ToolService.HotkeyNames[enum]
	end

	table.remove(ftab, fi)
	table.sort(ftab, function(a,b) return getkeystr(a.Hotkey) < getkeystr(b.Hotkey) end)
	self.GUIs[toolobj]:Destroy()
	self.GUIs[toolobj] = nil
	self:UpdatePositions()
end

function ToolGui:AddTool(toolobj)
	-- Cannot direct include toolservice QQ	
	local ToolService = _G.Instinct.Services.ToolService
	local KeyService = _G.Instinct.Services.KeyService
	
	-- helper
	local function getkeystr(enum)
	
		return ToolService.HotkeyNames[enum]
	end
	
	local new = self.Template:Clone()
	new.Parent = self.Root
	if toolobj.Type == "NonPhysical" then
		new.ContentClipper.Drop:Destroy()
		new.ContentClipper.ChangeHand:Destroy()
		new.ContentClipper.ToolName.Text = toolobj.Name
		
	else
		new.ContentClipper.Drop.MouseButton1Click:connect(function()
			_G.Instinct.Communicator:Send("DropTool", toolobj.ToolRoot)
		end)
		new.ContentClipper.ToolName.Text = toolobj.Tool.Name -- handle name = toolname

		new.ContentClipper.ChangeHand.MouseButton1Click:connect(function()

			if toolobj.Type == "Normal" then
				local i
				for index, tool in pairs(self.Tools[toolobj.Hand]) do
					if tool == toolobj then
						i = index
						break
					end
				end
				table.remove(self.Tools[toolobj.Hand], i)
				-- force quit update
				self.CanUpdate = false
				ToolService:ChangeHand(toolobj)
				self.CanUpdate = true
				local ftab
				if toolobj.Hand == "Left" then
					ftab = self.Tools.Left
				else
					ftab = self.Tools.Right
				end
		
				table.insert(ftab, toolobj)
				table.sort(ftab, function(a,b) return getkeystr(a.Hotkey) < getkeystr(b.Hotkey) end)
				self:UpdatePositions()
			end
		end)
	end
	
	new.ContentClipper.Hotkey.Text = getkeystr(toolobj.Hotkey)
	new.ContentClipper.ToolName.MouseButton1Click:connect(function()
		ToolService:GeneralEquip(toolobj)
	end)
	warn("CONNECT KEYSERVICE")
	--[[KeyService.KeyDown:connect(function(key)
		print(key, toolobj.Hotkey)
		if key == toolobj.Hotkey then
			ToolService:GeneralEquip(toolobj)
		end
	end)--]]
	-- register tool in data
	local ftab
	if toolobj.Type == "Normal" then
		if toolobj.Hand == "Left" then
			-- hakes
			ftab = self.Tools.Left
		elseif toolobj.Hand == "Right" then
			ftab = self.Tools.Right
		end
	elseif toolobj.Type == "NonPhysical" then
		ftab = self.Tools.NonPhysical
	end
	table.insert(ftab, toolobj)
	table.sort(ftab, function(a,b) return getkeystr(a.Hotkey) < getkeystr(b.Hotkey) end)
	self.GUIs[toolobj] = new
	
	self:UpdatePositions()
end

return ToolGui