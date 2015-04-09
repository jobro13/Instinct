local ClothingService = {}

-- general interface to clothing. should be expanded later.
-- clothing are just resources. v1=current
-- v1: do not add to resources, as we need additional rules for gathering then. not something we want, rite?
-- v2: add to objects
-- v3: make unwear/wear
-- v4: add chcreator

function ClothingService:Constructor()
	self.Clothing = {}
end

function ClothingService:AddCloth(ClothData)
	-- what is necessary?
	local function check(prop)
		if ClothData[prop] == nil then
			error(prop .. " is notprovided with clothdata")
		end
	end
	check "Name"
	check "BodyPart"
	check "Grip" -- grip is derived from bodypart CF
	check "Root"
	self.Clothing[ClothData.Name] = ClothData
end

-- shamelessly copied from tools

function ClothingService:UpdateWeld(part1, part2, c1, c2)
	if part1:FindFirstChild("Weld") then
		part1.Weld:Destroy()
	end
	local Weld = Instance.new("Weld", part1)
	Weld.Name = "Weld"
	Weld.Part0 = part2
	Weld.Part1 = part1
	Weld.C0 = c2:toObjectSpace(c1)
end

function ClothingService:Transform(part)
	print('transform', part.Name)
	part.CanCollide = false
	part.Anchored = false
end

function ClothingService:CreateWelds(root, weld_to, grip, dontweldtoroot)
	local hand = hand
	local handle = root
--	handle.Parent = game.Workspace
	if not root then return end
	local mainpart = root


	for i,v in pairs(mainpart:GetChildren()) do
		if v:IsA("BasePart") and v ~= mainpart then
			self:UpdateWeld(v, mainpart, v.CFrame, mainpart.CFrame)
			if not dontweldtoroot then
				self:Transform(v)
			end
		end
	end
	if not dontweldtoroot and mainpart:IsA("BasePart") then
		self:Transform(mainpart)
	end
	local Weld
	if not dontweldtoroot then
		Weld = Instance.new("Weld", weld_to)
		Weld.Name = "Weld"
		Weld.Part1 = weld_to
		Weld.Part0 = mainpart
		Weld.C1 = grip or CFrame.new()
		Weld.C0 = CFrame.new()
	end
	return 
end

function ClothingService:GetCloth(name)
	return self.Clothing[name]
end


-- v1: no check for clothes which are being worn.
-- v2: check for clothes.. etc..
-- clothinst is a copy of the cloth; can be changed if necessary; only change style, sizes will be problematic
-- no hard checks for hta.t
function ClothingService:WearCloth(ClothName, ClothInst, Player)
	-- clothinst should be a clone.
	if self.Clothing[ClothName] == nil then
		-- clothing doesnt exist, baibai
		warn(ClothName.. " does not exist, cannot wear.")
		return
	end
	local ClothData = self.Clothing[ClothName]
	local char = Player.Character
	if char:FindFirstChild("Clothing") == nil then
		local mod = Instance.new("Model", char)
		mod.Name = "Clothing"
	end
	local this = char.Clothing 
	local BodyPart = ClothData.BodyPart
	if char:FindFirstChild(BodyPart) then
		local weldto = char[BodyPart]
		local root = ClothInst
		-- assuming the chParent structure;
		self:CreateWelds(root, weldto, ClothData.Grip, nil)
		root.Parent=this
	else 
		-- body part doesnt exist, cannot wear this cloth. baibai.
	end
end

function ClothingService:UnwearCloth(root)
	-- unwear cloth by destroying it or something. or dropping it. not supported as of v1
end

return ClothingService

