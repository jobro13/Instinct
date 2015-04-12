-- Should be loaded AFTER all services and other BS are loaded
-- Loads the action hooks
-- Action hooks;

-- Run(Target, Tool) -> (tool is optional) runs given actions. IS already confirmed to be ok
-- Check(Target, Tool) -> 


return (function()
local IntentionService = _G.Instinct.Services.IntentionService
local ToolService = _G.Instinct.Services.ToolService
local DamageService = _G.Instinct.Services.DamageService
local Knapping = _G.Instinct.Libraries.Knapping


local toadd ={}
local function mk(name, type)
	local o = {Name=name}
	table.insert(toadd, {o,type})
	return o
end

-- START ACTION INSPECT DEAD CORPSE 
local InspectBackpack = mk("Inspect Backpack", "Default")

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


		local function hashumanoid(t)
			local c = t
			repeat
				c = c.Parent
			until (c and c:FindFirstChild("Humanoid")) or not c
			if c and c:FindFirstChild("Humanoid") then
				return true, c.Name
			end
		end


function InspectBackpack:Cache(OptList, Target, Tool)

		local hum, name = hashumanoid(Target)
		if Target:IsDescendantOf(game.Workspace.Corpses) then 
			local n = Inst 
			while n.Parent ~= game.Workspace.Corpses do
				n = n.Parent
			end
			-- we found root which is n.
			local cName = n.Name 
			bool = false 
			if n:FindFirstChild("Clothing") and Target:IsDescendantOf(n.Clothing) then
				if n.Clothing:FindFirstChild("Backpack") then
					if Target == n.Clothing.Backpack or Target:IsDescendantOf(n.Clothing.Backpack) then
						-- it backpack!
						OptList.Gather.TargetName = "Backpack of "..cName
						return true
					end
				end
			else 
				-- is a corpse
				OptList.Gather.TargetName = "Corpse of " .. cName 
				OptList.Gather.InfoStrings:insert("I wonder what happened?")
			end 
		elseif hum then 
			-- Show player names.
			OptList.Gather.TargetName = name 
		end 

end 


------------------------ END OF ACTION	

-- Shake tree action 
local ShakeTree = mk("Shake tree", "Default")

function ShakeTree:Cache()
	-- if a tree then, return true
end

function ShakeTree:Run(targ)

end
------------------------ END OF ACTION
-- Attack action --
local Attack = mk("Attack", {"Default", "DefaultTool"})

function Attack:Run(Targ, Tool)
	if Tool then
		DamageService:Attack(Tool, Targ)
	end
end

function Attack:Cache(OptList, Target, Tool)
	if Tool then 
		if DamageService:CanAttack(Target) then 
			OptList.Gather.TargetName = select(2,hashumanoid(Target))
			return true 
		end
	end 
end 


------------------------ END OF ACTION


--- ////////////////
-- Start TOOL actions
-- /////////////////

local Knap = mk("Knap", "Tool")

function Knap:Cache(OptList, Target, Tool)
	-- Target should be gatherable;
	if OptList.Gather.PossibleNaive then 
		local Obj = ObjectService:GetObject(Target)
		if Obj then 
			if Obj.Material == "Stone" then 
				return "Knap"
			end
		end 
	end  
end 

function Knap:Run(Target, Tool)
	Knapping:Knap(Target,Tool)
end 

-- ///// --

local Plant = mk("Plant", "Tool")

function Plant:Cache(OptList, Target, Tool)
	if Target and Target.Name == "FertileGround" then 
		return "Plant"
	end 
end 

function Plant:Run()
	return true -- is a pure server call
end 

function Plant:RunServer(Target, ToolRoot)
	warn("Planting not implemented yet.")
end 

-- ///// --

local Chop = mk("Plant", "Tool")

function Chop:Cache(OptList, Target,Tool)
	local Object = ObjectService:GetObject(Target)
	if Object then
		local Value = Object:GetProperty(Target, "ChoppedDown")
		if Object:IsA("Wood") then 
			if Value == nil or Value == 1 then 
				return "Chop"
			end 
		end 
	end  
end 

function Chop:Run(Target, Tool)
	return true 
end 

function Chop:RunServer(Target, Tool)
	warn("Not implemented yet, (chop)")
end 


for _,action in pairs(toadd) do
	if type(action[2]) ~= "table" then 
		IntentionService:AddAction(action[1], action[2])
	else 
		for i, tname in pairs(action[2]) do 
			IntentionService:AddAction(action[1], tname)
		end 
	end
end
	
end)