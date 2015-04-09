local Mover = {}

local KeyService

function Mover:Constructor()
	KeyService = _G.Instinct.Services.KeyService
end

local Mouse = game.Players.LocalPlayer:GetMouse()

Mover.MoveRoot = nil


Mover.Mode = "Nothing" 

Mover.CurrentAngles = {
	0,0,0
} -- Angles in RAD

Mover.AngleIncrement = math.pi/4 -- 45 degrees ^_^
Mover.StudIncrement = 1 -- snapper

function Mover:CreateBuilder()
	self.RemConn = {}
	local Gui = game:GetService("ReplicatedStorage").BuildGui:Clone()
	Gui.Parent = game.Players.LocalPlayer.PlayerGui
	local r = Gui.BuildGui.ContentClipper
	self.Gui = Gui
	self.ContentRoot = r	
	-- Connect all events to be very interactive ^_^
	local mv = r.Mode.Contents

	local arrow = mv.Arrow
	self.Arrow = arrow
	
	mv.Handle.MouseButton1Click:connect(function()
		if not self.MoveRoot then return end
		self:ToHandleMode()
		arrow:TweenPosition(UDim2.new(0.05, 0, 0, 35))
	end)
	mv.Resize.MouseButton1Click:connect(function()
		if not self.MoveRoot then return end
		local ok, err = self:CanResize() 
		if ok then 
			self:ToResizeMode()
			arrow:TweenPosition(UDim2.new(0.05, 0, 0, 60))
		else 
			self:SetStatus(err)
		end
	end)	
	mv.Rotate.MouseButton1Click:connect(function()
		if not self.MoveRoot then return end
		self:ToRotateMode()
		arrow:TweenPosition(UDim2.new(0.05, 0, 0,85))
	end)
	mv.Target.MouseButton1Click:connect(function()
		if not self.MoveRoot then return end
		arrow:TweenPosition(UDim2.new(0.05, 0, 0,10))
		self:ToMoveMode()
		
	end)
	-- Snap connections to change GripSnap size
	local sr = r.Snap.Contents.Target
	for i,v in pairs(sr:GetChildren()) do
		if v.Name ~= "Selection" then
			v.MouseButton1Click:connect(function()
				sr.Selection.Text = v.Text
				self.StudIncrement = tonumber(v.Text)
			end)
		end
	end
	-- Rotatoes
	local rr = r.Rotate.Contents.Target
	for i,v in pairs(rr:GetChildren()) do
		if v.Name ~= "Selection" then
			v.MouseButton1Click:connect(function()
				rr.Selection.Text = v.Text
				local num = tonumber(v.Text)
				local part = num/90
				self.AngleIncrement = part * math.pi/2
			end)
		end
	end
	r.Confirm.Contents.Target.MouseButton1Click:connect(function()
		print("CLICKED CONFIRM")
		if self.MoveRoot then
			self:Confirm()
		end
	end)
end

function Mover:CreateMover()
	self.RemConn = {}
end

function Mover:Confirm()
	-- notify server of size,cf
	self:SetStatus("Confirming...")
	local size = self.MoveRoot.Size
	if self.UseSize == size then
		size=nil
	end
	if self.MoverType == "Build" then
		_G.Instinct.Communicator:Ask("Build", self.MoveRoot, self.MoveRoot.CFrame, size)
	elseif self.MoverType == "Move" then
		_G.Instinct.Communicator:Ask("RequestMove", self.MoveRoot, self.MoveRoot.CFrame)
	end
	self:SetStatus("Click a resource to start")
	self.MoveRoot = nil
	self:InitializeActionChange()
end

function Mover:Clicked(m)
	print(m, self.Mode)
	if self.MoveRoot and self.MoverType == "Move" then
		self:Confirm()
		return
	elseif self.MoverType == "Move" then
		return
	end
	if m == "m1" and self.Mode == "Target" then
		self:CancelMovements()
	elseif self.MoveRoot and self.Mode == "Nothing" then
		if self.Arrow then
			self.Arrow:TweenPosition(UDim2.new(0.05, 0, 0, 10))
		end
		self:ToMoveMode()
	end
end

function Mover:DoubleClicked(m)
	-- confirm!
	print("DOUBLE LCIKC", m)
end

function Mover:CancelMovements()
	self.Mode = "Nothing"
	self:InitializeActionChange()
end

-- disown; return;
function Mover:Abort()
	self:CancelMovements()
	self:SetStatus("Cancelling...")
	_G.Instinct.Communicator:Ask("CancelResourceLock", self.MoveRoot)
	self:SetStatus("Click a resource to start")
	self.MoveRoot = nil
end

function Mover:SetStatus(Text)
	if not self.Gui then return end
	self.ContentRoot.Status.Contents.Target.Text=Text
end

function Mover:GetRootCFrame()
	if self.MoveRoot:IsA("Model") then
		-- FAK!
		return self.MoveRoot:GetModelCFrame()
	else
		return self.MoveRoot.CFrame
	end
end

function Mover:GetRootSize()
	if self.MoveRoot:IsA("Model") then
		return self.MoveRoot:GetModelSize()
	else
		return self.MoveRoot.Size
	end
end

function Mover:SetRootCFrame(CF)
	local Player = game.Players.LocalPlayer
	local Char = Player.Character
	if Char then
		if Char:FindFirstChild("Torso") then
			if (Char.Torso.Position - CF.p).magnitude > 20 then
				return
			end
		end
	end	
	
	
	if self.MoveRoot:IsA("Model") then
		local function moveModel(model,targetCFrame)
			for i,v in pairs(model:GetChildren()) do
				if v:IsA("BasePart") then
					v.CFrame=targetCFrame:toWorldSpace(model:GetModelCFrame():toObjectSpace(v.CFrame))
				end
				moveModel(v, targetCFrame)
			end
		end

		moveModel(self.MoveRoot, CF)
	else
		if self.MoveRoot:FindFirstChild("chParent") then
			for i,v in pairs(self.MoveRoot:GetChildren()) do
				if v:IsA("BasePart") and v.Name == "chParent" then
					local weld = v:FindFirstChild("Weld")
					if weld then
						local c0 = weld.C0
						v.CFrame = CF * c0
					end
				end
			end
			self.MoveRoot.CFrame = CF
		else
			self.MoveRoot.CFrame = CF
		end
	end
end

function Mover:SetRootSize(Size)
	local v = Size.x * Size.y * Size.z 
	local mv = self.UseSize.x * self.UseSize.y * self.UseSize.z 
	if v > mv then
		self:SetStatus("The volume of the resize is bigger than the original")
		return false
	end
	if self.MoveRoot:IsA("Model") then
		-- ... wat ... 
		warn("cannot resize models")
		return false
	end
	self.MoveRoot.Size=Size
	return true
end

function Mover:SelectTarget(Root)
	-- First check if we can get..
	warn("HERE")
	print(self.MoverType,  self.MoverType == "Build")
	if self.MoverType == "Build" then
	
		local o = _G.Instinct.Services.ObjectService:GetObject(Root.Name)
		local c = o:GetConstant("BuildingMaterial")
		print(#c)
		if #c==0 then
			self:SetStatus("This is not a building material!")
			return
		end
		for i,v in pairs(c) do
			if not v then
				self:SetStatus("This is not a building material!")
				return
			end
		end
		local size = _G.Instinct.Services.ObjectService:GetSize(Root)
		if size.x < 1 or size.y  < 1 or size.z < 1 then
			self:SetStatus("This resource is too small.")
			return
		end

	end	
	
	
	self.GettingMoveRoot = true
	-- call server to lock resource for self.
	self:SetStatus("Trying to lock resource...")
	local CanGet, msg = _G.Instinct.Communicator:Ask("RequestResourceLock", Root)
	
	if CanGet then
		self.MoveRoot = Root
		self.MoveRoot.Parent = game.Workspace 
	
		if Root:IsA("Model") then
			self.UseSize = Root:GetModelSize()
			function scan(f) 
				for i,v in pairs(f:GetChildren()) do
					if v:IsA("BasePart") then
						v.Anchored=true
						v.CanCollide=false
						v.Locked=true -- .. k
					end
					scan(v)
				end
			end
		
		else
			Root.Anchored=true
			Root.Locked=true
			Root.CanCollide=false
			self.UseSize = Root.Size
		end
		
		if self.MoverType == "Build" then
			local size = _G.Instinct.Services.ObjectService:GetSize(Root)
			local rs = {x=size.x, y=size.y, z=size.z}
			for i,v in pairs(rs) do
				rs[i] = math.floor(v) -- round down to lowest.
			end
			self:SetRootSize(Vector3.new(rs.x,rs.y,rs.z))
		end
	else
		self:SetStatus(msg or "")
	end
	self.GettingMoveRoot = false

end

-- Move to close grid number
local function close(num, tonext)
	local upv = (num + (tonext - (num % tonext)))
	if upv - num > tonext * 0.5 then
		return (num - (num % tonext))
	end
	return upv
end



function Mover:ResetAngles()
	self.CurrentAngles = {0,0,0}
end

-- Function to clean up OldActions
function Mover:InitializeActionChange()
	if self.CurrentHandles then
		self.CurrentHandles:Destroy()
	end
	for i,v in pairs(self.RemConn) do
		v:disconnect()
	end
	self.RemConn = {}
end

function Mover:CanResize() -- should return false + err
	if self.MoveRoot:IsA("BasePart") then
		if self.MoveRoot:FindFirstChild("chParent") == nil then
			local o = _G.Instinct.Services.ObjectService:GetObject(self.MoveRoot.Name)
			if o:GetConstant("ResizeTool") then
				local tr = o:GetConstant("ResizeTool")
				local tools = _G.Instinct.Services.ToolService
				if tools.EquippedRight and tools.EquippedRight.Tool.Name == tr[1] then
					return true
				elseif tools.EquippedLeft and tools.EquippedLeft.Tool.Name == tr[1] then
					return true
				else
					return false, "You need a " .. tr[1] .. " equipped to resize this!"
				end
			end			
			
			return true
		else
			return false, "You cannot resize this resource!"
		end
	else
		return false, "You cannot resize this resource!"	
	end

end

function Mover:ToResizeMode()
	if self:CanResize() then
		
		self:InitializeActionChange()
		self.Mode = "Resize"
		self:SetStatus("Drag the handles to resize the resource.")
		local handles = Instance.new("Handles", game.Players.LocalPlayer.PlayerGui)
		handles.Adornee = self.MoveRoot
		handles.Style = "Resize"
		self.CurrentHandles = handles
		self.LockedCF = self:GetRootCFrame() -- origin cframe, can be used for resets
		self.OrigSize = self:GetRootSize()
		local last = {}
		setmetatable(last, {__index=function() return 0 end})
	
		local low = 0.2 
		handles.MouseDrag:connect(function(face, delta)
			if math.abs(last[face] - delta) >= self.StudIncrement then 
				local nDist = last[face] - delta
				local size_now = self:GetRootSize()
				local r = Enum.NormalId 

				local x,y,z = size_now.x, size_now.y, size_now.z 
				local dx, dy, dz = 0,0,0
				local fx,fy,fz = x,y,z
				local mod = 1
				local snap = close(nDist, self.StudIncrement)
				if face == r.Back then --
					z = -snap + z 
				elseif face == r.Right then 
					x = -snap + x 
				elseif face == r.Left then 
					mod = -1 -- ?
					x = -snap + x
				elseif face == r.Front then  --
					z = -snap + z
					mod = -1
				elseif face == r.Top then 
					y = -snap + y
					
				elseif face == r.Bottom then 
					y = -snap + y 
					mod = -1
				end
				print(face)
				last[face] = last[face] - nDist

				if x < low or y < low or z < low then 
					return 
				end
				local rcf = self:GetRootCFrame()
				local ok = self:SetRootSize(Vector3.new(x,y,z))
				local vec = Vector3.new(x,y,z) - Vector3.new(fx,fy,fz)
				if not ok then
					vec = Vector3.new(0,0,0)
				end
				local mod = (vec) * 0.5 * mod 
				--print(Vector3.new(offset.x, offset.y, offset.z))
				self.LockedCF = rcf * CFrame.new(mod)
				self:SetRootCFrame(self.LockedCF)-- * CFrame.new(Vector3.new(-use.x/2, -use.y/2, -use.z/2)))
			end
		end)
		--print("connectiong")
		-- ONLY GETS FIRED WHEN UP @ HANDLE, CONNECT TO UINPUT
		table.insert(self.RemConn, KeyService.KeyUp:connect(function(mouse, state)
			if mouse ~= "m1" then return end
		--	print("UP")
			for i,v in pairs(last) do
				last[i] = 0
			
			end

		end))
	end
end

function Mover:ToHandleMode()
	self:InitializeActionChange()
	self.Mode = "Move"
	self:SetStatus("Drag the handles to move the resource.")
	local handles = Instance.new("Handles", game.Players.LocalPlayer.PlayerGui)
	handles.Adornee = self.MoveRoot
	handles.Style = "Movement"
	self.CurrentHandles = handles
	self.LockedCF = self:GetRootCFrame() -- origin cframe, can be used for resets
	local offset = {x=0,y=0,z=0}
	local root = {x=0,y=0,z=0}
	handles.MouseDrag:connect(function(face, delta)
		--print(face)
		local cfd = { -- unit delta vectors.
			[Enum.NormalId.Top] = Vector3.new(0,1,0); --
			[Enum.NormalId.Back] = Vector3.new(0,0,1);  --
			[Enum.NormalId.Left] = Vector3.new(-1,0,0); --
			[Enum.NormalId.Right] =Vector3.new(1,0,0);
			[Enum.NormalId.Front] = Vector3.new(0,0,-1); --
			[Enum.NormalId.Bottom] = Vector3.new(0,-1,0); --
		}
		local mvpos = cfd[face] * delta
		--local rpos = Vector3.new(close(mvpos.x, self.StudIncrement), close(mvpos.y, self.StudIncrement), close(mvpos.z, self.StudIncrement))
		for _,i in pairs({"x", "y", "z"}) do
			if mvpos[i] ~= 0 then
				offset[i] = close(cfd[face][i] * delta, self.StudIncrement) + root[i]
			end
		end
		local vec = offset 
		self:SetRootCFrame(self.LockedCF * CFrame.new(Vector3.new(offset.x, offset.y, offset.z)))
	end)
	table.insert(self.RemConn, KeyService.KeyUp:connect(function(mouse, state)
		if mouse ~= "m1" then return end
		for i,v in pairs(offset) do
			root[i] = root[i] + v
		end
	end)
	)
	
end



function Mover:ToRotateMode()
	self:InitializeActionChange()
	self.Mode = "Rotate"
	local handles = Instance.new("ArcHandles", game.Players.LocalPlayer.PlayerGui)
	handles.Adornee = self.MoveRoot
	self:SetStatus("Drag the handles to rotate the resource.")
	self.CurrentHandles = handles
	self.LockedCF = self:GetRootCFrame() -- origin cframe, can be used for resets
	local offset = {X=0,Y=0,Z=0}
	local root = {X=0,Y=0,Z=0}
	handles.MouseDrag:connect(function(face, delta)
		--print(face)
		local mvpos = delta
		--local rpos = Vector3.new(close(mvpos.x, self.StudIncrement), close(mvpos.y, self.StudIncrement), close(mvpos.z, self.StudIncrement))
		for _,i in pairs({"X", "Y", "Z"}) do
			if face == Enum.Axis[i] then
				offset[i] = (close(delta, self.AngleIncrement) + root[i]) % (math.pi * 2)
			end
		end
		local vec = offset 
		--print(offset.X/(math.pi/2), offset.Y/(math.pi/2), offset.Z/(math.pi/2))
		self:SetRootCFrame( self.LockedCF * CFrame.Angles(offset.X, offset.Y, offset.Z))
	end)
	table.insert(self.RemConn, KeyService.KeyUp:connect(function(mouse, state)
		if mouse ~= "m1" then return end
		for i,v in pairs(offset) do
			root[i] = (root[i] + v) % (math.pi * 2)
		end
	end))
end

-- Where should targ move? (For Target mode)
function Mover:GetTransformedCFrame()
	-- Move MoveRoot away so we can get the current target and hit..
	self.MoveRoot.Parent = nil
	local Target = Mouse.Target
	local Hit = Mouse.Hit
	if not Target then return end
	
		-- Rotate
	local Rotates = {
		[Enum.NormalId.Top] = CFrame.Angles(0,0,0); --
		[Enum.NormalId.Back] = CFrame.Angles(math.pi/2,0,0);  --
		[Enum.NormalId.Left] = CFrame.Angles(0,0, math.pi/2); --
		[Enum.NormalId.Right] = CFrame.Angles(0, 0,-math.pi/2);
		[Enum.NormalId.Front] = CFrame.Angles(-math.pi/2, 0, 0); --
		[Enum.NormalId.Bottom] = CFrame.Angles(math.pi, 0, 0); --
	}	
	
	
	local Surface = (Mouse.TargetSurface)
	--print(Surface)
	
	-- Get a rotated cframe so we can get a "local axis" offset.
	local RotatedCFrame = (Target.CFrame * Rotates[Surface])


	self.MoveRoot.Parent = game.Workspace
	-- Strip rotation matrix..
	local TargetRot = RotatedCFrame:toObjectSpace(CFrame.new(Target.Position))
	
	local Hit = CFrame.new(Hit.p) * TargetRot -- rotate the cframe. (Just copy target cframe)
	-- Retrieve offset.
	local offset = RotatedCFrame:toObjectSpace(Hit).p;
	-- Tansform target (this strips the rotation of the hit cframe and aligns it)
	--print(offset)
	-- y is always UP; noffset the rest.
	local noffset = Vector3.new(close(offset.x, self.StudIncrement), offset.y, close(offset.z, self.StudIncrement))	
	--print(noffset)
	--local vcf = Target.CFrame * CFrame.new(noffset)
	
	
	--[[local CenterCF = Target.CFrame * Rotates[Surface] -- rotated;
	local CenterSize = Target.Size
	local CenterCF = CenterCF * CFrame.new(0, CenterSize/2, 0)
	local Offset = Hit:toObjectSpace(CenterCF)
	print(Offset.p)--]]
	local newcf = RotatedCFrame * CFrame.new(noffset)
	
	-- Specific wedgepart top surface chk
	if Target:IsA("WedgePart") then 
		if Surface == Enum.NormalId.Top then 
			local real_ang = math.atan2(Target.Size.x, Target.Size.z)
	--		print(real_ang)
			newcf = newcf * CFrame.Angles(-real_ang, 0, 0)
		end
	end
	

	
	local Transform = CFrame.Angles(unpack(self.CurrentAngles))
	-- Here are hooks for possible r/t keys to rotate!
	local ax, ay, az = self.CurrentAngles[1], self.CurrentAngles[2], self.CurrentAngles[3]
	
	local Size =  self:GetRootSize()/2
	local newSize = Vector3.new(Size.x * math.sin(ax), Size.y * math.cos(ay), Size.z * math.sin(az))
	
	--print(newSize)	

	return newcf * CFrame.new(newSize) * Transform
end

function Mover:ToMoveMode()
	if not self.MoveRoot then return end
	self:InitializeActionChange()
	self.Mode = "Target"
	self:SetStatus("The resource moves to the mouse cursor. Click to lock position.")
	local id = (self.ModeID or 0) + 1
	self.ModeID = id
	print("moving..")
	while self.MoveRoot and self.Mode == "Target" and self.ModeID == id do -- breaks other threads.
		
		local newCF = self:GetTransformedCFrame()
	--	print(newCF)
		if newCF then
			self:SetRootCFrame(newCF)
		end
		wait()
	end
end


if false then
delay(1, function()
	Mover:ToHandleMode()
	wait(1)
	Mover:ToRotateMode()
	wait(1)
	Mover:ToResizeMode()
end)
Mover:ToMoveMode()
end

return Mover