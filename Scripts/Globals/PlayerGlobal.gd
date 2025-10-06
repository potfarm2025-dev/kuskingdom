extends Node

signal inventory_updated(item: Resource)
signal in_hand_changed(item: Resource)
signal leveled_up(level: int)
signal money_changed(new_money: int)
signal bucks_changed(new_bucks: int)
signal state_refreshed()

var player_id: String = "AZON"
var in_hand: Item = null
var inventory: Array = []
var player_current_state: player_state = player_state.MOVING

enum player_state {
	MOVING,
	HARVESTING,
	PLACING
}

var money: int = 5000000
var bucks: int = 50
var level: int = 1
var xp: int = 0
var xp_needed: int = 200

func _ready() -> void:
	addXP(0)

# --- LEVEL / XP ---
func addXP(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		levelup()

func levelup() -> void:
	level += 1
	emit_signal("leveled_up", level)
	print("🎉 Level up! Now level %s" % level)
	xp_needed = int(xp_needed * 1.25)

# --- MONEY ---
func set_money(value: int) -> void:
	money = value
	emit_signal("money_changed", money)

func add_money(amount: int) -> void:
	set_money(money + amount)

func spend_money(amount: int) -> bool:
	if money >= amount:
		set_money(money - amount)
		return true
	return false

# --- BUCKS ---
func set_bucks(value: int) -> void:
	bucks = value
	emit_signal("bucks_changed", bucks)

func add_bucks(amount: int) -> void:
	set_bucks(bucks + amount)

func spend_bucks(amount: int) -> bool:
	if bucks >= amount:
		set_bucks(bucks - amount)
		return true
	return false

# --- INVENTORY / HAND ---
func set_hand(item: Item) -> void:
	in_hand = item
	emit_signal("in_hand_changed", in_hand)

	# ✅ only switch state, no text updates here
	if in_hand != null and in_hand.placeable:
		player_current_state = player_state.PLACING
	else:
		player_current_state = player_state.MOVING

func clear_in_hand() -> void:
	set_hand(null)
# --- ADDED: Clear all inventory items safely ---

func clear_inventory() -> void:
	# Notify UI that items are gone
	for item in inventory:
		if item:
			if "quantity" in item:
				item.quantity = 0
			emit_signal("inventory_updated", item)
	# Clear internal inventory array
	inventory.clear()
	# Emit general refresh so UI can fully update
	emit_signal("state_refreshed")

func add_to_inventory(item: Item, amount: int = 1) -> void:
	if item.stackable:
		for inv_item in inventory:
			if inv_item.id == item.id:
				inv_item.quantity += amount
				emit_signal("inventory_updated", inv_item)
				return
	var item_copy: Item = item.duplicate()
	item_copy.quantity = amount
	inventory.append(item_copy)
	emit_signal("inventory_updated", item_copy)
	
# Returns the number of the current in-hand item in inventory
func get_in_hand_quantity() -> int:
	if in_hand == null:
		return 0
	for inv_item in inventory:
		if inv_item.id == in_hand.id:
			return int(inv_item.quantity)
	return 0

func remove_from_inventory(item_id: String, amount: int = 1) -> void:
	for i in range(inventory.size()):
		var inv_item: Item = inventory[i]
		if inv_item.id == item_id:
			if inv_item.stackable:
				inv_item.quantity -= amount
				if inv_item.quantity <= 0:
					inventory.remove_at(i)
				emit_signal("inventory_updated", inv_item)
			else:
				inventory.remove_at(i)
				emit_signal("inventory_updated", inv_item)
			return

# --- UTILS ---
func format_money(amount: int) -> String:
	var suffixes = ["", "k", "M", "B", "T", "Qa", "Qi"]
	var value = float(amount)
	var index = 0
	while value >= 1000 and index < suffixes.size() - 1:
		value /= 1000.0
		index += 1
	value = floor(value * 10 + 0.5) / 10.0
	if is_equal_approx(value, floor(value)):
		return str(int(value)) + suffixes[index]
	else:
		return str(value) + suffixes[index]

func refresh_state() -> void:
	emit_signal("money_changed", money)
	emit_signal("bucks_changed", bucks)
	emit_signal("leveled_up", level)
	emit_signal("in_hand_changed", in_hand)
	for item in inventory:
		emit_signal("inventory_updated", item)
	emit_signal("state_refreshed")
