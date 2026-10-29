extends SceneTree
## Run: godot --headless --path . --script tests/test_game.gd
## Deterministic integration checks. Uses a separate user-data directory in CI.

var game: Node
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func() -> void:
		push_error("TEST TIMEOUT: check prior runtime errors")
		quit(2)
	)
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS ", description)
	else:
		failed += 1
		push_error("FAIL " + description)

func fresh() -> void:
	game.start_run()
	game.rng.seed = 20261028
	game.spawn_timer = 999.0

func no_combat() -> void:
	game.enemies.clear()
	game.bullets.clear()
	game.acid.clear()
	game.drops.clear()
	game.spawn_timer = 999.0

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	check(scene != null, "Main scene loads")
	if scene == null:
		quit(1)
		return
	game = scene.instantiate()
	game.set_process(false)
	root.add_child(game)
	game.test_mode = true
	game.sound.muted = true
	await process_frame
	check(game.state == "menu", "Starts in menu")
	check(not game.hud.visible, "Menu hides combat HUD")
	fresh()
	check(game.state == "wave" and game.wave == 1, "Deploy starts wave 1")
	var initial_phase: float = game.phase_time
	game.start_wave()
	game.start_wave()
	check(game.wave == 1 and game.phase_time == initial_phase, "Repeated wave start cannot skip a wave or reset its timer")
	check(game.hp == 100.0 and game.weapons.rifle == 1, "New run begins with health and rifle")
	check(game.hud.visible, "Combat HUD visible")

	# Every enemy type has its own profile and attack behaviour.
	var runner: Dictionary = game._spawn_enemy("runner", Vector2(100, 200))
	var spitter: Dictionary = game._spawn_enemy("spitter", Vector2(1100, 200))
	var brute: Dictionary = game._spawn_enemy("brute", Vector2(100, 650))
	var boss: Dictionary = game._spawn_enemy("boss", Vector2(1100, 650))
	check(game.enemies.size() == 4, "Four enemy variants spawn")
	check(brute.hp > runner.hp and brute.speed < runner.speed, "Brute is slower and tougher")
	check(boss.hp == 2200.0 and boss.r == 57.0, "Boss has large silhouette and 2200 health")
	for e: Dictionary in game.enemies:
		e.warmup = 0.0
	spitter.fire = 0.0
	boss.fire = 0.0
	boss.pulse = 0.0
	game._update_enemies(0.016)
	check(game.acid.size() == 11, "Spitter aims one acid shot, boss fires ten radial shots")
	check(game.enemies.size() == 7, "Boss summons three runners")

	# Automatic aim, each weapon, cooldowns, continuous collision, and kill rewards.
	for kind: String in ["rifle", "shotgun", "flame"]:
		fresh()
		no_combat()
		game.weapons = {"rifle": 0, "shotgun": 0, "flame": 0}
		game.weapons[kind] = 1
		var target: Dictionary = game._spawn_enemy("runner", game.player + Vector2(120, 0))
		target.warmup = 0.0
		target.hp = 5.0
		game._update_weapons(0.016)
		var expected: int = 1 if kind == "rifle" else (7 if kind == "shotgun" else 2)
		check(game.bullets.size() == expected, kind + " fires expected projectile count automatically")
		game._update_weapons(0.0)
		check(game.bullets.size() == expected, kind + " cooldown prevents duplicate firing")
		for step: int in range(30):
			game._update_bullets(0.025)
		check(game.kills == 1 and game.enemies.is_empty(), kind + " projectile hits and kills")
		check(game.drops.size() == 1 and game.xp == 2, kind + " kill creates salvage and XP")
		check(game.telemetry.damage_dealt >= 5.0, kind + " damage recorded")
		await process_frame
	fresh()
	no_combat()
	game.weapons = {"rifle": 1, "shotgun": 1, "flame": 1}
	var combined_target: Dictionary = game._spawn_enemy("brute", game.player + Vector2(120, 0))
	combined_target.warmup = 0.0
	game._update_weapons(0.016)
	check(game.bullets.size() == 10, "All three weapons can fire together")
	no_combat()
	game._spawn_enemy("runner", game.player + Vector2(700, 0)).warmup = 0.0
	game.cooldowns = {"rifle": 0.0, "shotgun": 0.0, "flame": 0.0}
	game._update_weapons(0.016)
	check(game.bullets.is_empty(), "Weapons do not fire beyond range")
	fresh()
	no_combat()
	var pierce_a: Dictionary = game._spawn_enemy("runner", game.player + Vector2(80, 0))
	var pierce_b: Dictionary = game._spawn_enemy("runner", game.player + Vector2(130, 0))
	pierce_a.warmup = 0.0
	pierce_b.warmup = 0.0
	var a_hp: float = pierce_a.hp
	var b_hp: float = pierce_b.hp
	game._fire_bullet(0.0, 340.0, 5.0, 0.53, Color.ORANGE, 8, "flame")
	for step: int in range(18):
		game._update_bullets(0.025)
	check(is_equal_approx(pierce_a.hp, a_hp - 5.0) and is_equal_approx(pierce_b.hp, b_hp - 5.0), "Flame pierces multiple enemies, hits each only once")

	# Damage, safety frames, dash, movement bounds, resource collection, progression.
	fresh()
	no_combat()
	game.hurt_timer = 0.0
	game.armor = 0.6
	game._hurt_player(10.0)
	check(is_equal_approx(game.hp, 96.0), "Armor reduces damage by 60 percent")
	game._hurt_player(10.0)
	check(is_equal_approx(game.hp, 96.0), "Hurt invulnerability blocks repeated contact")
	game.hurt_timer = 0.0
	game._dash()
	game._hurt_player(100.0)
	check(game.hp == 96.0 and game.dash_timer > 0.0, "Dash grants invulnerability")
	game._dash()
	check(game.telemetry.dashes == 1, "Dash cannot bypass cooldown")
	game.dash_timer = 0.0
	game.player = Vector2(1200, 700)
	game.joystick_vector = Vector2(1, 1).normalized()
	for step: int in range(20):
		game._update_game(0.05)
	check(game.player.x <= 1208.0 and game.player.y <= 718.0, "Movement is clamped to arena")
	game.joystick_vector = Vector2.ZERO
	game.drops.append({"p": game.player, "value": 7, "age": 0.0})
	game._update_drops(0.016)
	check(game.cash == 7 and game.drops.is_empty(), "Nearby salvage is collected")
	game.hp = 50.0
	game._gain_xp(game.xp_needed)
	check(game.level == 2 and game.max_hp == 106.0 and game.hp == 68.0, "Level-up heals and increases max health")
	check(is_equal_approx(game.damage_mult, 1.06), "Level-up boosts damage")
	var old_phase: float = game.phase_time
	var old_player: Vector2 = game.player
	var old_dash: float = game.dash_cooldown
	game._toggle_pause()
	game._process(0.05)
	check(game.paused and game.phase_time == old_phase and game.player == old_player and game.dash_cooldown == old_dash, "Pause freezes combat, movement, timer, and cooldown")
	game._toggle_pause()
	game._process(0.05)
	check(not game.paused and game.phase_time < old_phase, "Resume restores simulation")
	await process_frame

	# A finished wave vacuums resources, clears combat, heals, and opens the shop.
	fresh()
	game.hp = 50.0
	game.drops.append({"p": Vector2(100, 100), "value": 7, "age": 0.0})
	game.finish_wave()
	check(game.state == "shop" and game.cash == 37, "Wave reward includes all uncollected salvage")
	check(game.hp == 68.0 and game.enemies.is_empty() and game.acid.is_empty(), "Wave transition heals 18 percent and clears threats")
	check(game.offer_keys.size() == 6, "Shop has three weapons and three enhancements")
	for kind: String in ["rifle", "shotgun", "flame", "damage", "speed", "attack", "health", "armor", "magnet", "regen"]:
		game.offer_keys.assign([kind])
		game.sold.clear()
		game.cash = 1000
		var price: int = int(game._offer(kind).cost)
		var before: Dictionary = {"weapon": game.weapons.get(kind, 0), "damage": game.damage_mult, "speed": game.speed_mult, "attack": game.attack_mult, "health": game.max_hp, "armor": game.armor, "magnet": game.pickup_radius, "regen": game.regen}
		check(game._purchase(0), kind + " can be bought")
		check(game.cash == 1000 - price + (12 if kind == "magnet" else 0), kind + " charges exact cost")
		check(not game._purchase(0), kind + " duplicate purchase is denied")
		var improved: bool = false
		match kind:
			"rifle", "shotgun", "flame": improved = game.weapons[kind] == int(before.weapon) + 1
			"damage": improved = game.damage_mult > before.damage
			"speed": improved = game.speed_mult > before.speed
			"attack": improved = game.attack_mult > before.attack
			"health": improved = game.max_hp > before.health
			"armor": improved = game.armor > before.armor
			"magnet": improved = game.pickup_radius > before.magnet
			"regen": improved = game.regen > before.regen
		check(improved, kind + " changes the correct player stat")
		await process_frame
	game.offer_keys.assign(["rifle"])
	game.sold.clear()
	game.cash = 0
	check(not game._purchase(0) and not game._purchase(-1) and not game._purchase(1), "Cannot buy unaffordable or invalid offer")
	game.weapons.rifle = 4
	game.cash = 1000
	check(not game._purchase(0), "Weapon max level cannot be exceeded")
	game.offer_keys.assign(["armor"])
	game.armor = 0.6
	check(not game._purchase(0), "Armor cap cannot be exceeded")
	game.hp = 1.0
	var healing_cost: int = 15 + game.wave * 2
	game._heal()
	check(game.hp == 1.0 + game.max_hp * 0.5 and game.cash == 1000 - healing_cost, "Paid heal restores half max health")
	game.hp = game.max_hp
	var before_heal_cash: int = game.cash
	game._heal()
	check(game.cash == before_heal_cash, "Healing at full health costs nothing")
	game._roll_offers()
	game.sold.assign([0, 4])
	var before_reroll: int = game.cash
	game._reroll()
	check(game.cash == before_reroll - 8 and game.reroll_cost == 13, "Reroll charges price then increases it")
	check(0 in game.sold and not 4 in game.sold and game.offer_keys.size() == 6, "Reroll preserves bought weapons, refreshes enhancement slots")
	game.cash = 0
	game._reroll()
	check(game.reroll_cost == 13 and game.cash == 0, "Insufficient funds block reroll")
	await process_frame

	# All ten waves and boss victory. This tests the real transition methods,
	# not real-time balance or the player's ability to survive each wave.
	fresh()
	for number: int in range(1, 10):
		check(game.wave == number and game.state == "wave", "Wave %d starts correctly" % number)
		game.phase_time = 0.001
		game.spawn_timer = 999.0
		game._update_game(0.01)
		check(game.state == "shop", "Wave %d timer opens supply shop" % number)
		game.start_wave()
		await process_frame
	check(game.wave == 10 and game.state == "wave" and game.boss_spawned, "Wave 10 automatically deploys boss")
	check(game.enemies.size() == 1 and game.enemies[0].kind == "boss", "Final wave begins with one boss")
	game.start_wave()
	check(game.wave == 10 and game.enemies.size() == 1, "Repeated final-wave start cannot spawn another boss")
	game.phase_time = 0.0
	game.spawn_timer = 999.0
	game._update_game(0.01)
	check(game.state == "wave", "Final wave cannot be won by timer alone")
	var final_boss: Dictionary = game.enemies[0]
	game._hit_enemy(final_boss, 3000.0, Vector2.RIGHT, "rifle")
	game._update_bullets(0.0)
	game._update_game(0.01)
	check(game.state == "victory" and game.boss_dead and game.best_wave == 10, "Destroying boss completes victory")
	check(game.wins >= 1, "Victory increments win counter")
	game.start_wave()
	check(game.wave == 10 and game.state == "victory", "Wave 11 is blocked after victory")
	game.start_run()
	check(game.state == "wave" and game.wave == 1 and game.kills == 0 and game.weapons.rifle == 1 and game.weapons.shotgun == 0, "Restart after victory resets progression")
	game.hurt_timer = 0.0
	game._hurt_player(999.0)
	check(game.state == "dead" and game.hp == 0.0, "Lethal damage reaches death screen")
	game.start_run()
	check(game.state == "wave" and game.hp == 100.0 and not game.paused, "Restart after death resets health and pause")
	game._toggle_pause()
	game._abandon()
	check(game.state == "menu" and not game.paused, "Abandon paused run returns to menu")
	game.start_run()
	check(game.state == "wave" and game.wave == 1, "Deploy works again after abandoning")
	await process_frame
	# Mobile input regression: real screen events, independent fingers and interruption.
	fresh()
	no_combat()
	game.touch_mode = true
	var finger := InputEventScreenTouch.new()
	finger.index = 4
	finger.position = Vector2(180, 610)
	finger.pressed = true
	game._input(finger)
	check(game.joystick_id == 4, "Touch claims one joystick finger")
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = Vector2(300, 610)
	game._input(drag)
	check(game.joystick_vector.x > 0.99 and game.joystick_vector.length() <= 1.001, "Joystick clamps radius and points right")
	var wrong_drag := InputEventScreenDrag.new()
	wrong_drag.index = 8
	wrong_drag.position = Vector2(50, 500)
	game._input(wrong_drag)
	check(game.joystick_vector.x > 0.99, "Other finger cannot hijack joystick")
	var right_finger := InputEventScreenTouch.new()
	right_finger.index = 8
	right_finger.position = game.DASH_POSITION
	right_finger.pressed = true
	game._input(right_finger)
	check(game.telemetry.dashes == 1 and game.joystick_id == 4, "Second finger dashes while first finger keeps moving")
	right_finger.pressed = false
	game._input(right_finger)
	check(game.joystick_id == 4 and game.joystick_vector.x > 0.99, "Releasing dash finger does not stop movement")
	var fake_mouse := InputEventMouseButton.new()
	fake_mouse.device = -1
	fake_mouse.button_index = MOUSE_BUTTON_LEFT
	fake_mouse.pressed = true
	fake_mouse.position = Vector2(170, 590)
	game._input(fake_mouse)
	fake_mouse.pressed = false
	game._input(fake_mouse)
	check(game.joystick_id == 4 and not game.mouse_joystick and game.joystick_vector.x > 0.99, "Emulated mouse does not overwrite or release a real touch")
	finger.canceled = true
	game._input(finger)
	check(game.joystick_id == -1 and game.joystick_vector == Vector2.ZERO, "Canceled touch clears movement")
	finger.canceled = false
	game._input(finger)
	game._input(drag)
	game._pause_for_focus_loss()
	check(game.paused and game.joystick_id == -1 and game.joystick_vector == Vector2.ZERO, "Losing focus pauses and clears held touch")
	game._pause_for_focus_loss()
	check(game.paused, "Repeated focus-loss does not resume game")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game.paused, "Android Back resumes a paused run")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.paused, "Android Back pauses a running wave")
	game._toggle_pause()
	game._input(finger)
	game._input(drag)
	game.finish_wave()
	check(game.state == "shop" and game.joystick_id == -1 and game.joystick_vector == Vector2.ZERO, "Entering shop releases all touch input")
	await process_frame
	var card_targets := 0
	for child in game.overlay.get_children():
		if child is Button and child.size.x == 370 and child.size.y == 200:
			card_targets += 1
	check(card_targets == 6, "Mobile shop has six full-card thumb targets")
	game.start_wave()
	check(game.joystick_id == -1 and game.joystick_vector == Vector2.ZERO, "Next wave cannot inherit stale joystick")
	game._input(finger)
	game._input(drag)
	game.hurt_timer = 0
	game.dash_timer = 0
	game._hurt_player(999.0)
	check(game.state == "dead" and game.joystick_id == -1, "Death releases held touch")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.state == "menu", "Android Back from results returns to menu")
	check(not root.get_tree().quit_on_go_back, "Android Back automatic quit is disabled")
	print("TEST_RESULT ", JSON.stringify({"passed": passed, "failed": failed}))
	game.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
