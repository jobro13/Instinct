local IntentionService = {}

-- Action fields -- 
-- Name: identifier
-- ActionName: if exists, return this as action name
-- can be used to have more actions have same actionname
-- Run: function to run on client
-- Should return a bool if server must be invoked
-- If yes, invoke server and run RunServer function

-- Check: checks action given target and tool (if available)


local ToolService, ObjectService, DamageService

function IntentionService:Constructor()
	ToolService = _G.Instinct.Services.ToolService
	ObjectService = _G.Instinct.Services.ObjectService
	DamageService = _G.Instinct.Services.DamageService
	self.Actions = {}
end

-- Target can be a tool, non-tool, etc
function IntentionService:AddAction(Action, Target)
	local Target = Target or "Tool"
	if not self.Actions[Target] then
		self.Actions[Target] = {}
	end 
	self.Actions[Target][Action.Name] = Action 
end 

function IntentionService:GetAction(Name)
	for i,Targets in pairs(self.Actions) do 
		for i, Action in pairs(Targets) do 
			if Action.Name == Name then 
				return Action 
			end 
		end 
	end 
end 

function IntentionService:GetActionFromNamespace(Name, NameSpace)
	return (self.Actions[NameSpace] and self.Actions[NameSpace][Name])
end 

-- returns an opt struct.
-- can be used as "dummy"
function IntentionService:GetOptStruct(LeftAction, RightAction)
	local Out = {}
	Out.Move = {
		Possible = nil -- Setting possible is a hard-set
	}
	Out.Gather = {
		Possible = nil
		InfoStrings = {},
		WarningStrings = {}, 
		TargetName = nil,
	--[[	ToolActions = {
			Left = nil, 
			Right = nil,
		}--]]
	}
	Out.Actions = {
		LeftHand = LeftAction;
		RightHand = RightAction; 
		-- "no hand" tool for non-tool actions
	--	NoHand = NonToolAction;
	--No, is actually set to left hand.
	}

	setmetatable(Out.Gather.WarningStrings, {__index=table})
	setmetatable(Out.Gather.InfoStrings, {__index=table})
	return Out
end 


-- For scalability create rules for different targets
-- For now rules are inside jobs

-- Get options for given target
-- Returns a table with options;
-- A table with reasons,
-- A table with help messages,
-- This function should be the main controller of tools and gather handlers

--ForceReload to overwrite cache

-- WARNING
-- Define LeftAction AND RightAction if this is called from ANY TOOL CACHE ACTION FUNCTION
-- If this is NOT done, it will per definition stack overflow!
function IntentionService:GetOptions(Target, LeftAction, RightAction, ForceReload)
	local Target = ObjectService:GetMainPartRoot(Target)
	if self.CachedTarget == Target and not ForceReload then 
		return self.CachedOptions
	end 

		-- Execute a list of possible actions
	-- Tool actions overrides NonTool actions
	-- Actual processing of TARGETS should be done by a script
	-- Not done in this service
	 -- NOT USED local NonToolAction = nil; 
	-- Processed below VVVV 

	-- Tools can cahce lasttarget;
	-- If same: return same action
	-- However before execute always recheck.
	local Out = {}
	local ToolService = _G.Instinct.ToolService 
	local ObjectService = _G.Instinct.ObjectService 
	local Object = ObjectService:GetObject(Target.Name)
	local LeftTool, RightTool = ToolService.EquippedLeft, ToolService.EquippedRight
	--@Start job Move
	-- If can gather then move is also OK
	-- Gather is NOK if Volume too high
	local Out = self:GetOptStruct(LeftAction, RightAction)

	-- Better if this gets LeftAction/RightActionb itself

	----- GET ACTIONS FROM TOOLS -----
	-- Can't do that from here. Provide LeftAction and RightAction via args
	-- Otherwise we will get recursive calls -> stack overflow.

	local LeftAction, RightAction = LeftAction, RightAction 
	if not LeftAction then 
		-- > Cache action
		if ToolService.EquippedLeft then 
			LeftAction = ToolService.EquippedLeft:CacheAction(Out, Target)
		end
	end 

	if not RightAction then 
		-- > Cache 
		if ToolService.EquippedRight then 
			RightAction = ToolService.EquippedRight:CacheAction(Out, Target, ToolService.EquippedRight) 
		end 
	end


	if Object.CheckGather then 
		local Use = Object.CheckGather 
		if type(Use) == "boolean" then 
			if Use and ObjectService:GetVolume(Inst) > ObjectService:GetVolume(Target)
				Out.Move.Possible = true 
				Out.Gather.Possible = false 
				Out.Gather.WarningStrings:insert("This resource is too large to gather.")
			else 
				Out.Gather.Possible = Use 
			end	
		elseif type(Use) == "function" then 
			-- Expecting return values, in order;
			-- Boolean CanGather
			-- InfoList
			-- Table which has following elements:
			--> is string -> parsed as INFO if CanGather is true
			--> is string -> parsed as WARN if CanGather is false
			--> is table --> must have Style and Text element, if not, dropped
			--			--> Style (Info/Warn / ?)
						--> Text : passed string
			-- > Required action to Gather (string Identifier, or a list of possible actions)
			-- > optional arguments are deprecated as of Insv2
				local ArgList = {Object:CheckGather(Target,Out)}
				local CanGather = ArgList[1]
				if type(CanGather) ~= "bool" then
					error("Cannot parse CheckGather rule for " .. Target.Name .. " because a non-bool is returned")
				end 
				Out.Gather.Possible = CanGather 
				if ArgList[2] then 
					-- Detect Standard message type
					local StdMessage = (CanGather and "Info") or (not CanGather and "Warning")
					local TargetTable = Out.Gather[StdMessage.."String"]
					for i, data in pairs(ArgList[2]) do 
						if type(data) == "table" then 
							if data.Style and data.Text then 
								local TargetTable = Out.Gather[data.Style.."String"]
								if not TargetTable then 
									error("Style unknown: " .. data.Style)
								end 
								TargetTable:insert(data.Style)
							else 
								error("Cannot parse malformed data: data not right formatted, stopping")
							end 
						elseif type(data) == "string" then 
							-- Putting it in Std table
							TargetTable:insert(data)
						else 
							error("Cannot parse wlist data of type " .. data.Type .. " unknown handler")
						end 
					end
				end 
				-- parse wanted action identifier
				if ArgList[3] then 
					local ActionWanted = ArgList[3]
					if type(ActionWanted) == "string" then 
						if ActionWanted == LeftAction then 
							Out.Actions.LeftHand = ActionWanted 
						end 
						if ActionWanted == RightAction then 
							Out.Actions.RightHand = ActionWanted
						end 
						if not Out.Actions.LeftHand and not Out.Actions.RightHand then 
							Out.Gather.WarningStrings:insert("To gather this resource, you need a tool which can " .. ActionWanted .. '.')
						end 
					elseif type(ActionWanted) == "table" then 
						-- ipairs, should be a list
						local GotAction = false 
						for i, ActionName in ipairs(ActionWanted) do 
							if not Out.Actions.LeftHand and ActionName == LeftAction then 
								GotAction = true 
								Out.Actions.LeftHand = ActionName
							end

							if not Out.Actions.RightHand and ActionName == RightAction then 
								GotAction = true 
								Out.Actions.RightHand = ActionName 
							end 
						end 
						if not GotAction then 
							-- Notify player of tools;
							-- Doesn't work well with string formatting if #Args > 2
							Out.Gather.WarningStrings:insert("To gather this resource, you need a tool which can ".. table.concat(ActionWanted, " or ") .. ".")
						end 
					end 
				end 	
				if ArgList[4] then 
					Out.Gather.TargetName = ArgList[4]
				else 
					Out.Gather.TargetName = Target.Name 
				end 
		else 
			error("Unable to handle CheckGather type: " .. type(CheckGather))
		end  
	end 

	-- Figure out if Left/Right actions have been set, else set to cached actions;

	Out.Actions.LeftHand = Out.Actions.LeftHand or LeftAction
	Out.Actions.RightHand = Out.Actions.RightHand or RightAction 


	-- Now retrieve a list of DefaultACtions and run those, if no action is present

	if not Out.Actions.LeftHand then 
		for _,Action in pairs(self.Actions.Default) do 
			local CanRun, NewName = Action:Cache(Target) 
			if NewName and not Out.Gather.TargetName then 
				Out.Gather.TargetName = NewName 
			end 
			if CanRun then 
				Out.Actions.LeftHand = Action.Name 
			end 
		end 
	end 

	if Out.Gather.Possible then 
		if 	Inst:IsDescendantOf(game.Workspace.Buildings) or Inst:IsDescendantOf(game.Workspace.Tools) or Inst:IsDescendantOf(game.Workspace.Garbage) then	
			Out.Gather.Possible = false 
		end 
	end 

	self.CachedTarget = Target
	self.CachedOptions = Out

	return Out 
end 


return IntentionService 