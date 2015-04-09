local Chat = {}

local ScrollBar = Instinct.Include "Gui/ScrollBar"
local Palette = Instinct.Include "Utilities/Palette"
local ChatData = Instinct.Include "Chat"
local SFX = Instinct.Include "Gui/SFX"
local DimTools = Instinct.Include "Gui/DimTools"

Chat.IsFocussed = false

function Chat:SelectMode(char)
	local kw = ChatData.Keywords[char.."/"]
	if kw and self.SelectedText then
		self.SelectedText.Text = kw .. " [" .. ChatData.EnergyTap[kw]  .. "]"
		
	end
end

function Chat:Enable()
	self.Enabled=true
	warn("creating")
	warn(tostring(self))
	local Screen = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
	local Root = Instance.new("Frame")
	Root.Parent = Screen
	Root.BackgroundColor3 = Palette:Get("Default", "Shade2")
	Root.BackgroundTransparency = 0
	Root.Size = UDim2.new(0,260,0,200)
	Root.BorderColor3 = Palette:Get("Default", "Shade4")
	Root.BorderSizePixel = 2;
	Root.Position = UDim2.new(0,20,0,20)
	--Root.ClipsDescendants = true
	Root.BackgroundTransparency = 1
	local ChatModes = {"w", "d", "y", "s", "g"}
	local ChatETap = {}
	for i,v in pairs(ChatModes) do
		local kw = ChatData.Keywords[v.."/"]
		if kw then
			ChatETap[v] = ChatData.EnergyTap[kw]
		end
	end
	self.ChatContainer = Root
	print(Root:GetFullName())
	local ChatBar = Instance.new("Frame", Screen)
	ChatBar.Position = UDim2.new(0, 20, 0, 200 + 20 + 10)	
	ChatBar.BorderSizePixel = 2
	ChatBar.BorderColor3 = Palette:Get("Default", "Shade4")
	ChatBar.BackgroundColor3 = Palette:Get("Default", "Shade2")
	
	ChatBar.Size = UDim2.new(0, 220, 0, 36)
	local CX = 0
	local selected
	for i,v in pairs(ChatModes) do
		local new = Instance.new("TextButton", ChatBar)
		new.BorderSizePixel = 1
		new.BorderColor3 = Palette:Get("Default", "Shade3")
		new.BackgroundColor3 = Palette:Get("Default", "Shade1")
		new.Text = v
		new.Size = UDim2.new(0, 15, 0, 18)
		new.Position = UDim2.new(0, 15 * (i - 1) + i * 1, 0, 0)
		new.Font = "ArialBold"
		new.TextColor3 = Palette:Get("Text", "White")
		new.TextStrokeColor3 = Palette:Get("Text")
		new.TextStrokeTransparency = 0
		new.FontSize = "Size14"
		CX = 15 * (i ) + (i-1) * 1
		if v == "d" then
			selected=new
			new.BackgroundColor3 = Palette:Get("Shade1", "Shade2")
		end
		new.MouseButton1Click:connect(function()
			self:SelectMode(v)
			selected.BackgroundColor3 = Palette:Get("Default", "Shade1")
			new.BackgroundColor3 = Palette:Get("Shade1", "Shade2")
			selected=new
		end)
	end
	
	local SelectedText = Instance.new("TextLabel", ChatBar)
	SelectedText.BorderColor3 = Palette:Get("Default", "Shade3")
	SelectedText.BackgroundColor3 = Palette:Get("Default", "Shade1")
	SelectedText.Text = ""
	SelectedText.Size = UDim2.new(0, CX, 0, 16)
	SelectedText.Position = UDim2.new(0, 1, 0, 19)
	SelectedText.Font = "ArialBold"
	SelectedText.TextColor3 = Palette:Get("Text", "White")
	SelectedText.TextStrokeColor3 = Palette:Get("Text")
	SelectedText.TextStrokeTransparency = 0
	SelectedText.FontSize = "Size14"

	
	self.SelectedText = SelectedText	
	self:SelectMode("d")	
	
	ChatBar.Size = UDim2.new(0, CX+2, 0, 36)
	
	local Form = Instance.new("TextBox", ChatBar)
	Form.BorderColor3 = Palette:Get("Default", "Shade3")
	Form.BackgroundColor3 = Palette:Get("Default", "Shade1")
	Form.Text = "Click here or press / to chat"
	Form.Size = UDim2.new(0, 260 - CX - 8 - 2, 0, 16)
	Form.Position = UDim2.new(0, CX + 8, 0, 10)
	Form.Font = "ArialBold"
	Form.TextColor3 = Palette:Get("Text", "White")
	Form.TextStrokeColor3 = Palette:Get("Text")
	Form.TextStrokeTransparency = 0
	Form.FontSize = "Size14"
	local osize =  UDim2.new(0, 260 - CX - 8 - 2, 0, 16)
	Form.Changed:connect(function(prop)
		if prop == "Text" then
			if Form.TextBounds.X + 10 > Form.Size.X.Offset then
				Form.Size = UDim2.new(0, Form.TextBounds.X + 10, 0, Form.Size.Y.Offset)
				
			end
		end
	end)
	
	Form.FocusLost:connect(function(t)
		if not t then return end
		self.IsFocussed = false
		if selected.Text == "d" then
			Instinct.Communicator:Send("Chat", Form.Text)
		else
			Instinct.Communicator:Send("Chat", selected.Text.."/ "..Form.Text)
		end
		Form.Size = osize
		Form.Text = "Click here or press / to chat"
	end)
	
	local uis = game:GetService("UserInputService")
	uis.InputBegan:connect(function(obj)
		local _,key = pcall(function() return obj.KeyCode end)
		
		if key == Enum.KeyCode.Slash then
			if self.IsFocussed then return end
			self.IsFocussed = true
			Form:CaptureFocus()
		end
	end)
	
	return Root
end

function Chat:Push(delta, ignore)
	for i,v in pairs(self.ChatContainer:GetChildren()) do
		if v ~= ignore then 
			v.Position = UDim2.new(0,0,1, v.Position.Y.Offset - delta)
		end
		if (v.Position.Y.Offset + v.Size.Y.Offset + 2) < -self.ChatContainer.Size.Y.Offset then
			v:Destroy()
		end
	end
end

function Chat:PutLocal(Message)
	self:Process(Message, "Default", "_local")
end

function Chat:Process(Message, Mode, Receipent)
	warn(tostring(self.ChatContainer))
	warn(tostring(self))
	-- I WANT A FUCKING STACK TRACE< WTF
	--error("err, mes was : " .. Message)
	if not self.ChatContainer then return end
	print("PROCESSING", Message, Mode, Receipent, self.Enabled)
	print(self.ChatContainer:GetFullName())
	if not self.Enabled then return end
	local transform = {
		Default = "said",
		Whisper = "whispered",
		Yell = "yelled",
		Shout = "shouted",
		Global = "screamed"
	}	
	
	local text = Instance.new("TextLabel", self.ChatContainer)
	local font = "ArialBold"
	local fonts = "Size18"
	
	local Receipent=Receipent
	local put = Receipent .. " " .. (transform[Mode] or "ERR_NOMODSTR") .. ": " .. Message
	if Receipent == "_host" then
		text.BackgroundColor3 = Palette:Get("Shade1", "Shade2")
		put = "Server notified: " .. Message
	elseif Receipent == "_local" then
		put = Message
		text.BackgroundColor3 = Palette:Get("Complement", "Shade1")
	else
		text.BackgroundColor3 = Palette:Get("Complement", "Shade2")
	end
	
	local x,y = DimTools.TextSize(put, font, fonts)
	text.Size = UDim2.new(0, x + 10, 0, y + 6)
	SFX.Shade(text,2)

	text.Font = font
	text.FontSize = fonts
	text.Text = put
	text.TextColor3 = Palette:Get("Text", "White")
	text.TextStrokeColor3 = Palette:Get("Text")
	text.TextStrokeTransparency = 1
	
	text.Position = UDim2.new(0, 0, 1, -(y + 6 + 2))
	
	self:Push(y + 6 + 6, text) -- 3 = whitespace qq
end


return Chat