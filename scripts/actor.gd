extends Node2D
## Hojas originales: dos pasos y dos poses de pistola por dirección.
const TEXTURES = [preload("res://assets/aliens/alien_verde.png"), preload("res://assets/aliens/alien_naranja.png")]
const WALK = [preload("res://assets/aliens/verde_caminar.png"), preload("res://assets/aliens/naranja_caminar.png")]
const SHOOT = [preload("res://assets/aliens/verde_disparar.png"), preload("res://assets/aliens/naranja_disparar.png")]
const NAMES = ["Alien verde", "Alien naranja"]
const SPEED := 240.0
const HEIGHT := 285.0
const FrameData = preload("res://scripts/alien_frames.gd")
const WALK_RECTS = FrameData.WALK_RECTS
const SHOT_RECTS = FrameData.SHOT_RECTS
const WALK_ANCHORS = FrameData.WALK_ANCHORS
const SHOT_ANCHORS = FrameData.SHOT_ANCHORS
const MUZZLES = FrameData.MUZZLES
const VISIBLE_BOUNDS = FrameData.VISIBLE_BOUNDS

var destination: float = 240.0
var walk_phase: float = 0.0
var walking := false
var facing := 1.0
var armed := false
var aim := Vector2.RIGHT
var selected := 0
var flash_left := 0.0
var current_frame := 0
var sprite: Sprite2D
var frames: Array = []
var feet: Array = []

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.name = "AlienSprite"
	sprite.centered = false
	sprite.modulate = Color(0.82,0.8,0.73)
	add_child(sprite)
	_build_frames()
	set_character(selected)


func _build_frames() -> void:
	# Las regiones del atlas mantienen intactos los PNG suministrados.
	frames.clear()
	feet.clear()
	for character in range(2):
		var character_frames: Array = []
		var character_feet: Array = []
		for mode in range(2):
			var sheet: Texture2D = WALK[character] if mode == 0 else SHOOT[character]
			var rects: Array = WALK_RECTS[character] if mode == 0 else SHOT_RECTS[character]
			var mode_frames: Array = []
			var mode_feet: Array = []
			for region in rects:
				var texture: AtlasTexture = AtlasTexture.new()
				texture.atlas = sheet
				texture.region = region
				texture.filter_clip = true
				mode_frames.append(texture)
				mode_feet.append(VISIBLE_BOUNDS[character][mode][mode_frames.size()-1])
			character_frames.append(mode_frames)
			character_feet.append(mode_feet)
		frames.append(character_frames)
		feet.append(character_feet)

func set_character(index: int) -> void:
	selected = clampi(index,0,1)
	flash_left = 0.0
	walk_phase = 0.0
	refresh_pose()

func _get_frame_index() -> int:
	var direction_offset: int = 0
	if facing < 0.0:
		direction_offset = 2
	var animation_offset: int = 0
	if armed:
		if flash_left > 0.0:
			animation_offset = 1
	elif walking:
		animation_offset = int(walk_phase) % 2
	return direction_offset + animation_offset


func refresh_pose() -> void:
	if not is_instance_valid(sprite) or frames.is_empty():
		return
	var mode: int = 1 if armed else 0
	current_frame = _get_frame_index()
	var region: Rect2 = SHOT_RECTS[selected][current_frame] if armed else WALK_RECTS[selected][current_frame]
	var bounds: Rect2i = feet[selected][mode][current_frame]
	var anchor: float = SHOT_ANCHORS[selected][current_frame] if armed else WALK_ANCHORS[selected][current_frame]
	var factor: float = HEIGHT / float(bounds.size.y)
	sprite.texture = frames[selected][mode][current_frame]
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2(-(anchor-region.position.x)*factor, -bounds.end.y*factor)
	queue_redraw()

func step(delta: float, mouse: Vector2) -> void:
	flash_left = maxf(0,flash_left-delta)
	var distance: float = destination - position.x
	walking = absf(distance)>2
	if walking:
		facing = signf(distance)
		position.x = move_toward(position.x,destination,SPEED*delta)
		walk_phase += delta*6
	else:
		walk_phase = 0
	if armed:
		facing = 1 if mouse.x >= position.x else -1
	refresh_pose()
	if armed:
		aim = muzzle_origin().direction_to(mouse)
		if aim == Vector2.ZERO: aim = Vector2.RIGHT

func play_shot(point: Vector2) -> void:
	armed = true
	facing = 1 if point.x >= position.x else -1
	flash_left = 0.12
	refresh_pose()
	aim = muzzle_origin().direction_to(point)

func muzzle_origin() -> Vector2:
	if not armed or not is_instance_valid(sprite):
		return position + Vector2(0, -HEIGHT * 0.8)
	var region: Rect2 = SHOT_RECTS[selected][current_frame]
	return position+sprite.position+(MUZZLES[selected][current_frame]-region.position)*sprite.scale

func muzzle() -> Vector2:
	return muzzle_origin()

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,42,Color(0,0,0,0.3))
	draw_set_transform(Vector2.ZERO)
