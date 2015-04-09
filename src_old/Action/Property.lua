-- Property provides a small context helper class
-- It can be used to serialize properties!

local Property = {}

Property.Type = "string" 
Property.Supported = {
	string=true,
	Vector3=false
}

Property.Mode = {
	Constant = true, -- No copy! 
	ShowInfo = false, -- show on tooltips?
}

local meta = {__index=Property.Mode, __newindex = function(tab,ind,val) 		
	
	if Property.Mode[ind] == nil then -- EXPLICIT for nil! otherwise false will troll 	
		warn(ind.. " is not a valid value")
		return
	end 
	rawset(tab,ind,val)
end}

function Property:Constructor()
	self.Mode = setmetatable({}, meta)
end

function Property:Serialize(value)
	if not self.Supported[self.Type] then 
		throw("Serializing of " .. self.Type .. " is not suppored")
	end 
	if self.Type == "string" then
		return value 
	end 
end 

return Property