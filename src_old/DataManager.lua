local DataManager = {}

function DataManager:GetRoot(player)
	if game:GetService("ReplicatedStorage"):FindFirstChild("LocalPlayerData") then
		return game:GetService("ReplicatedStorage"):FindFirstChild("LocalPlayerData"):FindFirstChild(tostring(player.userId))
	end
end

function DataManager:GetContainer(player, name)
	local root =self:GetRoot(player)
	if root then
		return root:FindFirstChild(name)
	end
	
end



return DataManager