--!strict
-- Purchase/equip rules shared by the server (authoritative) and the client
-- (only to render button states; the server re-checks everything).

local ShopRules = {}

-- Catalogue items (see CosmeticCatalog.Item). Kept structural and loose so
-- both the catalogue's literal-typed items and plain test tables fit.
export type Item = any

function ShopRules.priceFor(item: Item, featured: { [string]: boolean }?, discountPercent: number): number?
	if item.unlock.kind ~= "Shop" or item.price == nil then
		return nil
	end
	local price = item.price :: number
	if featured and featured[item.id] then
		local discounted = math.floor(price * (100 - discountPercent) / 100)
		-- Always at least 1 cheaper when discounted, never free.
		price = math.max(1, math.min(discounted, price - 1))
	end
	return price
end

function ShopRules.canPurchase(
	profile: { [string]: any },
	item: Item?,
	featured: { [string]: boolean }?,
	discountPercent: number
): (boolean, string, number?)
	if not item then
		return false, "UnknownItem", nil
	end
	if profile.owned[item.id] then
		return false, "AlreadyOwned", nil
	end
	local price = ShopRules.priceFor(item, featured, discountPercent)
	if not price then
		return false, "NotForSale", nil
	end
	local balance = if item.currency == "Coins" then profile.coins else profile.wins
	if balance < price then
		return false, "NotEnough" .. item.currency, price
	end
	return true, "Ok", price
end

-- Returns the loadout key path for an item: slotKey, accessorySlot.
function ShopRules.equipTarget(item: Item, equipSlot: string?): (string?, string?)
	if item.category == "Accessory" then
		return "Accessories", item.slot
	end
	return equipSlot, nil
end

-- What the item would replace if equipped (for the incompatibility warning).
function ShopRules.wouldReplace(loadout: { [string]: any }, item: Item, equipSlot: string?): string?
	local key, accessorySlot = ShopRules.equipTarget(item, equipSlot)
	if key == "Accessories" and accessorySlot then
		local current = loadout.Accessories[accessorySlot]
		if current ~= item.id then
			return current
		end
		return nil
	elseif key then
		local current = loadout[key]
		if current ~= item.id then
			return current
		end
	end
	return nil
end

function ShopRules.applyEquip(loadout: { [string]: any }, item: Item, equipSlot: string?): (boolean, string?)
	local key, accessorySlot = ShopRules.equipTarget(item, equipSlot)
	if key == "Accessories" then
		if not accessorySlot then
			return false, nil
		end
		local replaced = loadout.Accessories[accessorySlot]
		loadout.Accessories[accessorySlot] = item.id
		return true, if replaced ~= item.id then replaced else nil
	elseif key then
		local replaced = loadout[key]
		loadout[key] = item.id
		return true, if replaced ~= item.id then replaced else nil
	end
	return false, nil
end

function ShopRules.applyUnequip(loadout: { [string]: any }, item: Item, equipSlot: string?): boolean
	local key, accessorySlot = ShopRules.equipTarget(item, equipSlot)
	if key == "Accessories" and accessorySlot then
		if loadout.Accessories[accessorySlot] == item.id then
			loadout.Accessories[accessorySlot] = nil
			return true
		end
	elseif key and loadout[key] == item.id then
		loadout[key] = nil
		return true
	end
	return false
end

function ShopRules.isEquipped(loadout: { [string]: any }, item: Item, equipSlot: string?): boolean
	local key, accessorySlot = ShopRules.equipTarget(item, equipSlot)
	if key == "Accessories" and accessorySlot then
		return loadout.Accessories[accessorySlot] == item.id
	elseif key then
		return loadout[key] == item.id
	end
	return false
end

return ShopRules
