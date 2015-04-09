-- Should be loaded AFTER all services and other BS are loaded
-- Loads the action hooks
-- Action hooks;

-- Run(Target, Tool) -> (tool is optional) runs given actions. IS already confirmed to be ok
-- Check(Target, Tool) -> 


return (function()
local IntentionService = _G.Instinct.Services.IntentionService
local ToolService = _G.Instinct.Services.ToolService
local DamageService = _G.Instinct.Services.DamageService

local toadd ={}
local function mk(name)
	local o = {Name=name}
	table.insert(toadd, o)
	return o
end

-- START ACTION INSPECT DEAD CORPSE 
local InspectBackpack = mk "Inspect Backpack"

local IBS_Open = nil; -- inspect backpack open debouncher.

function InspectBackpack:Run(targ)
	if IBS_Open then
		return --no.
	end
	local r = targ
	if targ.Name ~= "Backpack" then
		if targ.Name == "chParent" then 
			r = targ.Parent
		end
	end
	if r and r:FindFirstChild("BPRootLocation") then
		if r.BPRootLocation.Value then
			-- good. let's get sidebar.
			local newsidebar = _G.Instinct.Create(_G.Instinct.Gui.SideBar)
			IBS_Open = newsidebar
			local root = r.BPRootLocation.Value
			_G.Instinct.Gui.SideBar:ForceClose() --> close own inventory.
			
			newsidebar.Root.Sidebar.RealBar.Tabs:ClearAllChildren()
			local close_button_loc = newsidebar.Root.Sidebar.RealBar.Tabs
			local new = Instance.new("TextButton", close_button_loc)
			new.Size = UDim2.new(0.9, 0, 0.9, 0)
			new.Position = UDim2.new(0.05, 0, 0.05,0)
			new.BackgroundTransparency = 0.8
			new.Text = "Close"
			new.FontSize = Enum.FontSize.Size24
			new.Font = Enum.Font.SourceSans
			new.BorderSizePixel=0
			new.ZIndex=3
			
			new.MouseButton1Click:connect(function()
				newsidebar:Destroy() -- removes gui.
				IBS_Open = nil
				_G.Instinct.Gui.SideBar:EnableOpen()
			end)
			
			for i,v in pairs(root:GetChildren()) do
				newsidebar:AddBackpackItem(v)
			end
			root.ChildRemoved:connect(function(v)
				newsidebar:RemoveBackpackItem(v)
			end)
			
			function newsidebar:RequestDrop(v)
				local comm = _G.Instinct.Communicator
				comm:Send("SwapBackpack", v)
			end
			
			-- we are done; open
			newsidebar:MakeVisible() -- done drawing
			newsidebar:Open()
		end
	end
end
	

-- Shake tree action LOL KAPPA XDDDDD JOBRO SO FUCKING TRASH-- 	
local ShakeTree = mk "Shake tree"

function ShakeTree:Run(targ)
	print("oh very shake tree Kappa")
end

-- Attack action --
local Attack = mk "Attack"

function Attack:Run(Targ, Hand)
	print("WAT attack? jobro13 so trashhh XDDD")
	local Tool = ToolService["Equipped"..Hand]
	print(Tool, Hand)
	if Tool then
		print("EXISITSerino	")
		DamageService:Attack(Tool, Targ)
	end
end

for _,action in pairs(toadd) do
	IntentionService:AddAction(action)
end
	
end)