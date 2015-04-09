-- Command gets called with info packet and data
local Commands = {}

local Chat = Instinct.Include "Chat"


function Commands.Test(Data, arg1)
	warn(arg1, "cmds work")
end

function Commands.Chat(Data, Message, Mode, Sender)
	warn("->>> CHAT")
	if Instinct.Gui and Instinct.Gui.Chat then 
		Instinct.Gui.Chat:Process(Message, Mode, Sender)
	end
end

function Commands.SetSkinColor(Data, Color)
	local ch = game.Players.LocalPlayer.Character
	for i,v in pairs(ch:GetChildren()) do
		if v:IsA("BasePart") then
			v.BrickColor = BrickColor.new(Color)
		end
	end
end

return Commands