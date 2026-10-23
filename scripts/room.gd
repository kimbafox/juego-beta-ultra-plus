extends Node2D
## Fondos ilustrados e interacciones alineadas con los objetos de cada imagen.
var game: Node
const NAMES := ["01 / VESTÍBULO", "02 / ARCHIVO", "03 / TALLER", "04 / CONTROL"]
const BACKGROUNDS = [preload("res://assets/horror/lobby.png"),preload("res://assets/horror/archive.png"),preload("res://assets/horror/workshop.png"),preload("res://assets/horror/control.png")]
const LATCH_RECT := Rect2(772,420,31,35)
var card_icon: AtlasTexture
var fuse_icon: AtlasTexture
var hover_name: String = ""

func _ready() -> void:
	card_icon = game.item_icon(3)
	fuse_icon = game.item_icon(2)

func hotspots() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if game.room_index > 0:
		list.append({"id":"left","rect":Rect2(18,330,95,110),"name":"Volver"})
	if game.room_index < 3:
		list.append({"id":"right","rect":Rect2(1167,330,95,110),"name":"Seguir"})
	match game.room_index:
		0:
			list.append({"id":"coat","rect":Rect2(244,207,88,255),"name":"Abrigo"})
			list.append({"id":"note","rect":Rect2(387,181,220,156),"name":"Nota del guardia"})
			list.append({"id":"cabinet","rect":Rect2(814,360,222,190),"name":"Suministros"})
		1:
			list.append({"id":"books","rect":Rect2(237,63,366,487),"name":"Estantería"})
			list.append({"id":"safe","rect":Rect2(737,323,177,227),"name":"Caja fuerte"})
		2:
			list.append({"id":"fusebox","rect":Rect2(187,101,205,201),"name":"Tablero encendido" if game.power else "Tablero sin fusible"})
			list.append({"id":"warning","rect":Rect2(476,132,197,171),"name":"Instrucciones"})
			list.append({"id":"case","rect":Rect2(755,243,309,315),"name":"Vitrina"})
		3:
			list.append({"id":"reader","rect":Rect2(264,296,45,80),"name":"Lector de tarjeta"})
			list.append({"id":"console","rect":Rect2(480,283,326,267),"name":"Consola"})
			list.append({"id":"exit","rect":Rect2(922,143,273,405),"name":"Salida"})
	return list

func label_at(text: String, pos: Vector2, size: int = 15, tint: Color = Color("d4c9b5")) -> void:
	draw_string(preload("res://assets/Interface.ttf"),pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)

func _draw() -> void:
	if not is_instance_valid(game): return
	draw_texture_rect(BACKGROUNDS[game.room_index],Rect2(0,0,1280,720),false)
	# Barras discretas para mantener legibles los controles.
	draw_rect(Rect2(0,0,1280,64),Color(0.025,0.025,0.02,0.78))
	draw_rect(Rect2(0,562,1280,158),Color(0.025,0.025,0.02,0.93))
	draw_line(Vector2(32,627),Vector2(1248,627),Color(0.5,0.46,0.36,0.3),1)
	match game.room_index:
		0:
			if game.supplies_open:
				draw_circle(Vector2(942,433),3,Color("a8b489"))
		1:
			if game.safe_open:
				draw_arc(Vector2(830,416),16,0,TAU,24,Color("b4ba9b"),2,true)
		2:
			if game.power:
				draw_texture_rect(fuse_icon,Rect2(296,162,31,60),false)
				draw_circle(Vector2(340,270),4,Color("a9bb83"))
			if not game.card_taken:
				draw_texture_rect(card_icon,Rect2(877,361,77,55),false)
			if not game.latch_broken:
				draw_rect(LATCH_RECT,Color(0.85,0.64,0.31,0.15))
				label_at("×",LATCH_RECT.position+Vector2(8,23),20,Color("d1b987"))
			else:
				draw_line(Vector2(777,425),Vector2(792,449),Color("171913"),4)
				draw_line(Vector2(791,424),Vector2(778,450),Color("bdafa0"),1)
		3:
			if game.authorized:
				draw_line(Vector2(276,316),Vector2(292,316),Color("bdd097"),3)
			var colors := [Color("9d4034"),Color("be9b55"),Color("a0b77f")]
			for i in range(3):
				draw_circle(Vector2(590+i*42,305),7,colors[game.channels[i]])
			if game.exit_open:
				draw_line(Vector2(946,170),Vector2(946,535),Color(0.65,0.75,0.48,0.75),3)
	for h in hotspots():
		if h.id in ["left","right"]:
			var center: Vector2 = h.rect.get_center()
			var direction := -1.0 if h.id=="left" else 1.0
			var tint := Color("d7c9af") if h.rect.has_point(get_global_mouse_position()) else Color(0.8,0.75,0.65,0.5)
			draw_polyline(PackedVector2Array([center+Vector2(-direction*9,-14),center+Vector2(direction*9,0),center+Vector2(-direction*9,14)]),Color(0,0,0,0.8),6,true)
			draw_polyline(PackedVector2Array([center+Vector2(-direction*9,-14),center+Vector2(direction*9,0),center+Vector2(-direction*9,14)]),tint,2,true)
	if game.state=="playing" and not game.armed and not game.modal_open:
		for h in hotspots():
			if h.rect.has_point(get_global_mouse_position()):
				var mouse := get_global_mouse_position()
				var pos := Vector2(clampf(mouse.x+17,20,1050),maxf(82,mouse.y-19))
				draw_rect(Rect2(pos-Vector2(7,19),Vector2(h.name.length()*9+18,28)),Color(0.025,0.025,0.02,0.88))
				label_at(h.name,pos)
	for trace in game.traces:
		draw_line(trace.a,trace.b,Color(1,0.84,0.52,trace.life/0.13),2,true)
	if game.armed and game.state=="playing" and not game.modal_open:
		var mouse := get_global_mouse_position()
		draw_arc(mouse,8,0,TAU,24,Color("d8c8a6"),1,true)
		draw_line(mouse-Vector2(13,0),mouse+Vector2(13,0),Color("d8c8a6"),1)
		draw_line(mouse-Vector2(0,13),mouse+Vector2(0,13),Color("d8c8a6"),1)
