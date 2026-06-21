# Monetization: gamepasses, products, and packs

Load this when the game sells anything: gamepasses, developer products, or bundled packs.
Monetization is half structure and half danger. The structure (where definitions live, how
they're discovered, where the grant logic sits) is clean and worth copying. The danger is
product delivery: get it wrong and players pay Robux for nothing, or get items for free.
This doc covers both, and leans on `references/data-persistence.md` for the data side.

## The three parts

Same layer split as any feature:

| Part | Location | Role |
|---|---|---|
| **Content** | `src/shared/Data/Monetization/` | What's for sale, keyed by asset id |
| **Authority** | `src/server/Services/MonetizationService.luau` | Prompts, ownership checks, granting |
| **Client** | `src/client/Controllers/MonetizationController.luau` | Asks to buy, listens for the result |

The content is split by kind:

```
shared/Data/Monetization/
├── GamePasses/      # permanent perks (Luck_x2, PremiumSuit, …)
│   ├── init.luau    # aggregator (see below)
│   ├── Luck_x2.luau
│   └── …
├── Products/        # consumable developer products (gem packs, boosts, …)
│   ├── init.luau
│   └── …
└── Packs/           # bundles (StarterPack, VIPPack, …)
    ├── init.luau
    └── …
```

## Definitions carry their own grant logic

Each file returns a frozen table keyed by the **Roblox asset id**, with the code that grants
the item living right next to it:

```luau
-- Products/ServerLuckBoost_2x.luau
return table.freeze({
	[3412752768] = {
		Name = "ServerLuckBoost_2x",
		BeforeCheck = function(self, userId)   -- optional pre-purchase gate
			return true
		end,
		Purchased = function(self, userId)     -- the actual grant
			ServerBoostService:BoughtBoost(userId, "Luck", 2)
		end,
	},
})
```

Keying by asset id matters: when a purchase lands, all you get from Roblox is the id, so the
id is how you look the item up. `Purchased` is the grant function the service calls once a
buy is confirmed. Content and grant logic in one place, nothing scattered.

## The aggregator: drop a file, it's registered

Each folder's `init.luau` merges every definition under it into one table, so there's no
master list to maintain:

```luau
-- GamePasses/init.luau
local items = {}
for _, file in script:GetDescendants() do
	if file:IsA("ModuleScript") then
		for id, def in require(file) do
			items[id] = def
		end
	end
end
return items
```

Add a new gamepass by dropping a file in the folder. Same auto-discovery idea as the
service/controller bootstraps. The service requires the top-level `Monetization` table once
and indexes it as `MonetizationList[kind][assetId]`.

## What the service owns

`MonetizationService` is the authority. Its jobs:

- **Prompt a purchase** for the player (a `Client:PromptPurchase(id, kind)` method).
- **Check ownership** of gamepasses with `MarketplaceService:UserOwnsGamePassAsync`, wrapped
  in `pcall` (it's a web call and will fail sometimes).
- **Re-validate gamepasses on join.** On `PlayerAdded`, walk every gamepass and reconcile
  `profile.Data.Gamepasses` against what the player actually owns. This is what makes a
  permanent perk survive across sessions even if a grant was ever missed.
- **Grant** by calling the item's `Purchased(self, userId, name)` callback, then routing any
  currency/data change through `DataService` so it persists.

## Delivering purchases safely (the part people get wrong)

There are two ways the server hears about a purchase, and they are not equally safe.

**Gamepasses** are permanent, so the reliable backstop is the join-time re-validation above.
Listening to `PromptGamePassPurchaseFinished` for an instant in-session update is fine
*because* the join check will catch anything it misses.

**Developer products are different.** They're consumable and one-shot, and the safe delivery
callback is `MarketplaceService.ProcessReceipt`, not `PromptProductPurchaseFinished`. Here's
why it matters:

- `PromptProductPurchaseFinished` only fires for the prompting client's session, does **not**
  guarantee delivery, and **never retries**. If the player leaves before the grant or the
  server dies mid-grant, the product is gone. They paid, got nothing, and Roblox will not
  re-deliver.
- `ProcessReceipt` keeps re-firing on every server the player touches until you return
  `Enum.ProductPurchaseDecision.PurchaseGranted`. It survives rejoins and crashes.

> The reference game grants products off `PromptProductPurchaseFinished`. Treat that as the
> one part **not** to copy. Use `ProcessReceipt` for products.

The safe order, tied into the profile write:

```luau
local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet  -- retry when they're back
	end

	local def = MonetizationList.Products[info.ProductId]
	if not def then
		return Enum.ProductPurchaseDecision.NotProcessedYet  -- unknown id; don't eat it
	end

	-- Grant + persist as one step. Only confirm if it actually stuck.
	local ok = pcall(function()
		def.Purchased(MonetizationService, info.PlayerId)
		-- the grant should mutate profile.Data via DataService; force a save here
	end)

	if ok then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet      -- failed; let Roblox retry
end

MarketplaceService.ProcessReceipt = processReceipt
```

Only one place may set `ProcessReceipt`, so the monetization layer owns it. Grant and save
before you return `PurchaseGranted`; if anything fails, return `NotProcessedYet` and Roblox
tries again later. See `references/data-persistence.md` (SE-3) for the data-write rules.

## Validate like any other client input

A purchase prompt is still a client request. The `Client` methods that prompt or report
state must validate the same way as everything else (type, range, the id actually existing in
`Monetization`, region policy via `PolicyService` where relevant). The grant amounts and the
currency math stay server-side. See the checklist in `references/conventions.md`.

## Where things live (recap)

| Piece | Location |
|---|---|
| Gamepass / product / pack definitions | `src/shared/Data/Monetization/{GamePasses,Products,Packs}` |
| Per-folder aggregator | `…/init.luau` |
| Purchasing + granting authority | `src/server/Services/MonetizationService.luau` |
| Client prompts + result handling | `src/client/Controllers/MonetizationController.luau` |
| `ProcessReceipt` handler | inside `MonetizationService` (set exactly once) |
| Persisted ownership/currency | `profile.Data`, via `DataService` |
