-- Object is interface to data --

local Object = {}

Object.PropertyContainerClassName = "Configuration"
Object.PropertyContainerName = "Properties"
Object.NoGroupPrefix = "."
Object.GroupPrefix = ".Group."

function Object:Constructor()
	self.Groups = {}
end 

-- USES buildin extend class
-- All objects can only have one extension!!
-- Other "groups" should be added via :AddGroup
-- Properly document that in group database


function Object:CreateExtension(name)
	if self.Name ~= "Object" then 
		local new = _G.Instinct:Create(self)
		new.Extends = self 
		new.Name = name or "Object"
		return new 
	else 
		error("Change name first")
	end
end 

-- Object:SetProperty
-- Instance = Roblox instance
-- PropertyName = name of property. wow
-- PropertyValue - value of property (wow)
-- > if PropertyValue == nil -> REMOVES property!
-- Group: (optional) puts it inside a PropertyGroup
function Object:SetProperty(Instance, PropertyName, PropertyValue, Group)
	if not Instance then
		error("No Instance provided to Object:SetProperty")
	end 
	if not PropertyName then
		error("No PropertyName provided to Object:SetProperty")
	end 
	-- Get root
	local Instance = _G.Instinct.Services.ObjectService:GetMainPartRoot(Instance)
	if not Instance:FindFirstChild(self.PropertyContainerName) then 
		Instance.new(self.PropertyContainerClassName, Instance).Name = self.PropertyContainerName
	end 
	local root = Instance[self.PropertyContainerClassName]
	if Group then 
		local nstr = self.GroupPrefix .. Group
		if not root:FindFirstChild(nstr) then 
			local GroupInstance = Instance.new(self.PropertyContainerClassName, root)
			GroupInstance.Name = nstr
		end 
		root = root[nstr]
	end
	local Name = ((Group == nil and self.NoGroupPrefix) or "") .. PropertyName 
	

	if _G.Instinct.Type == "Server" then 
		-- OK to write changes
		if PropertyValue == nil then 
			-- removing ..
			-- lol this solution...
			if root:FindFirstChild(Name) then
				root[Name]:Destroy() -- awh
				if #(root:GetChildren()) == 0 then 
					root:Destroy()
				end 
			end 
		else 
			if root:FindFirstChild(Name) then 
				root[Name].Value = PropertyValue
			else 
				local typeof = tostring(type(PropertyValue))
				local make
				if typeof == "number" then 
					make = "NumberValue"
				elseif typeof == "string" then 
					make = "StringValue"
				elseif typeof == "boolean" then 
					make = "BoolValue"
				elseif typeof == "userdata" then 
					error("No handle for userdata")
				else 
					error("No handle for unknown type: " .. typeof)
				end
				local nprop = Instance.new(make, root) 
				nprop.Name = Name 
				nprop.Value = PropertyValue
			end 
		end 
	elseif _G.Instinct.Type == "Local" then 
		error("Cannot write to resource: is local")
	end 
end

-- Gets a property from Objct
-- Group is optional
function Object:GetProperty(Instance, PropertyName, Group)
	if not Instance or not PropertyName then 
		error("Missing argument for GetProperty")
	end 
	if Instance:FindFirstChild(self.PropertyContainerName) then 
		local root = Instance[self.PropertyContainerName]
		if Group then 
			local nstr = self.GroupPrefix .. Group
			if root:FindFirstChild(nstr) then 
				if root[nstr]:FindFirstChild(PropertyName) then 
					return root[nstr][PropertyName].Value
				end 
			end 		
		else
			local nstr = self.NoGroupPrefix .. PropertyName 
			if root:FindFirstChild(nstr) then 
				return root[nstr].Value 
			end 
		end 
	end
	return nil;
end 

-- Object:SetContext removed
-- Object:RemoveContext removed
-- Object: GetContext removed


-- Remove a property by calling SetProperty with PropertyValue =nil
function Object:RemoveProperty(Instance, PropertyName, Group)
	self:SetProperty(Instance, PropertyName, nil, Group)
end 

-- Object v2 doesn't need context;
-- Cannot get higher level values.

-- New api for "groups"
-- use pairs to loop over groups; 
-- can also be manually set via resources (better)

function Object:AddGroup(GroupName)
	table.insert(self.Groups, GroupName)
end 

function Object:IsInGroup(GroupName)
	for i,v in pairs(self.Groups) do 
		if v == GroupName then 
			return true 
		end 
	end 
	return false 
end 


-- Digs inside all extended objects and returns a list of all properties
-- if automerge is present, unpack tables in the returned table
function Object:GetAnchestryProperties(PropName, AutoMerge) 
	local Out = {}
	if rawget(self, PropName) then 
		table.insert(Out, self.PropName)
	end 
	local target = self 
	while target.Extends do 
		target = target.Extends 
		if rawget(target, PropName) then 
			table.insert(Out, target.PropName)
		end 
	end 
	if AutoMerge then 
		-- handy for rule lists;
		-- only merges 'lists'
		local MergedOut = {}
		for i,v in pairs(Out) do 
			if type(v) == "table" then 
				for ind, val in ipairs(v) do 
					table.insert(MergedOut, val)
				end 
			else 
				table.insert(MergedOut, v)
			end 
		end 
		return MergedOut
	end 
	return Out 
end 

function Object:GetSaveDataList()
	return self:GetAnchestryProperties("SaveDataList", true)
end 

function Object:GetMoveDataList()
	return self:GetAnchestryProperties("MoveRuleList", true)
end 

function Object:IsA(ObjectName)
	if self.Name == ObjectName then 
		return true 
	end 
	local target = self 
	while target.Extends do 
		target = target.Extends 
		if target.Name == ObjectName then 
			return true 
		end 
	end 
	return false 
end 

return Object

