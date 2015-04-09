wait(1)
DEBUG = (game.Workspace.DistributedGameTime > 30)-- true -- do NOT REBUILD
math.randomseed(os.time())
for i,v in pairs(script.Parent:GetChildren()) do
	if v ~= script then
		if v:IsA("Script") then
			v.Disabled = true
		end
	end
end

-- why do we even modulescript
function refr(root)
	for i,v in pairs(root:GetChildren()) do
		if v:IsA("ModuleScript") then
			v:Clone().Parent = v.Parent
			v:Destroy()
		end
		refr(v)
	end
end
refr(game:GetService("ReplicatedStorage").Instinct)
refr(game:GetService("ServerStorage").Instinct)

_G.__InstinctPresets = {
	LoadType = "Server"
}

_G.Instinct = {} 

_G.WaitForInstinct = function()
	repeat wait(1/60) until _G.Instinct
end

local Instinct = require(game:GetService("ReplicatedStorage").Instinct.Instinct)()
Instinct.Initialize "Server"
Instinct.Include "World/Tree"
Instinct.Include "World/WorldTools"
Instinct.Include "World/Mine"
local resinit = require(game:GetService("ReplicatedStorage").Instinct.Resources)
resinit()
local recinit = require(game:GetService("ReplicatedStorage").Instinct.Recipes)
recinit()

function dig(v, prev)
	do return end
	for i,v in pairs(v) do 
		print(prev.."."..i)
		if type(v) == "table" and not v.IsAClass then 
			dig(v, prev.."."..i)
		end
	end
end

dig(Instinct, "Instinct")
if not DEBUG then
game.Workspace.Life:ClearAllChildren()
game.Workspace.Mine.Dynamic:ClearAllChildren()
game.Workspace.Mine.Static:ClearAllChildren()
game.Workspace.Resources:ClearAllChildren()
game.Workspace.Corpses:ClearAllChildren()
game:GetService("ReplicatedStorage").DroppedBackpacks:ClearAllChildren()
end
local Tree = Instinct.Create(Instinct.World.Tree)

local Placer = Instinct.Include "World/Placer"
local ColorData = Instinct.Include "Utilities/BrickColorUtils"
local Random = Instinct.Include "Utilities/Random"

require(game:GetService("ReplicatedStorage").Instinct.Tools)()

for i,v in pairs(script.Parent:GetChildren()) do
	if v ~= script then
		if v:IsA("Script") then
			v.Disabled = false
		end
	end
end


local ColorWeights = {
["Deep pink"] = 1,
Purple = 1,
["Deep yellow"]=10,
Green=0.5,
["Light pink"]=2,
White=0.25,
Brown=0.4,
["Deep blue"]=5,
["Light yellow"]=6,
Black=0.05,
["Light blue"]=6,
Red=4,
}

-- TREE --

local check = function(child)
	return child.Name == "FertileGround"
end

local place = function(pos, part)
	Instinct.Create(Instinct.World.Tree)
	local ok =Tree:Initialize(pos, part)
	if ok then 
	Tree:Generate()
	wait(0.25)
	end
end

-- ROCK --

local check_rock = function(child)
	return child.BrickColor == BrickColor.new "Dark stone grey" or child.Name == "FertileGround" --and math.random(1,4) == 1
end

local place_rock = function(pos, part)
	local wt = Instinct.World.WorldTools
	if wt:IsRoom(pos + Vector3.new(0,3/2,0), Vector3.new(6,3,6)) then
		if not Instinct.World.Mine then 
			repeat wait() until Instinct.World.Mine
		end
		local ground = Instinct.World.Mine:GetStone(nil, Instinct.Option.StoneType.General)
		local function get(min,max)
			return min + math.random() * (max-min)
		end
		local new = Instance.new("Model", game.Workspace.Mine.Static)
		new.Name = "Stones"
		for i = 1, math.random(2,3) do 
			local sizeof = Vector3.new(get(3,4), get(2,3), get(3,4))
			local moveof = Vector3.new(get(-2,2), 0, get(-2,2))
			local npos = pos + moveof
			local x = ground:Clone()
			x.FormFactor = "Custom"
			x.Size = sizeof
			
			x.Parent = new
			x.CFrame = CFrame.new(npos) * CFrame.Angles(math.rad(get(0,45)), math.rad(get(1,360)), math.rad(get(0,45)))
		end
		if math.random(1,2) == 1 then -- okay also spawn a small stone
			local function make()
			local smstone = ground:Clone()
			smstone.FormFactor = "Custom"
			smstone.Size = Vector3.new(1,1,1)
			smstone.Parent = game.Workspace.Resources
			smstone.Anchored = false
			smstone.CFrame = CFrame.new(pos) * CFrame.new(0,4 + math.random() * 4,0)  * CFrame.Angles(0, math.rad(get(1,360)), 0)
			end 
			make()
			if math.random(1,4) == 1 then make()
				if math.random(1,4) == 1 then make() 
					
				end
			end
		end
		if math.random() <= Instinct.World.Mine.GroundOreChance then 
		--	warn('we are spawning ORE')
			local ore = Instinct.World.Mine:GetOre(ground)
			if ore then
				ore.Parent = game.Workspace.Resources 
				ore.Anchored = false
				ore.CFrame = CFrame.new(pos) * CFrame.new(0,4 + math.random() * 4,0)  * CFrame.Angles(0, math.rad(get(1,360)), 0)
			end		
		end
	end
end

-- PLANT

function check_plant(child)
	return child.Name == "FertileGround" 
end

function make_plant(pos, part)
	if Instinct.World.WorldTools:IsRoom(pos + Vector3.new(0,2,0), Vector3.new(5,4,5))  then
		local scol = {
			BrickColor.new "Bright green",
			BrickColor.new "Earth green",
			BrickColor.new "Medium green",
			BrickColor.new "Grime"
		}	
		local stalkcol = scol[math.random(1,#scol)]
		local cgroup = Random:FromWeightsTable(ColorWeights)
		local cdata = ColorData.Data[cgroup]
		local d = {}
		for i,v in pairs(cdata) do
			if v ~= stalkcol.Number then
				table.insert(d,v)
			end
		end
		local function place(pos)
			local stalk = Instance.new("Part", game.Workspace)
			stalk.TopSurface = "Smooth"
			stalk.BottomSurface = "Smooth"
			stalk.BrickColor = stalkcol
			stalk.Anchored = true
			stalk.FormFactor = "Custom"
			stalk.Name = "Flower Stalk"
			local x,y = math.random() * 0.5 + 0.3, math.random() * 2 + 1
			stalk.Size = Vector3.new(x,y,x)
	
			local flower = stalk:Clone()
			flower.Name = "Flower"
			flower.Size = Vector3.new(x,x,x)
			flower.BrickColor = BrickColor.new(d[math.random(1,#d)])
		
			stalk.CFrame = CFrame.new(pos) * CFrame.new(0, y/2, 0) * CFrame.Angles(0, math.rad(math.random(1,360)), 0)
			flower.CFrame = stalk.CFrame * CFrame.new(0, y/2 + x/2, 0)
			flower.Parent = stalk
			stalk.Parent = game.Workspace.Resources
		end
		local iter = math.random(3,5)
		local sp = pos + Vector3.new(-iter,0,-iter)
		for i = 1, math.random(3,5) do 
			local plus = sp + Vector3.new(i * (math.random()/2+0.5) * 1.5, 0, math.random() * 5)
			place(plus)
		end
	end
	
end

local slowrates = {AcadiaIsland = true, LagoonIsland = true, Island1 = true, MegaRock = true}

delay(0, function() 
	do return end
	local Placement = Instance.new("RemoteFunction", game:GetService("ReplicatedStorage"))
Placement.Name = "PlaceFunc"

local growt = {}

function Placement.OnServerInvoke(player,pos, targ)
	print(pos, targ)
	local new = Instinct.Create(Instinct.World.Tree)
	local ok = new:Initialize(pos, targ)
	if ok then 
		table.insert(growt,new)
	end
end

while wait(1) do
	for i,v in pairs(growt) do
		v:Grow()
		wait(0.2)
	end
end

end)

if not DEBUG then
for i,v in pairs(game.Workspace.World:GetChildren()) do 
	
	if not slowrates[v.Name] then 	
		Placer:DoJob( v, 6000,8000, check, place)
		Placer:DoJob( v, 5000,12000, check_rock, place_rock)
	else
		Placer:DoJob(v, 1400,1800, check, place)
		Placer:DoJob( v, 5000,12000, check_rock, place_rock)
	end
		Placer:DoJob(v, 2000,4000, check_plant, make_plant)
	
end

end