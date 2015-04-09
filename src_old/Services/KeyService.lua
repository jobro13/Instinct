local KeyService = {}

KeyService.Keys = {}

KeyService.DoubleClickTime = 0.25

-- enums plz

KeyService.State = "Default" -- block keys later (via keydown event)

local fix = {}
fix.__index = function(tab, index)
	rawset(tab, index, {true, tick()})
	return rawget(tab, index)
end

setmetatable(KeyService.Keys, fix) -- Fixes a "nil-call" when key was not down / up yet

function KeyService:Constructor()
	self.KeyDown = Instinct.Create "Event"
	self.DoubleClick = Instinct.Create "Event"
	self.KeyUp = Instinct.Create "Event"
end

function KeyService:GetKey(input)
	return (type(input) == "number" and input) or (type(input) == "string" and input:byte()) or 1
end

function KeyService:KeyIsUp(key)
	return self.Keys[self:GetKey(key)][1] and true 
end

function KeyService:KeyIsDown(key)
	return not self:KeyIsUp(key)
end

function KeyService:GetTime(key)
	return tick() - self.Keys[key][2]
end

function KeyService:KeyIsDownFor(key, time)
	return self:KeyIsDown(key) and self:GetTime(key) > time
end

function KeyService:KeyIsUpFor(key, time)
	return self:KeyIsUp(key) and self:GetTime(key) > time
end

function KeyService:Initiate() 
local uis = game:GetService("UserInputService")
uis.InputBegan:connect(function(obj)
	local _,kc = pcall(function() return obj.KeyCode end)
	if kc then
		self.Keys[kc] = {true, tick()}
		self.KeyDown:fire(kc, self.State)
	end
end)
uis.InputEnded:connect(function(obj)
	local _,kc = pcall(function() return obj.KeyCode end)
	if kc then
		self.Keys[kc] = {false,tick()}
		self.KeyUp:fire(kc, self.State)
	--	self.KeyUp:fire(kc, self.State)
	end
end)
local mouse = game.Players.LocalPlayer:GetMouse() 
--[[mouse.KeyUp:connect(function(key) 
	self.Keys[key:byte()] = {true, tick()}
end)
mouse.KeyDown:connect(function(key)
	self.Keys[key:byte()] = {false, tick()}
	OLDPRINT("Key down: "..key)
	self.KeyDown:fire(key, self.State)
end)--]]
local lastm1down = 0
local lastm2down = 0
mouse.Button1Down:connect(function()
	self.KeyDown:fire("m1", self.State)
	if os.time() - lastm1down < self.DoubleClickTime then
		self.DoubleClick:fire("m1", self.State)
	end
	lastm1down = os.time()
end)
mouse.Button2Down:connect(function()
	self.KeyDown:fire("m2", self.State)
	if os.time() - lastm2down < self.DoubleClickTime then 
		self.DoubleClick:fire("m2", self.State)
	end
	lastm2down = os.time()
end)
mouse.Button1Up:connect(function()
	self.KeyUp:fire("m1", self.State)

end)
mouse.Button2Up:connect(function()
	self.KeyUp:fire("m2", self.State)

end)
end

return KeyService

