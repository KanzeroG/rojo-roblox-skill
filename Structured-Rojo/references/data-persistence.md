# Data Persistence: saving player data without losing it

Load this whenever player data is saved or loaded. Data loss and item duplication are the
most damaging bugs a Roblox game can ship, and they almost always come from doing
persistence by hand. This is non-negotiable territory.

## The core problem

Roblox's raw `DataStoreService` is a key-value store with no session locking. If you
`SetAsync` player data directly, you open the door to:

- **Data loss** when two servers (or a rejoin race) write the same key and one clobbers the
  other.
- **Rollback / duplication** exploits where a player rejoins fast across servers and an old
  snapshot overwrites a newer one, duplicating items or refunding spent currency.
- **Lost saves on crash** if you only save on leave and the server dies.

You do not solve these by being careful with `SetAsync`. You solve them by using a layer
that does **session locking** for you.

## Use a session-locking layer

Use **ProfileService** (or its successor **ProfileStore**). It guarantees one server "owns"
a player's profile at a time, handles autosave, retries, and releases the lock on leave so
the next session loads clean data.

In this framework, the data layer is a service (`DataService`) that wraps ProfileService.
ProfileService itself is commonly vendored into `src/server/Modules/ProfileService` rather
than pulled from Wally, either is fine.

### Shape of a DataService

```luau
-- src/server/Modules/ProfileService  (vendored)
-- src/server/Constants/DataTemplate.luau  (the default profile)
local ProfileService = require(script.Parent.Parent.Modules.ProfileService)
local Template = require(script.Parent.Parent.Constants.DataTemplate)

local DataService = Knit.CreateService({
    Name = "DataService",
    Profiles = {},     -- [player] = profile
    Client = {
        DataInit = Knit.CreateSignal(),
        Money1Updated = Knit.CreateSignal(),
    },
    IsRegistered = false,
})

local ProfileStore = ProfileService.GetProfileStore("PlayerData_v1", Template)
```

The `Template` is the single source of truth for a fresh player's data, every key a player
can have, with sane defaults. Keep it in `src/server/Constants` (server-only; clients don't
need the raw template).

### Load on join, release on leave

```luau
function DataService:_loadProfile(player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if not profile then
        player:Kick("Data failed to load, please rejoin.")
        return
    end
    profile:AddUserId(player.UserId)           -- GDPR compliance
    profile:Reconcile()                        -- fill in any new template keys
    profile:ListenToRelease(function()
        self.Profiles[player] = nil
        player:Kick("Data released, please rejoin.")
    end)
    if player:IsDescendantOf(Players) then
        self.Profiles[player] = profile
        self.Client.DataInit:Fire(player, profile.Data)
    else
        profile:Release()                      -- left before load finished
    end
end

function DataService:KnitStart()
    Players.PlayerAdded:Connect(function(p) self:_loadProfile(p) end)
    Players.PlayerRemoving:Connect(function(p)
        local profile = self.Profiles[p]
        if profile then profile:Release() end  -- releases lock + saves
    end)
    for _, p in Players:GetPlayers() do task.spawn(function() self:_loadProfile(p) end) end
    self.IsRegistered = true
end
```

## Rules that prevent disasters

1. **Never raw `SetAsync` player data.** Always go through the session-locking layer.
2. **Mutate `profile.Data`, then fire an update signal.** Don't keep a second copy of the
   truth elsewhere. Other services and the client mirror `profile.Data`; they don't own it.
3. **Reconcile on load** so existing players gain new template keys without manual
   migrations for simple additions.
4. **Version the store name** (`PlayerData_v1`). If you ever need a breaking change, bump to
   `_v2` and write a migration, never silently change the meaning of a key.
5. **Currency and inventory changes happen here, server-side, validated.** A `Client` method
   that grants currency without server checks is an exploit, not a feature.
6. **Wrap any raw DataStore call in `pcall`** and handle failure. Network calls fail; assume
   they will.

## Products and receipts (if you sell anything)

`MarketplaceService.ProcessReceipt` is its own minefield: mishandle it and players get
double-charged or get free items. The safe order is: record the purchase as pending → grant
the item and persist it → only then return `Enum.ProductPurchaseDecision.PurchaseGranted`.
If the grant or save fails, return `NotProcessedYet` so Roblox retries later. Tie this into
`DataService` so the grant is part of the same profile write. Keep monetization product
definitions in `src/shared/Data/Monetization`.

## Where things live (recap)

| Piece | Location |
|---|---|
| ProfileService library | `src/server/Modules/ProfileService` |
| Default profile template | `src/server/Constants/DataTemplate.luau` |
| DataService (the wrapper) | `src/server/Services/DataService.luau` |
| Product / gamepass definitions | `src/shared/Data/Monetization` |

If the user is on ProfileStore (the newer successor) instead of ProfileService, the same
principles apply with slightly different method names, see `references/alternatives.md`.
