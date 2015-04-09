-- Setups initial communications 
repeat wait() until _G.Instinct
Instinct=_G.Instinct
local ds = game:GetService("DataStoreService")
local rs = game:GetService("ReplicatedStorage")
local OBJS = Instinct.Include "Services/ObjectService"
local ToolService = Instinct.Include "Services/ToolService"
local SpawnService = Instinct.Include "Services/SpawnService"
warn(SpawnService)
-- [player] = {STORE = store}
local STORES_OPEN = {}
local SHOULD_UPDATE = {}
local SHOULD_UPDATE_TOOLS = {}

local STATS = {}

local DeltaStats = { -- decrease per second.
	Hunger = 0.05,
	Thirst = 0.0, -- disable thirst for now! [was 0.1]
	Health = -0.2,
	Energy = -0.5,
}

local ZOOM_MAX = 30 -- how much zoom max? QQ


	function tdump(a,l)
		local l = l or 0
		print('dump', a)
		if not a then return end
		for i,v in pairs(a) do
			if type(v) == "table" then
			--	print(string.rep("_", l) .. " going inside " .. tostring(v))
				tdump(v, l+1)
				
			else
				--print(string.rep("_", l ) .. " " .. tostring(i) .. " : " .. tostring(v))
			end
		end
	end	

-- Stats handler --
function CRstats(root, player)
	local StatData = SafeGet(GetStore(player, "Stats"), "Data") or {}
	
	local function mk(name, type, def)
		local has = nil;
		-- > implies player has died; reset val.
		if root:FindFirstChild(name) then has = true; root[name]:Destroy() end
		local new = Instance.new(type.."Value", root)
		new.Name = name
		if not has then 
			if StatData[name] == nil then
				new.Value = def
			else
				new.Value = StatData[name]
			end 
		else
			new.Value = def
		end
	end
	mk("Thirst", "Number", 100)
	mk("Hunger", "Number", 100)
	mk("Health", "Number", 100)
	mk("Energy", "Number", 100)
	mk("Alive", "Bool", true)
	SpawnService:ConvertPlayer(player, StatData)
	--if StatData.Alive ~= true then  -- > also for case nil
		SpawnService:SpawnPlayer(player)
--	end
--delay(5, function() SpawnService:CreateCorpse(player) end)
	STATS[player] = root
end

function wrapfunction(func, name)
	if rs:FindFirstChild(name) then
		rs[name]:Destroy()
	end
	local new = Instance.new("RemoteFunction", rs)
	new.Name = name
	new.OnServerInvoke = func
end

function getmod(root, name)
	if root:FindFirstChild(name) then
		return root[name]
	end
	local new = Instance.new("Model", root)
	new.Name = name
	return new
end

function getbp(player)
	return getmod(getmod(getmod(rs, "LocalPlayerData"), player.userId), "Backpack")
end

function getproot(player)
	return getmod(getmod(rs, "LocalPlayerData"), player.userId)
end

function ClearBackpack(player)
	local mod = getbp(player.userId)
	mod:ClearAllChildren()
end

function getcontainer(player, what)
	return getmod(getproot(player), what)
end
-- everything prefixed with PlayerData is a big no no for write all others are ok
function GetStore(player, name)
	local scope = "PlayerData" .. (player.userId)
	if STORES_OPEN[player] and STORES_OPEN[player][name] then
		return STORES_OPEN[player][name]
	end
	if not STORES_OPEN[player] then
		STORES_OPEN[player] = {}
	end
	STORES_OPEN[player][name] = ds:GetDataStore(name, scope)
	print("Created DS: " .. name .. " ; " .. scope .. " name,scope")
	return STORES_OPEN[player][name]
end

function SafeGet(DS, STR)
	local err, ret, nope
	err, ret = pcall(function() return DS:GetAsync(STR) end) -- oh hellu
	--print(err)
	if not err then
		local nope = false
		while wait(1) and (not nope) do
			print("Trying again")
			print("GET data")
			nope, ret = pcall(function() DS:GetAsync(STR) end)
			print(ret)
		end
	end
	return ret
end


function setup(player)
	player.CharacterAdded:connect(function(c)
		warn("in connection")
		repeat wait() until c:FindFirstChild("Humanoid")
		c.Humanoid.Died:connect(function() 
						Instinct.CommandsServer.Died({Player=player})
		end)
	end)
	if Instinct.Chat then
		Instinct.Chat:SendGlobal(player.Name .. " has joined the game!")
	end	
	
	
	local root = getbp(player)
	local proot = getproot(player)
	local app = getcontainer(player, "Appearance")
	local tools = getcontainer(player, "Tools")
	local stats = getcontainer(player, "Stats")
	player.CameraMaxZoomDistance = ZOOM_MAX 
	--player.CharacterAppearance = "http://www.roblox.com/Asset/CharacterFetch.ashx?userId=4030068"
	root.ChildAdded:connect(function() 
		if SHOULD_UPDATE[player] then
			SHOULD_UPDATE[player].Backpack = true
		else
			SHOULD_UPDATE[player] = {Backpack=true}
		end
	end)	
	
	root.ChildRemoved:connect(function()
		if SHOULD_UPDATE[player] then
			SHOULD_UPDATE[player].Backpack = true
		else
			SHOULD_UPDATE[player] = {Backpack=true}
		end
	end)
	tools.ChildAdded:connect(function()
		--print("add tool")
		if SHOULD_UPDATE[player] then
			SHOULD_UPDATE[player].Tools = true
		else
			SHOULD_UPDATE[player] = {Tools=true}
		end
	end)
	tools.ChildRemoved:connect(function()
		--print("rem tool")
		if SHOULD_UPDATE[player] then
			SHOULD_UPDATE[player].Tools = true
		else
			SHOULD_UPDATE[player] = {Tools=true}
		end
	end)
	
	-- Good. Let's load some DATA!!!
	local DS = GetStore(player, "Backpack")
	print(DS, "LELWAT")
	print("dont know wtf we are doing")
	print("GET data")
	-- dun forget to return pls jobro
	local ret = SafeGet(DS, "Data")

	--tdump(ret, 0)
	print(ret, "THERE IS DATA!!!")
	if ret then
		for index, data in pairs(ret) do
			local obj = OBJS:CreateObjectFromSaveData(data)
			if obj then
				-- w0w
				obj.Parent=root
			end
		end
	else
		-- NEW PLAYERRE!!!
	end
	local ToolData = SafeGet(GetStore(player, "Tools"), "Data")
	print(ToolData, " tool data")
	--tdump(ToolData)
	if ToolData then
		for index, data in pairs(ToolData) do
			print(index,data)
			local name, obj = ToolService:FromSaveData(data)
			ToolService:CreateNormalTool(player, name, obj)
		end
	end
	
	delay(0, function()
		while wait(60) and player.Parent do
			savestats(STATS[player], player)
		end
	end)
end



function AddBackpackItem(player, item)
	local root = getbp(player)
	if item.Parent and item.Parent:IsDescendantOf(Workspace) then
		-- kthen
		item.Parent = root
		return true
	end
	return false
end

-- save the tools model

function savetools(tools, player)

	print("Saving tools")
	local out = {}
	for i,v in pairs(tools:GetChildren()) do
		table.insert(out, ToolService:ToSaveData(v))
	end
	tdump(out)
	local DataStore = GetStore(player, "Tools")
	local qq, err = pcall(function() DataStore:SetAsync("Data", out) end)
	
end

-- save la st00f for the player
function save(storage_root, player)
	print("WE ARE SAIVNG DATA")
	if not storage_root then return end

	local savet = {}	
	
	for _, child in pairs(storage_root:GetChildren()) do
		local data = OBJS:GetSaveData(child)
		table.insert(savet, data)
	end
	-- is it really this easy!? dafuq

	local DataStore = GetStore(player, "Backpack")
	print(DataStore)
	print("set DATA", savet)
	print(" -- DUMPING -- ")
	function tdump(a,l)
		local l = l or 0
		if not a then return end
		for i,v in pairs(a) do
			if type(v) == "table" then
				print(string.rep("_", l) .. " going inside " .. tostring(v))
				tdump(v, l+1)
				
			else
				print(string.rep("_", l ) .. " " .. tostring(i) .. " : " .. tostring(v))
			end
		end
	end	
	--tdump(savet, 0)
	local qq, err = pcall(function() DataStore:SetAsync("Data", savet) end) -- ok what
	if not qq then
		-- y u cry
		warn("Data didn't save, QQ, err: " .. tostring(err))
		return
	end
	print("DATA SAVED FOR: " .. player.Name)
end

-- remove player connections! qq
function rem(player)	
	if Instinct.Chat then
		Instinct.Chat:SendGlobal(player.Name .. " has left the game!")
	end	
		
	
	
	if SHOULD_UPDATE[player] then
		SHOULD_UPDATE[player] = nil
		save(getbp(player), player)
	end
	STORES_OPEN[player] = nil
	local qqbaibai = (getproot(player) or Instance.new("Part")):Destroy() -- qq baibai
	
end

game.Players.PlayerAdded:connect(function(p) setup(p) end)
for i,v in pairs(game.Players:GetPlayers()) do
	setup(v)
end

function savestats(container, player)
	local store = GetStore(player, "Stats")
	-- build table
	local save = {Alive=true}
	for i,v in pairs(container:GetChildren()) do
		save[v.Name] = v.Value
	end
	local qq, err = pcall(function() store:SetAsync("Data", save) end)
end

game.Players.PlayerRemoving:connect(function(p) 
	local uid = p.userId
	local op = p
	wait(5) -- makes sure Alive is OK'd
	local p = {Name = p.Name, userId = uid}
	pcall(function()
	save(getbp(p), p) 
	savetools(getcontainer(p, "Tools"), p)
	savestats(STATS[op], p)
	rem(p) 
	end)
end)



repeat wait(1/60) until _G.Instinct

local comm = Instinct.Include("Communicator")
comm:Constructor()

local DiscoveryService = Instinct.Include "Services/DiscoveryService"
local Discoveries = {"Resource", "Recipe", "Tool"}
game:GetService("ReplicatedStorage").Discoveries:ClearAllChildren()
delay(0, function()
	while true do
		for _, Disc in pairs(Discoveries) do
			pcall(function() DiscoveryService:GetDiscoveries(Disc) end)
		end
		wait(60)
	end
end)

-- called when player click Start
warn("CREATED THING")
function Instinct.CommandsServer.RequestSetup(Data)
	warn("WE ARE CREATING THIS ALL AND WE ALL DONT KNOW WHY")
	print("CALLED THING")
	local p = Data.Player
	CRstats(getcontainer(p, "Stats"), p, true) -- stats will check for alive.
	
	if Instinct.Chat then
		Instinct.Chat:Send("Welcome to Stranded!", p)
		local Player = Data.Player
		if not (Player:IsInGroup(626209)) then
			Instinct.Chat:Send("Consider joining the Official Stranded Community group for the latest news!", Player)
		end
		if not (Player:IsInGroup(629748)) then
			Instinct.Chat:Send("Do you want to help improving this game? Join the Stranded Developer Community group!", Player)
		end
		Instinct.Chat:Send("Get in touch with other survivors via reddit: /r/robloxstranded!",Player)
	end	
	
	return true
end

--wait(5)
--comm:Send(game.Players.Player1, "Test", 'HI')
pcall(function()
game.OnClose = function()
	local num = 0
	for i,v in pairs(SHOULD_UPDATE) do
		num=num+1
	end
	for player, val in pairs(SHOULD_UPDATE) do
		if player.Parent and val.Backpack then
			save(getbp(player), player)
		end
		if player.Parent and val.Tools then
			savetools(getcontainer(player, "Tools"), player)
		end
		SHOULD_UPDATE[player]=nil
		wait(12 / num)
	end
	
	wait(10)
end

end)

local function IncreaseStat(Player, Stat, Value)
	if STATS[Player] then
		if STATS[Player]:FindFirstChild(Stat) then
			local stat = STATS[Player]:FindFirstChild(Stat)
			local v_now = stat.Value
			stat.Value = v_now + Value
			return stat.Value
		end
	end
end

function Instinct.CommandsServer.Eat(Data, Target, ED_Data)
	if Target.Parent then
		OBJS:ToBackpack(Target, nil)
		Target:Destroy()
		
		for stat, inc in pairs(ED_Data) do
			IncreaseStat(Data.Player, stat, inc)
		end
	end
end

function Instinct.CommandsServer.DoDamage(Data, Enemy, Damage)
	local d = IncreaseStat(Enemy, "Health", -Damage)
	if d then
		return true, Damage, d -- value of health now = d
	end
end

function Instinct.CommandsServer.Died(Data)
	local Player = Data.Player 
	-- handle death.
	-- first tools
	for i,v in pairs (getcontainer(Player, "Tools"):GetChildren()) do
		Instinct.CommandsServer.DropTool({Player=Player}, v)
	end
	
	local corpseloc = SpawnService:CreateCorpse(Player)
	local cloth = corpseloc and corpseloc:FindFirstChild("Clothing") 
	local bp = cloth and cloth:FindFirstChild("Backpack")
	if bp then
		local this = Instance.new("ObjectValue")
		this.Name = "BPRootLocation"
		local mk = Instance.new("Model")
		mk.Name = "Backpack"
		local bpr = getbp(Player)
		if bpr then
			for i,v in pairs(bpr:GetChildren()) do
				v.Parent = mk
			end
			mk.Parent = game:GetService("ReplicatedStorage").DroppedBackpacks
			this.Value = mk
			this.Parent = bp
		end
	end
	-- rem tools
	-- rem stuff bladibla
end

delay(0, function()
	while true do
		local t = wait(1)
		for player, root in pairs(STATS) do
			for index, child in pairs(root:GetChildren()) do
				if child.Name == "Health" and child.Value < 0 then
					Instinct.CommandsServer.Died({Player=player})
					
				end
				if DeltaStats[child.Name] then
					local calc = t * DeltaStats[child.Name]
					local rest = (child.Value - calc)
					child.Value = child.Value - calc
					if rest < 0 then
						child.Value = 0
						if root:FindFirstChild("Health") then
							root.Health.Value = root.Health.Value + rest
						end
					end
				end
				-- warn for later skills; change.
				if child:IsA("NumberValue") and child.Value > 100 then
					child.Value = 100
				end 
			end
		end
	end
end)


while wait(1) do
	local num = 0
	for i,v in pairs(SHOULD_UPDATE) do
		num=num+1
	end
	-- 12 seconds per loop + 1 second waitin on top will make sure we keep 5 requests per minutes to other DStores
	local err, whatwrong = pcall(function()	
	for player, val in pairs(SHOULD_UPDATE) do
		print(player, val.Backpack, val.Tools)
		if player.Parent and val.Backpack then
			save(getbp(player), player)
		end
		if player.Parent and val.Tools then
			print(savetools)
			savetools(getcontainer(player, "Tools"),player)
		end
		SHOULD_UPDATE[player]=nil
		wait(12 / num)
	end
	end)
	
	if not err then
		print(whatwrong)
		SHOULD_UPDATE={} -- qq
	end
end

