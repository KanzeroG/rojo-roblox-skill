--[=[
	A client Controller. Lives in src/client/Controllers/. The client-side half of a
	feature: input, local effects, talking to a service, driving UI. Rename the file and
	the `Name` field to match (e.g. ShopController). The client bootstrap auto-requires it.
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- Siblings / services: resolve in KnitInit, USE in KnitStart
local TemplateService

local TemplateController = Knit.CreateController({
	Name = "TemplateController",
})

local selfPrint = "[ TemplateController ]"

--|| Public methods (called by UI or other controllers) ||--
-- function TemplateController:DoThing(payload)
-- 	-- maps to TemplateService.Client:DoThing(player, payload) on the server
-- 	TemplateService:DoThing(payload)
-- end

-- KNIT LIFECYCLE --
function TemplateController:KnitInit()
	TemplateService = Knit.GetService("TemplateService") -- proxy: only the service's Client table
end

function TemplateController:KnitStart()
	-- listen for server -> client signals here, e.g.:
	-- TemplateService.ExampleSignal:Connect(function(payload) ... end)
end

return TemplateController
