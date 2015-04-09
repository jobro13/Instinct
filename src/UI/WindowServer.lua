local WindowServer = {}

WindowServer.Windows = {}

function WindowServer.Notify(Window, StateChange)
	
end

function WindowServer.RequestOpen(WindowName, Button)
	local new
	if WindowServer.Windows[WindowName] then
		WindowServer.Windows[WindowName]:Toggle()

		
	else
		new = _G.Instinct.Create(_G.Instinct.Gui.Window)
		new:Create(nil, WindowName)
		if Button then
			new:SetButton(Button)
		end
		new:SetTitle(WindowName)
		new:Open()
		WindowServer.Windows[WindowName] = new

	end
	for i,v in pairs(WindowServer.Windows) do
		if i ~= WindowName then
			v:Close()
		end
	end
	return new
end

return WindowServer