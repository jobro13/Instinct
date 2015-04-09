-- A scrollbar
-- The :Add function should generate a Gui item which is then aligned

-- Call :Initialize() first after setting options to init the GUI

local ScrollBar = {}

ScrollBar.Type = "Vertical" -- not implemented horizontally yet, placeholder

ScrollBar.Parent = nil
ScrollBar.Size = nil
ScrollBar.BackgroundColor = Color3.new(0,0,0) -- THIS is just a placeholder;
-- > default is transparent
ScrollBar.BackgroundTransparency = 1

ScrollBar.WhiteSpace = 10 -- pixels between LIST items

ScrollBar.Align = "Middle" --> FOR HOOKS LATER ALIGN LEFT, RIGHT, etc
ScrollBar.Speed = 20

function ScrollBar:Constructor()
	self.Items = {}
end

function ScrollBar:Create(size)
	if not self.Parent then
		warn("No parent set, aborting ScrollBar creation")
		return
	end
	local new = Instance.new("Frame", self.Parent)
	new.BackgroundTransparency  = self.BackgroundTransparency
	new.BackgroundColor3 = self.BackgroundColor
	new.ClipsDescendants = true --> hehe
	new.Size = size or self.Size or UDim2.new(1,0,1,0)
	new.MouseWheelBackward:connect(function()
		self:Scroll(-1)
	end)
	new.MouseWheelForward:connect(function()
		self:Scroll(1)
	end)
	self.Root = new
	return new
end

function ScrollBar:PushGUIsAfterPos(pos, amount)
	for i = pos+1, #self.Items do
		local gui = self.Items[i]
		gui.Position = gui.Position + UDim2.new(0,0,0,amount)
		--x = x + itersize + self.WhiteSpace
	end
end

--> INTERNAL GUI insertion 

function ScrollBar:Insert(GUI, pos)
	local pos = pos or (#self.Items + 1)
	table.insert(self.Items, pos, GUI)
	GUI.Parent = self.Root
	local last_item = self.Items[pos-1]
	local x
	if not last_item then
		x = 0
	else
		--> OTHER HOOKS FOR HORIZONTAL!
		x = last_item.Position.Y.Offset + last_item.AbsoluteSize.Y + self.WhiteSpace
	end
	
	local barxsize = self.Root.AbsoluteSize.X	
	
	local alignsize = GUI.AbsoluteSize.X
	local loffset = (barxsize - alignsize)/2
	GUI.Position = UDim2.new(0,loffset,0,x)
	
	local plus = GUI.AbsoluteSize.Y + self.WhiteSpace
	print(plus)	
	self:PushGUIsAfterPos(pos, plus)
end

function ScrollBar:Scroll(dir)
	if not self.Items[1] then 
		return -- no items kthen
	end
	local mysize = self.Root.AbsoluteSize.Y
	local lgui = self.Items[#self.Items]
	local y = lgui.Position.Y.Offset + self.Speed * dir
	if y + lgui.AbsoluteSize.Y < mysize and dir < 0 then
		return -- end of scroll
		
	end
	if self.Items[1].Position.Y.Offset + self.Speed * dir > 0 then
		--print(self.Items[1].Position.Y.Offset + self.Speed * dir)

		return -- start of scroll
	end
	for i,v in pairs(self.Items) do
		v.Position = v.Position + UDim2.new(0,0,0,self.Speed*dir)
	end
end

function ScrollBar:Add(...)
	warn("No Add Function set -> return a GUI item please")
end

-- helper

function ScrollBar:FindGuiIndex(GUI)
	for i,v in pairs(self.Items) do
		if v == GUI then
			return i
		end
	end
end

function ScrollBar:AddBefore(GUI, ...)
	local gpos = self:FindGuiIndex(GUI) or 1
	local GUI_Item = self:Add(...)
	self:Insert(GUI_Item, gpos)
	return GUI_Item
end

function ScrollBar:AddAfter(GUI, ...)
	local gpos = self:FindGuiIndex(GUI)
	--> the insertion position is AFTER the gui so our actual pos is +1
	local gpos = (gpos and gpos+1) or 1
	local GUI_Item = self:Add(...)
	self:Insert(GUI_Item, gpos)
	return GUI_Item
end

function ScrollBar:Place(_,...)
	if #self.Items ~= 0 then 
		warn("sb is not emtpy use addafter or addbefore")
		return
	end
	ScrollBar:AddAfter(nil,...)
end

function ScrollBar:AddToEnd(...)
	local gpos = #self.Items+1
	local GUI_Item = self:Add(...)
	self:Insert(GUI_Item, gpos)
	return GUI_Item
end

-- DO NOT CHANGE GUI SIZE BEFORE CALLING THIS
-- WILL CHANGE GUI SIZE
function ScrollBar:ChangeGUISize(Gui, NewSize)
	local pos = self:FindGuiIndex(Gui)
	local osize = Gui.Size.Y.Offset
	local nsize = NewSize.Y.Offset
	local delta = nsize - osize
	self:PushGUIsAfterPos(pos, delta)
	Gui.Size = NewSize
end

function ScrollBar:AddToStart(...)
	local gpos = 1
	local GUI_Item = self:Add(...)
	self:Insert(GUI_Item, gpos)
	return GUI_Item
end

function ScrollBar:Remove(GUI)
	local lepos = self:FindGuiIndex(GUI)
	if not lepos or not self.Items[lepos] then
		warn("cannot find item!?")
		return -- wat dafaq
	end
	local ledelta = self.Items[lepos].AbsoluteSize.Y + self.WhiteSpace	
	table.remove(self.Items, lepos)
	for i = lepos, #self.Items do
		local gui = self.Items[i]
		gui.Position = gui.Position - UDim2.new(0,0,0,ledelta)
	end
	GUI:Destroy() -- .. !? why wasnt this there...
end

return ScrollBar