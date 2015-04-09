local ToolService = {}

function ToolService:Constructor()
	self.ToolEquipped = Instinct.Create(Instinct.Event)
end

function ToolService:EquipTool(tool)
	if tool.Hand == "Left" then
		tool.OtherEquipped = self.Right
	elseif tool.Hand == "Right" then
		tool.OtherEquipped = self.Left
	else
		warn("no hand set")
		return
	end 
	tool:Equip()
	self.ToolEquipped:fire(tool)
end


return ToolService