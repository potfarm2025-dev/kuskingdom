extends Control

##------------------ Buttons ------------------##
@onready var shop_button: Button        = $SideButtons/ShopButton
@onready var inventory_button: Button   = $SideButtons/InventoryButton
@onready var exit_button: Button        = $Inventory/MarginContainer/Exit
@onready var harvest_button: Button = $"../HarvestButton"
@onready var clear_hand_button: Button = $"../ClearHandButton"





##------------------ Panels ------------------##
@onready var inventory_panel: Control   = $Inventory
@onready var shop_panel: Control        = $Shop
@onready var main_shop: Control         = $Shop/Main_Shop
@onready var seeds_shop: Control        = $Shop/Seeds_Shop
@onready var event_seeds_shop: Control  = $Shop/Event_Seed_Shop
@onready var decoration_shop: Control   = $Shop/Decoration_Shop

##------------------ Labels ------------------##
@onready var in_hand_label: Label       = $In_Hand
@onready var player_money_label: Label  = $PlayerUI/PlayerMoney/MoneyLabel
@onready var player_level_label: Label  = $PlayerUI/PlayerLevel/LevelLabel
@onready var player_bucks_label: Label  = $PlayerUI/PlayerBucks/BucksLabel
@onready var shop_name: Label           = $Shop/Top_UI_Panel/ShopName

##------------------ State ------------------##
var current_panel: Control = null
var current_shop: Control = null

func _ready() -> void:
	# Hide all panels
	inventory_panel.hide()
	shop_panel.hide()
	main_shop.hide()
	seeds_shop.hide()
	event_seeds_shop.hide()
	decoration_shop.hide()

	# Connect buttons
	inventory_button.pressed.connect(self.toggle_inventory)

	# Connect PlayerGlobal signals
	PlayerGlobal.connect("leveled_up", Callable(self, "_on_level_up"))
	PlayerGlobal.connect("in_hand_changed", Callable(self, "_on_in_hand_changed"))
	PlayerGlobal.connect("money_changed", Callable(self, "_on_money_changed"))
	PlayerGlobal.connect("bucks_changed", Callable(self, "_on_bucks_changed"))
	PlayerGlobal.connect("state_refreshed", Callable(self, "update_labels"))

	# Connect inventory pick signal
	inventory_panel.connect("item_picked", Callable(self, "_on_inventory_item_picked"))

	update_labels()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_inventory"):
		toggle_inventory()

##------------------ Panel Helpers ------------------##
func open_panel(panel: Control) -> void:
	if current_panel:
		current_panel.hide()
	panel.show()
	current_panel = panel
	UiGlobal.ui_open = true

func close_panel() -> void:
	if current_panel:
		current_panel.hide()
		current_panel = null
	UiGlobal.ui_open = false

func toggle_inventory() -> void:
	if current_panel == inventory_panel:
		close_panel()
	else:
		open_panel(inventory_panel)

func switch_shop(new_shop: Control) -> void:
	if current_shop:
		current_shop.hide()
	new_shop.show()
	current_shop = new_shop
	update_labels()

##------------------ Shop Functions ------------------##
func _on_shop_pressed() -> void:
	open_panel(shop_panel)
	switch_shop(main_shop)

func _on_shop_exit_pressed() -> void:
	close_panel()
	current_shop = null

func _on_seed_store_pressed() -> void:
	switch_shop(seeds_shop)

func _on_home_pressed() -> void:
	switch_shop(main_shop)

func _on_event_seeds_pressed() -> void:
	switch_shop(event_seeds_shop)

func _on_decoration_pressed() -> void:
	switch_shop(decoration_shop)

##------------------ Inventory ------------------##
func _on_inventory_exit_pressed() -> void:
	close_panel()

func _on_inventory_item_picked(item: Item) -> void:
	PlayerGlobal.set_hand(item)
	close_panel()

##------------------ Player UI Updates ------------------##
func _on_level_up(new_level: int) -> void:
	update_labels(new_level)

func _on_money_changed(new_money: int) -> void:
	player_money_label.text = PlayerGlobal.format_money(PlayerGlobal.money)

func _on_bucks_changed(new_bucks: int) -> void:
	player_bucks_label.text = PlayerGlobal.format_money(PlayerGlobal.bucks)

func _on_in_hand_changed(new_item: Item) -> void:
	in_hand_label.text = "Holding: " + str(new_item.id) if new_item else "Holding: Nothing"

func update_labels(new_level: int = -1) -> void:
	var level_to_show = new_level if new_level != -1 else PlayerGlobal.level
	player_level_label.text = PlayerGlobal.player_id + " Level " + str(level_to_show)
	player_money_label.text = PlayerGlobal.format_money(PlayerGlobal.money)
	player_bucks_label.text = PlayerGlobal.format_money(PlayerGlobal.bucks)
	shop_name.text = current_shop.name if current_shop else ""

##------------------ Harvest & Clear Hand ------------------##
func _on_harvest_pressed() -> void:
	# Only allow harvesting if hand is empty
	if PlayerGlobal.in_hand != null:
		print("Cannot harvest while holding an item!")
		return

	PlayerGlobal.player_current_state = PlayerGlobal.player_state.HARVESTING
	print("Player state: HARVESTING")

func _on_clear_hand_pressed() -> void:
	PlayerGlobal.clear_in_hand()
	PlayerGlobal.player_current_state = PlayerGlobal.player_state.MOVING
	print("Player state: MOVING")
