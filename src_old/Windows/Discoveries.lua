local Discovery = {}

local ScrollBar = Instinct.Include "Gui/ScrollBar"
local Palette = Instinct.Include "Utilities/Palette"
local SFX = Instinct.Include "Gui/SFX"

local ObjectService = Instinct.Include "Services/ObjectService"

function Discovery:Constructor()
	self.Tabs = {}
	self.Data = {}
end

function Discovery:ShowTab(Which)
	local wind = self
	if not self.Tabs[Which] then 
		self.Data[Which] = {}
		local new = Instinct.Create(ScrollBar)
		new.Parent = self.Window.Canvas
		new:Create(UDim2.new(0.8, 0, 0.8, 0))
		new.Root.Position = UDim2.new(0.1, 0, 0.1, 0)
		function new:Add(name, discoverer, tabletitle)
			local Container = Instance.new("Frame")
			Container.Size = UDim2.new(1,0,0, 22)
			Container.BackgroundTransparency=1
			
			local text = Instance.new("TextLabel", Container)
			text.BackgroundColor3 = Palette:Get("Shade1", "Shade2")
			if tabletitle then
				text.BackgroundColor3 = Palette:Get("Shade1", "Shade3")
			end
			text.TextColor3 = Palette:Get("Text", "White")
			text.TextStrokeTransparency = 0
			text.TextStrokeColor3 = Palette:Get("Text")
			text.Font = "ArialBold"
			text.FontSize = "Size18"
			text.Text = name
			text.BorderSizePixel=0
			text.Size = UDim2.new(0.4,0,  0, 20)
			local main=text
			local text = Instance.new("TextLabel", Container)
			text.BackgroundColor3 = Palette:Get("Shade1", "Shade2")
			if tabletitle then
				text.BackgroundColor3 = Palette:Get("Shade1", "Shade3")
			end
			text.BorderSizePixel=0
			text.TextColor3 = Palette:Get("Text", "White")
			text.TextStrokeTransparency = 0
			text.TextStrokeColor3 = Palette:Get("Text")
			text.Font = "ArialBold"
			text.FontSize = "Size18"
			text.Text = discoverer or "No one yet."
			if not discoverer then
				text.BackgroundColor3 = Palette:Get("Shade1", "Shade1")
			elseif discoverer == game.Players.LocalPlayer.Name then
				text.BackgroundColor3 = Palette:Get("Complement", "Shade1")
			end
			text.Size = UDim2.new(0.4, 0, 0, 20)
			text.Position = UDim2.new(0.5,0,0,0)
			SFX.Shade(text, 2)
			SFX.Shade(main, 2)
			if not tabletitle then
		
				wind.Data[Which][name] = {Name = main, Discoverer = text}
			end
			return Container
		end
		self.Tabs[Which] = new
		new:AddToStart("Resource name", "Discoverer", true)
		
				
		
		
		if Which == "Resource" then 

			
			local  mknames = {}
			for ObjName in pairs(ObjectService.ObjectData) do
				if not self.Tabs[Which][ObjName] then
					table.insert(mknames, ObjName)
				end
			end
			table.sort(mknames)		
			local check = game:GetService("ReplicatedStorage"):FindFirstChild("Discoveries")	
			for i,name in pairs(mknames) do
				local disc = check:FindFirstChild("Resource")
				local discoverer

				if disc then
					if disc:FindFirstChild(name) then
						discoverer = disc[name].Value
					end
				end
				new:AddToEnd(name,discoverer)
			end
						
			
			if check then
				if check:FindFirstChild("Resource") then
					check.Resource.ChildAdded:connect(function(what)
						local objname = what.Name
						local discoverer = what.Value
						local data = self.Data[Which][objname]
						if data then
							local gui = data.Discoverer
							gui.Text = discoverer
							if discoverer == game.Players.LocalPlayer.Name then
								gui.BackgroundColor3 = Palette:Get("Complement", "Shade1")
							end
						end
					end)
				end
			end
		end
	end
end


function Discovery:Open(Window)
	print(Window.Canvas:GetFullName())
	self.Window = Window
	self:ShowTab("Resource")
end

function Discovery:Close(Window)
	print('final')
end

return Discovery