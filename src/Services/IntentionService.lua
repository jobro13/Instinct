local IntentionService = {}

local ToolService, ObjectService, DamageService

function IntentionService:Constructor()
	ToolService = _G.Instinct.Services.ToolService
	ObjectService = _G.Instinct.Services.ObjectService
	DamageService = _G.Instinct.Services.DamageService
	self.Actions = {}
end

function IntentionService:AddAction(Action)
	if Action.Name and Action.Run then
		self.Actions[Action.Name]=Action
	end
end

function IntentionService:DoAction(AName, Arg, Hand)
--	print(AName, self.Actions[AName])
	if self.Actions[AName] then
		table.insert(Arg, Hand)
		self.Actions[AName]:Run(unpack(Arg))
	end
end

function IntentionService:IsTool(Inst)
	-- returns if Inst is a tool, very naive checking 
	return Inst:IsDescendantOf(game.Workspace.Tools)
end 



-- left/right action are strings of cached left/right actions for given inst

function IntentionService:CanGather(Inst, LeftAction, RightAction)
	local CanMove = false
	local LeftTool = ToolService.EquippedLeft
	local RightTool = ToolService.EquippedRight
	local obj = ObjectService:GetObject(Inst.Name)
	local bool, rlist, oaction
	local oaction = oaction or {}
	local UseName
	if obj  and obj.CheckGather then
		local func = obj.CheckGather
		if type(func) == "boolean" then
			if func and ObjectService:GetVolume(Inst) > ObjectService.MaximumGatherVolume then
				bool, rlist = false, {"This resource is too large to gather. Move it with the move tool."}
				CanMove = true
			else 
				bool, rlist = func, {}
			end
		else
			-- Call the function. This will be called with
			-- one arg: Inst.
			-- The function should return:
			--> can gather (bool)
			--> if not can gather ->
			--> provide the ReasonList
			--> provide which action would be necessary.
			local CanGather, Reasons, ActionNeeded -- oaction not local pls.
			CanGather, Reasons, ActionNeeded, oaction = func(obj, Inst)
			oaction = oaction or {}
			if CanGather then
				if ObjectService:GetVolume(Inst) > ObjectService.MaximumGatherVolume then
					bool,rlist =  false, {"This resource is too large to gather. Move it with the move tool."}
				else
					bool, rlist = true, {}
				end
			end
			if type(ActionNeeded) == "table" then 
				local has_equipped=false
				for _, Action in pairs(ActionNeeded) do 
					if Action == LeftAction then 
						has_equipped = "left"
						break
					elseif Action == RightAction then 
						has_equipped = "right"
						break
					end
				end
				if has_equipped then 
					bool, rlist = false, Reasons 
				else
					bool, rlist = false, {"Use your "..has_equipped.."-handed tool to do the required action"}
				end
			elseif type(ActionNeeded) == "string" then
				if ActionNeeded == LeftAction then 
					bool, rlist = false, {"Use your left-handed tool to do the required action"}
				elseif ActionNeeded == RightAction then 
					bool, rlist = false, {"Use your right-handed tool to do the required action"}
				else 
					bool, rlist = false, Reasons 
				end
			elseif not CanGather then
				warn("got strange exception from INTSERV: "..(tostring(ActionNeeded)))
				if type(ActionNeeded) == "table" then
					for i,v in pairs(ActionNeeded) do
					--	print(tostring(i), tostring(v))
					end
				end
				bool, rlist = false, {"cannot gather; unknown reason;"}
			end
		end
	end
	
	-- here, check for actions lft/right hand and for cooldown, change
	-- info accordingly
	
	if not oaction.Left and not oaction.Right then
		local function hashumanoid(t)
			local c = t
			repeat
				c = c.Parent
			until (c and c:FindFirstChild("Humanoid")) or not c
			if c and c:FindFirstChild("Humanoid") then
				return true, c.Name
			end
		end
		-- start general procedure to check if we want anything else!
		local has, name = hashumanoid(Inst)
		if Inst:IsDescendantOf(game.Workspace.Corpses) then
			-- uhoh.
			rlist = {}
			local n = Inst 
			while n.Parent ~= game.Workspace.Corpses do
				n = n.Parent
			end
			-- we found root which is n.
			local cName = n.Name 
			bool = false 
			if n:FindFirstChild("Clothing") and Inst:IsDescendantOf(n.Clothing) then
				if n.Clothing:FindFirstChild("Backpack") then
					if Inst == n.Clothing.Backpack or Inst:IsDescendantOf(n.Clothing.Backpack) then
						-- it backpack!
						UseName = "Backpack of "..cName
						oaction = {Left = "Inspect Backpack"}
					end
				end
			end
			if not oaction.Left then
				UseName = "Corpse of " .. cName
				table.insert(rlist, "I wonder what happened...")
			end
		elseif has then
			UseName = name -- show player name on hover;
			local temp = oaction or {}
			local changed = false
			if LeftTool then
				local Info = DamageService:GetDamageInfo(LeftTool, Inst)
				if Info then
					temp.Left = "Attack"
					changed = true
				end
			end
			if RightTool then
				local Info = DamageService:GetDamageInfo(RightTool, Inst)
				if Info then
					temp.Right = "Attack"
					changed = true
				end
			end
			if changed then
				oaction = temp
			end
		end
		
	end
	
	if bool == nil then 
		bool= false
	end
	
	if rlist == nil then
		rlist = {}
	end
	
	if bool and Inst:IsDescendantOf(game.Workspace.Buildings) or Inst:IsDescendantOf(game.Workspace.Tools) or Inst:IsDescendantOf(game.Workspace.Garbage) then	
		bool=false
	end
	return bool, (rlist or {}), (oaction or {}), UseName, CanMove
end

return IntentionService