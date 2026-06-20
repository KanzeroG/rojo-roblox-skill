# Services & Controllers: the Knit architecture

Load this when writing or wiring server services or client controllers, or when explaining
how the two sides talk. This is the core architecture of the framework.

## The shape

- A **Service** runs on the **server**. It owns one feature and is the authority for it
  (data, shop, inventory, combat). It's created with `Knit.CreateService`.
- A **Controller** runs on the **client**. It's the client-side half of a feature, input,
  local effects, talking to a service, driving UI. Created with `Knit.CreateController`.
- Both are auto-discovered: the bootstrap requires every module in the folder, then starts
  Knit, which runs their lifecycle methods.

One service ↔ one controller is the common pairing, but not a rule. Some services have no
controller (pure server logic); some controllers have no service (pure client UI).

## Lifecycle: `KnitInit` then `KnitStart`

This is the part people get wrong, so internalize it. When `Knit.Start()` runs:

1. **`KnitInit` runs on every module first.** At this point all services/controllers
   *exist* but none have started. This is where you grab references to siblings,
   `Knit.GetService("DataService")`, and store them. **Do not call them yet**; they aren't
   ready.
2. **`KnitStart` runs on every module after all inits finish.** Now everything is live. Do
   your actual setup here: connect events, start loops, use other services.

Get this backwards (calling a sibling during `KnitInit`) and you'll hit nil or
half-initialized state. The split exists precisely so circular references between features
resolve cleanly.

## A service: end to end

This follows the framework's own convention (`selfPrint` tag, `Client` table,
`IsRegistered` readiness flag). Copy `templates/service.luau` to start.

```luau
-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Siblings (resolved in KnitInit, used in KnitStart)
local DataService

local ShopService = Knit.CreateService({
    Name = "ShopService",
    Client = {
        -- server → client signal
        PurchaseResult = Knit.CreateSignal(),
    },
    IsRegistered = false,
})

local selfPrint = "[ ShopService ]"

--|| Client-facing methods (client → server) ||--
-- Knit passes `player` as the first argument automatically. Validate EVERYTHING after it.
function ShopService.Client:BuyItem(player, itemId)
    return self.Server:BuyItem(player, itemId)   -- delegate to a server method
end

--|| Server methods ||--
function ShopService:BuyItem(player, itemId)
    -- 1. validate input shape
    if typeof(itemId) ~= "string" then return false end
    -- 2. look up the item in shared/Data (source of truth)
    -- 3. check the player can afford it (server-owned currency)
    -- 4. deduct and grant atomically, then:
    self.Client.PurchaseResult:Fire(player, { ok = true, itemId = itemId })
    return true
end

-- KNIT LIFECYCLE
function ShopService:KnitInit()
    DataService = Knit.GetService("DataService")   -- reference only
end

function ShopService:KnitStart()
    self.IsRegistered = true                       -- now safe to be used by others
end

return ShopService
```

Key conventions visible here:

- **`Name`** must match the module name and is how others fetch it
  (`Knit.GetService("ShopService")`).
- **`Client = { … }`** is the ONLY thing clients can reach. Signals
  (`Knit.CreateSignal()`) push server→client; methods under `Client` are callable
  client→server.
- **`Client:Method(player, …)`** receives the calling player as arg 1, injected by Knit.
  Treat every other argument as hostile until validated.
- **`selfPrint`** is a logging prefix so console output is greppable per service.
- **`IsRegistered`** is a readiness flag; pair it with an `IsReady(context, alsoWait)`
  helper when other services must wait for this one (see the framework's
  `NotificationService` pattern).

## A controller: end to end

Copy `templates/controller.luau`.

```luau
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Player
local player = Players.LocalPlayer

local ShopController = Knit.CreateController({
    Name = "ShopController",
})

local selfPrint = "[ ShopController ]"

local ShopService   -- resolved in KnitInit

function ShopController:Buy(itemId)
    ShopService:BuyItem(itemId)   -- calls the service's Client:BuyItem (player is implicit)
end

function ShopController:KnitInit()
    ShopService = Knit.GetService("ShopService")
end

function ShopController:KnitStart()
    -- listen for the server's response
    ShopService.PurchaseResult:Connect(function(result)
        if result.ok then
            print(`{selfPrint} bought {result.itemId}`)
        end
    end)
end

return ShopController
```

Note the asymmetry: from the client, `Knit.GetService("ShopService")` returns a *proxy* that
only exposes the service's `Client` table. `ShopService:BuyItem(itemId)` on the client maps
to `ShopService.Client:BuyItem(player, itemId)` on the server, Knit fills in `player`.

## Communication patterns

| Direction | How |
|---|---|
| Client → server (request/response) | Method under the service's `Client` table; controller calls `Service:Method(args)` |
| Server → one client | `self.Client.SomeSignal:Fire(player, payload)` |
| Server → all clients | loop `Players:GetPlayers()` and `:Fire(player, payload)`, or a `:FireAll`-style helper |
| Service → service (server) | `Knit.GetService("Other")` in `KnitInit`, use in `KnitStart`+ |
| Controller → controller (client) | `Knit.GetController("Other")`, same lifecycle rule |

For anything client-supplied, the server method is the security boundary. The golden rule
from `SKILL.md` applies on every single `Client` method: validate type, range, ownership,
and rate-limit. See `references/conventions.md` for a validation checklist.

## The bootstrap files

These are tiny and you rarely change them. They live in `templates/`.

`src/server/init.server.luau`:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

for _, module in script.Services:GetChildren() do
    if module:IsA("ModuleScript") then
        require(module)
    end
end

Knit.Start():andThen(function()
    print("[SERVER] started")
end):catch(warn)
```

`src/client/init.client.luau` does the same for `Controllers`, then mounts the UI (see
`references/ui-state.md` for the mount + preload sequence).

## Adding a new service or controller: fast path

1. Copy the template into `Services/` (or `Controllers/`) and rename it + its `Name` field.
2. Resolve any siblings in `KnitInit`.
3. Put the feature's content/config in `shared/Data`.
4. Add `Client` signals/methods for whatever the other side needs.
5. That's it, the bootstrap auto-requires it; no registration list to edit.

For a full feature touching all layers at once, follow `workflows/add-feature.md`.

## On Knit specifically

Knit is mature and gets the job done, but it's an older pattern and its original author has
moved toward other approaches. The *structure* here, feature modules, a two-phase
lifecycle, a clear client boundary, is what matters and carries over to modern frameworks.
If the user wants something newer, `references/alternatives.md` maps Knit concepts onto
current options without throwing away the layout.
