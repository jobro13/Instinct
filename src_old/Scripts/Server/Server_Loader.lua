--- Load server using new framework ---

local BRoot = game:GetService("ReplicatedStorage").Instinct 

local Loader = require(BRoot.Instinct)

Loader:SetType("Server")

-- Loading sequence: first check inside ServerStorage, then inside RS
-- Server-only modules should go in ServerStorage
Loader:AddSource(game:GetService("ServerStorage").Instinct, "Server")
Loader:AddSource(game:GetService("ReplicatedStorage").Instinct, "Replicated")

-- In new Instinct define own sequence of loading modules 
-- Loading is done automatically
-- In modules, find other modules via _G.Instinct
-- Do NOT clutter the global environment with old versions.

Loader:Load("ObjectService", "Server")
