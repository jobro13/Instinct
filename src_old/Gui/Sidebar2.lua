local Sidebar = {}

-- Sidebar is a special GUI.
-- It creates a sidebar which opens on the right side of the screen.
-- It also features a menu button bar on top of the bar


local Palette = Instinct.Include "Utilities/Palette"
local SFX = Instinct.Include "Gui/SFX"
local Dim = Instinct.Include "Gui/DimTools"
local ButtonBar = Instinct.Include "Gui/ButtonBar"

-- If mouse is x pixels right of it; open;
Sidebar.OpenXMinimum = 75
Sidebar.XSize = 150
Sidebar.Background = Palette:Get("Default", "Shade2")
Sidebar.Border = Palette:Get("Default", "Shade4")
Sidebar.BorderSize = 3
Sidebar.ButtonBarReserve = 30


function Sidebar:Create(buttonlist)
	local player = game.Players.LocalPlayer
	local root = Instance.new("ScreenGui", player.PlayerGui)
	root.Name = "Sidebar"
	self.Screen = root
	local bar = Instance.new("Frame", root)
	bar.BackgroundColor3 = self.Background
	bar.BorderSizePixel = self.BorderSize
	bar.BorderColor3 = self.Border
	bar.Size = UDim2.new(0, self.XSize, 1,0)
	bar.Position = UDim2.new(1, 0, 0, 0)
	local swbar = Instance.new("Frame", bar)
	swbar.Size = UDim2.new(0, self.XSize, 0, self.BorderSize)
	swbar.Position = UDim2.new(0,0,0,self.ButtonBarReserve)
	swbar.BorderSizePixel = 0
	swbar.BackgroundColor3 = self.Border
	-- reserve regions for menu and content
	local menu = Instance.new("Frame", bar)
	menu.Size = UDim2.new(1,0,0, self.ButtonBarReserve)
	menu.BackgroundTransparency = 1
	self.Menu = menu

	local content = Instance.new("Frame", bar)
	content.Size = UDim2.new(1,0,1, -(self.ButtonBarReserve + self.BorderSize))
	content.Position = UDim2.new(0,0,0, self.ButtonBarReserve + self.BorderSize)
	content.BackgroundTransparency = 1
	
	self.Content = content	
	
	local bb = Instinct.Create(ButtonBar)
	
	bb:Init(self.Menu)
	for i,v in pairs(buttonlist) do
		bb:AddButton(v)		
	end	
	bb.Root.Position = bb.Root.Position + UDim2.new(0,0,0,10)
	
	self.Root = bar
end


-- opens the work task to detect the mouse, etc.
function Sidebar:Work(showhelp)
	local mouse = game.Players.LocalPlayer:GetMouse()
	delay(0, function()
		while wait() do 
		local xs = Dim.GetScreenSize().X
		local mx = mouse.X
	--print(xs, mx)
		if not self.IsOpen then 
			if xs - mx <= self.OpenXMinimum then
				self:Open()
				self.IsOpen = true
			end
		elseif xs - mx >= self.OpenXMinimum + self.XSize then
			-- check if mouse is away; close
			self:Close()
			self.IsOpen = false
		end
		end
	end)
	if showhelp then
		local TextLabel = Instance.new("TextLabel", self.Screen)
		TextLabel.BackgroundColor3 = Palette:Get("Default", "Shade2")
		TextLabel.Size = UDim2.new(0, 200, 0, 50)
		TextLabel.BorderSizePixel = 0
		TextLabel.Text = "Hover your mouse here to show the sidebar!"
		TextLabel.TextColor3 = Palette:Get("Text", "White")
		TextLabel.TextStrokeColor3 = Palette:Get("Text")
		TextLabel.TextStrokeTransparency = 0
		TextLabel.Font = "Arial"
		TextLabel.FontSize = "Size18"
		TextLabel.TextWrapped = true
		TextLabel.Position = UDim2.new(1, - 250, 0.5, -25)
		self.Help = TextLabel
	end
end

function Sidebar:Open()
	if self.Help then
		self.Help:Destroy()
	end
	self.IsOpen = true
	self.Root:TweenPosition(UDim2.new(1,-self.XSize,0,0), "Out", "Quad", 0.125, true)
end

function Sidebar:Close()
	self.IsOpen = false
	self.Root:TweenPosition(UDim2.new(1,0,0,0), "Out", "Quad", 0.125, true)
end



return Sidebar