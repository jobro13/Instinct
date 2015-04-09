-- Command gets called with info packet and data
local Commands = {}

local Chat = _G.Instinct.Mechanics.Chat


function Commands.Test(Data, arg1)
	--warn(arg1, "cmds work")
end

function Commands.Chat(Data, Message, Mode, Sender)

	if _G.Instinct.Gui and _G.Instinct.Gui.Chat then 
		_G.Instinct.Gui.Chat:Process(Message, Mode, Sender)
	end
end

-- Ugly hack because setting character stuff from server is a big NOPE with Repl off
function Commands.SetSkinColor(Data, Color)
	local ch = game.Players.LocalPlayer.Character
	for i,v in pairs(ch:GetChildren()) do
		if v:IsA("BasePart") then
			v.BrickColor = BrickColor.new(Color)
		end
	end
end

return Commands