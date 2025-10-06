extends Resource
class_name Item

@export var id: String
@export var name: String
@export var icon: Texture2D
@export var stackable: bool = true
@export var quantity: int = 1
@export var value: int = 0
@export var scene: PackedScene
@export var tile_size: Vector2i = Vector2i(1, 1)
@export var placeable: bool = false 

enum ShopCategory {
	MAINSHOP,
	SEEDS,
	EVENT,
	PRODUCTION,
	DECORATION
}

@export var shop_space: ShopCategory = ShopCategory.SEEDS
