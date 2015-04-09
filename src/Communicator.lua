local Communicator = {}

local IsLocal = (game.Players.LocalPlayer~=nil)

function Communicator:Constructor()
	if IsLocal then
		-- war has begun god dammit
		_G.Counter = (_G.Counter or 0) + 1
		local DEBOUNCER = _G.Counter or 0
		
		self.Commands = _G.Instinct.Data.CommandsLocal
		self.SendData = game:GetService("ReplicatedStorage").ServerSocket
		self.AskData = game:GetService("ReplicatedStorage").ServerAsk
		-- START HAXY CODE --
		-- small env hack
		-- fix NON-GC'd connection (roblox memleak??)
		local ev = {}
		local function DISCONNECT()
			ev[1]:disconnect()
			ev[2]:disconnect()
			error("@------ DISCONNECTED FROM PREVIOUS EVENTS , ROBLOX GC FAILED? -----@")
		end
		
		ev[1] = self.SendData.OnClientEvent:connect(function(CommandName, ...)
			warn(_G.Counter, DEBOUNCER)
			if DEBOUNCER ~= _G.Counter then
				DISCONNECT()
			end
			print("<- " .. CommandName)
			if self.Commands[CommandName] then
				self.Commands[CommandName]({Type = "Event"}, ...)
			else

				warn(tostring(CommandName) .. " doesnt exist")
			end
		end)
		self.AskData.OnClientInvoke = function(CommandName, ...)
			print("<- " .. CommandName)
			--if DEBOUNCER ~= _G.Counter then
			--	DISCONNECT()
			--end
			if self.Commands[CommandName] then
				return self.Commands[CommandName]({Type="Function"}, ...)
			else
	
				warn(tostring(CommandName) .. " doesnt exist")
			end
		end
		-- END HAXY CODE -- 
	else
		self.Commands = _G.Instinct.Data.CommandsServer
		self.SendData = game:GetService("ReplicatedStorage").ServerSocket
		self.AskData = game:GetService("ReplicatedStorage").ServerAsk
		self.AskData:Destroy() self.SendData:Destroy()
		local new = Instance.new("RemoteEvent", game:GetService("ReplicatedStorage"))
		new.Name = "ServerSocket"
		self.SendData = new
		local new = Instance.new("RemoteFunction", game:GetService("ReplicatedStorage"))
		new.Name = "ServerAsk"
		self.AskData = new
		
		self.SendData.OnServerEvent:connect(function(Player, CommandName, ...)
		print("<- " .. CommandName)
			if self.Commands[CommandName] then
				self.Commands[CommandName]({Type = "Event", Player=Player}, ...)
			else
		
				warn(tostring(CommandName) .. " doesnt exist")
			end
		end)
		self.AskData.OnServerInvoke = function(Player, CommandName, ...)
			print("<- " .. CommandName)
			if self.Commands[CommandName] then
				return self.Commands[CommandName]({Type="Function", Player=Player}, ...)
			else
				
				warn(tostring(CommandName) .. " doesnt exist")
			end
		end
	end
end

if IsLocal then 
	function Communicator:Send(Command, ...)
		print("-> " .. Command)
		self.SendData:FireServer(Command, ...)
	end
	function Communicator:Ask(Command, ...)
		print("-> " .. Command)
		return self.AskData:InvokeServer(Command, ...)
	end
else
	function Communicator:Send(Player, Command, ...)
		print("-> " .. Command)
		self.SendData:FireClient(Player, Command, ...)
	end
	function Communicator:Ask(Player, Command, ...)
		print("-> " .. Command)
		return self.AskData:InvokeClient(Player, Command, ...)
	end
	function Communicator:SendAll(Command, ...)
		print("-> " .. Command)
		self.SendData:FireAllClients(Command, ...)
	end
end

return Communicator