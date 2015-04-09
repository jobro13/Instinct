local SideBar = {}
-- old sidebar, deprecated --


local ObjectService, ScrollBar, ToolService, Dim
SideBar.IsOpen = true

SideBar.ForceClosed = false

SideBar.OpenTime = 0.125
SideBar.MinimalXOpen = 75

function SideBar:Constructor()
	ObjectService = _G.Instinct.Services.ObjectService
	ScrollBar = _G.Instinct.UI.ScrollBar
	ToolService = _G.Instinct.Services.ToolService
	Dim = _G.Instinct.UI.DimTools
	print("CREATED SB")
	local new = game:GetService("ReplicatedStorage").Inventory:Clone()
	new.Parent = game.Players.LocalPlayer.PlayerGui
	self.XSize = new.Sidebar.Size.X.Offset
	local ResourceCategoryContainer = new.Sidebar.RealBar.Inventory.Ore:Clone()
	self.InventoryYBase = ResourceCategoryContainer.Size.Y.Offset
	local Contents = ResourceCategoryContainer.Contents
	local Line = Contents.Cassiterite.Line:Clone()
	local Resource = Contents.Cassiterite:Clone()
	self.InventoryYDelta = Resource.Size.Y.Offset
	--Contents:ClearAllChildren()
	self.ResourceCategoryContainer = ResourceCategoryContainer
	--self.Contents = Contents
	self.Line = Line
	self.Resource = Resource
	self.Resource.Line:Destroy()
	ResourceCategoryContainer.Contents:ClearAllChildren()	
	new.Sidebar.RealBar.Inventory:ClearAllChildren()
	self.Inventory = _G.Instinct:Create(ScrollBar)
	self.Inventory.Parent = new.Sidebar.RealBar.Inventory
	self.Inventory:Create()
	
	function self.Inventory:Add(GUI)
		return GUI -- HAX
	end
	
	self.Data = {}	
	
	self.Root = new
end

function SideBar:Destroy()
	self.Root:Destroy()
end


SideBar.DefaultCategory = "Miscallerous"
function SideBar:GetObjectCategory(Object)
	return (Object and Object.Material) or self.DefaultCategory
end

function SideBar:Work()
	local mouse = game.Players.LocalPlayer:GetMouse()
	self.Root.Sidebar.Visible=true
	delay(0, function()
		while wait() do 
			local xs = Dim.GetScreenSize().X
			local mx = mouse.X
			--print(xs, mx)
			if not self.ForceClosed then 
				if not self.IsOpen then 
					if xs - mx <= self.MinimalXOpen then
						self:Open()
					end
				elseif xs - mx >= self.MinimalXOpen + self.XSize then
					-- check if mouse is away; close
					self:Close()
				end
			end
		end
	end)
end

function SideBar:MakeVisible()
	self.Root.Sidebar.Visible = true
end

function SideBar:ForceClose()
	self.ForceClosed=true
	self:Close()
end

function SideBar:EnableOpen()
	self.ForceClosed=false
	
end

function SideBar:Open()
	self.IsOpen = true
	self.Root.Sidebar:TweenPosition(UDim2.new(1,-self.XSize,0,0), "Out", "Quad", self.OpenTime, true)
end

function SideBar:Close()
	self.IsOpen = false
	self.Root.Sidebar:TweenPosition(UDim2.new(1,0,0,0), "Out", "Quad", 0.125, true)
end



function SideBar:AddBackpackItem(resource)
	local obj = ObjectService:GetObject(resource.Name)
	local Category = self:GetObjectCategory(obj)
	if not self.Data[Category] then
		local RootGui = self.ResourceCategoryContainer:Clone()
		RootGui.Title.CategoryText.Text = Category
		self.Data[Category] = {GUI = RootGui}
		RootGui.Title.Collapse.MouseButton1Click:connect(function()
			-- TODO: change rectangle thing
			if RootGui.Contents.Visible then
				RootGui.Contents.Visible = false
				RootGui.Title.Collapse.Arrow.Rotation = 0
				self.Inventory:ChangeGUISize(RootGui, UDim2.new(1,0,0,self.InventoryYBase))
			else
				RootGui.Contents.Visible = true
				local NumItems = #(self.Data[Category])
				RootGui.Title.Collapse.Arrow.Rotation = 180
				self.Inventory:ChangeGUISize(RootGui, UDim2.new(1, 0,0, self.InventoryYBase + NumItems * self.InventoryYDelta))
			end
		end)
		if Category == self.DefaultCategory then
			self.Inventory:AddToEnd(RootGui)
		else
			self.Inventory:AddToStart(RootGui)
		end
	end
	local CatGUI = self.Data[Category].GUI
	local UseTable = self.Data[Category]
	local NumChildren = #(UseTable)
	local NewResource = self.Resource:Clone()
	NewResource.RealText.Text = resource.Name
	NewResource.Parent = CatGUI.Contents
	NewResource.Position = UDim2.new(0,0,0, NumChildren * self.InventoryYDelta)
	-- bind to events
	NewResource.MouseButton1Click:connect(function()
		self:RequestDrop(resource)
	end)
	NewResource.MouseButton2Click:connect(function()
		self:RequestCreateTool(resource)
	end)
	if NumChildren > 0 then
		local LastGui = UseTable[#UseTable]
		if LastGui then
			self.Line:Clone().Parent = LastGui
		end
	end
	-- Setup data to find it back
	table.insert(UseTable, NewResource)
	UseTable[resource] = NewResource
	-- figure out if changesize should be called to fix scrollbar st00f
	if CatGUI.Contents.Visible then
		self.Inventory:ChangeGUISize(CatGUI, UDim2.new(1, 0, 0, (NumChildren+1) * self.InventoryYDelta + self.InventoryYBase))
	end
end

function SideBar:RemoveBackpackItem(resource)
	local obj = ObjectService:GetObject(resource.Name)
	local Category = self:GetObjectCategory(obj)
	local Tab = self.Data[Category]
	local GUI = Tab[resource]
	local ID
	for i,v in ipairs(Tab) do 
		if v == GUI then
			ID = i
			break
		end
	end
	print(ID)
	-- first PUSHDOWN all remaing things
	for i = ID+1, #Tab do 
		print(i)
		Tab[i].Position = UDim2.new(0,0,0,(i-2) * self.InventoryYDelta)
	end
	if ID == #Tab then -- never remove line from first ID
		local LineGUI = Tab[ID-1]
		if LineGUI and LineGUI:FindFirstChild("Line") then
			LineGUI.Line:Destroy()
		end
	end
	Tab[resource] = nil
	table.remove(Tab, ID)
	GUI:Destroy()
	if #Tab == 0 then
		self.Inventory:Remove(Tab.GUI)
		self.Data[Category] = nil
	else
		if Tab.GUI.Contents.Visible then
			self.Inventory:ChangeGUISize(Tab.GUI, UDim2.new(1, 0, 0, (#Tab) * self.InventoryYDelta + self.InventoryYBase))
		end
	end
end

function SideBar:Show(WName)
	-- later. show craft/inventory
end

function SideBar:RequestDrop(resource)
	local comm = _G.Instinct.Communicator
	comm:Send("Drop", resource)
end

function SideBar:RequestCreateTool(resource)
	ToolService:RequestToolCreation("DefaultTool", {name={resource}})
end



return SideBar