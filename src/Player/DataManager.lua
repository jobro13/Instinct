-- DataManager
-- Used to Create/Get/Write to Server data (and create this data) in an organized way

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
end

return DataManager