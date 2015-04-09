local ButtonBar = {}

local Dim = Instinct.Include "Gui/DimTools"
local Presets = Instinct.Include "Gui/GuiPresets"

ButtonBar.Font = "ArialBold"
ButtonBar.FontSize = "Size12"
ButtonBar.WhiteSpace = 5
ButtonBar.Shade = 2
ButtonBar.TextWhiteSpace = 10 -- total whitespace


-- zomg u wanna msutfit? kthen
-- we will fit ur bar yes
-- we like that we like to fit the bar
-- pls


-- does not respect text size yes only y size
ButtonBar.MustFit = false
-- omg how much left; between buttons; etc
ButtonBar.FitGap = 10




function ButtonBar:Init(where, pos, size, parent)
	local frame = parent or Instance.new("Frame", where)
	frame.ClipsDescendants = true
	frame.BackgroundTransparency = 1
	local x_size, y_size = Dim.TextSize("test", self.Font, self.FontSize)
	frame.Size = size or UDim2.new(1,0, 0, y_size + self.Shade)
	frame.Position = pos or UDim2.new(0,0,0,0)
	self.Root = frame
end


function ButtonBar:AddButton(name)
	local button = Presets.Button(self.Shade)
	button.Parent = self.Root
	local max_x = -math.huge
	for i,v in pairs(self.Root:GetChildren()) do
		if v.Position.X.Offset + v.AbsoluteSize.X > max_x then
			max_x = v.Position.X.Offset + v.AbsoluteSize.X
		end
	end
	
	local new = max_x + self.WhiteSpace
	local size, ysize = Dim.TextSize(name, self.Font, self.FontSize)
	button.Size = UDim2.new(0, size + self.TextWhiteSpace, 0, ysize)
	button.Position = UDim2.new(0,new,0,0)
	button.Text = name 
	
	if self.MustFit then
		self:FixFit()
	end
	
	return button
end

return ButtonBar