-- MainMenu provides the main menu for the game
-- Additional modules can be launched from here
-- Insertion points are provided



local MainMenu = {}

MainMenu.TitleFont = "ArialBold"
MainMenu.FontSize = "Size36"
MainMenu.TitleShade = 3

MainMenu.BarSize = 4
MainMenu.BarOffset = 3
-- elegant is to put this in constructor
MainMenu.BarColor = _G.Instinct.Utilities.Palette:Get()  -- meh?
MainMenu.BarScale = 0.8 -- 80% of the original size

MainMenu.TextWhiteSpace = 10

MainMenu.ButtonFont = "ArialBold"
MainMenu.ButtonFontSize = "Size24"
MainMenu.VersionFontSize = "Size14"

MainMenu.WhiteSpace = 20
MainMenu.ButtonShading = 2 -- wow so much shading
MainMenu.XOffset = 50

MainMenu.Choosen = nil --


function MainMenu:Constructor()
	self.Choosen = _G.Instinct.Create(_G.Instinct.Utilities.Event)
end

local Player = game.Players.LocalPlayer

function MainMenu:CreateFromList(title, list) -- creates the main menu from gui items
	local Palette = _G.Instinct.Utilities.Palette 
	local Locale = _G.Instinct.Services.Locale 
	local Presets = _G.Instinct.Gui.GuiPresets 
	local Dim = _G.Instinct.Gui.DimTools
	local VERSION = _G.Instinct.Version
	local title = title 
	local Root = Instance.new("ScreenGui", Player.PlayerGui)
	self.Root = Root
	local Backdrop = Presets.Backdrop(5)
	local MMLabel, x, y = Presets.CustomButton(
		title,		self.TitleShade, self.TitleFont, self.FontSize, 
		 Palette:Get("Text"),  Palette:Get("Complement"), 
		self.TextWhiteSpace) 
	local curry = self.WhiteSpace
	Backdrop.Parent = Root
	MMLabel.Parent = Backdrop
	local curry = curry + y + self.WhiteSpace
	MMLabel.Position = UDim2.new(0.5, -x/2, 0, self.WhiteSpace)
	local max_x = x
	table.insert(list, 1, "Version "..VERSION)
	for i,v in pairs(list) do
		local DeltaY = -( self.TextWhiteSpace - self.BarOffset )
		local inspos = curry + DeltaY 
	--	local new = Instance.new("Frame", BackDrop) -- ?????????
		local b,x,y
		if i ~= 1 then 
			b,x,y = Presets.CustomButton(v, self.ButtonShading, self.ButtonFont, 
			self.ButtonFontSize, Palette:Get("Text"), Palette:Get("Complement", "Shade2"), 
			self.TextWhiteSpace
			)
		else 
			b,x,y = Presets.CustomButton(v, self.ButtonShading, self.ButtonFont,
			self.VersionFontSize,  Palette:Get("Text"), Palette:Get("Complement", "Shade1"), 
			self.TextWhiteSpace
			)
		end 
		b.Parent = Backdrop
		b.Position = UDim2.new(0.5, -x/2, 0, curry)
		b.MouseButton1Click:connect(function()
			self.Choosen:fire(b.Text)
		end)
		curry = curry + y + self.WhiteSpace
		if x > max_x then
			x = max_x
		end
	end
	
	Backdrop.Size = UDim2.new(0, max_x + self.WhiteSpace, 0, curry)
	Backdrop.Position = UDim2.new(1,-(max_x + self.WhiteSpace) - self.XOffset, 0.5, -curry/2)
end

function MainMenu:Close()
	self.Root:Destroy()
end


return MainMenu