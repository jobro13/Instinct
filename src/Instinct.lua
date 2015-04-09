-- Instinct --
-- Master loader --

-- Solution for the Constructor-Loads-Depenedencies:
-- > Add a list of dependencies to every class
-- > Auto-add to constructor

local Instinct = {}
Instinct.Sources = {} -- Sources, by name

function Instinct:Flush()
	_G.Instinct = {}
end
-- Load module from String, seperated by Seperator
-- Looks inside Source to find given module
function Instinct:Load(String, Source, Seperator)
	local Where = _G.Instinct
	local Inst = Source
	local LastMatch
	for match in string.gmatch(String, "[^" .. (Seperator or "/") .. "]+") do
		if LastMatch then
			if Where[LastMatch] then
				Where = Where[LastMatch]
			else
				Where[LastMatch] = {}
				Where = Where[LastMatch]
			end
			Inst = Inst:FindFirstChild(LastMatch)
		end
		LastMatch = match
	end
	-- Reached target instance --
	local Target = Inst:FindFirstChild(LastMatch)
	if Target then
		local Loaded = require(Target)
		if type(Loaded) == "table" then
			Where[LastMatch] = Instinct:Create(Loaded) -- provide new copy
		elseif type(Loaded) == "function" then
			Loaded()
		else
			print("Got strange module, type: ".. type(Loaded) .. " name: " .. String)
		end
	end
end


function Instinct:AddSource(source, name)
	if not source then
		error("Cannot add source " .. tostring(source) .. " doesn't exist")
	end
	self.Sources[name] = source
end

local ClassMeta = {}

-- Using __index, can later add more functionality
-- Current behaviour is same as __index=table
function ClassMeta:__index(Index)
	local ExtClass = rawget(self, "Extends")
	if ExtClass then
		return ExtClass[Index]
	end
end

-- Last version used Parent structure; not necessary, removing.
--[[
function ClassMeta:__newindex(Index, Value)
	
end
--]]

ClassMeta.__call = function(tab, ...)
	if tab.Call then
		return tab.Call(...)
	end
end

-- MS = ModuleScript input; require this script and create a proxy for it
function Instinct:GetChild(MS)
	local Master = require(MS)
	return self:Create(Master)
end

function Instinct:Create(Master)
	local OBJ = {Extends=Master}
	setmetatable(OBJ, ClassMeta)
	if OBJ.Constructor then 
		OBJ:Constructor()
	end
	return OBJ 
end


-- Set loading type; (Server | Local)
function Instinct:SetType(Type)
	self.Type = Type
end

return Instinct