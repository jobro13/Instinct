local Chat = {}

-- Chat provides everything necessary for backend chat. GUI should be loaded from anything else.

local IsLocal = (game.Players.LocalPlayer ~= nil)



Chat.EnergyTap = {
	Global = 50;
	Shout = 25;
	Yell = 10;
	Default = 0;
	Whisper = 0;
}

Chat.Range = {
	Global = math.huge;
	Shout = 300;
	Yell = 200;
	Default = 100;
	Whisper = 20;
}

Chat.Keywords = {
	["g/"] = "Global";
	["s/"] = "Shout",
	["kappa/"] = "Yell",
	["w/"] = "Whisper",
	["d/"] = "Default",
}

function Chat:Send(Message, Player)
	local Communicator = _G.Instinct.Communicator
	if IsLocal then

		Communicator:Send("Chat", Message, Player.Name)
	else
		Communicator:Send(Player, "Chat", Message, "Default", "_host")
	end
end

function Chat:SendGlobal(Message)
	local Communicator = _G.Instinct.Communicator
	Communicator:SendAll("Chat", Message, "Default", "_host")
end

-- returns energytap, range and "real message"
function Chat:GetAttributes(message)
	local mode = message:sub(1,2)
	local cmode = self.Keywords[mode] or "Default"
	local cmsg = message
	if self.Keywords[mode] then
		cmsg = message:match(mode.."%s*(.+)")
	end
	cmsg = self:FixMessage(cmsg)
	return self.EnergyTap[cmode], self.Range[cmode], (self.Keywords[mode] or "Default"), cmsg
end

-- makes msg nice.
function Chat:FixMessage(msg)
	if not msg then return "" end
	-- fix first
	local msg = msg:gsub("^%W*%w", function(what)  return string.upper(what) end)
	--local msg = msg:gsub("%.%W%w", function(what) print(2, what) return string.upper(what) end)
	local msg = msg:gsub("%.%s*%l", function(qq) return string.upper(qq) end)
	local msg = msg:gsub("\n", function(qq) return "" end)
	if msg:len() > 150 then
		msg = msg:sub(1,150)
	end
	return msg
end

return Chat