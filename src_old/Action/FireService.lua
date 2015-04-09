-- FireService

local ObjectService = require "Services/ObjectService"
local Object = require "Action/Object"

local FireService = {}

local function tick()
	if game then 
	else 
		tick=os.clock()
	end 
end 

function FireService:GetEnvironmentTemperature(root)
	return 20 
end 

function FireService:Light(inst, plust, spark)
	local o = ObjectService:GetObject(inst.Name)
	if o then 
		if o:HasConstant("Lighteable", true) then 
			local bt = o:GetConstant("BurnTemperature")
			if not bt then 
				print("no burn temp found")
				return 
			end 
			if spark and o:HasConstant("Sparkable", true) then 
				o:SetContext("Temperature", bt)
				o:SetContext("Lit", tick() )
			elseif plust then 
				local lt = o:GetConstant("LightTemperature")
				if lt then 
					local nt = o:GetContext(inst, "Temperature") or 20
					if nt then 
						
						if nt + plust > lt then 
							o:SetContext(inst, "Temperature", bt)
							o:SetContext(inst, "Lit", tick())
						else 
							o:SetContext(inst, "Temperature", nt  + plust)
						end 
					end 
				end 
			end 
		end 
	end 
end 

-- returns fuel with the highest temperature
function FireService:GetFuel(root)
	local max = 0
	local found 
	local fuels = {}
	for i,v in pairs(root:GetChildren()) do 
		if ObjectService:IsResource(v) then 
			local o = ObjectService:GetObject(v.Name)
			if o:GetConstant("IsFuel") and o:GetProperty(v, "Lit") then 
				local t = o:GetProperty(v, "Temperature")
				if t > max then 
					max=t 
					found = v 
				end 
			elseif o:GetConstant("IsFuel") then 
				table.insert(fuels,v)
			end 
		end 
	end 
	if found then 
		for i,v in pairs(fuels) do 
			if Object:SetProperty(v, )
		return vfound,max 
	end 
end 

-- root is a root entity, this contains the ingredients
-- this doesnt have to be a building
-- note: only suitable for buildings with range == 0 for ings.
function FireService:HandleRoot(root)
	local tmul = 1
	local dt = tick() - (Object:GetContext(root, "LastCheck") or (tick() - 1))
	local remt = dt 
	Object:SetContext(root, "LastCheck", tick())
	local bb = Object:GetContext(root, "BurnBoost")
	if bb then 
		remt = dt * bb
		if tmul < bb then 
			tmul = bb 
		end 
		local be = Object:GetContext(root, "BurnBoostTime")
		if be then 
			Object:SetContext(root, "BurnBoostTime", be-dt)
			if be-dt <= 0 then
				Object:RemoveContext(root, "BurnBoost")
				Object:RemoveContext(root, "BurnBoostTime")
			end 
		end 
	end 
	local envt = self:GetEnvironmentTemperature(root)
	local fuel 
	-- first get fuel

	local fuel, ft  = self:GetFuel(root)

	for i,v in pairs(root:GetChildren()) do 
		if ObjectService:IsResource(v) then 
			local t = Object:GetContext(v, "Temperature") or envt 

			if fuel then 
				-- very sipmle 
				if t < ft and not v == fuel then 
					t = t + 1 * dt 
				end 
			elseif t < envt then 
				t = t - 1 * dt 
			end 
		end 
	end 


end 

return FireService