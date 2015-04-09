-- Knapping function



local Knapping = {}

Knapping.Patterns = {
	Knife = {
		{false, false, false, false, false	},
		{false, false, false, false, false},
		{true, true, true, true, true},
		{true, true, true, true, false},
		{false, false, false, false, false}
	},
	Pickaxe = {
		{false, false, false, false, false},
		{false, true, true, true, false},
		{true, false, false, false, true},
		{false, false, false, false, false},
		{false, false, false, false, false},
		
	},
	Axe = {
		{false, false, false, false, true},
		{true, true, true, true, true},
		{true, true, true, true, true},
		{true, true, true, true, true},
		{false, false, false, false, true},
	}
}

function Knapping:Knap(What)
	if self.Knapping then
		self:StopKnap()
	end
	-- block tools
	_G.Instinct.Services.KeyService.State = "Knapping" 
	_G.Instinct.UI.Chat:PutLocal("Click on the rock to remove a piece. Press z to return. If nothing could be created the stone is lost.")
	self.KeyConnection = _G.Instinct.Services.KeyService.KeyDown:connect(function(key, state)
	--	OLDPRINT("KNAP KEYDOWN", key)
		if key == "m1" or key == "m2" then
			--OLDPRINT(Mouse.Target and Mouse.Target.Parent.Name)
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local Camera = game.Workspace.CurrentCamera
			if Mouse.Target and  Mouse.Target.Parent == Camera:FindFirstChild("Knap") then
				Mouse.Target:Destroy()
			end 
		elseif key == Enum.KeyCode.Z then
			self:StopKnap()
		end
	end)
	local Camera = game.Workspace.CurrentCamera
	self.Knapping = What
	self.KnappingParent = What.Parent
	game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 0
	self.LastCF = Camera.CoordinateFrame
	self:ConvertToKnapObject(What)
	Camera.CameraType = "Scriptable"
	Camera.CoordinateFrame = CFrame.new(What.Position + Vector3.new(0,5,0), What.Position)
	
end

function Knapping:StopKnap()
	if self.KeyConnection then
		self.KeyConnection:disconnect()
		self.KeyConnection = nil
	end
	local this = game.Workspace.CurrentCamera:FindFirstChild("Knap")
	local didhit = false
	local wrong
	local created
	-- chkcreate
	for createdname, data in pairs(self.Patterns) do
		wrong = false
		created = createdname
		for y, d in pairs(data) do
			for x, val in pairs(d) do
				print(val, this:FindFirstChild(y.."x"..x) ~= nil, x,y)
				if (this:FindFirstChild(y.."x"..x) ~= nil) == val then
					
				else
					if #(this:GetChildren()) ~= 25 then
						didhit = true
					end
					wrong = true
					created=nil
					break
				end 
			end
			if wrong then
				created=nil
				break
			end
			if created then
				--break
			end
		end
		if created then break end
	end

	
	if created then
		_G.Instinct.Communicator:Send("CreateKnap", self.Knapping, created)
	end
	
	if didhit then
		_G.Instinct.Communicator:Send("DestroyResource", self.Knapping, "KnappingError")
	end	
	
	game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=16
	_G.Instinct.Services.KeyService.State = "Default"
	local Camera = game.Workspace.CurrentCamera
	Camera.CoordinateFrame = self.LastCF
	Camera.CameraType = "Custom"
	if self.Knapping then 
		self.Knapping.Parent = self.KnappingParent
	end
	if Camera:FindFirstChild("Knap") then
		for i,v in pairs(Camera:GetChildren()) do 
			if v.Name == "Knap" then 
				v:Destroy()
			end
		end
	end
	self.Knapping = nil
	self.KnappingParent = nil
end



function Knapping:ConvertToKnapObject(root)
	root.Parent = nil
	local center = root.CFrame
	local y = root.Position.y
	local Camera = game.Workspace.CurrentCamera
	local temp = Instance.new("Model", Camera)
	temp.Name = "Knap"
	for x = -0.4, 0.4, 0.2 do 
		for z = -0.4, 0.4, 0.2 do
			local new = root:Clone()
			new.FormFactor = "Custom"
			new.Size = Vector3.new(0.2,1,0.2)
			new.Anchored = true
			new.CFrame = CFrame.new(center.x + x, y, center.z + z)
			new.Name = math.abs(((x + 0.6) * 5) - 6) .. "x" .. ((z + 0.6) * 5)
			new.Parent = temp
		end
	end	
end

return Knapping