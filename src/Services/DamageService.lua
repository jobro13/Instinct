local DamageService = {}

local ObjectService, ToolService, Communicator 

DamageService.CooldownScaler = 1;
DamageService.CriticalHitChance = 0.1

function DamageService:Constructor()
	ObjectService = _G.Instinct.Services.ObjectService
	ToolService = _G.Instinct.Services.ToolService
	Communicator = _G.Instinct.Communicator
	self.Cooldowns = {}
end


DamageService.DamageTypes = {
	Cut = {
		BuildingDamage = 0.5;
		PlayerDamage = 1.5;
	},
	Crush = {
		BuildingDamage = 2;
		PlayerDamage = 1;
	},
	Hack = {
		BuildingDamage = 1.5;
		PlayerDamage = 1.25;
	}
}

DamageService.NoToolDamage = {
	Hardness = 2;
	DamageType = "Crush"
}

DamageService.DamageMultiplier = {
	Head = 2;
	Torso = 1.5;
	["Left leg"] = 1;
	["Right leg"] = 1;
	["Left arm"] = 1;
	["Right arm"] = 1;
	Backpack = 1.25;
}

function DamageService:Constructor()
	if game.Players.LocalPlayer then 	
		local Gui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
		Gui.Name = "DamageGui"
		self.Gui=Gui
		self.Cooldowns = {}
	end
end

function DamageService:IsPlayer(Target)
	local c = Target
	repeat
		c = c.Parent
	until (c and c:FindFirstChild("Humanoid")) or (not c)
	if c and c:FindFirstChild("Humanoid") then
		return c
	end
end

-- Basically checks if this is a player we can attack. Returns a bool.
function DamageService:CanAttack(TargetInstance)
	local Mouse = game.Players.LocalPlayer:GetMouse()
	local Char = game.Players.LocalPlayer.Character
	if Char:FindFirstChild("Torso") and (Mouse.Hit.p - Char.Torso.Position).magnitude < 5 then
		local IsPlayer = self:IsPlayer(TargetInstance)
		if IsPlayer then
			return true 
		end 
	end
	return false 
end 

function DamageService:GetDamageInfo(Tool, TargetInstance)
	if not TargetInstance then return end
	if os.time() - (self.Cooldowns[Tool.Hand] or 0) < 0 then
		return -- cooldown thing
	end
	local Mouse = game.Players.LocalPlayer:GetMouse()
	local Char = game.Players.LocalPlayer.Character
	if Char:FindFirstChild("Torso") and (Mouse.Hit.p - Char.Torso.Position).magnitude < 5 then
		local IsPlayer = self:IsPlayer(TargetInstance)
		if IsPlayer then
			local Name = TargetInstance.Name
			-- check for backpack
			local DamageMultiplier = self.DamageMultiplier[Name] or self.DamageMultiplier.Backpack
			
			local ToolName = Tool.Tool.Name 
			local Object = ObjectService:GetObject(ToolName)
			if Object then
				-- all tools get damage calculation
				if true then -- (Object:GetConstant("Hardness")[1] and Object:GetConstant("DamageType")[1] and Object:GetConstant("Density")[1]) or  Object:GetConstant("GetBaseDamage")[1] then
					local glob = {}					
					if Object.GetBaseDamage then
						glob = Object:GetBaseDamage(Tool) or {}
					end
					local Mass = glob.Mass or (ObjectService:GetVolume(Object) or 1) * (glob.Density or Object.Density or 1)
					local Cooldown = Mass * self.CooldownScaler
					local DamageTypeMultiplier = self.DamageTypes[glob.DamageType or Object.DamageType or ""]  or 1
					if type(DamageTypeMultiplier) ~= "number" then
						DamageTypeMultiplier = 1
					end
					local Multiplier = DamageTypeMultiplier * DamageMultiplier
				--	local Critical = false

										
					-- Ok so we calculated Cooldown and Multiplier
					-- Let's calculate energy loss due to this dmaage [later]
					
					
					local BaseDamage = glob.BaseDamage or Object.BaseDamage or 1
				
					local Damage = math.sqrt(BaseDamage * Mass * (glob.Hardness or Object.Hardness or 1)) * Multiplier
					
					return {Damage = Damage,  Cooldown = Cooldown, TargetType = "Player", Target = IsPlayer}
				end
			end
		end
	end
end

function DamageService:Attack(Tool, TargetInstance)
	local Info = self:GetDamageInfo(Tool, TargetInstance)
	if Info then
		ToolService:SetCooldown(Tool.Hand, Info.Cooldowns)
		self.Cooldowns[Tool.Hand] = os.time() + (Info.Cooldown or 1)
		if math.random() <= self.CriticalHitChance then
			Info.Damage = Info.Damage * 2
			Info.IsCritical = true
		end
		if Info.TargetType == "Player" then
			Communicator:Send("DoPlayerDamage", Info.Target, Info.Damage, Info.IsCritical)

			-- > push to GUI
		end
	end
end

return DamageService