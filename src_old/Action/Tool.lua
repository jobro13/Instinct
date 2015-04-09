local Tool = {}

-- ! adding useful properties? add them to cpy list too. (in delegate function)

Tool.Grip = nil -- cf

Tool.IsEquipped = false
Tool.Hand = "Left"
Tool.Hotkey = 1
Tool.Type = "Normal"

function Tool:Constructor()
	self.Equipped = Instinct.Create(Instinct.Event)
	self.Unequipped = Instinct.Create(Instinct.Event)
	self.HotkeyChanged = Instinct.Create(Instinct.Event)
	self.IsEquipped = false
--	self:CreateWelds()
end

function Tool:UpdateWeld(part1, part2, c1, c2)
	if part1:FindFirstChild("Weld") then
		part1.Weld:Destroy()
	end
	local Weld = Instance.new("Weld", part1)
	Weld.Name = "Weld"
	Weld.Part0 = part2
	Weld.Part1 = part1
	Weld.C0 = c2:toObjectSpace(c1)
end

function Tool:Transform(part)
	print('transform', part.Name)
	part.CanCollide = false
	part.Anchored = false
end

function Tool:CreateWelds(root, weld_to, grip, dontweldtoroot)
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

function Tool:GetGrip()
	return self.Grip
end

function Tool:Equip()
	if Instinct.Communicator then
		
		Instinct.Communicator:Send("EquipTool", self.Tool, self.Hand, self:GetGrip())
	end
	if self.OnEquip then
		self:OnEquip()
	end
	--self.Equipped:fire()
end

function Tool:Unequip()
	if Instinct.Communicator then
		Instinct.Communicator:Send("UnequipTool", self.Tool)
	end
	if self.OnUnequip then
		self:OnUnequip()
	end
end

function Tool:CacheAction()
	-- figure out if we can do action, should return a string indication what it is
end

function Tool:GetDelegate()
	return setmetatable({}, {__index=self})
end

return Tool