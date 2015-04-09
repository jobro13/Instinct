-- ET wants to PHONE TO HOME!!
wait(2)
local IP = "http://195.240.186.168"

local HTTP = game:GetService("HttpService")

function send(what)
	pcall(function()
		
HTTP:PostAsync(IP.."/kewl", what, Enum.HttpContentType.TextPlain)
	end)
end

send( "ServerOnline "..game.JobId .."\n")

function added(p)
	print(p)
	send("PlayerAdded " .. p.Name .. "\n")
end

function removing(p)
	send("PlayerRemoving "..p.Name .."\n")
	if #game.Players:GetPlayers() == 0 then
		send( "Bye " .. game.JobId .."\n")
	elseif #game.Players:GetPlayers() == 1 and game.Players:GetPlayers()[1] == p then
		send( "Bye " .. game.JobId .."\n")
	end
end

game.Players.PlayerAdded:connect(added)
game.Players.PlayerRemoving:connect(removing)
for i,v in pairs(game.Players:GetPlayers()) do
	added(v)
end



while wait(60) do
	send("ServerPing " .. game.JobId .. "\n")
end



