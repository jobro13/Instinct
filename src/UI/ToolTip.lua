-- omg a tooltip
-- how awesome is dat
-- very awesome
-- such wow

local ToolTip = {}

local DT, PAL, ObjectService

ToolTip.Colors = {
	info = PAL:Get("Shade1", "Shade1")
}

ToolTip.BackgroundColor = PAL:Get("Default", "Shade2")
ToolTip.InfoColor = PAL:Get("Default", "Shade1")
ToolTip.ErrorColor = PAL:Get("Complement", "Shade1")
ToolTip.SeperationColor = PAL:Get("Background", "Shade4")
ToolTip.TextColor = PAL:Get("Text", "White")
ToolTip.TextBoundsColor = PAL:Get("Text")
ToolTip.WhiteSpace = 10
ToolTip.YWhiteSpace = 6
ToolTip.SeperationSize = 2

ToolTip.Font = "Arial"
ToolTip.FontSize = "Size14"

ToolTip.TitleFontSize = "Size18"
ToolTip.TitleFont = "ArialBold"

function ToolTip:Constructor()
	DT = _G.Instinct.UI.DimTools
	PAL = _G.Instinct.Utilities.Palette
	ObjectService = _G.Instinct.Services.ObjectService
	self.Mouse = game.Players.LocalPlayer:GetMouse()
	local gui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
	local fr = Instance.new("TextLabel", gui)
	fr.Visible = false 
	fr.BackgroundColor3 = self.BackgroundColor
	fr.TextColor3 = Color3.new(0,0,0)
	fr.Size = UDim2.new(0,10,0,20)
	self.Frame = fr
	fr.Font = self.TitleFont
	fr.FontSize = self.TitleFontSize
	fr.TextColor3 = self.TextColor
	fr.TextStrokeColor3 = self.TextBoundsColor
	fr.TextStrokeTransparency = 0
	fr.BorderSizePixel = 0
end

function ToolTip:Destroy()
	self.Frame.Parent:Destroy()
end

function ToolTip:Hide()
	self.Frame.Visible = false
end

-- SHOW A TOOLTIP!! AWESMEEE!
function ToolTip:Show(RBXInstance, WarnList, InfoCap, Raw, UseName) 
	-- ples
	local Mouse = self.Mouse
	local fr = self.Frame
	self.Frame.Visible=true
	self.Frame:ClearAllChildren()
	local o = ObjectService:GetObject(RBXInstance.Name)
--[[	if not o then 
		warn("Yeah I'm not gonna show a tooltip if it doesnt have an object, hiding")
		self:Hide()
		return
	end--]]
	
	fr.Text = UseName or RBXInstance.Name
	local x,y = DT.TextSize(fr.Text, fr.Font, fr.FontSize)
	fr.Size = UDim2.new(0,x+self.WhiteSpace,0,y + self.YWhiteSpace)
	local props = ObjectService:GetInfo(RBXInstance.Name, RBXInstance)
	local max_x = x + self.WhiteSpace
	local max_y = 0
	local wr = {}
	
	local function add(t,c)
			local new = fr:Clone()
			new:ClearAllChildren()
			new.Parent = fr
			new.BackgroundColor3 = c
			new.Font = self.Font
			new.FontSize = self.FontSize
			new.Text = t -- yeah we need some helper funcitons
			local sep = Instance.new("Frame", new)
			sep.BorderSizePixel = 0
			sep.BackgroundColor3 = self.SeperationColor
			sep.Size = UDim2.new(1,0,0,self.SeperationSize)
			sep.Position = UDim2.new(0,0,1,-self.SeperationSize)
			sep.ZIndex=2
			local x,y = DT.TextSize(t, fr.Font, fr.FontSize)
			local x = x + self.WhiteSpace
			max_x = (x > max_x and x) or max_x
			max_y = (y > max_y and y) or max_y
			table.insert(wr,new)
	end
		
	if not Raw then
	for i,v in pairs(props) do
	--	print(i,v)
		local propinfo = ObjectService:GetProperty(i)
	
		if propinfo and propinfo.Mode.ShowInfo then
			add(i .. " : " .. tostring(v), self.InfoColor)
		end
	end
	end
	-- push warnings here
	for i,v in pairs(WarnList or {}) do
		add(v, self.ErrorColor)
	end
	-- end push warn block
	
	if InfoCap then
		for i,v in pairs(InfoCap) do 
			if type(v) == "table" then -- k
				local iname = v[1]
				local txt = v[2]
				if iname and txt and self.Colors[iname] then
					add(txt,self.Colors[iname])
				end
			end
		end
	end

	fr.Size = UDim2.new(0, max_x, 0, y + self.YWhiteSpace)
	
	for i,v in pairs(wr) do
		v.Size = UDim2.new(0, max_x,0,max_y+self.YWhiteSpace)
		v.Position = UDim2.new(0.5, -v.Size.X.Offset/2, 1, (i-1) * (y+self.YWhiteSpace))
	end
	
	fr.Position = UDim2.new(0, Mouse.X - max_x, 0, Mouse.Y)
end

return ToolTip