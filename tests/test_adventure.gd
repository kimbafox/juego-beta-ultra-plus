extends SceneTree
## Recorrido completo con verificaciones y sin sonido.
var failures: int = 0
func check(condition: bool, text: String) -> void:
	if not condition:
		push_error("FAIL: " + text)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_enabled = false
	check(game.state == "splash", "logo antes del menú")
	game._physics_process(2.5)
	check(game.state == "menu", "transición automática a menú")
	await process_frame
	check(game.panel.get_global_rect().end.y < 720, "menú dentro de pantalla")
	game.show_controls()
	await process_frame
	check(game.panel.get_global_rect().end.y < 720, "controles dentro de pantalla")
	game.show_character_select(false)
	await process_frame
	check(game.panel.get_global_rect().end.y < 720, "selector dentro de pantalla")
	game.choose_alien(1)
	check(game.actor.selected == 1 and game.state == "playing", "elegir alien naranja e iniciar")
	check(game.actor.sprite.texture.atlas == game.Actor.WALK[1], "PNG naranja activo")
	for character in range(2):
		game.actor.set_character(character)
		game.actor.armed = false
		for direction in [-1,1]:
			game.actor.destination = game.actor.position.x + direction*200
			game.actor.step(0.18,Vector2.ZERO)
			check(game.actor.current_frame == (3 if direction < 0 else 1), "paso animado en ambas direcciones")
			var bounds: Rect2i = game.actor.feet[character][0][game.actor.current_frame]
			check(is_equal_approx(bounds.size.y*game.actor.sprite.scale.y,285.0), "altura visible 285 px")
			check(absf(game.actor.sprite.position.y+bounds.end.y*game.actor.sprite.scale.y) < 0.001, "pies sobre suelo")
			game.actor.play_shot(game.actor.position+Vector2(direction*400,-180))
			check(game.actor.current_frame == (3 if direction < 0 else 1), "fogonazo por dirección")
			check(game.actor.sprite.texture.atlas == game.Actor.SHOOT[character], "hoja de disparo correcta")
			game.actor.destination = game.actor.position.x
			game.actor.step(0.13,game.actor.position+Vector2(direction*400,-180))
			check(game.actor.current_frame == (2 if direction < 0 else 0), "fogonazo termina")
			game.actor.armed = false
	game.actor.set_character(1)
	game.world_click(Vector2(1210,380))
	check(game.room_index == 1 and game.pending.is_empty(), "flecha cambia de sala instantáneamente")
	game.world_click(Vector2(60,380))
	check(game.room_index == 0, "flecha izquierda instantánea")
	game.toggle_weapon()
	check(not game.armed, "no sacar arma sin recogerla")
	game.interact("cabinet")
	check(not game.has_gun, "armario bloqueado sin llave")
	# Clic sobre abrigo: caminar antes de recoger.
	game.world_click(Vector2(270,350))
	check(game.pending == "coat" and not game.has_key, "acción diferida hasta acercarse")
	for i in range(300): game._physics_process(1.0/60.0)
	check(game.has_key, "recoger llave al llegar")
	game.interact("note")
	check(game.modal_open and game.journal.size() >= 2, "pista y diario")
	game.close_modal()
	game.interact("cabinet")
	check(game.has_gun and game.ammo == 6 and game.reserve == 36, "recoger pistola y caja")
	game.pause_game()
	game.show_character_select(true)
	game.choose_alien(0)
	check(game.actor.selected == 0 and game.has_gun and game.reserve == 36 and game.state == "playing", "cambio a verde conserva inventario")
	check(game.actor.sprite.texture.atlas == game.Actor.WALK[0], "PNG verde activo")
	game.toggle_weapon()
	check(game.armed, "Q activa el modo de arma")
	check(game.actor.sprite.texture.atlas == game.Actor.SHOOT[0], "Q actualiza pose inmediatamente")
	game.shoot_at(Vector2(600,250))
	check(game.ammo == 5, "disparo dirigido consume una bala")
	game.inventory_click(0)
	check(game.reload_left > 0, "clic en caja inicia recarga")
	check(not game.shoot_at(Vector2(600,250)), "no disparar al recargar")
	game._physics_process(1.1)
	check(game.ammo == 6 and game.reserve == 35, "recarga consume reserva exacta")
	game.toggle_weapon()
	game.interact("right")
	check(game.room_index == 1, "puerta al archivo")
	check(game.actor.sprite.texture.atlas == game.Actor.WALK[0] and game.actor.flash_left == 0.0, "cambio de sala limpia pose de disparo")
	game.show_safe()
	check(not game.try_safe("1111") and not game.has_fuse, "código erróneo no abre")
	check(game.try_safe("3142") and game.has_fuse, "clave correcta entrega fusible")
	game.interact("right")
	check(game.room_index == 2, "puerta al taller")
	game.actor.position = Vector2(650,530)
	game.actor.destination = 650
	game.toggle_weapon()
	game.shot_left = 0
	game.shoot_at(game.Room.LATCH_RECT.get_center())
	check(not game.latch_broken, "cierre requiere corriente")
	game.toggle_weapon()
	game.interact("fusebox")
	check(game.power and not game.has_fuse, "instalar fusible")
	game.interact("case")
	check(not game.has_card, "tarjeta requiere romper cierre")
	game.toggle_weapon()
	game.shot_left = 0
	game.shoot_at(Vector2(500,200))
	check(not game.latch_broken, "fallar el blanco no rompe cierre")
	game.shot_left = 0
	game.shoot_at(game.Room.LATCH_RECT.get_center())
	check(game.latch_broken, "disparo al cierre libera vitrina")
	game.toggle_weapon()
	game.interact("case")
	check(game.has_card, "recoger tarjeta")
	game.interact("left")
	check(game.room_index == 1 and game.safe_open, "persistencia entre habitaciones")
	game.interact("right")
	game.interact("right")
	check(game.room_index == 3, "cuarta habitación")
	game.interact("exit")
	check(game.state == "playing", "salida cerrada hasta resolver")
	check(not game.confirm_console(), "no confirmar sin autorización")
	game.interact("reader")
	check(game.authorized, "tarjeta habilita consola")
	check(not game.confirm_console(), "canales incorrectos no abren")
	game.close_modal()
	game.channels.assign([2,2,2])
	check(game.confirm_console() and game.exit_open, "tres verdes abren salida")
	game.show_journal()
	await process_frame
	check(game.panel.get_global_rect().end.y < 720, "diario dentro de pantalla")
	game.close_modal()
	game.interact("exit")
	check(game.state == "won", "final de aventura")
	game.start_game()
	check(not game.has_card and not game.power and game.room_index == 0, "reinicio limpia progreso")
	game.pause_game()
	game._physics_process(1)
	check(game.state == "paused", "pausa real")
	game.resume_game()
	check(game.state == "playing", "continuar")
	# Prueba de reserva parcial y reposición: nunca quedarse sin solución.
	game.interact("coat")
	game.interact("cabinet")
	game.ammo = 0
	game.reserve = 2
	game.inventory_click(0)
	game._physics_process(1.1)
	check(game.ammo == 2 and game.reserve == 0, "recarga parcial")
	game.interact("cabinet")
	check(game.reserve == 36, "armario permite reponer balas")
	print("RESULTADO: %d errores. Recorrido completo, cuatro salas, logo, menú, movimiento, puzles, disparos, inventario, recarga y final." % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
