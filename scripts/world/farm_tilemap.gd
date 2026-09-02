extends TileMapLayer

## Farm map sample. The generated layout is intentionally small and data-driven:
## the rich illustration remains behind it as a visual reference while this
## layer establishes the real grid used by future terrain/collision work.

const TILESET_TEXTURE := "res://assets/scenes/imported_tilesets/farm_ground.png"
const ATLAS_COLUMNS := 8
const ATLAS_ROWS := 8
const SOURCE_TILE_SIZE := 128
const WORLD_TILE_SIZE := 32
const MAP_CELLS := Vector2i(50, 28)

func _ready() -> void:
	if tile_set == null:
		tile_set = _build_tile_set()
	_build_sample_layout()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _build_tile_set() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(SOURCE_TILE_SIZE, SOURCE_TILE_SIZE)
	var texture := load(TILESET_TEXTURE) as Texture2D
	if texture == null:
		return result
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(SOURCE_TILE_SIZE, SOURCE_TILE_SIZE)
	for y in range(ATLAS_ROWS):
		for x in range(ATLAS_COLUMNS):
			atlas.create_tile(Vector2i(x, y))
	result.add_source(atlas, 0)
	return result

func _build_sample_layout() -> void:
	clear()
	# Grass base: the first tile in the supplied farm ground sheet.
	for y in range(MAP_CELLS.y):
		for x in range(MAP_CELLS.x):
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	# Main north/south road. The supplied sheet's path tiles are used here;
	# exact auto-terrain transitions will be authored in the next map pass.
	for y in range(MAP_CELLS.y):
		for x in range(25, 29):
			set_cell(Vector2i(x, y), 0, Vector2i(3, 2))
	# Crossroad through the farm center.
	for x in range(MAP_CELLS.x):
		for y in range(13, 16):
			set_cell(Vector2i(x, y), 0, Vector2i(3, 3))

