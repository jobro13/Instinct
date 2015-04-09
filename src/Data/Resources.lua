return function()

local Instinct = _G.Instinct
local Object = _G.Instinct.Class.Object
local ObjectService = Instinct.Services.ObjectService
-- This part should be in a "Properties" data file -- 
local Property = Instinct.Class.Property
local new = Instinct.Create(Property)
new.Mode.ShowInfo = true
new.Name = "Material"
ObjectService:AddProperty(new)
print("add")


 -- //// START RESLIST
-- FLOWER
-- mk object
local FL = Instinct.Create(Object)
-- set name
FL.Name = "Flower"
-- What properties must be saved (resp. Save rule names)
FL.SaveDataList = {"Size", "Color"}
-- When moving, what should happen (moverules)
FL.MoveRuleList = {"UnanchorAll", "UnweldAll", "Ungroup"}
-- Evt. Special function which defines gather behaviour
FL.CheckGather = true -- no special function needed.
-- density, kg/m3
FL.Density = 0.01
-- damage;
FL.DamageType = "Crush"
-- base damage
FL.BaseDamage = 0.01
-- hardness
FL.Hardness = 0.01

-- FLOWRE STALK
local FLS = Instinct.Create(Object)
FLS.Name = "Flower Stalk"
FLS.SaveDataList = {"Size", "Color"}
FLS.MoveRuleList = {"UnanchorAll", "UnweldAll", "Ungroup"}
FLS.CheckGather = true
FLS.Density = 0.05
FLS.BaseDamage = 0.1
FLS.Hardness = 0.01
FLS.DamageType = "Cut"

ObjectService:AddObject(FL)
ObjectService:AddObject(FLS)

-- STONES -- 
local Stone = Instinct.Create (Object)

Stone.Name = "Stone"
Stone.Material = "Stone"
Stone.ToolToGatherWhenAnchored = "Pickaxe"
Stone.SaveDataList = {"Size"}
Stone.MoveRuleList = {"UnanchorAll", "UnweldAll", "Ungroup"}
Stone.BuildingMaterial = true
Stone.Hidden = true -- hide stone from resources
Stone.BaseDamage = 3
Stone.DamageType = "Crush"

function Stone:CheckGather(Inst)
	if (Inst:IsA("BasePart") and Inst.Anchored) or Inst:FindFirstChild("Weld") then 
		return false, {"Use a pickaxe to gather this resource"}, "Mine"
	end
	return true
end

ObjectService:AddObject(Stone)


local ToolHead = Instinct.Create(Object)
ToolHead.SaveDataList = {}

ToolHead.CheckGather = true

function ToolHead:GetBaseDamage(Tool)
	local n = Tool.Tool.Name
	local obj = ObjectService:GetObject(n)
	local mat = obj:GetContext(Tool.Tool, "Material")[1]
	print(mat)
	if mat then
		local obj = self:GetObject(mat)
		if obj then
			return {Hardness = obj.Hardness, Density = obj.Density}
		end
	end
end

local Axe = ToolHead:CreateExtension("Axe")
Axe.DamageType = "Cut"
Axe.BaseDamage = 10
ObjectService:AddObject(Axe)
 
local Knife = ToolHead:CreateExtension("Knife")
Knife.DamageType = "Cut"
Knife.BaseDamage = 20
ObjectService:AddObject(Knife)

local Pickaxe = ToolHead:CreateExtension("Pickaxe")
Pickaxe.DamageType = "Hack"
Pickaxe.BaseDamage = 15
ObjectService:AddObject(Pickaxe)


local StoneTypes = {
	"General",
	"River",
	"Pressured",
	"Volcanic",
	"All"
}

local Instinct = _G.Instinct
Instinct.Utilities.Options.New("StoneType", StoneTypes)

local stonedata = {}

_G.StoneData = stonedata
stonedata.StonesInStoneType = {}

local data = {
	[Instinct.Options.StoneType.General] = {
			Flint = {
				Rarity = 0.75,
				OreBoost = "Chalcopyrite",
				Hardness = 4,
				Density = 2.6
			},
			Chert = {
				Rarity = 4,
				OreBoost = "Franklinite",
				Hardness = 2,	
				Density = 2.65			
				
			},
			Chalk = {
				Rarity = 6,
				OreBoost = "Malachite",
				Hardness = 1,	
				Density = 2.4			
			},
			Coal = {
				Rarity = 2.5,
				OreBoost = "Cuprite",
				Hardness = 3,
				Density = 1.4
			},
			Shale = {
				Rarity = 11,
				OreBoost = "Cassiterite",
				Hardness = 2,
				Density = 2.6
			},
		},
	[Instinct.Options.StoneType.River] = {
		Sandstone = {
			Rarity = 10,
			OreBoost = "Pyrite",
			Hardness = 5,
			Density = 2.6
		},
		Mudstone = {
			Rarity = 3,
			OreBoost = "Cuprite",
			Hardness = 1,
			Density = 2.7
		},
		Breccia = {
			Rarity = 1,
			OreBoost = "Bismite",
			Hardness = 4,
			Density = 2.5
		},
		Dolomite = {
			Rarity = 5,
			OreBoost = "Nordenskioldine",
			Hardness = 5,
			Density = 2.9
			
		},
		Limestone = {
			Rarity = 8,
			OreBoost = "Malachite",
			Hardness = 3,	
			Density = 2.5		
		}
	},
	[Instinct.Options.StoneType.Pressured] = {
		Blueschist = {
			Rarity = 1,
			OreBoost = "Pyrolusite",
			Hardness = 7,
			Density = 1.8
		},
		Gneiss = {
			Rarity = 8,
			OreBoost = "Malachite",
			Hardness = 6,
			Density = 2.9
		},
		Quartzite = {
			Rarity = 0.5,
			OreBoost = "Pentlandite",
			Hardness = 8,
			Density = 2.8
		},
		Marble = {
			Rarity = 3,
			OreBoost = "Cassiterite",
			Hardness = 7,
			Density = 2.5
		},
		Slate = {
			Rarity = 10,
			OreBoost = "Stannite",
			Hardness = 9,
			Density = 2.8
		}
	},
	[Instinct.Options.StoneType.Volcanic] = {
		Obsidian = {
			Rarity = 0.3,
			OreBoost = "Chromium",
			Hardness = 11,
			Density = 2.4
		},
		Andesite = {
			Rarity = 5,
			OreBoost = "Chalcopyrite",
			Hardness = 11,
			Density = 2.5
		},
		Latite = {
			Rarity = 8,
			OreBoost = "Hematite",
			Hardness = 10,
			Density = 2.2
		},
		Rhyolite = {
			Rarity = 4,
			OreBoost = "Cassiterite",
			Hardness = 14,			
			Density = 2.6
		},
		Feldspar = {
			Rarity = 12,
			OreBoost = "Malachite",
			Hardness = 18,
			Density = 2.6
			
		}
		
	}
	
}

for StoneType, StoneData in pairs(data) do 
	for name, data in pairs(StoneData) do 
		local obj = Stone:CreateExtension(name)

		local new = Stone:CreateExtension(name)
		new.StoneType = StoneType


		for setting, settingdata in pairs(data) do 
			new[setting] = settingdata
			obj[setting] = settingdata
		end
		_G.StoneData[name] = new
		new.Material = "Stone"
		ObjectService:AddObject(new)

		if _G.StoneData.StonesInStoneType[StoneType] then
			table.insert(_G.StoneData.StonesInStoneType[StoneType], new)
		else
			_G.StoneData.StonesInStoneType[StoneType] = {new}
		end
	end	

end

local holder = {}

local Ore = Instinct.Create(Object)

Ore.Name = "Ore"
Ore.CheckGather=true
Ore.SaveDataList = {"Size"}
Ore.DamageType = "Crush"
Ore.BaseDamage = 1

ObjectService:AddObject(Ore)


_G.OreData = holder
_G.OreData.OresInStoneType = {}


local data = {
	Chalcopyrite = {
		Contents = {Cu = 34.6, Fe = 30.4},
		Rarity = 8,
		StoneType = Instinct.Option.StoneType.General,
		Density = 4.1
	},
	Cuprite = {
		Contents = {Cu = 88.8},
		Rarity = 1,
		StoneType = Instinct.Option.StoneType.General,
		Density = 6.14
	},
	Malachite = {
		Contents = {Cu = 57.3},
		Rarity = 10,
		StoneType = Instinct.Option.StoneType.All,
		Density = 3.7,
	},
	Cassiterite = {
		Contents = {Sn = 78.8},
		Rarity = 1,
		StoneType = Instinct.Option.StoneType.All,
		Density = 7,
	},
	Stannite = {
		Contents = {Cu = 29.6, Sn = 27.6, Fe = 13.0},
		Rarity = 3,
		StoneType = Instinct.Option.StoneType.General,
		Density = 4.3
	},
	Nordenskioldine = {
		Contents = {Sn = 43.0},
		Rarity = 7,
		StoneType = Instinct.Option.StoneType.General,
		Density = 4.1
		
	},
	Sphalerite = {
		Contents = {Zn = 67.1},
		Rarity = 0.25,
		StoneType = Instinct.Option.StoneType.General,
		Density = 3.9
	},
	Franklinite = {
		Contents = {Zn = 27.1, Fe = 46.3},
		Rarity = 0.75,
		StoneType = Instinct.Option.StoneType.General,
		Density = 5.1
	},
	Pyrite = {
		Contents = {Fe = 46.5},
		Rarity = 10,
		StoneType = Instinct.Option.StoneType.Pressured,
		Density = 4.8
	},
	Bismuthinite = {
		Contents = {Bi = 81.3},
		Rarity = 0.6,
		StoneType = Instinct.Option.StoneType.River,
		Density = 6.8
	},
	Bismite = {
		Contents = {Bi = 89.7},
		Rarity = 0.3,
		StoneType = Instinct.Option.StoneType.River,
		Density = 8.7
	},
	Stibnite = {
		Contents = {Sb = 71.7},
		Rarity = 0.25,
		StoneType = Instinct.Option.StoneType.River,
		Density = 4.63
	},
	Cobaltite = {
		Contents = {As = 45.2},
		Rarity = 1,
		StoneType = Instinct.Option.StoneType.River,
		Density = 6.3
	},
	Hematite = {
		Contents = {Fe = 69.9},
		Rarity = 6,
		StoneType = Instinct.Option.StoneType.Volcanic,
		Density = 5.3
	},
	Pyrolusite = {
		Contents = {Mn = 63.2},
		Rarity = 0.8,
		StoneType = Instinct.Option.StoneType.Pressured,
		Density = 5.1
	},
	["Native Silver"] = {
		Contents = {Ag = 80.5},
		Rarity = 0.08,
		StoneType = Instinct.Option.StoneType.Pressured,
		Density = 10.1
	},
	["Native Gold"] = {
		Contents = {An = 75.3},
		Rarity = 0.01,
		StoneType = Instinct.Option.StoneType.River,
		Density = 17;
	},
	Pentlandite = {
		Contents = {Ni = 41.0},
		Rarity = 10	,
		StoneType  = Instinct.Option.StoneType.Pressured,
		Density = 4.6
	},
	Chromite = {
		Contents = {Cr = 41.9},
		Rarity = 0.2,
		StoneType = Instinct.Option.StoneType.Volcanic ,
		Density = 4.6
		
	},
	Galena = {
		Contents = {Pb = 86.6},
		Rarity = 4,
		StoneType = Instinct.Option.StoneType.Volcanic,
		Density = 7.6
	},
	Beryl = {
		Contents = {Si = 31.0},
		Rarity = 1,
		StoneType = Instinct.Option.StoneType.Volcanic,
		Density = 2.7
	}

}

_G.OreData.OresInStoneType = {}

for OreName, OreData in pairs(data) do
	local new = {}
	new.Name = OreName

	local obj = Ore:CreateExtension(OreName)


	for setting, value in pairs(OreData) do
		new[setting] = value
		obj[setting] = value 
	end
	obj.Material = "Ore"
	ObjectService:AddObject(obj)
	_G.OreData[OreName] = new
	if _G.OreData.OresInStoneType[OreData.StoneType] and OreData.StoneType ~= Instinct.Option.StoneType.All then 
		table.insert(_G.OreData.OresInStoneType[OreData.StoneType], new)
	elseif  OreData.StoneType ~= Instinct.Option.StoneType.All then
		_G.OreData.OresInStoneType[OreData.StoneType] = {new}
	end
	
end

local new = Instinct.Create(Object)
new.Name = "Wood"
new.BuildingMaterial = true
new.Material = "Wood"
new.ToolToGatherWhenAnchored = "Axe"
new.ToolToGatherWhenWelded = "Axe"
new.ResizeTool = "Axe"
new.GatherVolumeMaximum = 2^3
new.SaveDataList = {"Size", "Color"}
new.MoveRuleList = {"UnanchorAll", "UnweldAll", "Ungroup"}
new.DamageType = "Crush"
new.BaseDamage = 4-- stick epic damage
new.Density = 0.7-- depends on wood, add later.
new.Hardness = 3

function new:CheckGather(Inst)
	local val = self:GetContext(Inst, "ChoppedDown")
	if val == 1 then
		return false, {"Use an axe to remove the leaves"}, "Chop"
	elseif val == 2 then
		return true
	else 
		return false, {"Use an axe to chop the tree down"}, "Chop", {Left="Shake tree"}
	end
end

ObjectService:AddObject(new)


-- le foliage

local Foliage = Instinct.Create(Object)
Foliage.Name = "Foliage"
Foliage.BuildingMaterial =true
Foliage.GatherVolumeMaximum = 2^3
Foliage.Material = "Leaves"
Foliage.ResizeTool = "Knife"
Foliage.SaveDataList = {"Size", "Color"}
Foliage.MoveRuleList = {"UnanchorAll", "UnweldAll", "Ungroup"}
Foliage.DamageType = "Cut"
Foliage.Hardness = 0.05
Foliage.Density = 0.4

function Foliage:CheckGather(Inst)
	if Inst.Parent.Name == "Wood" then
		return false, {"Chop the tree down with an axe"}, nil
	else
		return true
	end
end
ObjectService:AddObject(Foliage)
-- NEED KNIVE WHEN ANCHORED ?

local Apple = Instinct.Create(Object)
Apple.Name = "Apple"
Apple.SaveDataList = {"Size", "Color"} -- realy
Apple.MoveRuleList = {"Unweld", "Unanchor"}
Apple.CheckGather = true
Apple.Edible = {Hunger = 10, Thirst = 3}; -- edible value per studs^3
Apple.Hardness = 0.05
Apple.Density = 0.8
Apple.DamageType = "Crush"
function Apple:CustomVolume(inst) -- custom volume function; 
	if inst:IsA("BasePart") then
		local r = inst.Size.x/2
		return math.pi * 4/3 * r^3
	end
end
ObjectService:AddObject(Apple)


------------------------------------
------------------------------------
------------------------------------
--									--
--			SAVING RULES 			--
------------------------------------

local function addr(r,name)
	r.Name=r.Name or name
	ObjectService:AddRule(r,name,"Save")
end

-- SIZE RULE --
local Size = {}
Size.To = function(inst)
	local size = inst.Size
	local out = {x=size.X, y = size.Y, z=size.Z}
	return out
end

Size.From = function(data, instance)
	instance.Size = Vector3.new(data.x, data.y, data.z)
end
addr(Size,"Size")

local Colour = {}
Colour.To = function(inst)
	return inst.BrickColor.Number
end
Colour.From = function(data, inst)
	inst.BrickColor = BrickColor.new(data)
end
addr(Colour, "Color") -- QQ

local MaterialContext = {}

function MaterialContext.From(data, inst)
	local propcpy = {"Material", "BrickColor", "Reflectance", "Transparency"}
	-- only checks for stones
	print("called", inst.Name)
	warn("CALLED!!")
	-- please make a "STYLE" rule
	ObjectService:CopyStyle(game:GetService("ServerStorage").Mining:FindFirstChild(data), inst, propcpy)
	-- please move this somewhere else.. --	
	ObjectService:WeldObject(inst)		
end

MaterialContext.To = function() end

addr(MaterialContext, "ContextMaterial") -- qq

---- MOVERULES
-----
------
------
-------
local function addmvr(rule, name)
	ObjectService:Add(rule,name, "Move")
end

local unanchor = function(r)
	if r:IsA("BasePart") then
		r.Anchored=false
	else
		warn("no unanchor for models")
	end
end
addmvr(unanchor, "Unanchor")


local unweld = function(r)
	r:BreakJoints() -- works for mods/parts
end
addmvr(unweld, "Unweld")

function generic_inmod(where, func)
	local x = where
	while x.Parent and not x.Parent:IsA("Model") do
		x = x.Parent
	end
	local mod
	if x.Parent.Parent == game.Workspace then 
		mod = x
	elseif x.Parent.Parent == game.Workspace.Mine then 
		mod =x
	else
		mod = x.Parent
	end
	print("inmod " .. where:GetFullName(), mod:GetFullName())
	local function re(where)
		for i,v in pairs(where:GetChildren()) do
			if v:IsA("BasePart") then
				func(v, mod)
			end
			re(v)
		end
	end
	re(mod)
	func(mod, mod)
end

local unweld_all = function(r)
	generic_inmod(r, function(c) c:BreakJoints() end)
end

local unanchor_all = function(r)
	generic_inmod(r, function(c) if c:IsA("BasePart") then c.Anchored=false end end)
end
addmvr(unweld_all, "UnweldAll")
addmvr(unanchor_all, "UnanchorAll")

local ungroup = function(r)
	local c = r
	while c.Parent and not c.Parent:IsA("Model") do
		c = c.Parent
	end
	local root
	if c.Parent.Parent == game.Workspace then 
		root = c
	elseif c.Parent.Parent == game.Workspace.Mine then 
		root =c 
	else
		root = c.Parent
	end
print("inmod " .. r:GetFullName(), root:GetFullName())
	local function re(where)
		for i,v in pairs(where:GetChildren()) do
			if v:IsA("BasePart") and v ~= r then
				if root == r then 
					v.Parent=root.Parent				
				else 
					v.Parent = root
				end
			end
			re(v, root)
		end
	end
	re(root, root)
end

addmvr(ungroup, "Ungroup")

end