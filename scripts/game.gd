extends Node2D
## Aventura point and click. La lógica es independiente del dibujo de las salas.
const Actor = preload("res://scripts/actor.gd")
const Room = preload("res://scripts/room.gd")
const CAPACITY := 6
const LOGO = preload("res://logo.svg")
const INVENTORY_ART = preload("res://assets/horror/items.png")
const MENU_ART = preload("res://assets/horror/menu.png")
var menu_art: TextureRect
var menu_screen: Control
var selected_alien: int = 0
var choosing_from_pause: bool = false
var room_index: int = 0
var state: String = "splash"
var armed: bool = false
var modal_open: bool = false
var has_key: bool = false
var has_gun: bool = false
var has_fuse: bool = false
var has_card: bool = false
var supplies_open: bool = false
var safe_open: bool = false
var power: bool = false
var latch_broken: bool = false
var card_taken: bool = false
var authorized: bool = false
var exit_open: bool = false
var channels: Array[int] = [0, 1, 0]
var ammo: int = 0
var reserve: int = 0
var reload_left: float = 0.0
var shot_left: float = 0.0
var splash_left: float = 2.3
var pending: String = ""
var journal: Array[String] = []
var traces: Array[Dictionary] = []
var actor: Node2D
var room_view: Node2D
var title_label: Label
var objective_label: Label
var message_label: Label
var mode_label: Label
var inventory_buttons: Array[Button] = []
var overlay: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var code_input: LineEdit
var sound_enabled: bool = true
var audio: AudioStreamPlayer
var shot_sound: AudioStreamWAV
var last_message: String = ""

func _ready() -> void:
	room_view = Room.new()
	room_view.game = self
	add_child(room_view)
	actor = Actor.new()
	actor.position = Vector2(620,550)
	actor.destination = actor.position.x
	add_child(actor)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -18
	add_child(audio)
	shot_sound = make_sound()
	var preferences := ConfigFile.new()
	if preferences.load("user://preferences.cfg") == OK:
		selected_alien = clampi(int(preferences.get_value("character","selected",0)),0,1)
	actor.set_character(selected_alien)
	build_ui()
	show_splash()
	update_ui()

func label(text: String, size: int, tint: Color = Color("ded9ca")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", tint)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0,44)
	node.add_theme_font_size_override("font_size",17)
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(action)
	return node

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme := Theme.new()
	theme.default_font = preload("res://assets/Interface.ttf")
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("191a17")
	normal.border_color = Color("49483e")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate()
	hover.bg_color = Color("35332c")
	hover.border_color = Color("c8c1ad")
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	theme.set_color("font_color", "Button", Color("ded9ca"))
	ui.theme = theme
	title_label = label("",17,Color("c8c1ad"))
	title_label.position = Vector2(32,17)
	ui.add_child(title_label)
	objective_label = label("",17)
	objective_label.position = Vector2(32,55)
	objective_label.hide()
	ui.add_child(objective_label)
	var pause := button("ESC", pause_game)
	pause.position = Vector2(1175,15)
	pause.size = Vector2(75,36)
	ui.add_child(pause)
	message_label = label("",16,Color("c9aa7d"))
	message_label.position = Vector2(32,574)
	ui.add_child(message_label)
	mode_label = label("",15,Color("8d8a80"))
	mode_label.position = Vector2(32,610)
	ui.add_child(mode_label)
	var slots := HBoxContainer.new()
	slots.position = Vector2(32,636)
	slots.add_theme_constant_override("separation",12)
	ui.add_child(slots)
	for i in range(4):
		var slot := button("", func(): inventory_click(i))
		slot.custom_minimum_size = Vector2(126,64)
		slot.icon = item_icon(i)
		slot.expand_icon = true
		slot.add_theme_constant_override("icon_max_width",46)
		slot.add_theme_font_size_override("font_size",14)
		slots.add_child(slot)
		inventory_buttons.append(slot)
	var journal_button := button("PISTAS", show_journal)
	journal_button.custom_minimum_size = Vector2(135,64)
	journal_button.icon = item_icon(5)
	journal_button.expand_icon = true
	journal_button.add_theme_constant_override("icon_max_width",36)
	slots.add_child(journal_button)
	overlay = ColorRect.new()
	overlay.color = Color(0.025,0.025,0.02,0.87)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	menu_art = TextureRect.new()
	menu_art.texture = MENU_ART
	menu_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(menu_art)
	menu_screen = Control.new()
	menu_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(menu_screen)
	panel = PanelContainer.new()
	panel.position = Vector2(300,70)
	panel.size = Vector2(680,0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055,0.058,0.05,0.97)
	style.border_color = Color("5b5548")
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel",style)
	overlay.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",14)
	panel.add_child(content)

func item_icon(index: int) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = INVENTORY_ART
	var cell := Vector2(INVENTORY_ART.get_width()/3.0,INVENTORY_ART.get_height()/2.0)
	icon.region = Rect2(Vector2(index%3,index/3)*cell,cell)
	return icon

func clear_panel(title: String, body: String) -> void:
	menu_screen.hide()
	menu_art.visible = state in ["menu","splash"] or (state == "character_select" and not choosing_from_pause)
	panel.show()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	panel.set_deferred("size", Vector2(680,0))
	var header := label(title,26,Color("c8c1ad"))
	content.add_child(header)
	if not body.is_empty():
		var text := label(body,17)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if body.length() > 420:
			var scroll := ScrollContainer.new()
			scroll.custom_minimum_size = Vector2(608,330)
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			text.custom_minimum_size.x = 580
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			scroll.add_child(text)
			content.add_child(scroll)
		else:
			text.custom_minimum_size.x = 608
			content.add_child(text)
	overlay.show()

func add_logo() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.custom_minimum_size = Vector2(0,100)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(logo)

func add_alien_preview(index: int, height: float, parent: Node) -> void:
	var preview := TextureRect.new()
	preview.texture = Actor.TEXTURES[index]
	preview.custom_minimum_size = Vector2(220,height)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(preview)

func show_character_select(from_pause: bool = false) -> void:
	choosing_from_pause = from_pause
	state = "character_select"
	modal_open = false
	clear_panel("ELIGE TU PROTAGONISTA", "Puedes cambiarlo desde la pausa sin perder el progreso.")
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation",32)
	content.add_child(cards)
	for i in range(2):
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = 270
		cards.add_child(card)
		add_alien_preview(i,250,card)
		var name_label := label(Actor.NAMES[i].to_upper(),20,Color("c8c1ad") if i==0 else Color("c9aa7d"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(name_label)
		card.add_child(button("ELEGIR",func(): choose_alien(i)))
	content.add_child(button("VOLVER",func():
		if choosing_from_pause:
			state = "playing"
			pause_game()
		else:
			show_menu()))

func choose_alien(index: int) -> void:
	selected_alien = clampi(index,0,1)
	actor.set_character(selected_alien)
	var preferences := ConfigFile.new()
	preferences.set_value("character","selected",selected_alien)
	preferences.save("user://preferences.cfg")
	if choosing_from_pause:
		resume_game()
		notify("Ahora juegas con " + Actor.NAMES[selected_alien].to_lower() + ". Tu progreso se conserva.")
	else:
		start_game()

func title_screen() -> void:
	for child in menu_screen.get_children():
		menu_screen.remove_child(child)
		child.queue_free()
	panel.hide()
	menu_screen.show()
	menu_art.show()
	overlay.show()
	var chapter := label("C A P Í T U L O   I",15,Color("aa8b68"))
	chapter.position = Vector2(105,167)
	menu_screen.add_child(chapter)
	var heading := label("UMBRAL",65,Color("ded8ca"))
	heading.add_theme_font_override("font",preload("res://assets/Title.ttf"))
	heading.position = Vector2(98,197)
	menu_screen.add_child(heading)
	var subtitle := label("CUATRO HABITACIONES. UNA SALIDA.",13,Color("929085"))
	subtitle.position = Vector2(105,292)
	menu_screen.add_child(subtitle)
	var rule := ColorRect.new()
	rule.color = Color("7d3027")
	rule.position = Vector2(105,332)
	rule.size = Vector2(70,2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(rule)

func menu_option(text: String, y: float, callback: Callable) -> void:
	var option := button(text,callback)
	option.position = Vector2(91,y)
	option.size = Vector2(330,45)
	option.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0,0,0,0)
	normal.content_margin_left = 14
	var hover := normal.duplicate()
	hover.bg_color = Color(0.22,0.20,0.16,0.55)
	hover.border_color = Color("a17e55")
	hover.border_width_left = 2
	option.add_theme_stylebox_override("normal",normal)
	option.add_theme_stylebox_override("hover",hover)
	option.add_theme_stylebox_override("pressed",hover)
	menu_screen.add_child(option)

func show_splash() -> void:
	title_screen()
	menu_option("Entrar",395,show_menu)

func show_menu() -> void:
	state = "menu"
	modal_open = false
	title_screen()
	menu_option("Jugar",367,func(): show_character_select(false))
	menu_option("Cómo jugar",419,show_controls)
	menu_option("Sonido: sí" if sound_enabled else "Sonido: no",471,func():
		sound_enabled = not sound_enabled
		show_menu())
	menu_option("Salir",523,func(): get_tree().quit())

func show_controls() -> void:
	clear_panel("CÓMO JUGAR", "CLIC IZQUIERDO: caminar, examinar o usar un objeto.\nEl alien se acerca antes de interactuar.\nFLECHAS LATERALES: cambiar de habitación al instante.\n\nQ: sacar / guardar el arma después de encontrarla.\nCON EL ARMA FUERA: clic izquierdo dispara al ratón.\nCLIC DERECHO: guardar el arma y detenerse.\n\nINVENTARIO: pulsa CAJA DE MUNICIÓN para recargar.\nLas llaves y piezas se usan al tocar su objeto.\nESC: pausa o cierra una ventana.\n\nConsulta el diario si necesitas recordar una pista.")
	content.add_child(button("VOLVER", show_menu))

func start_game() -> void:
	actor.set_character(selected_alien)
	state = "playing"
	modal_open = false
	armed = false
	for flag in ["has_key","has_gun","has_fuse","has_card","supplies_open","safe_open","power","latch_broken","card_taken","authorized","exit_open"]:
		set(flag,false)
	channels = [0,1,0]
	ammo = 0
	reserve = 0
	reload_left = 0
	shot_left = 0
	journal.clear()
	traces.clear()
	overlay.hide()
	change_room(0,230)
	notify("La puerta de salida no responde. Empieza examinando el vestíbulo.")

func _physics_process(delta: float) -> void:
	if state == "splash":
		splash_left -= delta
		if splash_left <= 0:
			show_menu()
	if state != "playing" or modal_open:
		return
	shot_left = maxf(0,shot_left-delta)
	if reload_left > 0:
		reload_left = maxf(0,reload_left-delta)
		if reload_left <= 0:
			var amount := mini(CAPACITY-ammo,reserve)
			ammo += amount
			reserve -= amount
			notify("Arma recargada. Q para sacarla; clic para disparar.")
	actor.armed = armed
	actor.refresh_pose()
	actor.step(delta,get_global_mouse_position())
	if not pending.is_empty() and absf(actor.position.x-actor.destination) < 4:
		var action := pending
		pending = ""
		interact(action)
	for i in range(traces.size()-1,-1,-1):
		traces[i].life -= delta
		if traces[i].life <= 0:
			traces.remove_at(i)
	update_ui()
	room_view.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == "character_select":
				if choosing_from_pause:
					state = "playing"
					pause_game()
				else:
					show_menu()
			elif modal_open:
				close_modal()
			elif state == "paused":
				resume_game()
			elif state == "playing":
				pause_game()
		elif event.physical_keycode == KEY_Q and state == "playing" and not modal_open:
			toggle_weapon()
	if event is InputEventMouseButton and event.pressed and state == "playing" and not modal_open:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			armed = false
			pending = ""
			actor.destination = actor.position.x
		elif event.button_index == MOUSE_BUTTON_LEFT:
			world_click(get_global_mouse_position())

func world_click(point: Vector2) -> void:
	if point.y < 108 or point.y > 558:
		return
	# Las flechas son navegación de pantalla, incluso con el arma fuera.
	for h in room_view.hotspots():
		if h.id in ["left", "right"] and h.rect.has_point(point):
			interact(h.id)
			return
	if armed:
		shoot_at(point)
		return
	pending = ""
	for h in room_view.hotspots():
		if h.rect.has_point(point):
			pending = h.id
			actor.destination = clampf(h.rect.get_center().x,65,1215)
			notify("Acercándose: " + h.name + "…")
			return
	actor.destination = clampf(point.x,65,1215)

func toggle_weapon() -> void:
	if not has_gun:
		notify("No tienes un arma. Revisa el armario de suministros.")
		return
	armed = not armed
	pending = ""
	actor.destination = actor.position.x
	actor.armed = armed
	actor.refresh_pose()
	notify("Arma fuera: clic para disparar al ratón. Q para volver a explorar." if armed else "Modo explorar: clic para caminar o interactuar.")
	update_ui()

func change_room(index: int, entry_x: float) -> void:
	room_index = clampi(index,0,3)
	actor.position = Vector2(entry_x,550)
	actor.destination = entry_x
	pending = ""
	traces.clear()
	armed = false
	actor.armed = false
	actor.flash_left = 0.0
	actor.refresh_pose()
	notify("Has entrado en " + Room.NAMES[room_index].substr(5).to_lower() + ".")
	room_view.queue_redraw()
	update_ui()

func interact(id: String) -> void:
	match id:
		"left": change_room(room_index-1,1090)
		"right": change_room(room_index+1,190)
		"coat":
			if not has_key and not supplies_open:
				has_key = true
				remember("Encontré la llave del armario en el abrigo del guardia.")
				notify("Encontraste una llave pequeña en el bolsillo del abrigo.")
			else:
				notify("Ya revisaste los bolsillos. No hay nada más.")
		"note":
			remember("Caja fuerte: leer las cifras del turno de izquierda a derecha: 3 - 1 - 4 - 2.")
			show_message("NOTA DEL GUARDIA", "El fusible de repuesto está en la caja fuerte del archivo.\n\nLa clave son las cifras de mi turno, de izquierda a derecha:\n\n3   —   1   —   4   —   2\n\nLa llave de suministros quedó en mi abrigo.")
		"cabinet":
			if not has_key and not supplies_open:
				notify("Cerrado con llave. El abrigo del guardia podría tenerla.")
			else:
				has_key = false
				supplies_open = true
				if not has_gun:
					has_gun = true
					ammo = CAPACITY
				reserve = 36
				remember("Tengo una pistola. Q la saca; clic dispara. La caja del inventario recarga. El armario repone la reserva.")
				notify("Pistola disponible. Reserva repuesta a 36 balas. Pulsa Q para apuntar.")
		"books":
			remember("La nota del vestíbulo contiene la clave. El fusible debe instalarse en el taller.")
			show_message("REGISTRO DE MANTENIMIENTO", "Falta el fusible del taller. Hay un repuesto en la caja fuerte.\n\nEl guardia anotó la clave en el vestíbulo.\n\nUna vez encendida, la vitrina del taller permite liberar su cierre.")
		"safe":
			if safe_open:
				notify("La caja fuerte está vacía. Ya recogiste el fusible.")
			else:
				show_safe()
		"fusebox":
			if power:
				notify("El tablero funciona. La vitrina recibe corriente.")
			elif has_fuse:
				has_fuse = false
				power = true
				remember("Restauré la corriente. Puedo disparar al cierre marcado con X de la vitrina.")
				notify("Fusible instalado. Ahora dispara al cierre de la vitrina.")
			else:
				notify("Falta un fusible. Busca uno en la caja fuerte del archivo.")
		"warning":
			remember("Vitrina: primero corriente; después Q y clic al cierre X; guardar arma y recoger tarjeta.")
			show_message("APERTURA DE EMERGENCIA", "1. Instala el fusible para soltar el electroimán.\n2. Saca la pistola con Q.\n3. Apunta al cierre marcado con X y haz clic.\n4. Guarda el arma con Q y recoge la tarjeta.\n\nSi te faltan balas, pulsa la caja de tu inventario.\nEl armario del vestíbulo repone la reserva.")
		"case":
			if card_taken:
				notify("La vitrina está vacía. Ya tienes la tarjeta.")
			elif not power:
				notify("La vitrina está bloqueada. Primero restaura la corriente.")
			elif not latch_broken:
				notify("Rompe el cierre marcado con X: Q para sacar el arma, apunta y haz clic.")
			else:
				card_taken = true
				has_card = true
				remember("Recogí la tarjeta. El lector está en la habitación de control.")
				notify("Tarjeta de acceso añadida al inventario.")
		"reader":
			if has_card:
				authorized = true
				remember("Consola habilitada. Los tres canales deben quedar en VERDE.")
				notify("Identificación aceptada. Pon los tres canales de la consola en verde.")
			else:
				notify("Necesitas la tarjeta guardada en la vitrina del taller.")
		"console":
			if not authorized:
				notify("Consola bloqueada. Usa la tarjeta en el lector de la izquierda.")
			elif exit_open:
				notify("Todos los canales están en verde. Ya puedes salir.")
			else:
				show_console()
		"exit":
			if exit_open:
				win_game()
			else:
				notify("Salida bloqueada. Autoriza el lector y resuelve la consola.")
	update_ui()
	room_view.queue_redraw()

func show_message(title: String, body: String) -> void:
	modal_open = true
	clear_panel(title,body)
	content.add_child(button("CERRAR",close_modal))

func close_modal() -> void:
	modal_open = false
	overlay.hide()

func show_safe() -> void:
	modal_open = true
	clear_panel("CAJA FUERTE", "Introduce cuatro cifras. La pista está en la nota del vestíbulo.")
	code_input = LineEdit.new()
	code_input.placeholder_text = "Código de 4 cifras"
	code_input.max_length = 4
	code_input.custom_minimum_size.y = 54
	code_input.add_theme_font_size_override("font_size",26)
	code_input.text_submitted.connect(func(value): try_safe(value))
	content.add_child(code_input)
	content.add_child(button("ABRIR",func(): try_safe(code_input.text)))
	content.add_child(button("VOLVER",close_modal))
	code_input.grab_focus()

func try_safe(code: String) -> bool:
	if code != "3142":
		show_message("CÓDIGO INCORRECTO", "La caja sigue cerrada. Busca la nota del guardia en el vestíbulo.\nPuedes intentarlo cuantas veces quieras.")
		return false
	safe_open = true
	has_fuse = true
	remember("Abrí la caja con 3142. Recogí un fusible para el tablero del taller.")
	close_modal()
	notify("Caja abierta. Fusible añadido al inventario.")
	update_ui()
	return true

func show_console() -> void:
	modal_open = true
	clear_panel("CONEXIÓN DE SALIDA", "Cada botón cambia su canal: ROJO > ÁMBAR > VERDE > ROJO.\nLos TRES deben estar en VERDE. Luego confirma.")
	for i in range(3):
		var text: String = ["ROJO","ÁMBAR","VERDE"][channels[i]]
		content.add_child(button("CANAL %d   /   %s" % [i+1,text],func():
			channels[i] = (channels[i]+1)%3
			show_console()))
	content.add_child(button("CONFIRMAR CONEXIÓN", confirm_console))
	content.add_child(button("VOLVER",close_modal))

func confirm_console() -> bool:
	if not authorized:
		return false
	if channels != [2,2,2]:
		show_message("CONEXIÓN INCOMPLETA", "Aún hay canales en rojo o ámbar. Vuelve a la consola y deja los tres en verde.")
		return false
	exit_open = true
	close_modal()
	remember("Salida desbloqueada. Haz clic en la puerta de control para escapar.")
	notify("Puerta desbloqueada. Haz clic en SALIDA.")
	return true

func inventory_click(slot: int) -> void:
	if state != "playing" or modal_open:
		return
	match slot:
		0: begin_reload()
		1: notify("Llave del armario: toca el armario del vestíbulo para usarla." if has_key else "Aquí aparecerá la llave que encuentres.")
		2: notify("Fusible: toca el tablero del taller para instalarlo." if has_fuse else ("El fusible ya está instalado." if power else "Busca el fusible en el archivo."))
		3: notify("Tarjeta: toca el lector de la habitación de control." if has_card else "Todavía no tienes una tarjeta de acceso.")

func begin_reload() -> void:
	if not has_gun:
		notify("Primero encuentra la pistola en el armario del vestíbulo.")
	elif reload_left > 0:
		notify("Recargando…")
	elif ammo == CAPACITY:
		notify("El cargador ya está lleno.")
	elif reserve <= 0:
		notify("Caja vacía. Vuelve al armario del vestíbulo para reponer balas.")
	else:
		reload_left = 1.0
		notify("Recargando desde la caja del inventario…")

func shoot_at(point: Vector2) -> bool:
	if not has_gun or not armed or reload_left > 0 or shot_left > 0:
		return false
	if ammo <= 0:
		notify("Sin balas: pulsa CAJA DE MUNICIÓN en el inventario para recargar.")
		return false
	ammo -= 1
	shot_left = 0.24
	actor.play_shot(point)
	var origin: Vector2 = actor.muzzle_origin()
	var direction := origin.direction_to(point)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	actor.aim = direction
	var end := origin + direction*1800
	if room_index == 2 and not latch_broken and ray_hits_rect(origin,end,Room.LATCH_RECT):
		end = Room.LATCH_RECT.get_center()
		if power:
			latch_broken = true
			remember("Rompí el cierre de la vitrina. Q guarda el arma; clic en la vitrina recoge la tarjeta.")
			notify("¡Cierre roto! Guarda el arma con Q y toca la vitrina.")
		else:
			notify("El electroimán retiene el cierre. Necesitas restaurar la corriente.")
	else:
		notify("Disparo. Para explorar de nuevo, guarda el arma con Q.")
	traces.append({"a":origin,"b":end,"life":0.13})
	if sound_enabled:
		audio.stream = shot_sound
		audio.play()
	actor.queue_redraw()
	room_view.queue_redraw()
	update_ui()
	return true

func ray_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true
	var points := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(a,b,points[i],points[(i+1)%4]) != null:
			return true
	return false

func remember(text: String) -> void:
	if not journal.has(text):
		journal.append(text)

func show_journal() -> void:
	if state != "playing":
		return
	var text := "OBJETIVO: " + objective() + "\n\n"
	if journal.is_empty():
		text += "Aún no tienes notas. Examina el abrigo y el papel del vestíbulo."
	else:
		for entry in journal.slice(maxi(0,journal.size()-5)):
			text += "• " + entry + "\n\n"
	show_message("DIARIO / ÚLTIMAS PISTAS",text)

func objective() -> String:
	if exit_open: return "Cruza la puerta de salida de la habitación de control."
	if authorized: return "Pon los tres canales de la consola en verde."
	if has_card: return "Usa la tarjeta en el lector de control."
	if latch_broken: return "Guarda el arma con Q y recoge la tarjeta de la vitrina."
	if power: return "Dispara al cierre X de la vitrina del taller."
	if has_fuse: return "Instala el fusible en el tablero del taller."
	if not has_gun: return "Examina el abrigo y abre el armario de suministros."
	return "Lee la nota del vestíbulo y abre la caja fuerte del archivo."

func notify(text: String) -> void:
	last_message = text
	if is_instance_valid(message_label):
		message_label.text = text

func update_ui() -> void:
	title_label.text = Room.NAMES[room_index]
	objective_label.text = objective()
	mode_label.text = ("APUNTAR · Clic: disparar · Q: guardar" if armed else "CLIC: explorar   ·   Q: arma") + "     /     %02d : %02d" % [ammo,CAPACITY]
	inventory_buttons[0].text = "…" if reload_left>0 else str(reserve)
	inventory_buttons[1].text = ""
	inventory_buttons[2].text = ""
	inventory_buttons[3].text = ""
	var available := [has_gun,has_key,has_fuse,has_card]
	var names := ["CAJA DE MUNICIÓN · Clic para recargar", "LLAVE · Abre el armario", "FUSIBLE · Para el tablero del taller", "TARJETA · Para el lector de control"]
	for i in range(4):
		inventory_buttons[i].modulate = Color.WHITE if available[i] else Color(0.45,0.43,0.38,0.7)
		inventory_buttons[i].tooltip_text = names[i] if available[i] else "Espacio de inventario vacío"

func pause_game() -> void:
	if state != "playing" or modal_open:
		return
	state = "paused"
	clear_panel("PAUSA", "La partida está detenida.")
	content.add_child(button("CONTINUAR",resume_game))
	content.add_child(button("CAMBIAR ALIEN",func(): show_character_select(true)))
	content.add_child(button("REINICIAR PARTIDA",start_game))
	content.add_child(button("MENÚ PRINCIPAL",show_menu))

func resume_game() -> void:
	state = "playing"
	overlay.hide()

func win_game() -> void:
	state = "won"
	clear_panel("HAS ESCAPADO", "La puerta se abre. Al otro lado, por fin, aire fresco.\n\nExploraste las cuatro habitaciones, restauraste la corriente\ny resolviste la salida.\n\nFIN DEL PRIMER CAPÍTULO")
	add_logo()
	content.add_child(button("JUGAR OTRA VEZ",start_game))
	content.add_child(button("MENÚ PRINCIPAL",show_menu))

func make_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(2200*2)
	for i in range(2200):
		var fade := 1.0-float(i)/2200.0
		var value := int(sin(i*0.12*(fade+0.2))*fade*18000)
		data.encode_s16(i*2,value)
	stream.data = data
	return stream
