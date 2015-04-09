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

-- For scalability create rules for different targets
-- For now rules are inside jobs

-- Get options for given target
-- Returns a table with options;
-- A table with reasons,
-- A table with help messages,
-- This function should be the main controller of tools and gather handlers
function IntentionService:GetOptions(Target, LeftAction, RightAction)
	-- Better if this gets LeftAction/RightActionb itself

	----- GET ACTIONS FROM TOOLS -----
	local LeftAction = nil;
	local RightAction = nil;

	-- Execute a list of possible actions
	-- Tool actions overrides NonTool actions
	-- Actual processing of TARGETS should be done by a script
	-- Not done in this service
	local NonToolAction = nil; 


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
	Out.Move = {
		Possible = nil -- Setting possible is a hard-set
	}
	Out.Gather = {
		Possible = nil
		InfoStrings = {},
		WarningStrings = {}, 
		TargetName = {},
		ToolActions = {
			Left = nil, 
			Right = nil,
		}
	}
	Out.Actions = {
		LeftHand = LeftAction;
		RightHand = RightAction; 
		-- "no hand" tool for non-tool actions
		NoHand = NonToolAction;
	}

	setmetatable(Out.Gather.WarningStrings, {__index=table})
	setmetatable(Out.Gather.InfoStrings, {__index=table})

	local function ParseAction(Action)


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
				local ArgList = {Object:CheckGather(Target)}
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

						elseif ActionWanted == RightAction then 

						else 
							Out.Gather.WarningStrings:insert("To gather this resource, you need a tool which can " .. ActionWanted .. '.')
						end 
					elseif type(ActionWanted) == "table" then 
						-- ipairs, should be a list
						local GotAction = false 
						for i, ActionName in ipairs(ActionWanted) do 
							if ActionName == LeftAction then 
								GotAction = true 
								-- Use right tool;
							elseif ActionName == RightAction then 
								GotAction = true 
								-- Use left tool;
							end 
						end 
						if not GotAction then 
							-- Notify player of tools;
							-- Doesn't work well with string formatting if #Args > 2
							Out.Gather.WarningStrings:insert("To gather this resource, you need a tool which can ".. table.concat(ActionWanted, " or ") .. ".")
						end 
					end 
				end 	
		else 
			error("Unable to handle CheckGather type: " .. type(CheckGather))
		end  
	end 

	-- Now retrieve a list of DefaultACtions and run those, if no action is present

	if not Out.Actions.LeftHand then 
		for _,Action in pairs(self.Actions.Default) do 
			if Action:Cache(Target) then 
				Out.Actions.LeftHand = Action.Name 
			end 
		end 
	end 


end 


return IntentionService 