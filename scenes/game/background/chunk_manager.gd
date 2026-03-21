extends Node2D

const CHUNK_SIZE  = 8
const RENDER_DIST = 5

@export var base_map: TileMapLayer
@export var chunk:    TileMapLayer

var _base_origin: Vector2i
var _base_w:      int
var _base_h:      int
var _loaded:      Dictionary = {}

@onready var player = $"../Player"

func _ready() -> void:
	assert(base_map != null, "base_map not assigned")
	assert(chunk    != null, "chunk not assigned")
	
	chunk.tile_set              = base_map.tile_set
	chunk.y_sort_enabled        = base_map.y_sort_enabled
	chunk.rendering_quadrant_size = base_map.rendering_quadrant_size
	

	var rect     = base_map.get_used_rect()
	_base_origin = rect.position
	_base_w      = rect.size.x
	_base_h      = rect.size.y
	base_map.visible = false

	print("=== ChunkManager ready ===")
	print("base rect:   ", rect)
	print("base origin: ", _base_origin)
	print("base size:   ", _base_w, " x ", _base_h)
	print("chunk tileset: ", chunk.tile_set)
	print("base tileset:  ", base_map.tile_set)
	
func _process(_delta: float) -> void:
	_update_chunks(_world_to_chunk(player.global_position))

func _world_to_chunk(pos: Vector2) -> Vector2i:
	var tile := chunk.local_to_map(chunk.to_local(pos))
	return Vector2i(floori(float(tile.x) / CHUNK_SIZE),
					floori(float(tile.y) / CHUNK_SIZE))

func _update_chunks(center: Vector2i) -> void:
	var needed := {}
	for x in range(center.x - RENDER_DIST, center.x + RENDER_DIST + 1):
		for y in range(center.y - RENDER_DIST, center.y + RENDER_DIST + 1):
			var coord := Vector2i(x, y)
			needed[coord] = true
			if not _loaded.has(coord):
				_stamp_chunk(coord)
				_loaded[coord] = true

	for coord in _loaded.keys():
		if not needed.has(coord):
			_erase_chunk(coord)
			_loaded.erase(coord)

func _stamp_chunk(coord: Vector2i) -> void:
	var placed := 0
	var skipped := 0
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var wx := coord.x * CHUNK_SIZE + x
			var wy := coord.y * CHUNK_SIZE + y
			var base_tile := Vector2i(
				posmod(wx, _base_w) + _base_origin.x,
				posmod(wy, _base_h) + _base_origin.y
			)
			var source_id := base_map.get_cell_source_id(base_tile)
			if source_id == -1:
				skipped += 1
				continue
			chunk.set_cell(
				Vector2i(wx, wy),
				source_id,
				base_map.get_cell_atlas_coords(base_tile),
				base_map.get_cell_alternative_tile(base_tile)
			)
			placed += 1
	print("chunk ", coord, " → placed: ", placed, " skipped: ", skipped)

func _erase_chunk(coord: Vector2i) -> void:
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			chunk.erase_cell(Vector2i(
				coord.x * CHUNK_SIZE + x,
				coord.y * CHUNK_SIZE + y
			))
