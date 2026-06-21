--[=[
	Client bootstrap. Lives at src/client/init.client.luau (so the src/client folder
	becomes a LocalScript named "Client" under StarterPlayerScripts).

	Order: require controllers -> start Knit -> mount the UI under the Rodux provider.
	A real game usually adds a preloader/loading-screen phase before mounting; see
	references/ui-state.md for the fuller sequence. This is the minimal version.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

local Client = StarterPlayer.StarterPlayerScripts.Client

-- Auto-require all controllers. Guard the folder so a fresh project without a
-- Controllers/ folder yet starts cleanly instead of erroring on a nil index.
local controllersFolder = Client:FindFirstChild("Controllers")
if controllersFolder then
	for _, module in controllersFolder:GetChildren() do
		if module:IsA("ModuleScript") then
			require(module)
		end
	end
end

Knit.Start()
	:andThen(function()
		print("[CLIENT] Knit started")

		-- Mount the UI. Uncomment once Roact/Rodux are set up (see references/ui-state.md):
		-- local Roact = require(ReplicatedStorage.Packages.Roact)
		-- local RoduxHooks = require(ReplicatedStorage.Packages.RoduxHooks)
		-- local Store = require(Client.Rodux.Store)
		-- local Root = require(Client.Roact.Root.Application)
		-- require(Client.Modules.Synchronization)() -- wire services -> store
		--
		-- Roact.mount(
		-- 	Roact.createElement(RoduxHooks.Provider, { store = Store }, {
		-- 		GameScreenGui = Roact.createElement(Root.Game),
		-- 	}),
		-- 	Players.LocalPlayer.PlayerGui,
		-- 	"UI"
		-- )
	end)
	:catch(warn)
	:await()
