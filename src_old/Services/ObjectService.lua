-- Resource service is a very specific high level service
-- It basically is a class system for objects
-- Objects can be everything:
-- Resources, tools, houses, etc.
-- It extends roblox parts and models by providing extra info 
-- on game entities 

-- Used on both server and client as LUT

-- recipe user guide;
-- > figure out if recipe can be created, take Uselist
-- > pass uselist to CreationService
--  > figure out if multipel options; if so, 
-- 			provide user choices
--  > if not; make
-- > this service will convert UseList resources to an
-- > actual roblox instance
-- > this is then returned
-- > it is not parented, 
-- > as buildings will need a different placement than resources
local throw=warn
local Property = Instinct.Include "Action/Property"

print("DONE")

local ObjectService = {}

-- x meters per studs; used for all kinds of calculations
ObjectService.StudsLength = 0.2 
ObjectService.MaximumGatherVolume = 3^3; -- maximum volume to put something in backpack. 

ObjectService.ObjectData = {}
ObjectService.PropertyData = {}
ObjectService.PWarned = {}

warn("Need a property class")

function ObjectService:Constructor()
	self.ObjectData = {} -- global lut
	self.ObjectConstants = {} -- objconstants
	self.ObjectConstantsDescriptions = {} -- for later use for descriptions
	self.PropertyData = {} -- possible props
	self.PWarned = {}
	self.Rules = {}
	self.MoveRules = {}
end

function ObjectService:AddMoveRule(Rule, Name)
	self.MoveRules[Name] = Rule
end

function ObjectService:GetMoveRule(Name)
	if self.MoveRules[Name] then
		return self.MoveRules[Name]
	end
	warn(Name .. " a moverule doesnt exist, returning nil")
end

function ObjectService:AddProperty(Property) -- is a property class
	-- property class has integrated "no that is not a valid property" things.
	if self.PropertyData[Property.Name] then
		warn(Property.Name .. " already exists (a property)")
		return
	end

	self.PropertyData[Property.Name] = Property
end 

function ObjectService:GetProperty(Name)

	return self.PropertyData[Name]
end

-- possible static value values setter function
function ObjectService:AddPropertyValues(Name, Values)
	if not self.PropertyData[Name] then 
		throwt("ObjectService", Name .. "Object " .. Name .. " not available")
		return 
	end 
	local o = self.PropertyData[Name] 
	if o.PValues and o.PValuesLut then 
		for i,v in pairs(Values) do 
			if not o.PValues[v] then 
				table.insert(o.PValuesLut, v)
				o.PValues[v] = true 
			end
		end 
	else 
		o.PValuesLut = Values 
		o.PValues = {}
		for i,v in pairs(Values) do 
			o.PValues[v] = true 
		end 
	end 
end 

function ObjectService:AddObjects(list)
	for _, obj in pairs(list) do 
		self:AddObject(obj)
	end 
end

function ObjectService:GetObjectList()
	local out = {}
	for i,v in pairs(self.ObjectData) do
		table.insert(out, i)
	end 
	return out 
end

function ObjectService:CheckProperty(name)

end 

function ObjectService:AddObject(Object)
	-- if the resource has an extend field:
	--> check if extended resource is available
	--> not? throw error

	-- first _G.a = 3 o = getfenv() setfenv(1, setmetatable({o=o}, {__index = function(tab,ind) return tab.o[ind] or  _G[ind] end})) print(a) for non-props 

	local excl = {ExtendedBy = true, __root = true }

	for i,v in pairs(Object) do 
		if not excl[i] then 
			if not self.PropertyData[i] and not self.PWarned[i] then 
				warn("Property " .. i .. " does not exist")
				self.PWarned[i] = true 
			end 
		end 
	end 

	if Object.ExtendedBy then 
		if type(Object.ExtendedBy) == "string" then 
			if not self.ObjectData[Object.ExtendedBy] then 
				throw(Object.ExtendedBy .. " does not exist")
				return
			end 
		elseif type(Object.ExtendedBy) == "table" then 
			local ok = true 
			for i,v in pairs(Object.ExtendedBy) do 
				if not self.ObjectData[v] then 
					ok = false 
					throw(i .. " does not exist")
				end
			end
			if not ok then 
				return 
			end 
		end
	end 
	if self.ObjectData[Object.Name] then 
		throw (Object.Name .. " already exists")
	end 
	self.ObjectData[Object.Name] = Object 
end 

function ObjectService:GetInfo(ObjectName, Inst)
	local out = {}
	local o = self:GetObject(ObjectName)
	if not o then
		return {}
	end 
	-- yay 
	function r(o)
		for i,v in pairs(o) do 
			if not out[i] then 
				out[i] = v 
			end 
			if i == "ExtendedBy" and self:GetObject(v) then 
				r(self:GetObject(v))
			end 
		end 
	end 
	r(o)
	if Inst then
		local info = "objinfo"
		if Inst:FindFirstChild(info) then
			for i,v in pairs(Inst[info]:GetChildren()) do 
				if not out[i] then 
					out[i] = v.Value
				end
			end
		end
	end
	return out 
end 

-- gets volume from rbx instance 
function ObjectService:GetVolume(inst)
	--print("NO FUNCTION GETVOLUME DEFINED, SET THIS PLEASE, return 1 for test purposes")
	local o = self:GetObject(inst.Name)
	--warn(tostring( o and o:GetConstant("CustomVolume")[1]))
	if o and o:GetConstant("CustomVolume")[1] then
		local ret = o:GetConstant("CustomVolume")[1](o, inst)
		if ret then return ret end
	end
	if inst and inst:IsA("BasePart") then 
		return inst:GetMass()
	elseif inst and inst:IsA("Model") then
		local v = inst:GetModelSize()
		return v.x * v.y * v.z
	else
	--	warn("provided a non-part and non-model to objservice")
	end
	return nil
end 

function ObjectService:GetSize(inst)
	if inst and inst:IsA("BasePart") then 
		return inst.Size
	elseif inst and inst:IsA("Model") then
		local v = inst:GetModelSize()
		return v
	else
		warn("provided a non-part and non-model to objservice")
	end
	return nil
	
end


function ObjectService:IsResource(inst)
	if game then 
		return inst:IsA("BasePart") or inst:IsA("Model")
	else 
		if inst.islres then 
			return true 
		end 
	end 
end 

-- returns a resource from name
-- with handy functions yay
function ObjectService:GetObject(ObjectName)
	if type(ObjectName) ~= "string" then 
		throw("Provide a string for ObjectService")
		return
	end 
	return self.ObjectData[ObjectName]
end 

function ObjectService:ToBackpack(Resource, Backpack)
	--print("INTOBACKPACK", Resource:GetFullName())
	local obj = self:GetObject(Resource.Name)
	if not obj then return end
	for i,v in pairs(obj:GetMoveDataList()) do 
		local rule = self:GetMoveRule(v)
		if rule then
			rule(Resource)
		end
	end	
	
	if obj.CheckClean then 
		obj.CheckClean()
	end
	if Backpack then 
		Resource.Parent = Backpack
	end
end

-- gets a studvolume from GetMass and returns "real" volume
function ObjectService:ConvertStudVolume(studvolume)
	local Real = studvolume * self.StudsLength ^ 3
	-- is m^3
	return Real * 1000 -- is dm^3 - liters
end 

-- lelelelle
function ObjectService:GetSaveData(inst)
	local obj = self:GetObject(inst.Name)
	local out = {Name=inst.Name}
	if obj then
		if obj.SaveDataList then
			for _, rulename in pairs(obj:GetSaveDataList()) do
				if rulename ~= "Context" and self:GetRule(rulename) then
					out[rulename] = self:GetRule(rulename).To(inst)
				end
			end
			for i,v in pairs(inst:GetChildren()) do
				if v:IsA(obj.InfoClassName) then
					if not out.Context then
						out.Context = {}
					end
					out.Context[v.Name] = {}
					for ind, val in pairs(v:GetChildren()) do
						out.Context[v.Name][val.Name] = val.Value
					end
				end
			end			
			
		else
			warn("Cannot save " .. inst.Name .. " because no rules are available")
			return nil
		end
	else
		return nil
	end
	return out
end

function ObjectService:AddRule(Rule)
	if Rule.To and Rule.From and Rule.Name then
		self.Rules[Rule.Name] = Rule
	else
		error("provide a valid rule with fields To, From and Name")
	end
end

function ObjectService:GetRule(name)
	return self.Rules[name]
end

function ObjectService:WeldObject(Root)
	if Instinct.Action.Tool then
		Instinct.Action.Tool:CreateWelds(Root, nil, nil, true)
	end
end

-- There are two ways to get an Object's main part
-- The way it SHOULD be used (because it isn't ugly)
--> Create a model named "InstinctObject"
--> set primarypart
--> this function will return the primarypart
-- there must be NO bricks inside other bricks.
-- other, deprecated way:
-- chParent parts, which tell instinct to look at the parent for the mainpart


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

function ObjectService:CopyStyle(StyleBrick, Target, PropList)
	function r(w)
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

function ObjectService:CreateObjectFromSaveData(data)
	local ident = data.Name
	if not ident or not self:GetObject(data.Name) then
		warn('cannot identify saved data, returnning nil')
		return nil;
	end
	local baseobj = self:GetObjectRoot(ident)
	if not baseobj then
		warn('baseobj for ' .. ident .. ' is not available, cannot create')
		return nil;
	end
	local use = baseobj:Clone()
	local obj_data = self:GetObject(ident)
	for _, rulename in pairs(obj_data:GetSaveDataList()) do
		if rulename ~= "Name" and rulename ~= "Context" then -- skip 
			local rule = self:GetRule(rulename)
			warn('rule: ' .. rulename .. ' item: ' .. ident, data[rulename], data)

			if rule then
				rule.From(data[rulename],  use)
			end
		end
	end
	if data.Context then
		warn("has context")
		for ContextName, ContextData in pairs(data.Context) do
			print("cname", ContextName, ContextData)
			for PropName, PropValue in pairs(ContextData) do
				print("pname", PropName, PropValue)
				obj_data:SetContext(use, PropName, PropValue)
				local rule = self:GetRule("Context"..PropName)
				print(rule, "rule")
				if rule then
					rule.From(PropValue, use)
				end
			end
		end
	end
	return use
end
	
function ObjectService:GetObjectRoot(name)
	local root = game:GetService("ServerStorage")
	local locs = {root:FindFirstChild("Mining"), root:FindFirstChild("Ores"), root:FindFirstChild("Resources"), game:GetService("ReplicatedStorage").NewTools}
	for i,v in pairs(locs) do
		if v:FindFirstChild(name) then
			return v:FindFirstChild(name)
		end
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
		warn("cannot resize models")
		return
	elseif res:FindFirstChild("chParent") then
		-- no.
		return
	end
	res.Size = size 
	warn("ADD HOOKS TO RESIZE THE ROOT!")
end

return ObjectService