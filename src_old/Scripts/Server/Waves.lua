if game.JobId == "" then error() end
error() -- disable @server
local TimeManager = {}

TimeManager.DayCycleTime = 8 * 60-- -- How much seconds a day takes

local LinearInterpolate = function(x1, y1, x2, y2, delta, max_x) --if max_x specified then return y2 when x > max_x
 	-- Create a line
	if max_x and delta > max_x then 
		return y2
	end
	local r = (y2 - y1)/(x2 - x1)
	-- Goes through (x1, y1) -> k: y = rx + b
	-- r * x1 + b = y1 - r * x1
	-- b = y1 / (r * x1)
	local b = y1 - (r * x1)
	return r * delta + b 
end

if game.Name:match("Place%d*") then
	--TimeManager.DayCycleTime = 8 * 60 * 10^8
end
--TimeManager.Seasons = CreateProperty("List", {"Summer", "Autumn", "Winter", "Spring"})
TimeManager.DayTime = {Winter = {12,11,12}, Spring = {13,14,15}, Summer = {16,17,16}, Autumn = {15,14,13}}
TimeManager.DayTime = {Winter = {14,13}, Spring = {14, 15}, Summer = {16, 17}, Autumn = {16,15}}

TimeManager.CurrentDay = 2
TimeManager.CurrentSeason = "Summer"

TimeManager.Types = {Ambient = "Color3",
					OutdoorAmbient = "Color3", 
					Brightness = "Number",
					FogColor = "Color3",
					FogEnd = "Number",
					FogStart = "Number"}

TimeManager.DayState = {
	Ambient = Color3.new(100/255,100/255,110/255),
	Brightness = 1,
	OutdoorAmbient = Color3.new(130/255,130/255,140/255),
	FogColor = Color3.new(0.5, 0.5, 0.5),
	FogEnd = 300,
	FogStart = 50,
	
}

TimeManager.NightState = {
	Ambient = Color3.new(25/255,25/255,35/255),
	Brightness = 0.5,
	OutdoorAmbient = Color3.new(20/255,20/255,30/255),
	--FogStart = 0,
	--FogEnd = 200,
	FogColor = Color3.new(0,0,0)
}

TimeManager.StateShiftTime = 1 * 60 -- 60 minutes in-game time to change
TimeManager.NightShiftTimeStart = 17 * 60 + 45 -- 17:45
TimeManager.DayShiftTimeStart = 5 * 60

function TimeManager:GetDaylightTime()
	return 17 * 60 -- self.DayTime[self.CurrentSeason][self.CurrentDay] * 60
end

function TimeManager:GetNightTime()
	return 7 * 60--(24 - self.DayTime[self.CurrentSeason][self.CurrentDay]) * 60
end

function TimeManager:IsDay()
	return game.Lighting:GetMinutesAfterMidnight() > 6 * 60 and game.Lighting:GetMinutesAfterMidnight() < 18 * 60
end

function TimeManager:BatchUpdate(setting_table)
	for pname, pvalue in pairs(setting_table) do
		game.Lighting[pname] = pvalue
	end
end

function TimeManager:ChangeDay()
	--self.DayChanged:fire()
	do return end
	local new_day = self.CurrentDay + 1
	if false and not self.DayTime[self.CurrentSeason][new_day] then
		new_day = 1
		local current_season = nil
		for i,v in pairs(self.Seasons) do
			if v == self.CurrentSeason then
				current_season = i
				break
			end
		end
		local new_season = current_season + 1
		if not self.Seasons[new_season] then
			new_season =1
		end
		self.CurrentSeason = self.Seasons[new_season]
	--	self.SeasonChanged:Fire(self.CurrentSeason)

	end
	if self.CurrentDay > 3 then
		self.CurrentDay = 1
	end
	self.CurrentDay = new_day or 1
end

function TimeManager:UpdateTime(delta)
	local current_time = game.Lighting:GetMinutesAfterMidnight() 
	-- Calculate the "day-step" per second for this day.
	
	if not self:IsDay() then  -- night
		local NightTime = self:GetNightTime()
		local Proportion = NightTime / (24 * 60) 
		local Night_Need_Time = Proportion * self.DayCycleTime
		local ShiftTimeNeeded = 12 * 60 -- In game minutes shift.
		local ShiftTime = ShiftTimeNeeded / Night_Need_Time
		local up = delta * ShiftTime
	
		game.Lighting:SetMinutesAfterMidnight(current_time + up) 
	else 
		local DayLightTime = self:GetDaylightTime()
		local Proportion = DayLightTime / (24 * 60) 
		local Day_Need_Time = Proportion * self.DayCycleTime
		local ShiftTimeNeeded = 12 * 60 -- In game minutes shift.
		local ShiftTime = ShiftTimeNeeded / Day_Need_Time
		local up = delta * ShiftTime

		game.Lighting:SetMinutesAfterMidnight(current_time + up) 
	end
	-- Global lighting rechecks;
	-- Day change finder;
	if game.Lighting:GetMinutesAfterMidnight() < current_time then
		self:ChangeDay()
	end
	local current_time = game.Lighting:GetMinutesAfterMidnight() 
	if current_time > self.NightShiftTimeStart then
		if current_time < self.NightShiftTimeStart + self.StateShiftTime then
			local ctime = current_time - self.NightShiftTimeStart 
			local progress = ctime / self.StateShiftTime
			for index, value in pairs(self.NightState) do
				if self.Types[index] == "Color3" then
					local temp_reg = {}
					for _,field in pairs({"r", "g", "b"}) do
						local y1 = self.DayState[index][field]
						local y2 = self.NightState[index][field]
						local x1 = 0
						local x2 = 1
						local newval = LinearInterpolate(x1,y1,x2,y2,progress,x2)
						temp_reg[field] = newval
					end
					game.Lighting[index] = Color3.new(temp_reg.r, temp_reg.g, temp_reg.b)
				elseif self.Types[index] == "Number" then
					local x1 = 0
					local x2 = 0
					local y1 = self.DayState[index]
					local y2 = value
					local newval = LinearInterpolate(x1,y1,x2,y2,progress,x2)
					game.Lighting[index] = newval
				end
			end
		else
			-- parse defaults			
			self:BatchUpdate(self.NightState)
		end
	elseif current_time > self.DayShiftTimeStart then
		if current_time < self.DayShiftTimeStart + self.StateShiftTime then 
			local ctime = current_time - self.DayShiftTimeStart
			local progress = ctime / self.StateShiftTime
			for index, value in pairs(self.DayState) do
				if self.Types[index] == "Color3" then
					local temp_reg = {}
					for _,field in pairs({"r", "g", "b"}) do
						local y1 = self.NightState[index][field]
						local y2 = self.DayState[index][field]
						local x1 = 0
						local x2 = 1
						local newval = LinearInterpolate(x1,y1,x2,y2,progress,x2)
						temp_reg[field] = newval
					end
					game.Lighting[index] = Color3.new(temp_reg.r, temp_reg.g, temp_reg.b)
				elseif self.Types[index] == "Number" then
					local x1 = 0
					local x2 = 0
					local y1 = self.NightState[index]
					local y2 = value
					local newval = LinearInterpolate(x1,y1,x2,y2,progress,x2)
					game.Lighting[index] = newval
				end
			end
		else 
			-- parse defaults
			self:BatchUpdate(self.DayState)
		end
	end
end

function TimeManager:Initialize()
	--OLDPRINT("init")
	--self.SeasonChanged = CreateEvent(self, "SeasonChanged")
	--self.DayChanged = CreateEvent(self, "DayChanged")
	self.CurrentDay = 2
	self.CurrentSeasonDay = 2-- math.random(1,3)
	self.CurrentSeason = "Summer"-- self.Seasons[math.random(1,#self.Seasons)]
	game.Lighting.TimeOfDay = "12"
	delay(0, function() self:StartOcean() end)
--	self:StartCycle()
end

function TimeManager:StartOcean()
	--//Variable storage

local place=  game.Workspace.Ocean
local AmpStore = 0.1

--// FLOOD CALCULATIONS ARE HERE TOO

--// SEASON SUPPORT -NOT- IMPLEMENTED

--// ASSUMING THAT a + b cos (c ( x - d )) with a = FLOOD b = D FLOOD c = Amp d = 0

local Ocean = {}

--// Preferences

Ocean.Color = BrickColor.new("Bright blue")
Ocean.GroundColor = BrickColor.new("Pastel Blue")
local OceanParts = {}

local function Init()
	for i,v in pairs(place:GetChildren()) do
		if v.Name == "OceanVloer" then
			v.BrickColor = Ocean.GroundColor
		elseif v.Name:match("Oc%d") then
			v.BrickColor = Ocean.Color
			table.insert(OceanParts, v)
		end
	end
end

Init()

local function Update(height)
	for i,v in pairs(OceanParts) do
		
			v.CFrame = CFrame.new(Vector3.new(v.Position.x, height - v.Size.y/2, v.Position.z))
		
	end
end

local function FindClosestEven(number)
	return ((math.floor(number+0.5) % 2) == 0 and (math.floor(number+0.5)) or (math.floor(number+0.5) - 1))
end

while true do
	local x = 0	
		-- MAX HEIGHT is defined on  15.4 2.1 higher CENTER MAX IS 14.2
	--Sine 0 - HIGH - 0 - LOW - 0
	--     0    3     6    9    12
	--THAT MEANS THAT AT 3 OCLOCK (MAX) MAX HEIGHT IS 15.4, MEANING THAT CENTER IS 13
	-- AT 9 is low meaning that THAT - 1.2 is 10.9
	-- HIGH: 14.2
	-- LOW: 10.8
	-- CENTER (0) - 12,5 -- A = 12.5 B = 1.7 C = (360/(12*60)) D = 0
	-- That means aplitudo of the center wave is 1
	
	--// I forget here about that at not flood Amplitudo is not high (HOW TO FIX!?)
	local MaxAmp = 1
	local CenterAmp = MaxAmp/2
	local WaveTime = 90 -- This can change with weather. Storms, etc. Note that it's global and not to a local region.
	local AmpDiff = math.abs(AmpStore - CenterAmp) * 10
	local BaseDiff = AmpDiff / 2
	local start = FindClosestEven(BaseDiff)
	local DAmplitudo = (math.random(0,start) - (start / 2) )/10
	AmpStore = AmpStore + DAmplitudo
	if AmpStore <= 0 then
		AmpStore = 0.1
	elseif AmpStore > MaxAmp then
		AmpStore = MaxAmp
	end
	local RealTime = 360/WaveTime
	while x < RealTime do
		local TimeOfDay = game.Lighting:GetMinutesAfterMidnight() % (12 * 60) -- (returns 0-12*60 minutes)
		local center = 10 + 2 * math.sin(math.rad( (360/(12*60)) * TimeOfDay))
		x = x + wait() 		
		local Sine = center + AmpStore * math.sin(math.rad(WaveTime * x))
		Update(Sine)
	end
	
	end
end


--delay(0,function()TimeManager:Initialize()end)

while true do 
	TimeManager:UpdateTime(wait(0.25))
end
