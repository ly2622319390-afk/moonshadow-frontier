extends Node

signal shop_changed
var is_open := false

func toggle() -> void:
	is_open = not is_open
	shop_changed.emit()

func close() -> void:
	is_open = false
	shop_changed.emit()

func buy(item_id: String) -> String:
	var price := ItemCatalog.get_buy_price(item_id)
	if price <= 0:
		return "not_for_sale"
	if WorldManager.gold < price:
		return "not_enough_gold"
	WorldManager.gold -= price
	WorldManager.add_item(item_id)
	shop_changed.emit()
	return "bought"

func sell(item_id: String) -> String:
	var count := int(WorldManager.inventory.get(item_id, 0))
	if count <= 0:
		return "none"
	var price := ItemCatalog.get_sell_price(item_id)
	if price <= 0:
		return "not_sellable"
	WorldManager.inventory[item_id] = count - 1
	WorldManager.gold += price
	WorldManager.daily_income += price
	shop_changed.emit()
	return "sold"
