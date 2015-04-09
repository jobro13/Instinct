local NutritionService = {}

local ObjectService = Instinct.Include "Services/ObjectService"
local Communicator = Instinct.Include "Communicator"

-- target: rbxinstance

function NutritionService:IsEdible(target)
	local name = target.Name 
	local o = ObjectService:GetObject(name)
	if o then
		return not (not o.Edible), o.Edible
	end
end

function NutritionService:GetNutritionInfo(target)
	local is_edible, data = self:IsEdible(target)
	if is_edible then
		local vol = ObjectService:GetVolume(target)
		if vol then
			local cp = {}
			for i,v in pairs(data) do
				cp[i] = v * vol;
			end
			return cp
		end
	end
	return {}
end

function NutritionService:Eat(target, edb_data)
	--> Eat Hunger=num Thirt = nu
	print("Eat!!")
	
	Communicator:Send("Eat", target, edb_data)
end

return NutritionService