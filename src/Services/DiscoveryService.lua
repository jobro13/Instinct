local DiscoveryService = {}

function DiscoveryService:Constructor()
	self.Cache = {}
	self.LastChecks = {}
	self.LocalDiscoveries = {}
	self.DataStoreService = game:GetService("DataStoreService")
end

function DiscoveryService:GetStore(Name)
	return self.DataStoreService:GetDataStore(Name, "DiscoveryData")
end

function DiscoveryService:GetDiscoveries(Name)
	local store = self:GetStore(Name)
	if store then 
		local this
		if not self.LastChecks[Name] then
			self.LastChecks[Name] = os.time()
			self.LocalDiscoveries[Name] = {}
			this = store:GetAsync("Data") or {}
			self.Cache[Name] = this
			self:CreateFromData(Name, this)
		elseif (os.time() - self.LastChecks[Name]) >= 50 then
			-- sure
			self.LastChecks[Name] = os.time()
			this = store:GetAsync("Data") or {}
			for objname, discoverer in pairs(this) do
				if self.Cache[Name] and self.Cache[Name][objname] == nil then
					self:CreateFromData(Name, this)
					if _G.Instinct.Mechanics.Chat then
						if not self.LocalDiscoveries[Name][objname] then
							print("discovery", discoverer, Name, objname)
							_G.Instinct.Mechanics.Chat:SendGlobal(discoverer .. " discovered a " .. Name .. ": " .. objname)
						end
					end
				end
			end			
			self.Cache[Name] = this
		else
			this = self.Cache[Name]
		end
		return this
	end
end

function DiscoveryService:CreateFromData(Name, Data)
	local mod = game:GetService("ReplicatedStorage").Discoveries
	if mod:FindFirstChild(Name) == nil then
		Instance.new("Model", mod).Name = Name
	end
	for objname, discoverer in pairs(Data) do
		print("check", objname, discoverer)
		if mod[Name]:FindFirstChild(objname) == nil then 
			local this = Instance.new("StringValue")
			this.Name = objname
			this.Value = discoverer
			this.Parent = mod[Name]
		end
	end
end


-- name = recipe/tool/resource
-- who is player name
-- what is the objname
function DiscoveryService:SetDiscovery(Name, Player, What)
	local Who	
	-- sorry guests 
	if Player.userId <= 0 then
		return 
	-- sorry noob dev
	elseif Player.Name == "jobro13" then
		return
	end
	Who = Player.Name
	if not Name or not Who or not What then
		return
	end
	if type(Name) ~= "string" or type(What) ~= "string" or type(Who) ~= "string" then
		return 
	end
	if self.Cache[Name] and self.Cache[Name][What] == nil then
		local store = self:GetStore(Name)
		if store then
			pcall(function()
			store:UpdateAsync("Data", function(oldValue)
				if oldValue == nil then
					return {What=Who}
				elseif oldValue and not oldValue[What] then
					oldValue[What] = Who
					if _G.Instinct.Mechanics.Chat then
						print("discovery", Who, Name, What)
						if self.LocalDiscoveries[Name] then
							self.LocalDiscoveries[Name][What] = true
						end
						_G.Instinct.Mechanics.Chat:SendGlobal(Who .. " discovered a " .. Name .. ": " .. What)
					end
					return oldValue
				end
			end)
			end)
		end
	end
end

return DiscoveryService