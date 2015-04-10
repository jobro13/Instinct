-- DataManager
-- Used to Create/Get/Write to Server data (and create this data) in an organized way
-- Can be called from Client too; Player is then set to LocalPlayer if not provided.

local DataManager = {}
DataManager.ContainerClassName = "Folder"

local Root = game:GetService("ReplicatedStorage")

-- Find containerName inside RootContainer
-- if not exist make it
function DataManager:GetSubContainer(RootContainer, ContainerName)
	if not RootContainer or not ContainerName then
		error("Missing argument @DataManager:GetSubContainer")
	end
	if not RootContainer:FindFirstChild(ContainerName) then
		Instance.new(self.ContainerClassName, RootContainer).Name = ContainerName
	end
	return RootContainer[ContainerName]
end

function DataManager:GetContainer(CName, Player)
	local Player = Player or game.Players.LocalPlayer
	if not Player or not CName then
		error("Missing argument @DataManager:GetContainer")
	end
	local Root = self:GetSubContainer(Root, "LocalPlayerData")
	local UserData = self:GetSubContainer(Root, tostring(Player.userId))
	return self:GetSubContainer(UserData, CName)
end

function DataManager:PlayerGetStat(StatName, Player)
	local Player = Player or game.Players.LocalPlayer
	if not StatName or not Player then
		error("Missing argument @DataManager:PlayerGetStat")
	end
	-- return the StatValue here;
end

function DataManager:PlayerIncreaseStat(StatName,Value,Player)
	local Player = Player or game.Players.LocalPlayer 
	if not ( StatName and Player and Value ) then 
		error("Missing argument @DataManager:PlayerIncreaseStat")
	end 
	-- increase statvalue
end 

return DataManager