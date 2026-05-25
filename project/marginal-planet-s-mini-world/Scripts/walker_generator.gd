@tool
extends Node
class_name WalkerGenerator

const TILE_DATA: Dictionary = {
	"floor":{
		"source_id": 0,
		"atlas_coords": Vector2(3,15)
	},
	"wall":{
		"source_id": 0,
		"atlas_coords": Vector2(8,0)
	},
}

@export var gen_seed: int = 0
@export var randomize_seed: bool = true
@export var map_dimensions:Vector2i = Vector2i(40,40)
@export var total_steps: int = 600
@export var boundary_padding:int = 4
@export_tool_button("Generate Map")var map_gen_buttom = generate_map
@export var tilemap_layer: TileMapLayer

func ready() ->void:
	generate_map()

func generate_map() ->void:
	if randomize_seed:
		gen_seed = randi()
	seed(gen_seed)
	tilemap_layer.clear()
	draw_tile_rect(map_dimensions, TILE_DATA.wall.source_id, TILE_DATA.wall.atlas_coords)
	draw_walker_generation(map_dimensions, boundary_padding,
		TILE_DATA.wall.source_id, TILE_DATA.wall.atlas_coords )
	

func draw_tile_rect(dimensions: Vector2i,source_id: int,atlas_coords:Vector2i) -> void:
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			tilemap_layer.set_cell(Vector2(x, y),source_id,atlas_coords)

func draw_walker_generation(dimensions: Vector2i,padding: int,source_id: int,atlas_coords:Vector2i)->void:
	var directions: Array = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var cur_pos: Vector2i = Vector2i(
		floor(dimensions.x / 2.0),
		floor(dimensions.y / 2.0))
	var bounds: Rect2i = Rect2i(0,0, dimensions.x, dimensions.y)
	
	for side in [SIDE_LEFT, SIDE_LEFT, SIDE_TOP, SIDE_BOTTOM]:
		bounds = bounds.grow_side(side, -padding)
	for i in range(total_steps):
		if bounds.has_point(cur_pos):
			tilemap_layer.set_cell(cur_pos, source_id, atlas_coords)
		var move_dir: Vector2i = directions.pick_random()
		var next_pos: Vector2i = cur_pos + move_dir
		
		if bounds.has_point(next_pos):
			cur_pos = next_pos
		else:
			directions.shuffle()
			for d in directions:
				if bounds.has_point(cur_pos + d):
					cur_pos += d
					break
				
