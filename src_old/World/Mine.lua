local Mine = {}

Instinct.Include "Utilities/Random"

Mine.OtherStoneSpawningChance = 1/100
Mine.OtherOreSpawnChance = 1/100
Mine.OreChance = 1/40
Mine.GroundOreChance = 1/5
Mine.OreBoostMultiplier = 6

function Mine:GetStone(height, stonetype)
	local selected = stonetype or Instinct.Option.StoneType.General
	if height then 
		local height = height - (height % 8) - 24
		local my = -math.huge
		local standard = Instinct.Option.StoneType.General
		for i,v in pairs(self.Heights) do 
			if height < v[2] then 
				standard = v[1]
			end
		end
	end

	local Stones = _G.StoneData.StonesInStoneType[selected]
	local NonNativeStones = {}
	for i,v in pairs(_G.StoneData.StonesInStoneType) do 
		if i ~= selected then
			for _, stone in pairs(v) do 
				table.insert(NonNativeStones, stone)
			end
		end
	end
	local randomroulette = {}
	local function scan(t, multiplier)
		for i,v in pairs(t) do
		
			randomroulette[v.Name] = v.Rarity * multiplier
		end
	end
	scan(Stones, 1)
	scan(NonNativeStones, self.OtherStoneSpawningChance)

	local stone = Instinct.Utilities.Random:FromWeightsTable(randomroulette)
	local t =  game.ServerStorage.Mining[stone]:Clone()
	t.Anchored = true
	return t
end

function Mine:GetOre(voxel)
-- Create a RandomRoulette table
	local Ores = _G.OreData
	local Stone = _G.StoneData[voxel.Name]

	--warn(Stone)
	if Stone then 
		local OreBooster = Stone.OreBoost
		local StoneType = Stone.StoneType
		local native_ores = {}
		local non_native_ores = {}
		local t = {}
		for i,v in pairs(Ores) do
			if i ~= "OresInStoneType" then
				table.insert(t,v)
			end
		end
		--OLDPRINT("ORELEN", #t)
		for i,v in pairs(t) do
		--	OLDPRINT(v.Name, v.StoneType == StoneType, "hi") 
			if v.StoneType == StoneType or v.StoneType == Instinct.Option.StoneType.All then 
				table.insert(native_ores, v)
			else
				table.insert(non_native_ores, v)
			end
		end
		local randtable = {}
		function scan(tab, mul)
			for i,v in pairs(tab) do 
				
				if v.Name == OreBooster then 
					randtable[v.Name] = v.Rarity * self.OreBoostMultiplier * mul
				else
					randtable[v.Name] = v.Rarity * mul
				end
				
			end
		end
		scan(native_ores, 1)
		scan(non_native_ores, self.OtherOreSpawnChance)
	--	OLDPRINT("WEIGHT DUMP")
	--	OLDPRINT("VOXEL NAME: " .. voxel.Name)
		local x = {}
		for i,v in pairs(randtable) do 
			table.insert(x, {i,v})
		end
		table.sort(x, function(a,b) return a[2] > b[2] end)
		for i,v in pairs(x) do 
			--OLDPRINT(v[1], v[2])
		end
		local rr = Instinct.Utilities.Random:FromWeightsTable(randtable)
		--OLDPRINT("OREG",rr)
		local clone = game.ServerStorage.Ores:FindFirstChild(rr)
		--warn(rr)
		if clone then
			local new = clone:Clone()
			local ret
			local function mux()
				if ret then return ret end
				ret = (math.sqrt(0.5) + math.random() * (1-math.sqrt(0.5)))^2 -- guarantees square ores
				return ret
			end
			new.FormFactor = "Custom"
			new.Size = Vector3.new(mux(),mux(),mux())
			return new
		end
	end
end

return Mine