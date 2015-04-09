return (function() local toadd = {}
local function mk(n)
	local o = {Name=n}
	table.insert(toadd,o)
	return o
end

local ClothingService = Instinct.Include "Services/ClothingService"

local dr = game:GetService "ServerStorage"
local r = dr.Clothing

Backpack = mk "Backpack"
Backpack.Grip = CFrame.new(0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1) * CFrame.Angles(0,math.pi,0)
Backpack.Root = r.Backpack
Backpack.BodyPart = "Torso"

Shirt = mk "Shirt"
Shirt.Grip = CFrame.new(0,-0.2, 0.04, 1, 0, 0, 0, 1, 0, 0, 0, 1)
Shirt.Root = r.Shirt
Shirt.BodyPart = "Torso"

LeftPants = mk "LeftPants"
LeftPants.Grip = CFrame.new(0, 0.42, 0.01, 1, 0, 0, 0, 1, 0, 0, 0, 1)
LeftPants.Root = r.LeftPants
LeftPants.BodyPart = "Left Leg"

RightPants = mk "RightPants"
RightPants.Grip =  CFrame.new(0, 0.42, 0.01, 1, 0, 0, 0, 1, 0, 0, 0, 1)
RightPants.Root = r.RightPants
RightPants.BodyPart = "Right Leg"

for i,v in pairs(toadd) do
	ClothingService:AddCloth(v)
end
end)