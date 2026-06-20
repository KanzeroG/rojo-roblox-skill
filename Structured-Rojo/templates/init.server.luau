--[=[
	Server bootstrap. Lives at src/server/init.server.luau (so the src/server folder
	becomes a Script named "Server" under ServerScriptService).

	It requires every Service in the Services folder, then starts Knit. There is no
	registration list to maintain — drop a new service into Services/ and it loads.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
-- require here any packages that must initialize once, e.g.:
-- require(ReplicatedStorage.Packages.Animation)

-- Auto-require all services
for _, module in script.Services:GetChildren() do
	if module:IsA("ModuleScript") then
		require(module)
	end
end

Knit.Start()
	:andThen(function()
		print("[SERVER] started successfully")
	end)
	:catch(warn)
	:await()
