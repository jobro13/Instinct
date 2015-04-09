-- OBJECTSERVICE REWRITE --

-- ObjectService is the interface to Objects and other global-object related operations --

local ObjectService = {}

ObjectService.StudsLength = 0.2 -- 1 stud = x m
ObjectService.MaximumGatherVolue = 3^3 -- max volume for one resource in backpack

-- OBJ lists --

function ObjectService:Constructor() 
	self.Objects = {} 
	self.Rules = {} 
end 

function ObjectService:AddRule(Rule,RuleName,RuleType)
	if not Rule or not RuleName then 
		error("Missing argument @ObjectService:AddRule")
	end 
	if not self.Rules[RuleType or "Default"] then
		self.Rules[RuleType or "Default"] = {}
	end 
	self.Rules[RuleType or "Default"][RuleName] = Rule 
end 

function ObjectService:GetRule(RuleName, RuleType)
	if not RuleName then 
		error("Missing argument @ObjectService:GetRule")
	end 
	return (self.Rules[RuleType or "Default"] and self.Rules[RuleType or "Default"][RuleName])
end 

function ObjectService:AddObject(Object)
	if not Object then 
		error("Missing argument @ObjectService:AddObject")
	end 
	if self.Objects[Object.Name] then 
		error(Object.Name .. " already exists.")
	end 
	self.Objects[Object.Name] = Object 
end 

function ObjectService:GetObject(Name)
	if not Name then 
		error("Missing argument @ObjectService:GetObject")
	end 
	return self.Objects[Name]
end 

-- GetVolume procedure
-- > Get object
-- > Figure out if object has a CustomVolume field
-- > Call this on current resource
-- > if it returns a truthy value, return
-- > else basepart: return getmass
-- > else model: return GetModelSize() multiplied

function ObjectService:GetVolume(RBX_Inst)
	if not RBX_Inst then 
		error("Missing argument @ObjectService:GetVolume")
	end 
	-- First check for a CustomVolume rule
	-- Should get around ugly stuff like axes with parts in it
	local Obj = self:GetObject(RBX_Inst.Name)
	if Obj then 
		local CVolume = Obj.CVolume 
		if CVolume then 
			local val = CVolume(Obj, RBX_Inst)
			if val then 
				return val 
			end 
		end 
	end 

	if RBX_Inst:IsA("BasePart") then 
		return RBX_Inst:GetMass()
	elseif RBX_Inst:IsA("Model") then 
		local size = RBX_Inst:GetModelSize()
		return size.x * size.y * size.z 
	end 
end 

function ObjectService:GetSize(RBX_Inst)
	if not RBX_Inst then 
		error("Missing argument @ObjectService:GetSize")
	end 

	if RBX_Inst:IsA("BasePart") then 
		return RBX_Inst.Size 
	elseif RBX_Inst:IsA("Model") then 
		return RBX_Inst:GetModelSize()
	else
		error("Provided a non-model and non-object to ObjectService")
	end 
end 

-- Resource: RBXINST
-- RuleName: full name of property (MoveDataList)
-- RuleType: name for usage in Rules (Move)
function ObjectService:ApplyRules(Resource, RuleName, RuleType) 
	if not Resource or not RuleType then 
		error("Missing argument @ObjectService:ApplyRules")
	end 
	local Object = self:GetObject(Resource.Name)
	if not Object then 
		error(Resource.Name .. " doesnt exist")
	end 
	local RuleList = Object:GetAncestryProperties(RuleName, true)
	-- Automerged;
	for _, Rule in pairs(RuleList) do 
		local RuleFunc = self:GetRule(Rule, RuleType)
		if RuleFunc then
			RuleFunc(Resource)
		else 
			error(Rule .. " doesnt exist (Rule)")
		end 
	end 
end 

-- generalized "ToBackpack" function (as it was used..)
function ObjectService:ToLocation(Resource, Location)
	if not Resource or not Location then
		error("Missing argument @ObjectService:ToLocation")
	end 
	self:ApplyRules(Resource, "MoveRuleList", Location)
	Resource.Parent = Location 
end 

-- ////////////////////////// --
-- Damn saving/loading api is pretty cool 
-- SAVING / LOADING FUNCTIONS --
-- ////////////////////////// --

-- Warning: Saving data does ONLY accept tables
-- This means that directly copied values from xValues MUST be converted to tables first
-- This is not supported as of OSv2
-- All Save rules should be in the "Save" namespace

function ObjectService:GetSaveData(Inst)
	if not Inst then
		error("Missing argument @ObjectService:GetSaveData")
	end

	-- Procedure 
	-- Load Saving rules for given Instance
	-- Apply rules
	-- Dump properties inside table

	local Object = self:GetObject(Inst.Name)
	if not Object then 
		error("Cannot save; object unknown")
	end 
	-- Name is global identifier
	local SaveData = {Name=Inst.Name} 
	local SaveRules = Object:GetAncestryProperties("SaveDataList", true)
	-- Apply save rules -- 
	for _, RuleName in pairs(SaveRules) do 
		if RuleName == "Context" then
			error("Context rule cannot exist")
		end 
		local Rule = self:GetRule(RuleName, "Save")
		if Rule then 
			SaveData[RuleName] = Rule.To(Inst)
		else 
			error("Nonexistant rule: "..RuleName)
		end 
	end 
	local PPClassName = Object.PropertyContainerClassName
	-- Done with parsing rules; now get Context
	if Inst:FindFirstChild(Object.PropertyContainerName) then
		-- Found context; gotta save
		-- properties go only one level deep, so no need to recurse;
		-- properties are always xValues;
		-- if not then somewhere the code fked up
		SaveData.Context = {} 
		for _, Child in pairs(Inst[Object.PropertyContainerName]:GetChildren()) do 
			if Child:IsA(PPClassName) then 
				-- if Object:Get/SetProperty is used correctly
				-- then there are never empty subproperties;
				if not SaveData.Context.__SubProperties then 
					SaveData.Context.__SubProperties = {}
				end 
				SaveData.Context.__SubProperties[Child.Name] = {}
				for _, SubProperty in pairs(Child:GetChildren()) do
					SaveData.Context.__SubProperties[Child.Name][SubProperty.Name] = SubProperty.Value
				end 
			else 
				SaveData.Context[Child.Name] = Child.Value 
			end 
		end 
	end 
	return SaveData 
end 

-- Recreates an object from SaveData. Only works if the given rules 
-- Have the right To/From rules set. If not, it no work
function ObjectService:FromSaveData(SaveData)
	local Identifier = SaveData.Name -- Object Identifier.
	if not Identifier then
		error("Data doesn't have a Name field")
	end 
	local Object = self:GetObject(Identifier) 
	if not Object then 
		error("Object " .. Identifier .. " does not exist")
	end 
	local BaseObject = self:GetObjectRoot(Identifier)
	if not BaseObject then 
		error("Cannot load " .. Identifier .. " because it's base object doesn't exist")
	end 
	local Target = BaseObject:Clone()
	-- Start parsing the rules which are not the "Context" rules ..
	-- This method is forward-compatibility proof
	for RuleName, RuleData in pairs(SaveData) do
		if RuleName ~= "Context" then -- Context is a special field.
			local Rule = self:GetRule(RuleName, "Save")
			if Rule then 
				-- Parse rule
				Rule.From(RuleData, Target)
			end 
		end 
	end 	
	-- Check for context;
	if SaveData.Context then 
		-- Context is here
		for ContextName, ContextData in pairs(SaveData.Context) do 
			if ContextName ~= "__SubProperties" then 
				Object:SetProperty(Target, ContextName, ContextData)
			end 
		end 
		if SaveData.Context.__SubProperties then
			for ContextGroup, SubData in pairs(SaveData.Context.__SubProperties) do 
				for ContextName, ContextData in pairs(SubData) do 
					Object:SetProperty(Target, ContextName, ContextData, ContextGroup)
				end
			end 
		end
	end
	return Target  
end	

-- Updates a weld
function ObjectService:UpdateWeld(part1, part2, c1, c2)
	if part1:FindFirstChild("Weld") then
		part1.Weld:Destroy()
	end
	local Weld = Instance.new("Weld", part1)
	Weld.Name = "Weld"
	Weld.Part0 = part2
	Weld.Part1 = part1
	Weld.C0 = c2:toObjectSpace(c1)
end


function ObjectService:WeldTransform(part, CC, AN)
	part.CanCollide = CC or false
	part.Anchored = AN or false
end

-- WeldObject;
-- > Always  unanchors and unCCs
-- Inst: resource to weld. Welds to itself as default behaviour
function ObjectService:WeldObject(Inst, TargetInstance, Grip)
	error("Missing argument @ObjectService:WeldObject")
	local MainPart = self:GetMainPart(Inst)
	local Root = self:GetMainPartRoot(Inst)

	for i,v in pairs(Root:GetChildren()) do
		if v:IsA("BasePart") and v ~= MainPart then
			self:UpdateWeld(v, mainpart, v.CFrame, mainpart.CFrame)
			self:WeldTransform(v)
		end
	end
	self:WeldTransform(MainPart)
	if TargetInstance then 
		local Weld = Instance.new("Weld", TargetInstance)
		Weld.Name = "Weld"
		Weld.Part1 = TargetInstance
		Weld.Part0 = MainPart
		Weld.C1 = Grip or CFrame.new()
		Weld.C0 = CFrame.new()
	end 
end

function ObjectService:GetMainPart(Inst)
	if Inst.Parent:IsA("Model") and Inst.Parent.PrimaryPart then
		return Inst.Parent.PrimaryPart
	else
		if Inst.Name == "chParent" then
			return Inst.Parent
		end
	end
	return Inst -- just return self as mainpart then.
end

function ObjectService:GetMainPartRoot(Inst)
	if Inst.Parent:IsA("Model") and Inst.Parent.PrimaryPart then
		return Inst.Parent
	else
		if Inst.Name == "chParent" then
			return Inst.Parent
		end
	end
	return Inst -- just return self as mainpart then.
end

--Finds a roblox instance from a given name
-- Must update locs list in order to find it.
function ObjectService:GetObjectRoot(name)
	local root = game:GetService("ServerStorage")
	local locs = {root:FindFirstChild("Mining"), root:FindFirstChild("Ores"), root:FindFirstChild("Resources"), game:GetService("ReplicatedStorage").NewTools}
	for i,v in pairs(locs) do
		if v:FindFirstChild(name) then
			return v:FindFirstChild(name)
		end
	end
end

-- Copies a Style from StyleBrick to Target given Props in a PropList
function ObjectService:CopyStyle(StyleBrick, Target, PropList)
	local function r(w)
		for i,v in pairs(w:GetChildren()) do
			if v:IsA("BasePart") then
				for ind, val in pairs(PropList) do
					print(val)
					v[val] = StyleBrick[val]
					v.Anchored=false
					v.CanCollide=true
				end
			end
		end
	end
	r(Target)
	for ind, val in pairs(PropList) do
		Target[val] = StyleBrick[val]
		Target.Anchored=false
		Target.CanCollide=true
	end
end

function ObjectService:DropItem(res, pos)
	if not res then return end
	res.Parent = game.Workspace.Resources 
	if res:IsA("Part") then
		-- check for parts inside
		res.CFrame = CFrame.new(pos)
	else -- qq
		
	end
end

function ObjectService:SetResourceCFrame(res, CF)
	if res:IsA("Model") then
		local function moveModel(model,targetCFrame)
			for i,v in pairs(model:GetChildren()) do
				if v:IsA("BasePart") then
					v.CFrame=targetCFrame:toWorldSpace(model:GetModelCFrame():toObjectSpace(v.CFrame))
				end
				moveModel(v, targetCFrame)
			end
		end

		moveModel(res, CF)
	else
		if res:FindFirstChild("chParent") then
			for i,v in pairs(res:GetChildren()) do
				if v:IsA("BasePart") and v.Name == "chParent" then
					local weld = v:FindFirstChild("Weld")
					if weld then
						local c0 = weld.C0
						v.CFrame = CF * c0
					end
				end
			end
			res.CFrame = CF
		else
			res.CFrame = CF
		end
	end
end

-- oldparent can be used to put leftovers in.
function ObjectService:ResizeResource(res, size, oldparent)
	if res:IsA("Model") then
		-- ... wat ... 

		return
	elseif res:FindFirstChild("chParent") then
		-- no.
		return
	end
	res.Size = size 

end

return ObjectService







