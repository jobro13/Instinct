-- An object is a very abstract class
-- It holds info on game objects
-- Game objects are anything;
--> Tools
--> Resources
--> Buildings

--> WARNING
--> DO NOT CREATE NEW OBJECTS FOR EVERY ROBLOX INSTANCE
--> THE OBJECT INSTINCT INSTANCE SHOULD BE USED
--> TO LOOK UP INFO ON THE OBJECT CONTEXT

-- context and properties are basically the same
-- easire to branch between 

-- NOTE
-- For some objects we want a general "object"
-- such as a Crucible
-- but multiple "tiers" of it
-- ex: Bronze Crucible
-- In order to manage to do this use the following:
--> The in game identifier should be Crucible
--> A context variable should be set: the tier
--> This is of course derived from the bronze "object"
--> Which is a helper object to figure out the properties for
-- bronze
--> The in game name should be stored in a variable to 
-- make sure it shows correctly on GUIs

print('require')

local printm=print
local throwt =print
local throw=print

local Object = {}

local ObjectService = Instinct.Include( "Services/ObjectService" )

Object.ContextName = "contextinfo"
Object.InfoClassName = "Configuration"

-- ExtendedBy: 
--> string (extend one object)
--> table (extend more objects)

Object.ExtendedBy = nil 

function Object:CreateExtension(name)
	if self.Name ~= "Object" then 
		local new = Instinct.Create(self)
		new.ExtendedBy = self.Name 
		new.Name = name or "Object"
		return new 
	else 
		throw "rename object first"
	end
end 

local IsServer = _G.__InstinctPresets.LoadType == "Server"
local IsTerm = _G.__InstinctPresets.LoadType == "term"

-- We will first define some helper functions
-- These make an easy Instinct <-> Roblox transition

function Object:SetPropertyCat(Inst, PropertyName, Value, Cat)
	if Inst:FindFirstChild(Cat) == nil then 
		if IsServer then 
			-- Okay to create
			local new = Instance.new(self.InfoClassName, Inst)
			new.Name = Cat
		elseif IsTerm then 
			local new = Instinct.Local.rbxinstance:new(self.InfoClassName)
			new.Name = Cat
			new:SetParent(Instance)
		else 
			throw("No server contact rule defined yet - no action taken")
			return 1
		end
	end	

	local typeof = type(Value)
	local make
	if typeof == "number" then 
		make = "NumberValue"
	elseif typeof == "string" then 
		make = "StringValue"
	elseif typeof == "boolean" then 
		make = "BoolValue"
	end 

	if IsServer and make then 
		local my = Inst[Cat]:FindFirstChild(PropertyName)
		if not my then
			my = Instance.new(make, Inst[Cat])
		end
		my.Value = Value 
		my.Name = PropertyName		
	elseif IsTerm and make then 
		local my = Instinct.Local.rbxinstance:new(make)
		my.Name = PropertyName
		my.Value = Value 
		my:SetParent(Instance:FindFirstChild(Cat))
	end
end 

function Object:SetContext(Instance, ContextName, Value)
	self:SetPropertyCat(Instance, ContextName, Value, self.ContextName)
end 

function Object:RemoveContext(Instance,ContextName)
	if Instance:FindFirstChild(self.ContextName) then 
		if Instance:FindFirstChild(self.ContextName):FindFirstChild(ContextName) then 
			Instance[self.ContextName][ContextName]:Destroy()
		end 
	end 
end 

function Object:GetContext(Instance, PropertyName)
	if Instance:FindFirstChild(self.ContextName) then 
		local this = Instance:FindFirstChild(self.ContextName):FindFirstChild(PropertyName)
		if this then 
			return this.Value
		end 
	end
end 

-- lolwat!?
function Object:IsA(what)
	local list = self:GetConstant("Name")
	for i,v in pairs(list) do
		if v == what then
			return true
		end
	end
	return false
end

-- contact objservice to figure out all possible constants
-- returns a table with these constants
-- we must recurse (dammit)
function Object:GetConstant(const)
	ObjectService.ObjectConstants[const] = true
	if not ObjectService.ObjectConstantsDescriptions[const] then
		ObjectService.ObjectConstantsDescriptions[const] = true -- reg for no warn
		warn("No description for: "..const)
	end
	local out = {}
	if self[const] then 
		table.insert(out, self[const])
	end 
	if self.ExtendedBy then 
		if type(self.ExtendedBy) == "string" then 
			local other = ObjectService:GetObject(self.ExtendedBy)
			if not other then 
				throw(self.ExtendedBy .. " is not a valid object")
				return 
			end 
			local data = other:GetConstant(const)
			for _,c in pairs(data) do 
				table.insert(out, c)
			end 
		elseif type(self.ExtendedBy) == "table" then 
			for _, obj in pairs(self.ExtendedBy) do 
				local other = ObjectService:GetObject(obj)
				local data = other:GetData(const) 
				for _,c in pairs(data) do 
					table.insert(out, c)
				end 
			end 
		end 
	end 
	return out 
end 

-- figures out if the object has a ceratin constant 
function Object:HasConstant(const, val)
	-- figuring out if value is ok
--	printm("Object", "info", "checking for constant " .. const )
	local values = self:GetConstant(const)
	for _, value in pairs(values) do 
		if value == val then 
			return true 
		end 
	end 
	return false 
end 

-- returns list table which recsued

function Object:GetRecursedList(name)
	local c = self
	local rules = {}
	function chk(obj)
		if obj[name] then
			for _, rulename in pairs(obj[name]) do
				rules[rulename]=true
			end
		end
		if obj.ExtendedBy then
			if type(obj.ExtendedBy) == "string" and ObjectService:GetObject(obj.ExtendedBy) then
				chk(ObjectService:GetObject(obj.ExtendedBy))
			elseif type(obj.ExtendedBy) == "table" then
				for _, oname in pairs(self.ExtendedBy) do
					if ObjectService:GetObject(oname) then
						chk(ObjectService:GetObject(oname))
					end
				end
			end
		end		
		
	end	
	chk(self)
	local out = {}
	for i in pairs(rules) do
		table.insert(out,i)
	end
	return out
end

-- returns a list of all items which have to be saved
-- traverses complete extend road
function Object:GetSaveDataList()
	return self:GetRecursedList("SaveDataList")
end

function Object:GetMoveDataList()
	return self:GetRecursedList("MoveRuleList")
end

return Object