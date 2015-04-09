return function()
	-- setup rules
local Instinct = _G.Instinct
local printm=function() end
local throw = function() end

local RecipeService = Instinct.Include "Services/RecipeService"
local ObjectService = Instinct.Include "Services/ObjectService"
local Recipe = Instinct.Include "Action/Recipe"

RecipeService:AddCategory("Furnace")


local functemplate = function (RuleData, RuleSet, RuleType, 
	Context, List, Recipe) end 


-- amount only function to receive the whole list
-- hard list of possible ingredients
-- returns a list of useable ingredients!
local function checkamount(arg)
	local ingwant = arg.RuleType[2]
	local have = 0
	local ok = false 
	local skipd = {"Explicit", "AmountType", "Same"}
	print(ingwant)
	if arg.List[ingwant] then 

			ok = true 
			for i = 1, #(arg.List[ingwant]) do 
				arg.List.Used:Add(ingwant, arg.List[ingwant][i])
			end 	
		 
	elseif not arg.RuleSet.Explicit then 
		for _,idata in ipairs(arg.List) do 
			local obj = idata[2]
			if obj:HasConstant("Name", ingwant) then 
				
				arg.List.Used:Add(ingwant, idata[1])

			--[[	if have >= RuleData then 
					ok = true 
					break 
				end--]]
			end 
		end
	end 
	return ok, skipd
end

local function checktemp(arg) 
	local mode = arg.RuleData[1]
	local eq = arg.RuleData[2] 
	if mode == "L" then 
		for i,v in ipairs(arg.List) do

			if arg.Mode == 2 then 
				printm("RuleCheck", "info", "check " .. arg.RuleType[2])
			end 
			local temp =  arg.List.Object:GetContext(v, "Temperature")
			if not temp then 
				throw("no temp var  found ")
				return false 
			end 
			if arg.Mode == 2 then 
				printm("RuleCheck", "info", "t value found, is " .. temp)
			end 
			if temp  > arg.RuleData[2] then 

			else 
				arg.WholeList.Used:Delete(RuleType[2], v)
				printm("RuleCheck", "info", "Removed " .. arg.RuleType[2] )
			end 
		end 
		return true 
	end 
end 

local function chkloc(loc, what )
	return loc:HasConstant( what,true )
end 

local function checkfurnace(arg)
	if arg.Context.Location then 
		return chkloc(arg.Context.Location, "IsFurnace")
	end 
end 

function checkmix(arg)
	if arg.Context.Location then 
		return chkloc(arg.Context.Location, "IsMetalMixingDevice")
	end 
end 

RecipeService:AddRule("Amount", checkamount)
RecipeService:AddRule("Temperature", checktemp)
RecipeService:AddRule("Furnace", checkfurnace)
RecipeService:AddRule("MetalMixingDevice", checkmix)

function debug(...)
	--print(...)
end

-- OK gather rule

function checkg(arg)
	local Context = arg.Context
	local exc = {(game.Workspace:FindFirstChild("Garbage") and game.Workspace.Garbage:FindFirstChild("Tools")), game.Workspace.Buildings}
	if Context and Context.Target then	
		local ok = Context.Target
		--print(ok:GetFullName())
		if false and ok:IsDescendantOf(game.Workspace.Resources) then 
			return true 
		elseif ObjectService:GetObject(ok.Name) then 
			for i,v in pairs(exc) do
			--	print("CHECK DESCENDANT", v, ok:GetFullName())
				if ok:IsDescendantOf(v) then
					table.insert(arg.WholeList.Used.WarningMessages, "CANNOTGATHER")
					return false
				end
			end
			if ok:IsDescendantOf(game.Workspace.Tools) then
				table.insert(arg.WholeList.Used.WarningMessages, "ISTOOL")
				return false
			end
			local o = ObjectService:GetObject(ok.Name)
			if not o then
				-- yeah get out 
				debug("no object")
				return false
			end
			--print(o)
			--[[if not o.IsAClass then
				debug("not a class")
				return false
			end--]]
			--print(o.IsAClass)
			--print(ok.Anchored)
			if false then -- not ok.Anchored and not ok:FindFirstChild("Weld") then
				debug("no anc, no weld, ok")
				return true
			else 
				local Volume = ObjectService:GetVolume(ok)
				local av = o:GetConstant("ToolAnchorVolumeMinimum")[1]
				local wv = o:GetConstant("ToolWeldVolumeMinimum")[1]
				local gv = o:GetConstant("GatherVolumeMaximum")[1]
				print(gv)
			
				-- Really ugly solution here..
				if ok.Name == "Foliage" and ok.Parent.Name == "Wood" then
					table.insert(arg.WholeList.Used.WarningMessages,"Chop tree down first with axe")
				end	
				if ok.Name == "Wood"  then
					local val = o:GetContext(ok, "ChoppedDown")
					print(val)
					if val == 1 then
						table.insert(arg.WholeList.Used.WarningMessages,"Remove leaves first with axe")
						return false
					elseif val == 2 then
						return true
					else
						table.insert(arg.WholeList.Used.WarningMessages,"Chop tree down first with axe")
						return false
					end
				end			
			
				
				
				if ok.Anchored then
					if av and Volume <= av then 
						debug("volume smaller than minimum, okay")
						return true
					end
					local tool = o:GetConstant("ToolToGatherWhenAnchored")
					if tool and #tool > 0 then 
						debug("can gather with tool")
						table.insert(arg.WholeList.Used.WarningMessages, tool[1] .. " to gather")
					else 
						debug("no tool provided")
						return false
					end
				elseif ok:FindFirstChild("Weld") and #(o:GetConstant("ToolToGatherWhenWelded")) > 0 then
					if av and Volume <= av then 
						debug("volume smaller than minimum, okay")
						return true
					end
					local tool = o:GetConstant("ToolToGatherWhenAnchored")
					if tool and #tool > 0 then 
						debug("can gather with tool")
						table.insert(arg.WholeList.Used.WarningMessages, tool[1] .. " to gather")
					else 
						debug("no tool provided")
						return false
					end
					
				elseif gv then
					if gv and Volume <= gv then
						debug("volume smaller ok")
						return true
					end
					local tool = o:GetConstant("ToolToShrink")
					if tool and #tool > 0 then
						debug("tool provided")
						table.insert(arg.WholeList.Used.WarningMessages, tool[1] .. " to gather")
					else 
						table.insert(arg.WholeList.Used.WarningMessages, "Too large to gather")
						return false
					end	
				end 
			end
		end 
	end
end	

RecipeService:AddRule("Gather", checkg)	
	
local gather = Instinct.Create(Recipe)
gather.Context = {Gather=true}	
	
RecipeService:AddRecipe(gather, "Gather")	
	
end