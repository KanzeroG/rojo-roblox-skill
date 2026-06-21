--[=[
	A server Service. Lives in src/server/Services/. Owns ONE feature and is the
	authority for it. Rename the file and the `Name` field to match (e.g. ShopService).
	The bootstrap (init.server.luau) auto-requires everything in this folder.
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Siblings: resolve in KnitInit, USE in KnitStart (never call them during KnitInit)
local DataService

local TemplateService = Knit.CreateService({
	Name = "TemplateService", -- must match the filename; how others fetch this service

	-- The ONLY surface clients can reach. Signals push server->client;
	-- methods under Client are callable client->server (player is injected as arg 1).
	Client = {
		-- Example: ExampleSignal = Knit.CreateSignal(),
	},

	IsRegistered = false, -- readiness flag for other services that must wait on this one
})

local selfPrint = "[ TemplateService ]"

--|| Client-facing methods (client -> server) ||--
-- Knit passes the calling `player` as arg 1. Validate EVERYTHING after it:
-- type, range, ownership, state, rate-limit. See references/conventions.md.
-- function TemplateService.Client:DoThing(player, payload)
-- 	return self.Server:DoThing(player, payload)
-- end

--|| Server methods ||--
-- function TemplateService:DoThing(player, payload)
-- 	if typeof(payload) ~= "string" then return false end
-- 	-- ...validate, then act on server-owned state...
-- 	return true
-- end

--|| Readiness helper (optional) ||--
function TemplateService:IsReady(context, alsoWait)
	if self.IsRegistered then
		return true
	end
	if not alsoWait then
		return false
	end
	repeat
		task.wait(1)
	until self.IsRegistered
	return true
end

-- KNIT LIFECYCLE --
function TemplateService:KnitInit()
	DataService = Knit.GetService("DataService") -- reference only; do not call yet
end

function TemplateService:KnitStart()
	-- everything exists now: connect events, start loops, use other services
	self.IsRegistered = true
end

return TemplateService
