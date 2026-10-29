extends Node2D
## Starfront Survivors: deterministic, dependency-free arena roguelite.
const UISkin = preload("res://scripts/ui_skin.gd")
const Visuals = preload("res://scripts/visuals.gd")
const Sound = preload("res://scripts/audio.gd")
const Build = preload("res://scripts/build_v2.gd")
const Combat = preload("res://scripts/combat_v2.gd")
const Save = preload("res://scripts/save_v2.gd")
const Meta = preload("res://scripts/meta_v4.gd")
const Narrative = preload("res://scripts/narrative_v4.gd")
const Radio = preload("res://scripts/radio_v4.gd")
const SIZE := Vector2(1280, 800)
const ARENA := Rect2(48, 142, 1184, 600)
const CYAN := Color("00d2ff")
const GOLD := Color("ffa940")
const TEXT := Color("e4f1f5")
const DIM := Color("7c9ba9")
const GREEN := Color("99e695")
const RED := Color("ff677a")
const JOYSTICK_RADIUS := 88.0
const DASH_POSITION := Vector2(1110, 625)
const DASH_RADIUS := 95.0
const JOYSTICK_ZONE := Rect2(48, 390, 452, 352)
const WEAPON_NAMES := {"rifle":"磁轨步枪", "shotgun":"破阵霰弹枪", "flame":"等离子喷焰器"}
const WAVE_NAMES := ["接触确认","菌毯蔓延","酸蚀阵线","装甲推进","坑道突袭","围猎包围","地刺封锁","绿潮崩解","决死阵线","终焉虫心"]
var shop_speaker := "hank"
var rng := RandomNumberGenerator.new()
var ui := CanvasLayer.new()
var hud: Control
var overlay: Control
var hp_label: Label
var wave_label: Label
var time_label: Label
var cash_label: Label
var stats_label: Label
var weapon_label: Label
var notice_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var dash_bar: ProgressBar
var pause_button: Button
var sound_button: Button
var sound: Node
var font: Font
var state := "menu"
var ui_epoch := 0
var sell_uid := -1
var paused := false
var touch_mode := OS.has_feature("mobile")
var phase_time := 0.0
var total_time := 0.0
var player := Vector2(640, 440)
var facing := -PI / 2.0
var moving := false
var hp := 100.0
var max_hp := 100.0
var cash := 0
var wave := 0
var kills := 0
var level := 1
var xp := 0
var xp_needed := 15
var damage_mult := 1.0
var attack_mult := 1.0
var speed_mult := 1.0
var armor := 0.0
var pickup_radius := 100.0
var regen := 0.0
var weapons: Array = []
var build: Dictionary = {}
var support_attack_mult := 1.0
var rifle_branch_penalty := 0.75
var radio_was_paused := false
var profile: Dictionary = {}
var meta_path := "user://profile_v4.json"
var run_id := ""
var radio: Node
var supports: Array = []
var last_damage_source := "unknown"
var bark_times: Dictionary = {}
var intro_timer := 0.0
var bridge_tab := "tech"
var bridge_page := 0
var shop_roll_count := 0
var combat: Dictionary = {}
var class_id := "marine"
var selected_class := "marine"
var items: Array = []
var synergies: Dictionary = {}
var hazards: Array = []
var crit_rate := 0.05
var crit_mult := 1.5
var lifesteal := 0.0
var dodge := 0.0
var range_mult := 1.0
var base_speed := 215.0
var overcharge_timer := 0.0
var overcharge_points := 0
var stim_timer := 0.0
var stim_cooldown := 0.0
var stationary_time := 0.0
var harvesting := 0.0
var ballistic_damage_mult := 1.0
var ballistic_attack_mult := 1.0
var pierce_bonus := 0
var hurt_extra := 0.0
var hurt_invuln := 0.65
var heal_cost_mult := 1.0
var wave_subsidy := 0
var enemy_scale := 1.0
var extra_dash := 0
var turret := 0
var revive := 0
var magnet_bonus := 0.0
var dash_charges := 1
var safe_left := 0.0
var safe_right := 0.0
var safe_top := 0.0
var safe_bottom := 0.0
var right_touches: Dictionary = {}
var regen_clock := 0.0
var save_notice := ""
var save_path := "user://run_v2.json"
const WAVE_TIMES := [25,28,30,32,35,35,38,38,40,0]
const CLASS_IDS := ["marine","marauder","reaper","firebat","ghost"]
const CLASS_NAMES := ["游骑兵","重装劫掠者","死神","火蝠","幽灵"]
const CLASS_DESCS := ["均衡射击\n兴奋剂：耗血换射速与移速","140 生命，重甲慢速\n命中减速、强力击退","75 生命，高速双枪\n短冷却冲刺，留下跳雷","125 生命，贴身喷焰\n点燃持续伤害与热能殉爆","85 生命，远程狙击\n每 30 击杀释放 EMP"]
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var acid: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var spawn_timer := 0.0
var hurt_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_dir := Vector2.RIGHT
var notice_timer := 0.0
var shake := 0.0
var weapon_flash := 0.0
var boss_spawned := false
var boss_dead := false
var boss_pulse := 0.0
var next_id := 0
var joystick_id := -1
var joystick_origin := Vector2(155, 625)
var joystick_position := Vector2(155, 625)
var joystick_vector := Vector2.ZERO
var joystick_finger := Vector2.ZERO
var mouse_joystick := false
var offer_keys: Array[String] = []
var sold: Array[int] = []
var reroll_cost := 8
var best_wave := 0
var wins := 0
var test_mode := false
var auto_test := false
var auto_test_clock := 0.0
var telemetry := {"shots":0, "damage_dealt":0.0, "damage_taken":0.0, "purchases":0, "dashes":0}

func _ready() -> void:
	# Android Back pauses a live run instead of killing the application.
	get_tree().quit_on_go_back = false
	Engine.max_fps = 60
	rng.randomize()
	font = load("res://assets/Interface.ttf") if ResourceLoader.exists("res://assets/Interface.ttf") else ThemeDB.fallback_font
	sound = Sound.new()
	add_child(sound)
	add_child(ui)
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	var ui_root := Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = theme
	ui.add_child(ui_root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(overlay)
	_build_hud()
	_update_safe_area()
	get_viewport().size_changed.connect(_update_safe_area)
	_load_progress()
	profile = Meta.load_profile(meta_path)
	radio = Radio.new()
	add_child(radio)
	radio.setup(font)
	radio.history_opened.connect(func():
		radio_was_paused=paused
		if state=="wave": paused=true
		_reset_touch())
	radio.history_closed.connect(func(): paused=radio_was_paused)
	_update_safe_area()
	_show_menu()
	if "--autoplay" in OS.get_cmdline_user_args():
		auto_test = true
		start_run()
	if "--test" in OS.get_cmdline_user_args():
		test_mode = true
	queue_redraw()

func _style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(mini(radius, 2))
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _panel(parent: Node, rect: Rect2, bg := Color("102431"), border := Color("29424f")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.draw.connect(func(): UISkin.draw_panel(panel,Rect2(Vector2.ZERO,panel.size),border,bg))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size := 20, color := TEXT, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.clip_text = true
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, accent := CYAN) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = Vector2(rect.size.x, maxf(rect.size.y, 56.0) if touch_mode else rect.size.y)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("526774"))
	for mode in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,accent,0))
	var plate := Control.new()
	plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plate.show_behind_parent=true
	b.add_child(plate)
	plate.draw.connect(func():
		var pressed := b.button_pressed
		var edge: Color = DIM.darkened(0.5) if b.disabled else (GOLD if pressed else (accent if b.is_hovered() else accent.darkened(0.5)))
		UISkin.draw_panel(plate,Rect2(Vector2(0,2) if pressed else Vector2.ZERO,b.size-Vector2(0,2) if pressed else b.size),edge,Color("0e1217") if pressed or b.disabled else Color("26313d"),8)
		if b.disabled: UISkin.draw_hazard(plate,Rect2(10,b.size.y-7,b.size.x-20,3),DIM.darkened(0.4)))
	b.mouse_entered.connect(plate.queue_redraw)
	b.mouse_exited.connect(plate.queue_redraw)
	b.button_down.connect(plate.queue_redraw)
	b.button_up.connect(plate.queue_redraw)
	var epoch := ui_epoch
	b.pressed.connect(func():
		if parent != overlay or epoch == ui_epoch: callback.call()
	)
	parent.add_child(b)
	return b

func _bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.position = rect.position
	p.size = rect.size
	p.show_percentage = false
	p.add_theme_font_size_override("font_size",1)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := _style(Color("0b1b25"), Color.TRANSPARENT, 5)
	var fill := _style(color, Color.TRANSPARENT, 5)
	for box in [background,fill]:
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		box.content_margin_left = 0
		box.content_margin_right = 0
	p.add_theme_stylebox_override("background", background)
	p.add_theme_stylebox_override("fill", fill)
	parent.add_child(p)
	p.set_deferred("size",rect.size)
	return p

func _art(parent: Node, id: String, rect: Rect2, color: Color = CYAN) -> Control:
	var art:=Control.new()
	art.position=rect.position; art.size=rect.size; art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.draw.connect(func(): UISkin.draw_icon(art,id,Rect2(Vector2.ZERO,art.size),color))
	return art

func _portrait(parent: Node, id: String, rect: Rect2) -> Control:
	var art:=Control.new()
	art.position=rect.position; art.size=rect.size; art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.draw.connect(func(): UISkin.portrait(art,id,Rect2(Vector2.ZERO,art.size),total_time,false))
	var refresh:=Timer.new(); refresh.wait_time=0.1; refresh.autostart=true
	art.add_child(refresh); refresh.timeout.connect(art.queue_redraw)
	return art

func _build_hud() -> void:
	_panel(hud,Rect2(24,20,340,102),Color("1a2026"),Color("3d4c5e"))
	_portrait(hud,"tyron",Rect2(34,29,76,80))
	_label(hud,"TYRON / 前线协议",Vector2(120,28),Vector2(230,22),15,CYAN)
	hp_label=_label(hud,"",Vector2(120,53),Vector2(230,25),18)
	hp_bar=_bar(hud,Rect2(120,83,220,14),RED)
	var shield:=Control.new(); hud.add_child(shield)
	shield.draw.connect(func():
		shield.draw_rect(Rect2(120,102,220,4),Color("0e1217"))
		shield.draw_rect(Rect2(120,102,220*clampf(float(combat.get("engineer_shield",0))/30.0,0,1),4),CYAN))
	shield.set_meta("shield_hud",true)
	xp_bar=_bar(hud,Rect2(24,124,1232,4),GOLD)
	_panel(hud,Rect2(380,20,360,102),Color("0e1217"),Color("3d4c5e"))
	wave_label=_label(hud,"",Vector2(396,32),Vector2(330,30),23,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	time_label=_label(hud,"",Vector2(396,73),Vector2(330,28),19,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(hud,Rect2(756,20,240,102),Color("1a2026"),Color("3d4c5e"))
	_art(hud,"mineral",Rect2(771,31,26,26))
	cash_label=_label(hud,"",Vector2(804,29),Vector2(180,32),21,GOLD)
	weapon_label=_label(hud,"",Vector2(48,731),Vector2(930,24),14,DIM)
	var slots:=Control.new(); hud.add_child(slots)
	slots.draw.connect(func():
		for i in range(4):
			var r:=Rect2(771+i*52,70,46,38)
			UISkin.draw_panel(slots,r,GOLD if i<weapons.size() and int(weapons[i].level)>=3 else Color("3d4c5e"),Color("0e1217"),5)
			if i<weapons.size(): UISkin.draw_icon(slots,str(weapons[i].id),r.grow(-6),CYAN))
	slots.set_meta("shield_hud",true)
	stats_label=_label(hud,"",Vector2(48,758),Vector2(1160,25),16,DIM)
	dash_bar=_bar(hud,Rect2(1010,112,222,5),GREEN)
	pause_button=_button(hud,"暂停",Rect2(1010,26,95,80),_toggle_pause)
	sound_button=_button(hud,"声音 开",Rect2(1120,26,112,80),_toggle_sound,DIM)
	notice_label=_label(hud,"",Vector2(200,158),Vector2(880,50),28,GOLD,HORIZONTAL_ALIGNMENT_CENTER)

func _clear_overlay() -> void:
	ui_epoch += 1
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()

func _shade() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.03,0.05,0.92)
	shade.size = SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

func _show_menu() -> void:
	_reset_touch()
	state = "menu"
	paused = false
	hud.visible = false
	_clear_overlay()
	_label(overlay,"星际前线：孤军生还",Vector2(60,44),Vector2(1100,80),48,TEXT)
	_label(overlay,"V4.1  /  三大战区 · 三十波战役 · 休伯利安舰桥",Vector2(64,126),Vector2(1080,40),23,CYAN)
	for i in range(5):
		var x := 48.0 + i*239.0
		var chosen: bool = selected_class == CLASS_IDS[i]
		_panel(overlay,Rect2(x,210,226,280),Color("183546") if chosen else Color("102431"),CYAN if chosen else DIM)
		_art(overlay,CLASS_IDS[i],Rect2(x+20,228,34,34),GOLD if chosen else CYAN)
		_label(overlay,CLASS_NAMES[i],Vector2(x+57,226),Vector2(155,42),25,GOLD if chosen else TEXT,HORIZONTAL_ALIGNMENT_CENTER)
		var desc := _label(overlay,CLASS_DESCS[i],Vector2(x+16,286),Vector2(194,130),19,DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_button(overlay,"已选择" if chosen else "选择",Rect2(x+18,424,190,54),_select_class.bind(CLASS_IDS[i]),CYAN)
	_button(overlay,"开始新作战",Rect2(60,536,360,64),_confirm_new_run)
	var saved: Dictionary = Save.load_run(save_path)
	var resume := _button(overlay,"继续上次作战" + (" · 第 %d 波后" % int(saved.get("wave",0)) if not saved.is_empty() else ""),Rect2(446,536,400,64),_resume_run,GOLD)
	resume.disabled = saved.is_empty()
	_button(overlay,"触控 " + ("开" if touch_mode else "关"),Rect2(872,536,320,64),_toggle_touch,DIM)
	_button(overlay,"军械库 / 卡片精研",Rect2(60,620,360,58),_show_bridge,GOLD)
	_button(overlay,"通讯日志",Rect2(446,620,300,58),_show_radio_log,DIM)
	_label(overlay,"瓦斯 %d · 基因 %d" % [int(profile.get("gas",0)),int(profile.get("genes",0))],Vector2(780,620),Vector2(420,58),22,GREEN)
	_label(overlay,"左侧移动 · 右侧冲刺 · 游骑兵兴奋剂 · 自动攻击\n升级在波末选择，补给购物后自动保存。战斗中退出将回到上个补给站。",Vector2(64,686),Vector2(1130,48),17,DIM)
	_label(overlay,"非官方同人原型 · AI辅助美术 / 程序化美术 · 全程离线  |  " + save_notice,Vector2(64,737),Vector2(1130,30),16,DIM)

func _select_class(id: String) -> void:
	selected_class = id
	_show_menu()

func _confirm_new_run() -> void:
	if Save.load_run(save_path).is_empty():
		start_run()
		return
	_clear_overlay()
	_shade()
	_label(overlay,"已有补给站存档",Vector2(290,230),Vector2(700,80),40,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"开始新作战会替换上次进度。",Vector2(290,330),Vector2(700,50),24,DIM,HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay,"保留并返回",Rect2(290,440,320,70),_show_menu,DIM)
	_button(overlay,"确认新作战",Rect2(650,440,320,70),start_run,RED)

func _toggle_touch() -> void:
	# Keep touch controls available on devices without a keyboard.
	touch_mode = true if OS.has_feature("mobile") else not touch_mode
	_reset_touch()
	_show_menu()

func _toggle_sound() -> void:
	var muted: bool = sound.toggle_muted()
	if is_instance_valid(radio): radio.muted=muted
	sound_button.text = "声音 " + ("关" if muted else "开")

func start_run() -> void:
	if is_instance_valid(radio): radio.clear_queue()
	state = "menu"
	build = Build.new_run(selected_class)
	run_id = "%d-%d" % [Time.get_unix_time_from_system()*1000,rng.randi()]
	Meta.start_run(profile,build)
	build.run_id = run_id
	bark_times.clear()
	last_damage_source="unknown"
	class_id = selected_class
	kills = 0
	wave = 0
	level = 1
	xp = 0
	xp_needed = int(build.get("xp_needed",15))
	cash = int(build.get("cash",0))
	_apply_stats()
	hp = max_hp
	_reset_world()
	if not test_mode and not auto_test: Save.clear_run(save_path)
	start_wave()

func _reset_world() -> void:
	enemies.clear()
	bullets.clear()
	acid.clear()
	particles.clear()
	drops.clear()
	popups.clear()
	hazards.clear()
	combat.clear()
	player = ARENA.get_center()
	hurt_timer = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	dash_charges = 1+extra_dash
	overcharge_timer = 0.0
	overcharge_points = 0
	stim_timer = 0.0
	stim_cooldown = 0.0
	stationary_time = 0.0
	paused = false
	_reset_touch()
	telemetry = {"shots":0,"damage_dealt":0.0,"damage_taken":0.0,"purchases":0,"dashes":0}
	hud.visible = true

func _apply_stats() -> void:
	var stats: Dictionary = Build.recompute(build)
	for key in stats:
		if key in ["max_hp","armor","base_speed","damage_mult","attack_mult","speed_mult","pickup_radius","regen","crit_rate","crit_mult","lifesteal","dodge","range_mult","harvesting","ballistic_damage_mult","ballistic_attack_mult","pierce_bonus","hurt_extra","hurt_invuln","heal_cost_mult","wave_subsidy","enemy_scale","extra_dash","turret","revive","magnet_bonus","synergies","support_attack_mult","rifle_branch_penalty"]:
			set(key,stats[key])
	weapons = build.weapons
	items = build.items
	supports = build.get("supports",[])
	hp = minf(hp,max_hp)

func _sync_build() -> void:
	build.hp = hp
	build.cash = cash
	build.wave = wave
	build.level = level
	build.xp = xp
	build.xp_needed = xp_needed
	build.kills = kills
	build.rng_state = str(rng.state)
	build.run_id = run_id

func _persist_checkpoint() -> bool:
	if test_mode or auto_test or build.is_empty(): return true
	_sync_build()
	if not Save.save_run(build,save_path):
		save_notice = "存档写入失败，请勿退出"
		_notify(save_notice,5)
		return false
	return true

func _resume_run() -> void:
	var data: Dictionary = Save.load_run(save_path)
	if data.is_empty():
		save_notice = "存档不可读或版本不兼容"
		_show_menu()
		return
	build = data
	run_id = str(build.get("run_id","legacy-%s" % JSON.stringify(data).sha256_text().substr(0,16)))
	class_id = str(build.class_id)
	selected_class = class_id
	wave = int(build.wave)
	level = int(build.level)
	xp = int(build.xp)
	xp_needed = int(build.xp_needed)
	cash = int(build.cash)
	hp = float(build.hp)
	kills = int(build.get("kills",0))
	_apply_stats()
	_reset_world()
	if build.has("rng_state"): rng.state = int(build.rng_state)
	state = "shop"
	_advance_checkpoint_ui()

func start_wave() -> void:
	hud.visible=true
	if state == "wave" or wave >= 30: return
	if not build.is_empty() and (int(build.get("pending_levels",0))>0 or _pending_branch()>=0):
		_advance_checkpoint_ui()
		return
	_clear_overlay()
	state = "wave"
	paused = false
	_reset_touch()
	wave += 1
	phase_time = float(Combat.DURATIONS[wave-1])
	intro_timer = 3.0 if not test_mode and not auto_test else 0.0
	_radio_wave("start")
	boss_spawned = false
	boss_dead = false
	enemies.clear()
	acid.clear()
	bullets.clear()
	hazards.clear()
	hurt_timer = 1.5
	dash_charges = 1+extra_dash
	dash_cooldown = 0.0
	Combat.reset_wave(self)
	_notify("第 %02d 波 · %s" % [wave,Combat.wave_name(wave)],3.0)
	sound.play_sfx("wave")
	_update_hud()

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	total_time += dt
	if state == "wave" and not paused:
		if joystick_id>=0 or mouse_joystick:
			_set_joystick_position(joystick_finger,1.0-exp(-18.0*dt))
		if intro_timer>0:
			intro_timer=maxf(0,intro_timer-dt)
		else:
			_update_game(dt)
	if not paused:
		_update_effects(dt)
		shake = maxf(0.0, shake-dt*30.0)
		weapon_flash = maxf(0.0, weapon_flash-dt*9.0)
		notice_timer = maxf(0.0, notice_timer-dt)
		notice_label.modulate.a = minf(1.0,notice_timer*2.0)
	if state == "wave":
		_update_hud()
	if auto_test:
		_autoplay(dt)
	queue_redraw()

func _movement_input() -> Vector2:
	if auto_test:
		var desired := Vector2(cos(total_time*0.8)*400.0, sin(total_time*0.8)*200.0)+ARENA.get_center()
		var avoidance := Vector2.ZERO
		for e in enemies:
			var diff: Vector2 = player-e.p
			if diff.length() < 110:
				avoidance += diff.normalized() * (110.0-diff.length())/45.0
		return ((desired-player).normalized()+avoidance).limit_length(1.0)
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): v.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): v.x += 1
	if joystick_vector.length() > 0.1: v = joystick_vector
	return v.limit_length(1.0)

func _update_game(dt: float) -> void:
	if not Combat.is_boss_wave(wave): phase_time = maxf(0.0,phase_time-dt)
	hurt_timer = maxf(0.0,hurt_timer-dt)
	dash_timer = maxf(0.0,dash_timer-dt)
	dash_cooldown = maxf(0.0,dash_cooldown-dt)
	stim_timer = maxf(0.0,stim_timer-dt)
	stim_cooldown = maxf(0.0,stim_cooldown-dt)
	overcharge_timer = maxf(0.0,overcharge_timer-dt)
	if dash_cooldown<=0 and dash_charges<1+extra_dash:
		dash_charges += 1
		if dash_charges<1+extra_dash: dash_cooldown = _dash_interval()
	var movement := _movement_input()
	moving = movement.length_squared()>0.01
	stationary_time = 0.0 if moving else stationary_time+dt
	if dash_timer>0:
		player += dash_dir*740.0*dt
		_emit(player,Vector2.ZERO,CYAN,7,0.25,1)
	else:
		player += movement*(0.92 if wave>=21 else 1.0)*base_speed*minf(1.7,speed_mult*(1.35 if stim_timer>0 else 1.0))*dt
	player = player.clamp(ARENA.position+Vector2(24,24),ARENA.end-Vector2(24,24))
	regen_clock += dt
	if regen_clock>=0.5:
		hp = minf(max_hp,hp+regen*0.5)
		regen_clock -= 0.5
	Combat.update(self,dt)
	_update_drops(dt)
	if state!="wave": return
	if not Combat.is_boss_wave(wave) and phase_time<=0: finish_wave()
	elif Combat.is_boss_wave(wave) and boss_dead:
		if wave==30: _end_run(true)
		else: finish_wave()

func _spawn_enemy(kind: String, point := Vector2(-999,-999)) -> Dictionary:
	return Combat.spawn_enemy(self,kind,point)

func _update_enemies(dt: float) -> void:
	Combat.update_enemies(self,dt)

func _add_acid(pos: Vector2, velocity: Vector2, damage: float) -> void:
	acid.append({"p":pos,"v":velocity,"life":7.0,"r":7.0,"dmg":damage})

func _nearest(range_limit: float) -> Dictionary:
	var target: Dictionary = {}
	var distance := range_limit*range_limit
	for e in enemies:
		if e.hp <= 0 or e.warmup > 0: continue
		var d: float = player.distance_squared_to(e.p)
		if d < distance:
			distance = d
			target = e
	return target

func _update_weapons(dt: float) -> void:
	Combat.update_weapons(self,dt)

func _fire_bullet(angle: float, speed: float, damage: float, life: float, color: Color, pierce: int, kind: String) -> void:
	var dir := Vector2.from_angle(angle)
	bullets.append({"p":player+dir*27.0,"prev":player+dir*27.0,"v":dir*speed,"dmg":damage,"life":life,"max_life":life,"color":color,"pierce":pierce,"kind":kind,"hit":[],"r":4.0 if kind != "flame" else 14.0})
	telemetry.shots += 1

func _update_bullets(dt: float) -> void:
	Combat.update_bullets(self,dt)

func _hit_enemy(e: Dictionary, damage: float, direction: Vector2, kind: String) -> void:
	Combat.hit_enemy(self,e,damage,direction,kind)

func _kill_enemy(e: Dictionary) -> void:
	Combat.kill_enemy(self,e)

func _gain_xp(amount: int) -> void:
	_sync_build()
	var previous: int = level
	Build.gain_xp(build,amount)
	level = int(build.level)
	xp = int(build.xp)
	xp_needed = int(build.xp_needed)
	if level>previous:
		_notify("等级 %d · 波末领取三选一升级" % level,2)
		sound.play_sfx("level")

func _hurt_player(amount: float) -> void:
	Combat.hurt_player(self,amount)

func _update_drops(dt: float) -> void:
	for i in range(drops.size()-1,-1,-1):
		var d := drops[i]
		d.age += dt
		var distance: float = d.p.distance_to(player)
		if distance<pickup_radius:
			d.p = d.p.move_toward(player,dt*(360.0+260.0/maxf(1.0,distance/30.0)))
		if distance<24:
			if d.has("heal"):
				hp = minf(max_hp,hp+float(d.heal))
				drops.remove_at(i)
				if combat.has("drop_pool"): combat.drop_pool.append(d)
				continue
			var earned := maxi(1,int(round(float(d.value)*harvesting)))
			cash += earned
			build.total_earned = int(build.get("total_earned",0))+earned
			overcharge_points += 1
			if rng.randf()<0.20 and magnet_bonus>0: overcharge_points += 1
			if overcharge_points>=10:
				overcharge_points -= 10
				overcharge_timer = 3.0
				v4_event("overcharge")
			if int(synergies.get("hightech",0))>=4:
				for w in weapons:
					if "hightech" in Build.weapon_tags(str(w.id)): w.cooldown = float(w.cooldown)*0.9
			drops.remove_at(i)
			if combat.has("drop_pool"): combat.drop_pool.append(d)
			if i%3==0: sound.play_sfx("pickup",-15.0)

func _dash_interval() -> float:
	return float(Build.recompute(build).get("dash_cooldown",3.5))

func _dash() -> void:
	if state!="wave" or paused or dash_charges<=0: return
	var dir := _movement_input()
	if dir.length()<0.1: dir = Vector2.from_angle(facing)
	dash_dir = dir.normalized()
	dash_timer = 0.20
	dash_charges -= 1
	if dash_cooldown<=0: dash_cooldown = _dash_interval()
	telemetry.dashes += 1
	Combat.dash_effect(self)
	sound.play_sfx("dash",-2.0)

func _stim() -> void:
	if state!="wave" or paused or class_id!="marine" or stim_cooldown>0: return
	hp = maxf(1.0,hp*0.85)
	v4_event("stim")
	stim_timer = 5.0
	stim_cooldown = 12.0
	_notify("兴奋剂 · 射速 +45% / 移速 +35%",2)
	sound.play_sfx("level",-8)

func finish_wave() -> void:
	if state!="wave": return
	if not _reward_meta(false): return
	_radio_wave("end")
	shop_roll_count=0
	var salvage := 0
	for d in drops: salvage += int(d.value)
	var reward := int(floor(salvage*float(Build.recompute(build).get("salvage_rate",0.75)))) + 25 + wave*5 + wave_subsidy
	cash += reward
	build.total_earned = int(build.get("total_earned",0))+reward
	drops.clear()
	enemies.clear()
	bullets.clear()
	acid.clear()
	hazards.clear()
	hp = minf(max_hp,hp+max_hp*0.12)
	best_wave = maxi(best_wave,wave)
	_save_progress()
	state = "shop"
	_reset_touch()
	_sync_build()
	build.reroll_cost = 8
	Build.roll_shop(build,rng)
	_persist_checkpoint()
	_advance_checkpoint_ui()
	sound.play_sfx("wave")

func _roll_offers() -> void:
	_sync_build()
	Build.roll_shop(build,rng)

func _offer(key: String) -> Dictionary:
	return {"name":key,"description":"","cost":0}

func _rich_description(parent: Node, value: String, rect: Rect2, font_size: int=18) -> RichTextLabel:
	var label:=RichTextLabel.new()
	label.position=rect.position; label.size=rect.size
	label.bbcode_enabled=true; label.scroll_active=false; label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size",font_size)
	var lines:=PackedStringArray()
	for part in value.replace("；","\n").split("\n"):
		var negative:=part.contains("降低") or part.contains("减少") or part.contains("代价") or part.contains(" -") or part.contains("−") or part.contains("费用+") or part.contains("额外承受") or part.contains("后续敌人") or part.contains("缩短")
		lines.append("[color=#ff677a]"+part+"[/color]" if negative else "[color=#64e5ed]"+part+"[/color]")
	label.text="\n".join(lines)
	parent.add_child(label)
	return label

func _shop_portrait(id: String) -> void:
	shop_speaker=id
	_show_shop()

func _show_shop() -> void:
	hud.visible=false
	state="shop"
	paused=false
	_clear_overlay()
	_shade()
	_label(overlay,"战地补给 / 第 %02d 波完成" % wave,Vector2(48,24),Vector2(850,48),32,TEXT)
	_label(overlay,"矿晶 %d   生命 %d/%d   护甲 %.0f   暴击 %d%%" % [cash,ceili(hp),int(max_hp),armor,int(crit_rate*100)],Vector2(48,80),Vector2(1170,35),21,GOLD)
	_panel(overlay,Rect2(44,135,238,475),Color("1a2026"),Color("3d4c5e"))
	_portrait(overlay,shop_speaker,Rect2(59,150,208,208))
	var names:={"hank":"汉克 / 军械补给","ella":"艾拉 / 战地医疗","collins":"柯林斯 / 战术指挥","adjutant":"副官 / 作战分析"}
	_label(overlay,names[shop_speaker],Vector2(60,368),Vector2(205,32),19,GOLD)
	var quote:={"hank":"装备已校准。先确认代价，再扣动扳机。","ella":"活着回来。医疗补给随时待命。","collins":"四个武器槽，选好你的作战路线。","adjutant":"补给站状态稳定。锁定可保留当前商品。"}
	var speech:=_label(overlay,quote[shop_speaker],Vector2(60,408),Vector2(205,90),19,TEXT)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for n in range(4):
		var id: String=["hank","ella","collins","adjutant"][n]
		_button(overlay,["军械","医疗","指挥","分析"][n],Rect2(57+(n%2)*108,490+int(n/2)*56,102,52),_shop_portrait.bind(id),GOLD if id==shop_speaker else DIM).add_theme_font_size_override("font_size",17)
	for i in range(4):
		var x:=298.0+i*235.0
		_panel(overlay,Rect2(x,135,224,303),Color("1a2026"),Color("3d4c5e"))
		if i>=build.offers.size() or build.offers[i].is_empty():
			_label(overlay,"已购买",Vector2(x+12,240),Vector2(200,60),25,DIM,HORIZONTAL_ALIGNMENT_CENTER)
			continue
		var offer: Dictionary=build.offers[i]
		var id:=str(offer.get("id",""))
		var icon:=id if offer.get("type","") in ["weapon","upgrade"] else "engineering"
		if offer.get("type","") in ["item","support"]: icon=id
		_art(overlay,icon,Rect2(x+14,150,48,44),GOLD)
		var title:=_label(overlay,Build.offer_label(offer),Vector2(x+72,146),Vector2(138,64),20,TEXT)
		title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_rich_description(overlay,Build.offer_description(offer),Rect2(x+14,220,196,138),18)
		var cost:=int(offer.get("cost",offer.get("price",0)))
		var buy:=_button(overlay,"购买 %d" % cost,Rect2(x+12,368,122,56),_purchase.bind(i),GOLD)
		buy.disabled=cash<cost
		_button(overlay,"已锁" if bool(build.locks[i]) else "锁定",Rect2(x+142,368,70,56),_lock_offer.bind(i),CYAN if bool(build.locks[i]) else DIM).add_theme_font_size_override("font_size",18)
		if bool(build.locks[i]): _art(overlay,"lock",Rect2(x+188,334,20,23),GOLD)
	_label(overlay,"武器槽 / 同类可多持 · Lv.3专精",Vector2(300,446),Vector2(925,30),18,CYAN)
	for i in range(4):
		var x:=298.0+i*235.0
		_panel(overlay,Rect2(x,482,224,128))
		if i<weapons.size():
			var w: Dictionary=weapons[i]
			_art(overlay,str(w.id),Rect2(x+12,492,34,30))
			_label(overlay,"%s %d%s" % [_weapon_name(w.id),int(w.level),str(w.get("branch","")).to_upper()],Vector2(x+50,489),Vector2(165,42),17,TEXT)
			_button(overlay,"回收 %d" % int(float(w.get("paid",0))*0.5),Rect2(x+12,542,200,56),_confirm_sell.bind(i),DIM)
		else: _label(overlay,"空槽 %d" % (i+1),Vector2(x+12,510),Vector2(200,42),21,DIM,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,_synergy_text(),Vector2(48,622),Vector2(870,34),17,GREEN)
	_button(overlay,"战备信道",Rect2(940,616,286,56),_shop_comms,CYAN)
	_button(overlay,("免费刷新 ×%d" % int(build.get("free_rerolls",0))) if int(build.get("free_rerolls",0))>0 else "刷新 ◆%d" % int(build.reroll_cost),Rect2(44,686,226,64),_reroll,CYAN)
	_button(overlay,"治疗 ◆%d" % ceili((18+wave*3)*heal_cost_mult),Rect2(288,686,226,64),_heal,GREEN)
	_button(overlay,"保存并退出",Rect2(532,686,226,64),_save_and_menu,DIM)
	_button(overlay,"下一波 →",Rect2(776,686,454,64),start_wave,GOLD)

func _weapon_name(id: String) -> String:
	return Build.WEAPON_NAMES.get(id,id)

func _synergy_text() -> String:
	var result: Array[String] = []
	for tag in ["ballistic","plasma","explosive","hightech","engineering"]:
		var n: int = int(synergies.get(tag,0))
		var name: String = {"ballistic":"实弹","plasma":"等离子","explosive":"高爆","hightech":"高科","engineering":"工程"}[tag]
		if n>0: result.append("%s %d/4%s" % [name,n," 已协同" if n>=2 else ""])
	return "   ·   ".join(result)

func _lock_offer(index: int) -> void:
	if state!="shop" or index>=build.offers.size(): return
	build.locks[index] = not bool(build.locks[index])
	_persist_checkpoint()
	_show_shop()

func _confirm_sell(index: int) -> void:
	if state!="shop" or index>=weapons.size(): return
	state = "sell_confirm"
	sell_uid = int(weapons[index].uid)
	_clear_overlay()
	_shade()
	_label(overlay,"回收 %s？" % _weapon_name(weapons[index].id),Vector2(300,250),Vector2(680,70),36,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"返还投入矿晶的 50%，该武器与专精将移除。",Vector2(260,340),Vector2(760,50),22,DIM,HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay,"取消",Rect2(300,440,300,70),_show_shop,DIM)
	_button(overlay,"确认回收",Rect2(660,440,300,70),_sell.bind(index),RED)

func _sell(index: int) -> void:
	if state!="sell_confirm" or index<0 or index>=weapons.size() or int(weapons[index].uid)!=sell_uid: return
	state = "shop"
	sell_uid = -1
	_sync_build()
	Build.sell(build,index)
	cash = int(build.cash)
	_apply_stats()
	_persist_checkpoint()
	_show_shop()

func _save_and_menu() -> void:
	if _persist_checkpoint(): _show_menu()

func _pending_branch() -> int:
	for i in range(weapons.size()):
		if int(weapons[i].level)>=3 and str(weapons[i].get("branch","" )).is_empty(): return i
	return -1

func _advance_checkpoint_ui() -> void:
	var branch_slot := _pending_branch()
	if branch_slot>=0:
		_show_branch(branch_slot)
	elif int(build.get("pending_levels",0))>0:
		if build.get("level_offers",[]).is_empty(): Build.roll_level(build,rng)
		_show_level()
	else:
		_show_shop()
	_persist_checkpoint()

func _show_branch(slot: int) -> void:
	hud.visible=false
	state = "branch"
	_clear_overlay()
	_shade()
	var w: Dictionary = weapons[slot]
	var id: String = w.id
	var options: Array = [["贫铀穿甲刺针","无限贯穿、射程 +15%\n伤害 -25%，后续目标逐步衰减"],["高精狙击","750 射程、高单发伤害和暴击\n射击间隔变长，击杀产生冲击波"]]
	if id=="shotgun": options = [["粉碎破片","12 枚弹丸，近距离暴击增伤\n范围限制为 200，散布增大"],["震荡重弹","3 枚大重弹，强力击退\n撞击其他敌人可短暂眩晕"]]
	if id=="flame": options = [["凝固地狱火","留下 1.5 秒焦土\n持续灼烧与点燃"],["低温冷焰","无限穿透、群体减速 40%\n伤害降低 20%"]]
	if id=="sniper": options=[["重型穿甲芯","伤害 +25%，贯穿4个目标\n射速降低15%"],["弱点解析","击杀产生范围冲击\n直接伤害降低10%"]]
	if id=="grenade": options=[["广域破片","爆炸半径 +40%\n伤害降低15%"],["震荡榴弹","爆炸短暂眩晕\n射速降低20%"]]
	if id=="tesla": options=[["扩散电网","链击7个目标\n伤害降低15%"],["强效麻痹","麻痹延长至0.8秒\n链击减少至3个目标"]]
	if id=="smg": options=[["过载弹匣","射速 +35%\n伤害降低15%"],["重型弹带","伤害 +15%，贯穿 +2\n射速降低20%"]]
	if id=="cannon": options=[["聚焦光束","伤害 +35%\n光束宽度降低35%"],["扩幅光束","光束宽度 +80%\n伤害降低20%"]]
	var canonical_desc: Array=Build.branch_descriptions(id)
	for i in range(2): options[i][1]=canonical_desc[i]
	_label(overlay,"Lv.3 战地改装协议",Vector2(220,140),Vector2(840,70),42,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"槽位 %d · %s · 两条路线互斥，选择后不可更改" % [slot+1,_weapon_name(id)],Vector2(180,225),Vector2(920,45),22,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(2):
		var x := 140.0+i*520.0
		_panel(overlay,Rect2(x,320,480,270))
		_label(overlay,options[i][0],Vector2(x+25,340),Vector2(430,50),30,CYAN)
		_rich_description(overlay,options[i][1],Rect2(x+25,410,430,90),22)
		_art(overlay,id,Rect2(x+385,325,60,60),GOLD)
		_button(overlay,"选择路线 " + ["A","B"][i],Rect2(x+25,515,430,60),_choose_branch.bind(slot,["a","b"][i]),GOLD)

func _choose_branch(slot: int, branch: String) -> void:
	if state!="branch": return
	if Build.select_branch(build,slot,branch):
		_apply_stats()
		_persist_checkpoint()
		_advance_checkpoint_ui()

func _show_level() -> void:
	hud.visible=false
	state = "level"
	_clear_overlay()
	_shade()
	_label(overlay,"战地晋升 · 三选一",Vector2(220,100),Vector2(840,70),42,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"待领取 %d 次 · 已保留当前随机结果，退出不会刷新" % int(build.pending_levels),Vector2(180,185),Vector2(920,40),22,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(mini(3,build.level_offers.size())):
		var card_id: String = build.level_offers[i]
		var o: Dictionary = Build.LEVEL_CARDS[card_id]
		var x := 80.0+i*380.0
		_panel(overlay,Rect2(x,275,360,310))
		_art(overlay,card_id,Rect2(x+24,309,50,50),GOLD)
		_label(overlay,str(o.name),Vector2(x+86,300),Vector2(250,60),25,CYAN)
		var desc := _label(overlay,str(o.desc),Vector2(x+22,380),Vector2(316,112),22,DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_button(overlay,"选择此升级",Rect2(x+22,510,316,60),_choose_level.bind(i),GOLD)
	var rolls: int = int(build.get("level_rerolls",0))
	var cost := 0 if rolls==0 else 5*rolls
	var reroll_button := _button(overlay,"刷新已用完" if rolls>=3 else ("免费刷新" if cost==0 else "刷新 ◆%d" % cost),Rect2(360,640,300,64),_reroll_level)
	reroll_button.disabled = rolls>=3
	_button(overlay,"保存并退出",Rect2(690,640,250,64),_save_and_menu,DIM)

func _choose_level(index: int) -> void:
	if state!="level": return
	_sync_build()
	if Build.apply_level(build,index):
		hp = float(build.hp)
		_apply_stats()
		_persist_checkpoint()
		_advance_checkpoint_ui()

func _reroll_level() -> void:
	if state!="level": return
	_sync_build()
	if Build.reroll_level(build,rng):
		cash = int(build.cash)
		_persist_checkpoint()
		_show_level()

func _purchase(index: int) -> bool:
	if state!="shop": return false
	_sync_build()
	var result: Dictionary = Build.buy(build,index)
	if not bool(result.get("ok",false)): return false
	cash = int(build.cash)
	hp = float(build.hp)
	_apply_stats()
	telemetry.purchases += 1
	sound.play_sfx("buy")
	_persist_checkpoint()
	_advance_checkpoint_ui()
	return true

func _heal() -> void:
	if state!="shop": return
	var cost := ceili((18+wave*3)*heal_cost_mult)
	if cash<cost or hp>=max_hp: return
	cash -= cost
	hp = minf(max_hp,hp+max_hp*0.45)
	_persist_checkpoint()
	_show_shop()

func _reroll() -> void:
	if state!="shop": return
	_sync_build()
	if Build.reroll_shop(build,rng):
		cash = int(build.cash)
		shop_roll_count+=1
		if shop_roll_count==3: _shop_comms()
		_persist_checkpoint()
		_show_shop()

func _toggle_pause() -> void:
	if state!="wave": return
	paused = not paused
	pause_button.text = "继续" if paused else "暂停"
	_clear_overlay()
	_reset_touch()
	if paused:
		_shade()
		_label(overlay,"通讯暂停",Vector2(340,240),Vector2(600,65),42,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
		_label(overlay,"喘口气。你的战线还在。",Vector2(340,319),Vector2(600,40),22,DIM,HORIZONTAL_ALIGNMENT_CENTER)
		_button(overlay,"返回战线",Rect2(440,400,400,60),_toggle_pause)
		_button(overlay,"结束本次作战",Rect2(440,480,400,50),_abandon,RED)

func _abandon() -> void:
	paused = false
	pause_button.text = "暂停"
	if not test_mode and not auto_test: Save.clear_run(save_path)
	_show_menu()

func _end_run(victory: bool) -> void:
	if state in ["dead","victory"]: return
	if victory and not _reward_meta(true): return
	profile.last_death=last_damage_source
	if not test_mode and not auto_test: Meta.save_profile(profile,meta_path)
	if victory: _radio_wave("end")
	else: _radio_play(Narrative.bridge(last_damage_source if last_damage_source in ["baneling","lurker","boss"] else "defeat"))
	if not test_mode and not auto_test: Save.clear_run(save_path)
	_reset_touch()
	state = "victory" if victory else "dead"
	best_wave = maxi(best_wave,wave)
	if victory: wins += 1
	_save_progress()
	_clear_overlay()
	_shade()
	_label(overlay,"SIGNAL RESTORED" if victory else "SIGNAL LOST",Vector2(340,180),Vector2(600,35),19,CYAN if victory else RED,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"撤离成功" if victory else "战线失守",Vector2(300,240),Vector2(680,80),62,TEXT,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"虫群之心已被摧毁。你守住了最后的信标。" if victory else "装甲可以重铸。下一次，带上更强的火力。",Vector2(250,337),Vector2(780,40),21,DIM,HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay,"波次 %02d / 30    ·    消灭 %d    ·    等级 %d" % [wave,kills,level],Vector2(300,406),Vector2(680,35),24,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay,"再次部署",Rect2(440,488,400,62),start_run,CYAN)
	_button(overlay,"返回指挥室",Rect2(440,572,400,48),_show_menu,DIM)
	sound.play_sfx("victory" if victory else "defeat")

func _notify(message: String, duration: float) -> void:
	notice_label.text = message
	notice_timer = duration
	notice_label.modulate.a = 1.0

func _update_hud() -> void:
	hp_label.text = "生命 %d/%d · Lv.%d" % [ceili(hp),int(max_hp),level]
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	xp_bar.max_value = xp_needed
	xp_bar.value = xp
	wave_label.text = "第 %02d/30 波 · %s" % [wave,Combat.wave_name(maxi(1,wave))]
	time_label.text = "生存 %02d 秒 · 升级待选 %d" % [ceili(phase_time),int(build.get("pending_levels",0))] if not Combat.is_boss_wave(wave) else "首领决战 · 第 %d 阶段" % int(combat.get("boss_phase",1))
	time_label.add_theme_color_override("font_color",RED if phase_time<=5 and not Combat.is_boss_wave(wave) else GOLD)
	cash_label.text = "%d  /  瓦斯%d" % [cash,int(profile.get("gas",0))]
	for child in hud.get_children():
		if child.has_meta("shield_hud"): child.queue_redraw()
	var names: Array[String] = []
	for w in weapons: names.append("%s%d%s" % [_weapon_name(w.id),int(w.level),str(w.get("branch","" )).to_upper()])
	weapon_label.text = " / ".join(names)
	stats_label.text = "%s · 护甲%.0f · 击杀%d · 超频 %s" % [_synergy_text(),armor,kills,("%.1fs" % overcharge_timer) if overcharge_timer>0 else "%d/10" % overcharge_points]
	dash_bar.value = 100.0 if dash_charges>0 else (1.0-dash_cooldown/_dash_interval())*100.0

func _reset_touch() -> void:
	joystick_id = -1
	joystick_vector = Vector2.ZERO
	joystick_origin = Vector2(155, 625)
	joystick_position = joystick_origin
	mouse_joystick = false
	right_touches.clear()

func _pause_for_focus_loss() -> void:
	_reset_touch()
	if is_instance_valid(pause_button) and state == "wave" and not paused:
		_toggle_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause_for_focus_loss()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "wave":
			_toggle_pause()
		elif state == "dead" or state == "victory":
			_show_menu()

func _set_joystick_position(pos: Vector2, follow: float = 0.35) -> void:
	joystick_finger = pos
	var diff := pos-joystick_origin
	if diff.length()>JOYSTICK_RADIUS:
		joystick_origin = joystick_origin.lerp(pos-diff.normalized()*JOYSTICK_RADIUS,follow)
	joystick_position = joystick_origin+(pos-joystick_origin).limit_length(JOYSTICK_RADIUS)
	joystick_vector = (joystick_position-joystick_origin)/JOYSTICK_RADIUS

func _update_safe_area() -> void:
	if DisplayServer.get_name()=="headless": return
	var rect := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if rect.size.x<=0 or screen.x<=0: return
	# Fixed 1280x800 canvas uses letterboxing. Convert display safe edges to
	# canvas coordinates, subtract letterbox margins before adding any inset.
	var scale_factor := minf(float(screen.x)/SIZE.x,float(screen.y)/SIZE.y)
	if scale_factor<=0: return
	var margin := (Vector2(screen)-SIZE*scale_factor)*0.5
	safe_left = clampf((float(rect.position.x)-margin.x)/scale_factor,0,100)
	safe_right = clampf((float(screen.x-rect.end.x)-margin.x)/scale_factor,0,100)
	safe_top = clampf((float(rect.position.y)-margin.y)/scale_factor,0,50)
	safe_bottom = clampf((float(screen.y-rect.end.y)-margin.y)/scale_factor,0,50)
	if is_instance_valid(radio): radio.apply_safe_area(safe_left,safe_right,safe_top,safe_bottom)
	# A global inward scale keeps every overlay/HUD element inside the safe area.
	var root_control: Control = ui.get_child(0)
	root_control.position = Vector2(safe_left,safe_top)
	root_control.scale = Vector2((SIZE.x-safe_left-safe_right)/SIZE.x,(SIZE.y-safe_top-safe_bottom)/SIZE.y)

func _dash_position() -> Vector2:
	return DASH_POSITION+Vector2(-safe_right,-safe_bottom)

func _stim_position() -> Vector2:
	return Vector2(1110-safe_right,420+safe_top)

func _can_joystick(pos: Vector2) -> bool:
	return pos.x>=safe_left and pos.x<SIZE.x*0.5 and pos.y>145+safe_top and pos.y<SIZE.y-safe_bottom

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_SPACE: _dash()
		if event.physical_keycode==KEY_E: _stim()
		if event.physical_keycode==KEY_ESCAPE or event.physical_keycode==KEY_P: _toggle_pause()
		if event.physical_keycode==KEY_M: _toggle_sound()
	if event is InputEventScreenTouch and (not event.pressed or event.canceled):
		if event.index==joystick_id:
			joystick_id=-1
			joystick_vector=Vector2.ZERO
			joystick_position=joystick_origin
		right_touches.erase(event.index)
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if mouse_joystick: _reset_touch()
		return
	if is_instance_valid(radio) and (event is InputEventScreenTouch or event is InputEventMouseButton) and radio.blocks_pointer(event.position): return
	if state!="wave" or paused or not touch_mode: return
	if event is InputEventScreenTouch:
		if _can_joystick(event.position) and joystick_id<0:
			joystick_id=event.index
			mouse_joystick=false
			joystick_origin=event.position
			_set_joystick_position(event.position)
		elif event.position.distance_to(_stim_position())<=65 and class_id=="marine":
			_stim()
		elif event.position.distance_to(_dash_position())<=DASH_RADIUS+15.0:
			_dash()
		elif event.position.x>SIZE.x*0.5 and event.position.y>145+safe_top:
			right_touches[event.index]={"origin":event.position,"time":Time.get_ticks_msec(),"fired":false}
	if event is InputEventScreenDrag:
		if event.index==joystick_id:
			_set_joystick_position(event.position)
		elif right_touches.has(event.index):
			var swipe: Dictionary = right_touches[event.index]
			if not swipe.fired and event.position.distance_to(swipe.origin)>=65 and Time.get_ticks_msec()-int(swipe.time)<450:
				swipe.fired=true
				_dash()
	if event is InputEventMouse and (event.device==-1 or OS.has_feature("mobile")): return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if _can_joystick(event.position) and joystick_id<0:
			mouse_joystick=true
			joystick_origin=event.position
			_set_joystick_position(event.position)
		elif event.position.distance_to(_stim_position())<=65 and class_id=="marine": _stim()
		elif event.position.distance_to(_dash_position())<=DASH_RADIUS+15.0: _dash()
	if event is InputEventMouseMotion and mouse_joystick: _set_joystick_position(event.position)

func _emit(pos: Vector2, velocity: Vector2, color: Color, radius: float, life: float, count: int) -> void:
	for i in range(count):
		if particles.size()>=350: break
		particles.append({"p":pos,"v":velocity+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(20,110),"color":color,"r":radius*rng.randf_range(0.6,1.4),"life":life,"max_life":life})

func _update_effects(dt: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var p := particles[i]
		p.life -= dt
		p.p += p.v*dt
		p.v *= 1.0-dt*3.0
		if p.life<=0: particles.remove_at(i)
	for i in range(popups.size()-1,-1,-1):
		popups[i].life -= dt
		popups[i].p.y -= dt*40.0
		if popups[i].life<=0: popups.remove_at(i)

func _draw() -> void:
	_draw_arena()
	if state=="menu":
		_draw_menu_art()
		return
	var offset := Vector2.ZERO
	if shake>0: offset = Vector2(sin(total_time*81),cos(total_time*67))*shake
	draw_set_transform(offset)
	for d in drops:
		var p: Vector2 = d.p
		var bob: float = sin(total_time*4.0+d.age)*2.0
		if d.has("heal"):
			draw_circle(p,13,Color(0.2,0.8,0.4,0.7))
			draw_line(p-Vector2(7,0),p+Vector2(7,0),Color.WHITE,4)
			draw_line(p-Vector2(0,7),p+Vector2(0,7),Color.WHITE,4)
			continue
		draw_circle(p,10,Color(0.35,0.9,1,0.08))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-7+bob),p+Vector2(5,bob),p+Vector2(0,7+bob),p+Vector2(-5,bob)]),CYAN)
	for a in acid:
		draw_circle(a.p,13,Color(0.55,1,0.3,0.1))
		draw_circle(a.p,7,Color("9ade6b"))
		draw_circle(a.p+Vector2(-2,-2),2,Color("e0ffbb"))
	for e in enemies:
		if e.warmup>0:
			draw_arc(e.p,e.r+10,0,TAU,30,Color(0.9,0.25,0.4,0.5),2)
			continue
		if not Combat.draw_enemy(self,e): Visuals.draw_enemy(self,e.p,e.kind,e.angle,total_time+e.id,e.flash)
		if e.hp<e.max_hp and e.kind!="boss":
			draw_line(e.p+Vector2(-e.r,-e.r-12),e.p+Vector2(e.r,-e.r-12),Color("263846"),4)
			draw_line(e.p+Vector2(-e.r,-e.r-12),e.p+Vector2(-e.r+2*e.r*maxf(0,e.hp/e.max_hp),-e.r-12),RED,3)
	for b in bullets:
		if b.kind=="flame":
			var alpha: float = b.life/b.max_life
			draw_circle(b.p,b.r,Color(1,0.25,0.05,alpha*0.25))
			draw_circle(b.p,b.r*0.6,Color(1,0.65,0.15,alpha*0.65))
			draw_circle(b.p,b.r*0.25,Color(1,0.94,0.65,alpha))
		else:
			draw_line(b.p-b.v.normalized()*17,b.p,b.color,3.0)
			draw_circle(b.p,2.2,Color.WHITE)
	if hurt_timer<=0 or int(hurt_timer*20)%2==0:
		Visuals.draw_marine(self,player,facing,total_time,moving,weapon_flash)
	if dash_timer>0: draw_arc(player,29,0,TAU,32,Color(0.4,0.95,1,0.8),2)
	for p in particles:
		var color: Color = p.color
		color.a = p.life/p.max_life
		draw_circle(p.p,p.r*color.a,color)
	for p in popups:
		var color: Color = p.color
		color.a = minf(1,p.life*3)
		draw_string(font,p.p,p.text,HORIZONTAL_ALIGNMENT_CENTER,60,17,color)
	Combat.draw_hazards(self)
	draw_set_transform(Vector2.ZERO)
	if Combat.is_boss_wave(wave) and state=="wave":
		for e in enemies:
			if e.kind=="boss":
				draw_style_box(_style(Color("111a25"),Color("61374f"),5),Rect2(390,215,500,30))
				draw_style_box(_style(Color("a84875"),Color.TRANSPARENT,5),Rect2(394,219,492*maxf(0,e.hp/e.max_hp),22))
				draw_string(font,Vector2(390,208),"%s  ·  %d / %d" % [Combat.wave_name(wave),maxi(0,int(e.hp)),int(e.max_hp)],HORIZONTAL_ALIGNMENT_CENTER,500,17,TEXT)
	if touch_mode and state=="wave" and not paused: _draw_touch_controls()
	if hp<max_hp*0.3 and state=="wave":
		draw_rect(Rect2(Vector2.ZERO,SIZE),Color(1,0.1,0.15,0.025+0.025*sin(total_time*5)))

func _draw_arena() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("07121d"))
	draw_rect(ARENA.grow(12),Color("142b38"))
	draw_rect(ARENA,[Color("0a1c28"),Color("291913"),Color("20152b")][clampi(int((maxi(1,wave)-1)/10),0,2)])
	for x in range(48,1233,48):
		draw_line(Vector2(x,142),Vector2(x,742),Color("102734"),1)
	for y in range(142,743,48):
		draw_line(Vector2(48,y),Vector2(1232,y),Color("102734"),1)
	for x in range(96,1230,192):
		for y in range(190,730,192):
			draw_line(Vector2(x-3,y),Vector2(x+3,y),Color("27414c"),1)
			draw_line(Vector2(x,y-3),Vector2(x,y+3),Color("27414c"),1)
	var center := ARENA.get_center()
	draw_arc(center,168,0,TAU,96,Color("18323f"),2)
	draw_arc(center,152,0,TAU,96,Color("142d3b"),1)
	for n in range(8):
		var a := n*TAU/8
		draw_line(center+Vector2.from_angle(a)*160,center+Vector2.from_angle(a)*176,Color("29414b"),3)
	var badge := PackedVector2Array([center+Vector2(0,-78),center+Vector2(56,-47),center+Vector2(43,35),center+Vector2(0,65),center+Vector2(-43,35),center+Vector2(-56,-47),center+Vector2(0,-78)])
	draw_polyline(badge,Color("1c3948"),5,true)
	draw_line(center+Vector2(-26,0),center+Vector2(26,0),Color("244351"),7)
	draw_line(center+Vector2(0,-30),center+Vector2(0,30),Color("244351"),7)
	for x in [50,1230]:
		draw_line(Vector2(x,150),Vector2(x,730),Color("315260"),3)
		for y in range(170,730,52):
			draw_line(Vector2(x-2,y),Vector2(x+2,y+17),Color("958055"),3)
	for y in [143,741]:
		draw_line(Vector2(60,y),Vector2(1220,y),Color("315260"),3)
	for p in [Vector2(62,155),Vector2(1218,155),Vector2(62,728),Vector2(1218,728)]:
		draw_circle(p,8,Color(0.25,0.9,1,0.10))
		draw_circle(p,3,CYAN)
	draw_string(font,Vector2(85,708),["01 / OUTPOST - KOPRULU","02 / MAGMA RIFT","03 / HIVE ABYSS"][clampi(int((maxi(1,wave)-1)/10),0,2)],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("294855"))

func _draw_menu_art() -> void:
	# Oversized original suit illustration with targeting rings.
	var p := Vector2(1015,400)
	for radius in [115,145,175]:
		draw_arc(p,radius,-PI*0.8,PI*0.8,80,Color("284552"),1.5)
	draw_arc(p,185,total_time*0.15,total_time*0.15+1.3,32,CYAN,3)
	Visuals.draw_marine(self,p,-PI/2-0.15,total_time,false,0,4.4)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(900,673),Vector2(1130,673),Color("38515d"),2)

func _draw_touch_controls() -> void:
	var origin := joystick_origin if joystick_id>=0 or mouse_joystick else Vector2(155+safe_left,635-safe_bottom)
	var knob := joystick_position if joystick_id>=0 or mouse_joystick else origin
	draw_circle(origin,JOYSTICK_RADIUS+8,Color(0.2,0.6,0.7,0.08))
	draw_arc(origin,JOYSTICK_RADIUS,0,TAU,48,Color(0.5,0.9,1,0.28),2)
	draw_circle(knob,32,Color(0.4,0.85,1,0.3))
	var pos := _dash_position()
	draw_circle(pos,DASH_RADIUS,Color(0.15,0.45,0.55,0.22))
	draw_arc(pos,DASH_RADIUS-1,-PI/2,TAU*(1-dash_cooldown/_dash_interval())-PI/2,40,CYAN if dash_charges>0 else DIM,3)
	UISkin.draw_icon(self,"dash",Rect2(pos-Vector2(28,53),Vector2(56,40)),CYAN)
	draw_string(font,pos+Vector2(-55,28),"冲刺 ×%d" % dash_charges if dash_charges>0 else "%.1f" % dash_cooldown,HORIZONTAL_ALIGNMENT_CENTER,110,24,TEXT)
	if class_id=="marine":
		pos=_stim_position()
		draw_circle(pos,65,Color(0.4,0.2,0.12,0.45))
		draw_arc(pos,64,0,TAU,40,GOLD if stim_cooldown<=0 else DIM,2)
		UISkin.draw_icon(self,"stim",Rect2(pos-Vector2(20,43),Vector2(40,35)),GOLD)
		draw_string(font,pos+Vector2(-52,23),"兴奋剂" if stim_cooldown<=0 else "%.1f" % stim_cooldown,HORIZONTAL_ALIGNMENT_CENTER,104,22,TEXT)

func _save_progress() -> void:
	if test_mode or auto_test: return
	var config := ConfigFile.new()
	config.set_value("progress","best_wave",best_wave)
	config.set_value("progress","wins",wins)
	config.save("user://progress.cfg")

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load("user://progress.cfg")==OK:
		best_wave = int(config.get_value("progress","best_wave",0))
		wins = int(config.get_value("progress","wins",0))

func _autoplay(dt: float) -> void:
	auto_test_clock += dt
	if state=="level": _choose_level(0)
	elif state=="branch": _choose_branch(_pending_branch(),"a")
	elif state=="shop":
		for i in range(4):
			if state=="shop": _purchase(i)
		if state=="shop":
			_heal()
			start_wave()
	if state=="wave":
		if _nearest(120).size()>0: _dash()
		if class_id=="marine" and hp>max_hp*0.5: _stim()
	if state in ["dead","victory"]:
		print("AUTOPLAY_RESULT ",JSON.stringify({"state":state,"wave":wave,"kills":kills,"hp":hp,"level":level,"weapons":weapons,"telemetry":telemetry}))
		get_tree().quit(0)

func _radio_play(lines: Array, priority: bool = false) -> void:
	if is_instance_valid(radio) and not test_mode and not auto_test:
		radio.play(lines,priority)

func _radio_wave(stage: String) -> void:
	_radio_play(Narrative.wave_lines(wave,stage),stage in ["phase2","phase3"])

func v4_event(id: String) -> void:
	if id in ["phase2","phase3"]:
		_radio_wave(id)
		return
	var now := Time.get_ticks_msec()/1000.0
	if now-float(bark_times.get(id,-100.0))<25.0: return
	bark_times[id]=now
	_radio_play(Narrative.bark(id))

func _reward_meta(victory: bool) -> bool:
	var before:=profile.duplicate(true)
	var reward:=Meta.reward(profile,run_id,wave,victory)
	if not bool(reward.ok): return true
	if not test_mode and not auto_test and not Meta.save_profile(profile,meta_path):
		profile=before
		_notify("舰桥资源写入失败；正在重试，请勿退出",5)
		return false
	return true

func _show_radio_log() -> void:
	if is_instance_valid(radio): radio.show_history()

func _shop_comms() -> void:
	_radio_play(Narrative.shop({"hp":hp,"max_hp":max_hp,"cash":cash,"rerolls":shop_roll_count}))

func _show_bridge() -> void:
	state="bridge"
	hud.visible=false
	_clear_overlay()
	_shade()
	_portrait(overlay,"adjutant",Rect2(1095,53,100,100))
	_label(overlay,"休伯利安 · 舰桥",Vector2(80,58),Vector2(820,60),40,TEXT)
	_label(overlay,"瓦斯 %d  ·  基因片段 %d" % [profile.get("gas",0),profile.get("genes",0)],Vector2(80,125),Vector2(1000,40),24,GOLD)
	_label(overlay,"完成每波获得资源；研发仅在下一局部署时生效，续局保留原配置。",Vector2(80,170),Vector2(1120,35),20,DIM)
	_button(overlay,"局外科技",Rect2(80,218,250,52),_bridge_switch.bind("tech"))
	_button(overlay,"卡片精研",Rect2(350,218,250,52),_bridge_switch.bind("mastery"))
	_button(overlay,"战地复盘",Rect2(620,218,250,52),_bridge_review)
	_button(overlay,"通讯日志",Rect2(890,218,310,52),_show_radio_log)
	var ids: Array=Meta.TECH_IDS if bridge_tab=="tech" else Meta.MASTERY_IDS
	var defs: Dictionary=Meta.TECH if bridge_tab=="tech" else Meta.MASTERY
	var start:=bridge_page*4
	for n in range(start,mini(start+4,ids.size())):
		var id: String=ids[n]
		var d: Dictionary=defs[id]
		var y:=292.0+(n-start)*91.0
		_panel(overlay,Rect2(80,y,1120,80))
		var lv:=int(profile.get(bridge_tab,{}).get(id,0))
		var maximum:=int(d.get("max",3))
		var cost:=Meta.tech_cost(profile,id) if bridge_tab=="tech" else Meta.mastery_cost(profile,id)
		_label(overlay,"%s  %d/%d" % [d.name,lv,maximum],Vector2(100,y+6),Vector2(740,32),23,CYAN)
		_label(overlay,str(d.desc),Vector2(100,y+39),Vector2(820,31),18,DIM)
		var b:=_button(overlay,"已满级" if cost<0 else "%d %s · 研发" % [cost,"瓦斯" if bridge_tab=="tech" else "基因"],Rect2(930,y+13,250,54),_bridge_buy.bind(id),GOLD)
		b.disabled=cost<0 or int(profile.get("gas" if bridge_tab=="tech" else "genes",0))<cost
	_button(overlay,"上一页",Rect2(80,685,200,52),_bridge_page.bind(-1))
	_button(overlay,"下一页",Rect2(300,685,200,52),_bridge_page.bind(1))
	_button(overlay,"返回指挥室",Rect2(870,685,330,52),_show_menu)

func _bridge_switch(tab: String) -> void:
	bridge_tab=tab
	bridge_page=0
	_show_bridge()

func _bridge_page(direction: int) -> void:
	bridge_page=clampi(bridge_page+direction,0,2 if bridge_tab=="tech" else 0)
	_show_bridge()

func _bridge_review() -> void:
	var cause:=str(profile.get("last_death",""))
	_radio_play(Narrative.bridge(cause if cause in ["baneling","lurker","boss"] else "welcome"))

func _bridge_buy(id: String) -> void:
	var before:=profile.duplicate(true)
	var ok:=Meta.buy_tech(profile,id) if bridge_tab=="tech" else Meta.buy_mastery(profile,id)
	if not ok: return
	if not test_mode and not auto_test and not Meta.save_profile(profile,meta_path):
		profile=before
		_notify("研发未保存，资源已退回",4)
		return
	_show_bridge()
	var line:="research"
	if id=="armor" and int(profile.tech.get(id,0))==5: line="armor_max"
	if id=="antenna" and int(profile.tech.get(id,0))==2: line="antenna"
	_radio_play(Narrative.bridge(line))
