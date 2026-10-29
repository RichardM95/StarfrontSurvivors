extends Node2D
## v0.5.0 — first-act validation slice. All UI commands delegate to the rule model.
const Data = preload("res://scripts/data_v5.gd")
const Build = preload("res://scripts/build_v5.gd")
const Combat = preload("res://scripts/combat_v5.gd")
const Save = preload("res://scripts/save_v5.gd")
const Meta = preload("res://scripts/meta_v5.gd")
const Sound = preload("res://scripts/audio.gd")
const Visuals = preload("res://scripts/visuals.gd")
const BG = Color("10161c")
const PANEL = Color("26313d")
const TEXT = Color("f0f4f7")
const MUTED = Color("b6c3cf")
const CYAN = Color("53d9f7")
const RED = Color("ff5968")
const GOLD = Color("ffcb70")
const GREEN = Color("8ae0c0")
const PURPLE = Color("e0b4f4")
var run: Dictionary = {}
var profile: Dictionary = {}
var settings: Dictionary = {}
var sim
var state = "bridge"
var bridge_tab = "出击"
var selected_class = "C01"
var selected_mode = "campaign"
var selected_techs: Array = []
var training_preset = true
var training_branch = "A"
var pressure_count = 35
var pressure_seconds = 60
var ui: CanvasLayer
var root_ui: Control
var page: Control
var modal: Control
var toast: Label
var toast_time = 0.0
var font = preload("res://assets/Interface.ttf")
var hud_labels: Dictionary = {}
var hp_bar: ProgressBar
var shield_bar: ProgressBar
var boss_bar: ProgressBar
var combat_time = 0.0
var shop_time = 0.0
var saved_ok = true
var profile_saved_ok = true
var sound: Node
var last_pickup_sound=0.0
var last_banter=0.0
var last_danger=0.0
var cost_text=""
var cost_time=0.0
var previous_skill_cd=0.0
var previous_active_value=0
var previous_warning_count=0
var low_hp_warned=false
var save_text = "已保存"
var load_result: Dictionary = {}
var touch_owners: Dictionary = {}
var move_finger = -999
var joystick_origin = Vector2.ZERO
var joystick_vector = Vector2.ZERO
var skill_held = false
var skill_cancel = false
var dash_held = false
var commands: Dictionary = {}
var comms_expanded = false
var countdown = 0.0
var countdown_resume = false
var notice_text = "守住信标。补给正在路上。"
var notice_time = 4.0
var result_success = false
var preview_mode = false
var setting_return = "bridge"
var layout_edit = false
var archive_filter = "全部"
var archive_kind = "武器"
var last_screen_size = Vector2.ZERO
var ui_rebuild_pending = false
var debug_density_scale = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sound=Sound.new(); add_child(sound)
	ui = CanvasLayer.new(); add_child(ui)
	root_ui = Control.new(); root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(root_ui)
	root_ui.theme = make_theme()
	profile = Save.load_profile()
	settings = profile.get("settings", {}).duplicate(true)
	for key in {"large_font":false,"left_handed":false,"low_fx":false,"reduced_motion":false,"banter":true,"control_scale":1.0,"dash_offset":[0,0],"skill_offset":[0,0],"danger_outline":true,"color_assist":false,"haptic_skill":true,"haptic_damage":true,"haptic_danger":true,"sound_danger":1.0,"sound_skill":0.7,"sound_pickup":0.4,"sound_voice":0.7,"opacity":1.0}:
		if not settings.has(key): settings[key] = {"large_font":false,"left_handed":false,"low_fx":false,"reduced_motion":false,"banter":true,"control_scale":1.0,"dash_offset":[0,0],"skill_offset":[0,0],"danger_outline":true,"color_assist":false,"haptic_skill":true,"haptic_damage":true,"haptic_danger":true,"sound_danger":1.0,"sound_skill":0.7,"sound_pickup":0.4,"sound_voice":0.7,"opacity":1.0}[key]
	load_result = Save.load_run()
	get_viewport().size_changed.connect(schedule_rebuild)
	show_bridge()
	var preview=""; var capture=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--v5-preview="): preview=arg.trim_prefix("--v5-preview=")
		if arg.begins_with("--v5-capture="): capture=arg.trim_prefix("--v5-capture=")
		if arg.begins_with("--v5-preview-density="): debug_density_scale=float(arg.trim_prefix("--v5-preview-density="))
		if arg=="--v5-preview-font130": settings.large_font=true
	if preview!="": call_deferred("preview_capture",preview,capture)

func make_theme() -> Theme:
	var t = Theme.new(); t.default_font = font; t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("8b9aa8"))
	for type in ["Button","CheckButton","OptionButton"]:
		t.set_stylebox("normal", type, box(Color("1d2b38"), Color("4b6376"), 1))
		t.set_stylebox("hover", type, box(Color("263c4b"), CYAN, 2))
		t.set_stylebox("pressed", type, box(Color("234958"), CYAN, 2))
		t.set_stylebox("disabled", type, box(Color("182029"), Color("455461"), 1))
		t.set_stylebox("focus", type, box(Color(0,0,0,0), CYAN, 2))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, Color("425261"), 1))
	t.set_stylebox("background", "ProgressBar", box(Color("0c1117"), Color("425261"), 1))
	t.set_stylebox("fill", "ProgressBar", box(CYAN, CYAN, 0))
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 12)
	t.set_constant("h_separation", "GridContainer", 14)
	t.set_constant("v_separation", "GridContainer", 14)
	return t

func box(fill: Color, edge: Color, border: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new(); s.bg_color = fill; s.border_color = edge
	s.set_border_width_all(border); s.set_corner_radius_all(5)
	s.content_margin_left = 16; s.content_margin_right = 16; s.content_margin_top = 12; s.content_margin_bottom = 12
	return s

func fs(n: int) -> int:
	return roundi(n * maxf(1.0,dp_scale()) * (1.3 if settings.get("large_font", false) else 1.0))

func label(text: String, size: int = 20, color: Color = TEXT, parent: Node = null) -> Label:
	var l = Label.new(); l.text = text; l.add_theme_font_size_override("font_size", fs(size)); l.add_theme_color_override("font_color", color); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.mouse_filter = Control.MOUSE_FILTER_IGNORE; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if parent: parent.add_child(l)
	return l

func button(text: String, callback: Callable, parent: Node, primary: bool = false) -> Button:
	var b = Button.new(); b.text = text; b.custom_minimum_size = Vector2(48*maxf(1,dp_scale()),maxf(56,48*dp_scale())); b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.add_theme_font_size_override("font_size", fs(18)); b.pressed.connect(callback,CONNECT_DEFERRED); b.focus_mode = Control.FOCUS_ALL
	if primary: b.add_theme_stylebox_override("normal", box(Color("234552"), CYAN, 2))
	parent.add_child(b); return b

func row(parent: Node) -> HBoxContainer:
	var h = HBoxContainer.new(); parent.add_child(h); return h

func adaptive_row(parent: Node, columns: int = 2) -> Container:
	if settings.get("large_font",false) or dp_scale()>1.2:
		var g=GridContainer.new(); g.columns=columns; parent.add_child(g); return g
	return row(parent)

func column(parent: Node) -> VBoxContainer:
	var v = VBoxContainer.new(); parent.add_child(v); return v

func spacer(parent: Node) -> Control:
	var c = Control.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.size_flags_stretch_ratio=0.15; parent.add_child(c); return c

func panel(parent: Node) -> VBoxContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(p); return column(p)

func safe_rect() -> Rect2:
	var sz = get_viewport_rect().size
	var unit=dp_scale()
	var margin = Vector4(maxf(18,12*unit),maxf(12,8*unit),maxf(18,12*unit),maxf(18,12*unit))
	if OS.has_feature("mobile"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = Vector2(DisplayServer.screen_get_size())
		if screen.x > 0 and screen.y > 0:
			var ratio = sz / screen
			margin.x += safe.position.x * ratio.x; margin.y += safe.position.y * ratio.y
			margin.z += (screen.x - safe.end.x) * ratio.x; margin.w += (screen.y - safe.end.y) * ratio.y
	return Rect2(Vector2(margin.x,margin.y), sz-Vector2(margin.x+margin.z,margin.y+margin.w))

func clear_page() -> void:
	if is_instance_valid(page): page.hide(); page.queue_free()
	if is_instance_valid(modal): modal.hide(); modal.queue_free()
	modal = null; hud_labels.clear()
	page = Control.new(); page.mouse_filter = Control.MOUSE_FILTER_IGNORE; root_ui.add_child(page); page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if is_instance_valid(toast): toast.hide(); toast.queue_free()
	toast = label("",18,GOLD); root_ui.add_child(toast); toast.visible = false
	toast.position = Vector2(30,get_viewport_rect().size.y-74); toast.size = Vector2(get_viewport_rect().size.x-60,56)

func page_body(title: String, subtitle: String = "") -> VBoxContainer:
	clear_page()
	var bg = ColorRect.new(); bg.color = Color("10161c"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_STOP; page.add_child(bg)
	var margins = MarginContainer.new(); page.add_child(margins); var safe = safe_rect(); margins.position = safe.position; margins.size = safe.size
	var outer = column(margins)
	var header = row(outer); label(title,28,TEXT,header); spacer(header)
	label("V0.5.0  /  验证切片",14,CYAN,header)
	if subtitle != "": label(subtitle,16,MUTED,outer)
	var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; outer.add_child(scroll)
	var body = column(scroll); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return body

func show_bridge() -> void:
	state = "bridge"; sim = null; touch_owners.clear(); move_finger=-999; joystick_vector = Vector2.ZERO
	var body = page_body("星际前线  /  孤军生还", "铸砂-IV · 人族后勤舱  |  第一幕 4 波 / 压力房 / 独立终局首领测试")
	var nav = GridContainer.new(); nav.columns=3 if dp_scale()>1.2 or settings.large_font else 5; body.add_child(nav)
	for tab in ["出击","军械档案","研究终端","人员通信"]:
		var t = tab; var b = button(tab,func(): bridge_tab = t; show_bridge(),nav,bridge_tab==tab); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("设置",func(): show_settings("bridge"),nav)
	match bridge_tab:
		"出击": bridge_sortie(body)
		"军械档案": bridge_archive(body)
		"研究终端": bridge_research(body)
		"人员通信": bridge_comms(body)

func bridge_sortie(body: VBoxContainer) -> void:
	var notice = Save.get_compatibility_notice()
	if notice != "": label(notice,16,GOLD,body)
	if profile.get("notice","")!="": label(str(profile.notice),17,GOLD,body)
	if profile.has("load_error"): label("局外档案损坏："+str(profile.load_error)+"。原数据保留，本次设置和解锁不能保存。",18,RED,body)
	if load_result.get("ok",false):
		var r = row(body); label(load_result.get("reason", "发现中断行动：恢复已保存进度"),16,GOLD,r)
		button("继续第 %d 波" % int(load_result.run.get("wave",1)), continue_run,r,true)
		button("放弃本局",func(): confirm_dialog("放弃中断行动？","未完成波次不结算；局外解锁与旧版档案保留。",func():
			if not preview_mode:
				var cleared=Save.clear_run()
				if not cleared.ok: notify(cleared.reason); return
			load_result = {}; show_bridge()),r)
	elif load_result.get("reason", "") != "": label(load_result.reason,16,GOLD,body)
	var cards = GridContainer.new(); cards.columns = 3 if not settings.large_font and dp_scale()<=1.2 else 2; body.add_child(cards)
	for id in Data.ACTIVE_CLASSES:
		var entry = Data.CLASSES[id]; var v = panel(cards)
		label(id + "  " + entry.name,23,CYAN if selected_class==id else TEXT,v)
		label("生命 %d  ·  护甲 %d  ·  移速 %du/s" % [entry.hp,entry.armor,entry.speed],16,MUTED,v)
		label(entry.benefit,18,TEXT,v)
		label("初武  " + Data.WEAPONS[entry.starter].name,18,GOLD,v)
		var c = id; button("✓ 已选中" if id==selected_class else "选择职业",func(): selected_class=c; selected_techs.clear(); show_bridge(),v,id==selected_class)
	var action = panel(body)
	label("行动范围",22,TEXT,action)
	label("本版开放第一幕 4 波。档案含完整设计内容，灰色条目尚未开放。训练不产研究数据。",18,MUTED,action)
	var modes = row(action)
	for m in [["campaign","第一幕出击"],["pressure","可调压力房"],["boss","W12 首领试场"]]:
		var mode_id = m[0]; var b = button(m[1],func(): selected_mode=mode_id; show_bridge(),modes,selected_mode==mode_id); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if selected_mode != "campaign":
		var preset = CheckButton.new(); preset.text="启用测试军械预设（非正常局经济进度）"; preset.button_pressed=training_preset; preset.custom_minimum_size.y=maxf(56,48*dp_scale()); preset.add_theme_font_size_override("font_size",fs(18)); action.add_child(preset)
		preset.toggled.connect(func(on): training_preset=on; show_bridge(),CONNECT_DEFERRED)
		if training_preset:
			var starter=Data.CLASSES[selected_class].starter
			label("初武 %s Lv3%s + W05狙击枪 Lv3B + S02医疗无人机"%[starter,training_branch],18,GOLD,action)
			var branches=row(action)
			for branch in ["A","B"]:
				var selected=branch
				button("初武分支 "+branch+" · "+Data.WEAPONS[starter].branches[branch].name,func(): training_branch=selected; show_bridge(),branches,branch==training_branch)
			label(Data.WEAPONS[starter].branches[training_branch].desc,17,MUTED,action)
		label("军械与生命仅在训练开始时初始化，战斗中不能重配；不作为完整12波平衡验收。",17,MUTED,action)
		label("训练科技 %d/3 · 选择仅用于本次演练" % selected_techs.size(),18,PURPLE,action)
		var techgrid = GridContainer.new(); techgrid.columns = 4 if not settings.large_font else 2; action.add_child(techgrid)
		var temp = Build.new_run(selected_class,1,selected_mode)
		for id in Data.ACTIVE_TECHS:
			var tid = id; var legal = Build.legal(temp,id)
			var b = button(("✓ " if id in selected_techs else "")+Data.TECHS[id].name,func():
				if tid in selected_techs: selected_techs.erase(tid)
				elif selected_techs.size()<3: selected_techs.append(tid)
				else: notify("最多指定三项科技"); return
				show_bridge(),techgrid,id in selected_techs)
			if not legal: b.disabled=true; b.tooltip_text="当前职业初武不满足前提"
		if selected_mode=="pressure":
			var rr = row(action); label("同屏上限",18,TEXT,rr)
			var count = SpinBox.new(); count.min_value=5; count.max_value=65; count.step=5; count.value=pressure_count; count.custom_minimum_size=Vector2(160,56); rr.add_child(count); count.value_changed.connect(func(n): pressure_count=int(n))
			label("时长（秒）",18,TEXT,rr); var secs=SpinBox.new(); secs.min_value=30; secs.max_value=300; secs.step=30; secs.value=pressure_seconds; secs.custom_minimum_size=Vector2(160,56); rr.add_child(secs); secs.value_changed.connect(func(n): pressure_seconds=int(n))
	button("开始行动  →",start_new_run,action,true)
	label("移动：WASD / 摇杆　冲刺：空格　职业技能：E　点击敌人集火　Esc 暂停",16,MUTED,body)

func bridge_archive(body: VBoxContainer) -> void:
	var controls = row(body)
	for kind in ["职业","武器","支援","科技","道具","构筑"]:
		var k = kind; button(kind,func(): archive_kind=k; show_bridge(),controls,kind==archive_kind)
	var filters = row(body)
	for tag in ["全部","实弹","爆破","工程","精密","机动"]:
		var filter = tag; button(tag,func(): archive_filter=filter; show_bridge(),filters,tag==archive_filter)
	label("标签仅描述适配，不存在两件／四件套。完整设计档案不代表全部可玩。",17,GOLD,body)
	var catalog = {"职业":Data.CLASSES,"武器":Data.WEAPONS,"支援":Data.SUPPORTS,"科技":Data.TECHS,"道具":Data.ITEMS,"构筑":Data.BUILDS}[archive_kind]
	for id in catalog:
		var e = catalog[id]
		if archive_filter!="全部" and archive_filter not in str(e): continue
		var r = row(body); label(id+"  "+e.name+("  ·  后续内容／仅参考" if e.get("reference_only",false) else ""),20,MUTED if e.get("reference_only",false) else TEXT,r); spacer(r)
		var cid=id; button("查看机制与代价",func(): detail_dialog(cid),r)

func bridge_research(body: VBoxContainer) -> void:
	label("研究数据  %d  ·  只解锁新选择" % int(profile.get("research_data",0)),26,PURPLE,body)
	label("不增加永久生命／伤害，不减轻道具代价。切片内初始内容已开放；未实现内容只供档案阅读，不收费解锁。",18,MUTED,body)
	label("本次切片启用池",22,TEXT,body)
	for group in [["weapons","武器",Data.ACTIVE_WEAPONS],["supports","支援",Data.ACTIVE_SUPPORTS],["techs","核心科技",Data.ACTIVE_TECHS]]:
		label(group[1],20,CYAN,body)
		var grid=GridContainer.new(); grid.columns=3 if not settings.large_font else 2; body.add_child(grid)
		for id in group[2]:
			var gid=group[0]; var cid=id; var enabled = enabled_ids(gid,group[2]); var on=id in enabled
			button(("✓ " if on else "○ ")+entry(id).name,func(): toggle_content(gid,cid,group[2]),grid,on)
	label("最少保留 4 武器 / 4 支援 / 6 科技；职业初武与至少 2 项适配科技受到保护。关闭仅影响下一局。",17,GOLD,body)

func enabled_ids(group: String, defaults: Array) -> Array:
	return profile.get("enabled",{}).get(group,defaults).duplicate()

func toggle_content(_group: String, id: String, _defaults: Array) -> void:
	if profile.has("load_error"): notify("局外档案损坏，未覆盖原数据"); return
	var group=Meta.category(id)
	var enabled=id in profile.enabled[group]
	var result=Meta.set_enabled(profile,id,not enabled)
	if not result.ok: notify(result.reason); return
	var saved=Save.save_profile(profile) if not preview_mode else {"ok":true}
	if not saved.ok: notify(saved.reason); return
	show_bridge()

func bridge_comms(body: VBoxContainer) -> void:
	var people = [["collins","柯林斯","铸砂-IV 最后一艘运输机被孢子炮锁住了。你能替我们打开航线吗？"],["hank","汉克","军械准备好了。矿晶买装备，瓦斯研究核心。拿不准就先看代价。"],["ella","艾拉","活着更重要。重伤撤回舰桥；这里不出售永久属性。"],["adjutant","副官 23-C","首轮验证任务只到前哨巢卫。完整三幕行动仍在设计档案中。"]]
	for p in people:
		var r=row(body)
		var tex=TextureRect.new(); tex.texture=load("res://assets/ui/portraits/%s.webp"%p[0]); tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; tex.custom_minimum_size=Vector2(112,112); r.add_child(tex)
		var v=panel(r); label(p[1],22,CYAN,v); label(p[2],19,TEXT,v)

func start_new_run() -> void:
	run=Build.new_run(selected_class,int(Time.get_unix_time_from_system()*1000),selected_mode)
	for group in ["weapons","supports","techs"]:
		run["enabled_"+group]=profile.get("enabled",{}).get(group,{"weapons":Data.ACTIVE_WEAPONS,"supports":Data.ACTIVE_SUPPORTS,"techs":Data.ACTIVE_TECHS}[group]).duplicate()
	if selected_mode!="campaign":
		run.techs=selected_techs.duplicate(); run["pressure_count"]=pressure_count; run["pressure_seconds"]=pressure_seconds
		if training_preset:
			run.weapons[0].level=3; run.weapons[0].branch=training_branch
			run.weapons.append({"id":"W05","level":3,"branch":"B","invested":0,"uid":2}); run.next_uid=3
			run.supports=["S02"]; run.support_invested={"S02":0}
			run["training_preset"]=true
		run.hp=Build.stats(run).max_hp
	if selected_mode=="boss": run.wave=12
	combat_time=0; shop_time=0; run["combat_time"]=0.0; run["shop_time"]=0.0
	start_wave()

func continue_run() -> void:
	run=load_result.run.duplicate(true); combat_time=float(run.get("combat_time",0)); shop_time=float(run.get("shop_time",0))
	if run.get("phase","")=="shop": show_shop()
	elif run.get("phase","") in ["result","ended"]: finish_result(run.get("success",false))
	else: start_wave()

func persist() -> bool:
	if preview_mode: save_text="演示状态 · 不写入存档"; saved_ok=true; return true
	run["combat_time"]=combat_time; run["shop_time"]=shop_time
	run.erase("visible_world")
	var result=Save.save_run(run); saved_ok=result.get("ok",false); save_text="已保存" if saved_ok else "保存失败 · 请重试"
	if not saved_ok: notify(result.get("reason","保存失败，已阻止离开整备"))
	return saved_ok

func start_wave() -> void:
	layout_edit=false
	run.phase="wave"
	if not preview_mode:
		var s=Save.save_wave_start(run)
		if not s.get("ok",false): saved_ok=false; notify(s.get("reason","波前保存失败")); show_shop(); return
	sim=Combat.new(); sim.initialize(run); previous_active_value=0; previous_skill_cd=0; last_banter=0; last_danger=0; low_hp_warned=false; state="wave"; commands.clear(); touch_owners.clear(); move_finger=-999; joystick_vector=Vector2.ZERO; skill_held=false; dash_held=false
	notice_text={1:"守住信标。补给正在路上。",2:"重甲来袭，尝试穿甲与走位。",3:"远程酸刺。横向移动可规避。",4:"巢卫挡住升降井。打穿它。",12:"击破神经囊，减少增援。"}.get(int(run.wave),"演练开始。观察预警与安全出口。")
	notice_time=4; show_hud(); countdown=3.0; countdown_resume=false

func show_hud() -> void:
	if dp_scale()>1.2:
		show_compact_hud()
		return
	clear_page(); var safe=safe_rect(); var w=safe.size.x
	var unit=maxf(1,dp_scale()); var top_height=maxf(100,88*unit)
	var top=PanelContainer.new(); page.add_child(top); top.position=safe.position; top.size=Vector2(w,top_height)
	var outer=column(top); var r=row(outer)
	hud_labels.hp=label("",20,TEXT,r); hud_labels.hp.custom_minimum_size=Vector2(200*unit,0)
	spacer(r); hud_labels.wave=label("",18,CYAN,r); spacer(r)
	if unit<=1.2: hud_labels.cash=label("",18,TEXT,r)
	button("暂停",pause_game,r)
	var bars=row(outer); hp_bar=ProgressBar.new(); hp_bar.show_percentage=false; hp_bar.custom_minimum_size=Vector2(250,12); hp_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bars.add_child(hp_bar)
	shield_bar=ProgressBar.new(); shield_bar.show_percentage=false; shield_bar.custom_minimum_size=Vector2(140,12); shield_bar.add_theme_stylebox_override("fill",box(Color("6bcbff"),Color("6bcbff"),0)); bars.add_child(shield_bar)
	hud_labels.shield=label("",16,CYAN,bars); hud_labels.time=label("",18,MUTED,bars); spacer(bars); hud_labels.level=label("",16,MUTED,bars)
	if unit>1.2: hud_labels.cash=label("",16,TEXT,bars)
	var comm=button("通讯 ▸",func(): comms_expanded=not comms_expanded; show_hud(),page); comm.position=Vector2(safe.position.x,safe.position.y+top_height+12); comm.size=Vector2(100*unit,maxf(52,48*unit))
	hud_labels.notice=label("",18,TEXT,page); hud_labels.notice.position=Vector2(safe.position.x+110*unit,safe.position.y+top_height+20); hud_labels.notice.size=Vector2(w-230*unit,68*unit)
	hud_labels.mark=label("",18,GOLD,page); hud_labels.mark.position=Vector2(safe.position.x+130,safe.position.y+top_height+55*unit); hud_labels.mark.size=Vector2(w-300,36)
	boss_bar=ProgressBar.new(); boss_bar.show_percentage=false; boss_bar.position=Vector2(get_viewport_rect().size.x*.27,safe.position.y+top_height+90*unit); boss_bar.size=Vector2(get_viewport_rect().size.x*.46,13); boss_bar.add_theme_stylebox_override("fill",box(RED,RED,0)); page.add_child(boss_bar)
	for threshold in ([.7,.35] if int(run.wave)==12 else [.5]):
		var tick=ColorRect.new(); tick.color=Color.WHITE; tick.mouse_filter=Control.MOUSE_FILTER_IGNORE; tick.position=Vector2(boss_bar.size.x*threshold,0); tick.size=Vector2(2,13); boss_bar.add_child(tick)
	hud_labels.boss=label("",18,TEXT,page); hud_labels.boss.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud_labels.boss.position=Vector2(boss_bar.position.x,boss_bar.position.y-28); hud_labels.boss.size=Vector2(boss_bar.size.x,30)
	hud_labels.equipment=label("",16,MUTED,page); hud_labels.equipment.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud_labels.equipment.position=Vector2(safe.position.x+220,safe.end.y-50); hud_labels.equipment.size=Vector2(w-440,48)
	hud_labels.countdown=label("",36,TEXT,page); hud_labels.countdown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud_labels.countdown.position=get_viewport_rect().size*.5-Vector2(180,80); hud_labels.countdown.size=Vector2(360,140)
	update_hud()

func show_compact_hud() -> void:
	clear_page()
	var safe=safe_rect(); var unit=dp_scale()
	var top=PanelContainer.new(); page.add_child(top); top.position=safe.position; top.size=Vector2(safe.size.x,0)
	var skin=box(Color("17232d"),Color("425261"),1)
	skin.content_margin_top=8; skin.content_margin_bottom=8; skin.content_margin_left=8; skin.content_margin_right=8
	top.add_theme_stylebox_override("panel",skin)
	var outer=column(top); outer.add_theme_constant_override("separation",4)
	var first=row(outer); first.add_theme_constant_override("separation",4)
	hud_labels.hp=label("",16,TEXT,first)
	hud_labels.wave=label("",16,CYAN,first)
	for key in ["hp","wave"]: hud_labels[key].autowrap_mode=TextServer.AUTOWRAP_OFF
	var comm=button("讯",func(): comms_expanded=not comms_expanded; show_hud(),first)
	comm.custom_minimum_size=Vector2(48*unit,48*unit); comm.size_flags_horizontal=Control.SIZE_SHRINK_END
	comm.add_theme_font_size_override("font_size",fs(16))
	var pause=button("Ⅱ",pause_game,first); pause.tooltip_text="暂停"; pause.autowrap_mode=TextServer.AUTOWRAP_OFF
	pause.custom_minimum_size=Vector2(48*unit,48*unit); pause.size_flags_horizontal=Control.SIZE_SHRINK_END
	pause.add_theme_font_size_override("font_size",fs(16))
	var second=row(outer); second.add_theme_constant_override("separation",4)
	hud_labels.cash=label("",16,TEXT,second)
	hud_labels.time=label("",16,MUTED,second)
	hud_labels.shield=label("",16,CYAN,second)
	for key in ["cash","time","shield"]: hud_labels[key].autowrap_mode=TextServer.AUTOWRAP_OFF
	var bars=row(outer); bars.add_theme_constant_override("separation",4)
	hp_bar=ProgressBar.new(); hp_bar.show_percentage=false; hp_bar.custom_minimum_size=Vector2(0,12); hp_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bars.add_child(hp_bar)
	shield_bar=ProgressBar.new(); shield_bar.show_percentage=false; shield_bar.custom_minimum_size=Vector2(100*unit,12); shield_bar.add_theme_stylebox_override("fill",box(Color("6bcbff"),Color("6bcbff"),0)); bars.add_child(shield_bar)
	hud_labels.notice=label("",16,TEXT,outer)
	hud_labels.notice.visible=false
	hud_labels.mark=label("",16,GOLD,outer)
	hud_labels.mark.visible=false
	hud_labels.boss=label("",16,TEXT,outer)
	hud_labels.boss.visible=false
	boss_bar=ProgressBar.new(); boss_bar.show_percentage=false; boss_bar.custom_minimum_size=Vector2(0,12); boss_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; boss_bar.add_theme_stylebox_override("fill",box(RED,RED,0)); outer.add_child(boss_bar)
	for threshold in ([.7,.35] if int(run.wave)==12 else [.5]):
		var tick=ColorRect.new(); tick.color=Color.WHITE; tick.mouse_filter=Control.MOUSE_FILTER_IGNORE
		boss_bar.add_child(tick); tick.anchor_left=threshold; tick.anchor_right=threshold; tick.anchor_bottom=1; tick.offset_right=2
	for bar in [hp_bar,shield_bar,boss_bar]:
		for style_name in ["background","fill"]:
			var style=bar.get_theme_stylebox(style_name).duplicate()
			style.content_margin_top=0; style.content_margin_bottom=0; style.content_margin_left=0; style.content_margin_right=0
			bar.add_theme_stylebox_override(style_name,style)
	# Noncritical readouts are intentionally folded in the large mobile HUD.
	hud_labels.level=label("",16,MUTED,page); hud_labels.level.hide()
	hud_labels.equipment=label("",16,MUTED,page); hud_labels.equipment.hide()
	hud_labels.countdown=label("",28,TEXT,page); hud_labels.countdown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud_labels.countdown.position=get_viewport_rect().size*.5-Vector2(230,70); hud_labels.countdown.size=Vector2(460,160)
	update_hud()

func cd_text(value: float) -> String:
	return str(ceili(value)) if value>3 else "%.1f"%value

func update_hud() -> void:
	if not sim or not hud_labels.has("hp"): return
	var stats=Build.stats(run)
	hud_labels.hp.text="生命 %d / %d"%[roundi(run.hp),roundi(stats.max_hp)]
	hud_labels.hp.modulate=RED if run.hp<stats.max_hp*.3 else TEXT
	hp_bar.max_value=stats.max_hp; hp_bar.value=run.hp
	shield_bar.max_value=stats.max_hp*.5; shield_bar.value=sim.shield; shield_bar.visible=sim.shield>0; hud_labels.shield.text="⬡ 护盾 %d"%roundi(sim.shield) if sim.shield>0 else ""
	hud_labels.wave.text=("W12 首领试场" if run.mode=="boss" else ("压力房" if run.mode=="pressure" else "W%d / 4"%run.wave))
	hud_labels.cash.text="◇ %d  气罐 %d · 本局"%[run.cash,run.gas]
	var isboss=int(run.wave) in [4,12]
	hud_labels.time.text=("已战斗 %.0fs"%sim.elapsed+(" · 压力上升" if sim.elapsed>=90 else "")) if isboss else "剩余 %02ds"%maxi(0,ceili((pressure_seconds if run.mode=="pressure" else 35)-sim.elapsed))
	hud_labels.level.text="Lv%d  %d/100"%[run.level,run.xp]
	hud_labels.notice.text=("副官  " + notice_text) if notice_time>0 or comms_expanded else ""
	var mark = find_enemy(sim.mark_uid)
	hud_labels.mark.text=""
	if not mark.is_empty():
		var max_range=0.0
		for weapon in run.weapons: max_range=maxf(max_range,float(Build.weapon_stats(run,weapon).get("range",400)))
		hud_labels.mark.text="◇ 集火：%s  %.1fs%s"%[enemy_name(mark.kind),sim.mark_left," · 超出射程" if sim.p.distance_to(mark.p)>max_range else ""]
	var boss: Dictionary={}
	for e in sim.enemies:
		if e.get("boss",false): boss=e; break
	boss_bar.visible=not boss.is_empty()
	hud_labels.boss.text=""
	if not boss.is_empty():
		boss_bar.max_value=boss.max_hp; boss_bar.value=boss.hp
		hud_labels.boss.text=("深巢暴君" if int(run.wave)==12 else "前哨巢卫")+"  P%d  %d/%d"%[boss.get("phase",1),ceili(boss.hp),ceili(boss.max_hp)]
	var equip: Array=[]
	for weapon in run.weapons: equip.append("%s Lv%d%s"%[weapon.id,weapon.level,weapon.branch])
	while equip.size()<4: equip.append("—")
	for id in run.supports:
		var status=""
		if id=="S03": status=" %d/8"%sim.point_defense_left
		if id=="S01":
			for device in sim.devices:
				if device.kind=="sentry" and not device.get("copy",false): status=" 损坏" if device.hp<=0 else " 就绪"
		equip.append(id+status)
	hud_labels.equipment.text="  |  ".join(equip) if not settings.large_font else "武器 %d/4 · 支援 %d/2"%[run.weapons.size(),run.supports.size()]
	hud_labels.countdown.text=("%d\n点击战场立即继续"%ceili(countdown)) if countdown>0 else ""
	if dp_scale()>1.2:
		hud_labels.hp.text="生命%d/%d"%[roundi(run.hp),roundi(stats.max_hp)]
		hud_labels.wave.text="W12试场" if run.mode=="boss" else ("压力房" if run.mode=="pressure" else "W%d/4"%run.wave)
		hud_labels.cash.text="矿%d  气%d"%[run.cash,run.gas]
		hud_labels.shield.text="盾%d"%roundi(sim.shield) if sim.shield>0 else ""
		hud_labels.shield.visible=sim.shield>0
		hud_labels.time.text=("战斗%ds"%int(sim.elapsed)+( " 压力↑" if sim.elapsed>=90 else "")) if isboss else "剩余%ds"%maxi(0,ceili((pressure_seconds if run.mode=="pressure" else 35)-sim.elapsed))
		hud_labels.notice.visible=hud_labels.notice.text!=""
		hud_labels.mark.visible=hud_labels.mark.text!=""
		hud_labels.boss.hide()
		if not boss.is_empty(): hud_labels.wave.text=("暴君" if int(run.wave)==12 else "巢卫")+" P%d"%boss.get("phase",1)
		hud_labels.level.hide(); hud_labels.equipment.hide()


func entry(id: String) -> Dictionary:
	return Data.entry(id)

func notify(text: String) -> void:
	toast_time=4.0
	if is_instance_valid(toast): toast.text="  " + text; toast.visible=true

func transaction(result: Dictionary, refresh: bool = true) -> void:
	if result.get("ok",false):
		sfx("buy","skill")
		persist()
		if refresh: show_shop()
	else: notify(result.get("reason","无法完成操作"))

func show_shop() -> void:
	state="shop"; sim=null; commands.clear(); touch_owners.clear(); move_finger=-999; joystick_vector=Vector2.ZERO
	var completed=int(run.get("completed_wave",run.wave))
	var body=page_body("前线整备  /  第 %d 波完成"%completed,"先购物，再选择升级与研究；所有必要选择完成后出击。")
	var stats=Build.stats(run)
	var top=adaptive_row(body); label("生命 %d/%d"%[roundi(run.hp),roundi(stats.max_hp)],22,TEXT,top); spacer(top); label("◇ 矿晶 %d"%run.cash,24,Color("78b8ff"),top); label("瓦斯 %d · 本局"%run.gas,22,Color("98d873"),top)
	var pending=adaptive_row(body)
	button("待选升级 %d"%run.pending_levels,show_levels,pending,run.pending_levels>0)
	button("核心研究 %d"%int(run.pending_research),show_research,pending,run.pending_research)
	button("汉克信道 ▾" if comms_expanded else "汉克信道 ▸",func(): comms_expanded=not comms_expanded; show_shop(),pending)
	spacer(pending); label(save_text,16,GREEN if saved_ok else RED,pending)
	if not saved_ok: button("重试保存",func(): persist(); show_shop(),pending,true)
	if comms_expanded: label("汉克：先核对收益和代价。矿晶可以等，活人不能等。",18,MUTED,body)
	var grid=GridContainer.new(); grid.columns=2 if settings.large_font or dp_scale()>1.2 else 4; body.add_child(grid)
	for i in range(run.shop.size()):
		var offer=run.shop[i]; var id=str(offer.id); var e=entry(id); var v=panel(grid)
		if id=="": label("售罄",22,MUTED,v); continue
		label(id+"  /  "+{"weapon":"军械","item":"改装","support":"支援"}.get(str(offer.kind),str(offer.kind)),15,CYAN,v)
		label(e.name,22,TEXT,v)
		if offer.kind=="weapon":
			var ws=Build.weapon_stats(run,{"id":id,"level":1,"branch":""})
			label("%.1f伤害 × %.2f发/s\n射程 %du"%[ws.get("damage",0),ws.get("rate",ws.get("attack",1)),ws.get("range",0)],17,GREEN,v)
			label("四武器槽 · 同型最多两把",16,MUTED,v)
		else:
			label("+ "+str(e.get("benefit",e.get("desc",""))),17,GREEN,v)
			label("− "+str(e.get("penalty","无额外代价")),17,Color("ff9e9e"),v)
		var idx=i
		button("详情",func(): detail_dialog(id),v)
		var price=Build.price(run,id)
		var buytext="已购买" if offer.get("bought",false) else "购买  ◇ %d"%price
		var buybutton=button(buytext,func(): buy_offer(idx),v,true); buybutton.disabled=offer.get("bought",false)
		if not offer.get("bought",false) and run.cash<price: label("还差 %d 矿晶"%(price-run.cash),16,GOLD,v)
		var lockbutton=button("▣ 下波保留" if offer.get("locked",false) else "锁定货格",func(): transaction(Build.lock(run,idx)),v)
		lockbutton.disabled=offer.get("bought",false)
	var tools=adaptive_row(body)
	var reroll_price=Build.reroll_cost(run)
	button("刷新 · 免费 1 次" if reroll_price==0 else "刷新 · %d 矿晶"%reroll_price,func():
		var count=0
		for o in run.shop:
			if not o.get("bought",false) and not o.get("locked",false): count+=1
		if count==0: notify("所有货格已购买或锁定，无可刷新货格"); return
		confirm_dialog("刷新 %d 格货架？"%count,"费用 %d 矿晶；锁货、升级与研究选项保持不变。"%reroll_price,func(): transaction(Build.reroll(run))),tools)
	button("属性与适配",show_stats,tools); button("道具 %d/12 · 回收"%run.items.size(),show_recycle,tools); spacer(tools)
	button("返回舰桥",func(): confirm_dialog("返回舰桥？","整备状态已保存；下次继续当前货架与选择。",func(): if persist(): load_result=Save.load_run(); show_bridge()),tools)
	label("装备与升级  /  武器 %d/4 · 支援 %d/2 · 核心科技 %d/3"%[run.weapons.size(),run.supports.size(),run.techs.size()],23,TEXT,body)
	var equipment=GridContainer.new(); equipment.columns=2; body.add_child(equipment)
	for weapon in run.weapons:
		var v=panel(equipment); var uid=int(weapon.uid)
		label("%s  Lv%d %s"%[entry(weapon.id).name,weapon.level,weapon.branch],20,CYAN,v)
		var rr=adaptive_row(v,1)
		if weapon.level<3: button("升级 ◇ %d"%Build.upgrade_cost(run,uid),func(): upgrade_weapon(uid),rr,true)
		else: label("终阶分支本局固定",17,GOLD,rr)
		button("回收 +%d"%Build.sell_value(run,"weapon",uid),func(): confirm_sale("weapon",uid),rr)
	for id in run.supports:
		var cid=id; var v=panel(equipment); label(entry(id).name,20,TEXT,v); label("唯一支援 · 下一波重新部署",17,MUTED,v)
		button("回收 +%d"%Build.sell_value(run,"support",id),func(): confirm_sale("support",cid),v)
	if not run.techs.is_empty(): label("核心科技："+" / ".join(run.techs.map(func(id): return entry(id).name)),18,PURPLE,body)
	var bottom=adaptive_row(body); label("保证收入不因受伤扣除 · 不自动满血",16,MUTED,bottom); spacer(bottom)
	var can=Build.can_depart(run)
	button("出击第 %d 波 →"%(completed+1) if can.ok else can.reason,depart,bottom,can.ok)

func depart() -> void:
	var can=Build.can_depart(run)
	if not can.ok:
		notify(can.reason)
		if run.pending_levels>0: show_levels()
		elif run.pending_research: show_research()
		return
	if not persist(): return
	run.wave=int(run.get("completed_wave",run.wave))+1
	start_wave()

func buy_offer(index: int) -> void:
	var offer=run.shop[index]; var kind=str(offer.kind)
	if kind=="weapon" and run.weapons.size()>=4:
		show_replacement(index,"weapon"); return
	if kind=="support" and run.supports.size()>=2:
		show_replacement(index,"support"); return
	if kind=="item" and run.items.size()>=12 and not run.items.has(offer.id):
		show_recycle(); notify("先回收一种道具，再返回货架购买"); return
	transaction(Build.buy(run,index))

func show_replacement(index: int, kind: String) -> void:
	var offer=run.shop[index]; var e=entry(offer.id)
	var v=dialog("替换比较 / "+e.name)
	label("取消不会扣费；确认后先回收旧装备，再购入新装备。已研究科技不退还，可能失去触发条件。",18,GOLD,v)
	label(e.desc,18,GREEN,v)
	var options=run.weapons if kind=="weapon" else run.supports
	for old in options:
		var key=old.uid if kind=="weapon" else old
		var id=old.id if kind=="weapon" else old
		var refund=Build.sell_value(run,kind,key)
		var c=panel(v); label("替换："+entry(id).name,20,TEXT,c)
		if kind=="weapon":
			var stats=Build.weapon_stats(run,old)
			label("Lv%d %s · 伤害%.1f · 射速%.2f · 射程%du"%[old.level,old.branch,stats.get("damage",0),stats.get("rate",1),stats.get("range",0)],17,MUTED,c)
		else: label(entry(id).desc,17,MUTED,c)
		label("回收 %d · 新品 %d · 净花费 %d"%[refund,Build.price(run,offer.id),Build.price(run,offer.id)-refund],18,GOLD,c)
		var replace_key=key
		button("确认替换",func(): transaction(Build.buy(run,index,replace_key)); close_dialog(),c,true)
	button("取消，不扣费",close_dialog,v)

func upgrade_weapon(uid: int) -> void:
	var index=Build.find_weapon(run,uid)
	if index<0: return
	var weapon=run.weapons[index]
	if int(weapon.level)==1: transaction(Build.upgrade(run,uid)); return
	var e=entry(weapon.id); var v=dialog("终阶分支对比  /  "+e.name)
	label("Lv2 → Lv3：基础伤害倍率 1.25 → 1.50。确认后分支本局固定；返回不扣费。",18,GOLD,v)
	var g=GridContainer.new(); g.columns=1 if settings.large_font else 2; v.add_child(g)
	for branch in ["A","B"]:
		var b=branch; var c=panel(g); var branch_data=e.branches[branch]
		label(branch+" / "+branch_data.name,24,CYAN,c); label(branch_data.desc,20,TEXT,c)
		if weapon.id=="W07" and branch=="B" and run.supports.is_empty() and run.class_id!="C06": label("当前没有攻击装置：维修收益无法触发，射速代价仍生效。",18,GOLD,c)
		button("选择 %s · %d 矿晶"%[branch,Build.upgrade_cost(run,uid)],func():
			confirm_dialog("确认分支 "+b+"？",branch_data.desc+"\n本局固定。支付 %d 矿晶。"%Build.upgrade_cost(run,uid),func(): transaction(Build.upgrade(run,uid,b))),c,true)
	button("返回，不扣费",close_dialog,v)

func show_levels() -> void:
	if run.pending_levels<=0: notify("本次升级已完成"); return
	var v=dialog("战术升级  /  还有 %d 项待选"%run.pending_levels)
	label("可返回先查看装备；未选择不会自动替你决定。",17,MUTED,v)
	var stats=Build.stats(run)
	for choice in run.level_choices:
		var id=str(choice); var e=Build.LEVEL_CHOICES.get(id,{"name":"矿晶补给","desc":"矿晶 +15","key":"cash","value":15})
		var before=float(stats.get(e.get("key",""),run.cash if id=="cash" else 0))
		var text=e.name+"  ·  "+e.desc
		if id=="armor": text+="\n护甲 %.0f → %.0f，减伤 %.1f%% → %.1f%%"%[before,before+4,before/(before+50)*100,(before+4)/(before+54)*100]
		button(text,func():
			transaction(Build.choose_level(run,id)); if run.pending_levels>0: show_levels(),v,true)
	button("返回整备，稍后选择",close_dialog,v)

func show_research() -> void:
	if not run.pending_research: notify("本次无待研究科技"); return
	var v=dialog("核心研究  /  科技 %d/3 · 20 瓦斯"%run.techs.size())
	if run.research_choices.is_empty():
		label("先选择组偏好，再固定本次三项。生成后不能重抽；所有选项均需满足装备前提。",19,MUTED,v)
		for preference in ["生化","军械","工程","通用"]:
			var pref=preference; button(preference+"优先 · 生成选项",func():
				var result=Build.generate_research(run,pref)
				if result.get("ok",false): persist(); show_research()
				else: notify(result.get("reason","无法生成研究")),v,true)
	else:
		label("本次选项已固定 · 可先查看详情，确认后才支付。",17,GOLD,v)
		for id in run.research_choices:
			var tid=str(id); var e=entry(tid); var c=panel(v)
			label(e.name,23,CYAN,c); label("+ "+e.benefit,19,GREEN,c); label("− "+e.penalty,19,Color("ff9e9e"),c)
			label("当前装备满足前提 · 来源题材："+e.source,16,MUTED,c)
			button("预览研究  ·  20 瓦斯",func(): confirm_dialog("研究确认 / "+e.name,e.desc+"\n支付20瓦斯，占用一个核心槽，本局不可替换。",func(): transaction(Build.research(run,tid))),c,true)
	button("返回整备，不支付",close_dialog,v)

func confirm_sale(kind: String, key) -> void:
	var id=run.weapons[Build.find_weapon(run,int(key))].id if kind=="weapon" else str(key)
	confirm_dialog("回收 "+entry(id).name+"？","返还实付投入的50%%：%d矿晶。\n移除后可能失去科技触发条件；不返还科技，不补血。"%Build.sell_value(run,kind,key),func(): transaction(Build.sell(run,kind,key)))

func show_recycle() -> void:
	var v=dialog("道具回收  /  %d种 · 最多12种"%run.items.size())
	if run.items.is_empty(): label("尚未持有普通改装道具。",20,MUTED,v)
	for id in run.items:
		var cid=str(id); var c=panel(v); label(entry(id).name+" ×"+str(run.items[id]),21,TEXT,c)
		label("移除对应收益与代价：\n"+entry(id).desc,17,MUTED,c)
		button("回收此种全部份数 +%d矿晶"%Build.sell_value(run,"item",id),func(): confirm_sale("item",cid),c)
	button("返回货架",close_dialog,v)

func show_stats() -> void:
	var v=dialog("当前构筑 / 属性与适配")
	var s=Build.stats(run)
	label("生命上限 %.0f　护甲 %.0f　减伤 %.1f%%\n移速 %.0fu/s　伤害 ×%.2f　攻速 ×%.2f\n工程 ×%.2f　暴击 %.0f%%　拾取 %.0fu\n冲刺 %.2fs　职业技能 %.2fs"%[s.max_hp,s.armor,s.armor/(s.armor+50)*100,s.speed,s.damage,s.attack,s.engineering,s.crit*100,s.pickup,s.dash_cd,s.skill_cd],22,TEXT,v)
	label("科技槽 %d/3 · 支援 %d/2 · 道具 %d/12种\n救命额度：%s"%[run.techs.size(),run.supports.size(),run.items.size(),"已消耗" if run.get("rescue_spent",false) else "未消耗（不代表装备了救命效果）"],18,MUTED,v)
	for id in run.techs: label(entry(id).name+"："+entry(id).desc,17,PURPLE,v)
	button("关闭",close_dialog,v)

func detail_dialog(id: String) -> void:
	var e=entry(id); var v=dialog(id+" / "+e.name)
	if e.get("reference_only",false): label("后续设计内容：本切片仅供查看，未开放实战。",19,GOLD,v)
	label(e.desc,20,TEXT,v)
	if e.has("branches"):
		for b in ["A","B"]: label(b+" · "+e.branches[b].name+"\n"+e.branches[b].desc,20,CYAN,v)
	label("原型灵感与改编边界\n"+str(e.get("source","本作原创设计参数，待实测")),16,MUTED,v)
	button("返回",close_dialog,v)

func dialog(title: String) -> VBoxContainer:
	close_dialog()
	modal=Control.new(); root_ui.add_child(modal); modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade=ColorRect.new(); shade.color=Color(0.015,0.025,0.04,.9); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.add_child(shade)
	var p=PanelContainer.new(); modal.add_child(p); var safe=safe_rect(); var width=minf(safe.size.x-32,1000); p.position=Vector2((get_viewport_rect().size.x-width)*.5,safe.position.y+8); p.size=Vector2(width,safe.size.y-16)
	var outer=column(p); var header=row(outer); label(title,25,TEXT,header); spacer(header); button("关闭",close_dialog,header)
	var scroll=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; outer.add_child(scroll)
	var content=column(scroll); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return content

func close_dialog() -> void:
	if is_instance_valid(modal): modal.hide(); modal.queue_free()
	modal=null

func confirm_dialog(title: String, text: String, yes: Callable) -> void:
	var v=dialog(title); label(text,21,TEXT,v)
	var r=row(v); button("取消，不改变状态",close_dialog,r); button("确认",func(): close_dialog(); yes.call(),r,true)

func dp_scale() -> float:
	if debug_density_scale>0: return debug_density_scale
	# Convert Android logical dp to canvas coordinates; desktop uses a 1:1 UI floor.
	if not OS.has_feature("mobile"): return 1.0
	var pixels=Vector2(DisplayServer.screen_get_size())
	var density=maxf(1.0,float(DisplayServer.screen_get_dpi())/160.0)
	return density * get_viewport_rect().size.y / maxf(pixels.y,1.0)

func control_radius(kind: String) -> float:
	var diameter=72.0 if kind=="skill" else 64.0
	return maxf(48.0,diameter*float(settings.get("control_scale",1.0)))*dp_scale()*.5

func control_pos(kind: String) -> Vector2:
	var safe=safe_rect(); var factor=dp_scale()
	var default=Vector2(safe.end.x-95*factor,safe.end.y-(120 if factor>1.2 else 140)*factor) if kind=="skill" else Vector2(safe.end.x-225*factor,safe.end.y-65*factor)
	var offset=settings.get(kind+"_offset",[0,0]); default+=Vector2(offset[0],offset[1])*factor
	if settings.left_handed: default.x=get_viewport_rect().size.x-default.x
	var radius=control_radius(kind)
	default.x=clampf(default.x,safe.position.x+radius,safe.end.x-radius)
	default.y=clampf(default.y,safe.position.y+260+radius,safe.end.y-radius)
	return default

func joystick_default() -> Vector2:
	var safe=safe_rect(); var center=Vector2(safe.position.x+115*dp_scale(),safe.end.y-100*dp_scale())
	if settings.left_handed: center.x=get_viewport_rect().size.x-center.x
	return center

func cancel_rect() -> Rect2:
	var skill=control_pos("skill")
	return Rect2(skill+Vector2(75 if settings.left_handed else -215,-95)*dp_scale(),Vector2(140,65)*dp_scale())

func show_settings(back: String) -> void:
	setting_return=back; state="settings"; layout_edit=false
	var body=page_body("辅助设置 / 操作布局","设置不改变伤害与碰撞。低特效仍保留全部敌方预警。")
	var toggles=[["large_font","大字体 130% · 卡牌两列重排"],["left_handed","左手操作 · 只镜像移动与技能区"],["low_fx","低特效 · 保留危险边界与敌弹"],["reduced_motion","减少动态 · 静态头像与面板"],["banter","可选闲聊 · 关闭不影响必要提示"],["danger_outline","危险边界强化"],["color_assist","色觉辅助 · 图形识别始终保留"],["haptic_skill","技能震动"],["haptic_damage","受击震动"],["haptic_danger","危险震动"]]
	for item in toggles:
		var key=item[0]; var cb=CheckButton.new(); cb.text=item[1]; cb.button_pressed=settings.get(key,false); cb.custom_minimum_size.y=maxf(56,48*dp_scale()); cb.add_theme_font_size_override("font_size",fs(19)); body.add_child(cb)
		cb.toggled.connect(func(on): settings[key]=on; save_settings(); if key in ["large_font","left_handed"]: show_settings(setting_return))
	var r=row(body); label("操作键缩放",19,TEXT,r)
	var scale=HSlider.new(); scale.min_value=.85; scale.max_value=1.3; scale.step=.05; scale.value=settings.control_scale; scale.custom_minimum_size=Vector2(350,56); r.add_child(scale)
	scale.value_changed.connect(func(value): settings.control_scale=value; save_settings())
	button("拖动布局 / 测试按键",show_layout_editor,body,true)
	button("恢复默认操作布局",func(): settings.control_scale=1.0; settings.dash_offset=[0,0]; settings.skill_offset=[0,0]; save_settings(); show_settings(setting_return),body)
	for audio in [["sound_danger","危险音"],["sound_skill","技能就绪"],["sound_pickup","资源拾取"],["sound_voice","通信提示音（无配音）"]]:
		var key=audio[0]; var ar=row(body); label(audio[1],18,TEXT,ar); var sl=HSlider.new(); sl.min_value=0; sl.max_value=1; sl.step=.1; sl.value=settings.get(key,.7); sl.custom_minimum_size=Vector2(350,56); ar.add_child(sl); sl.value_changed.connect(func(value): settings[key]=value; save_settings())
	label("默认无快速闪光、无全屏白闪、无持续血条闪烁。震屏关闭。",17,MUTED,body)
	button("保存并返回",func(): save_settings(); return_settings(),body,true)

func save_settings() -> void:
	if profile.has("load_error"): notify("档案损坏：未覆盖旧数据，设置仅本次有效"); return
	profile.settings=settings.duplicate(true)
	if not preview_mode:
		var saved=Save.save_profile(profile)
		if not saved.ok: notify(saved.reason)

func return_settings() -> void:
	layout_edit=false
	if setting_return=="pause": state="paused"; show_hud(); show_pause()
	elif setting_return=="shop": show_shop()
	else: show_bridge()

func show_layout_editor() -> void:
	layout_edit=true; clear_page()
	var safe=safe_rect(); var header=PanelContainer.new(); header.position=safe.position; header.size=Vector2(safe.size.x,130); page.add_child(header); var v=column(header)
	label("拖动冲刺与技能键 · 松手保存 · 控件热区不得重叠",21,CYAN,v)
	var rr=row(v); button("测试：点击操作键",func(): notify("测试模式：触碰操作键亮起，无战斗消耗"),rr)
	button("保存布局并返回",func(): save_settings(); show_settings(setting_return),rr,true)
	button("恢复默认",func(): settings.dash_offset=[0,0]; settings.skill_offset=[0,0]; save_settings(),rr)

func pause_game() -> void:
	if state!="wave": return
	state="paused"; joystick_vector=Vector2.ZERO; touch_owners.clear(); move_finger=-999; commands.clear(); skill_held=false; dash_held=false; countdown=0
	if not preview_mode: Save.save_rescue(run)
	show_pause()

func show_pause() -> void:
	var v=dialog("行动暂停")
	label("战场已冻结。返回舰桥后，下次从本波开始恢复；已消耗救命额度保留。",20,MUTED,v)
	button("继续行动",func(): close_dialog(); state="wave"; countdown=3.0; countdown_resume=true; show_hud(),v,true)
	button("当前构筑",show_stats,v)
	button("设置",func(): close_dialog(); show_settings("pause"),v)
	button("返回舰桥",func(): confirm_dialog("返回舰桥？","恢复将从本波起点开始，不是逐帧续玩。未完成波次不结算。",func():
		if not preview_mode: Save.save_rescue(run)
		load_result=Save.load_run(); show_bridge()),v)

func wave_finished() -> void:
	var mode=str(run.mode)
	if mode=="campaign":
		var result=Build.settle_wave(run,sim.active_value)
		if not result.ok: notify(result.reason); return
		if int(run.wave)==4:
			finish_result(true); return
		persist(); show_shop()
	else: finish_result(true)

func finish_result(success: bool) -> void:
	state="result"; result_success=success
	run["last_damage_source"]=sim.last_damage_source if sim else run.get("last_damage_source","")
	run["phase"]="result"; run["success"]=success; run["combat_time"]=combat_time; run["shop_time"]=shop_time
	run.erase("visible_world")
	if success and run.mode=="campaign" and int(run.wave)==4 and not profile.has("load_error"):
		var award=Meta.award(profile,run,4,true)
		run["research_earned"]=maxi(int(run.get("research_earned",0)),int(award.get("earned",0)))
		if not preview_mode: profile_saved_ok=Save.save_profile(profile).get("ok",false)
	if not preview_mode: saved_ok=Save.save_run(run).get("ok",false)
	var body=page_body("第一幕验证完成" if success and run.mode=="campaign" else ("演练完成" if success else "紧急撤离 / 任务未完成"),"铸砂-IV  /  行动复盘")
	label("地面信标已保住。后续矿井与主巢篇章仍在完整设计中。" if success and run.mode=="campaign" else ("训练不产研究数据，不影响局外成长。" if run.mode!="campaign" else "救援信标已接收，保持呼吸。"),24,CYAN,body)
	var v=panel(body)
	label("到达第 %d 波　|　战斗 %.1fs　|　整备 %.1fs"%[run.wave,combat_time,shop_time],23,TEXT,v)
	label("研究数据 +%d（只解锁选择）"%int(run.get("research_earned",0)),22,PURPLE,v)
	label("矿晶 / 瓦斯是本局资源，不带入下一局，不兑换永久属性。",18,MUTED,v)
	if not success: label("最后伤害："+str(run.get("last_damage_source","未知")),18,GOLD,v)
	label("武器："+" / ".join(run.weapons.map(func(w): return "%s Lv%d%s"%[entry(w.id).name,w.level,w.branch])),18,TEXT,v)
	label("科技："+" / ".join(run.techs.map(func(id): return entry(id).name)),18,PURPLE,v)
	label("切片验收范围：第一幕4波、可调压力房与独立W12首领。尚不代表完整12波时长或真实Android持续性能已验收。",17,MUTED,body)
	if not saved_ok or not profile_saved_ok: label("保存失败：奖励或本局状态尚未安全写入。请重试后返回。",20,RED,body)
	button("重试保存并返回" if not saved_ok or not profile_saved_ok else "返回舰桥",func():
		if not profile_saved_ok:
			profile_saved_ok=Save.save_profile(profile).get("ok",false)
			if not profile_saved_ok: notify("研究档案保存仍失败，未离开结算"); return
		if not saved_ok and not persist(): return
		if not preview_mode:
			var cleared=Save.clear_run()
			if not cleared.ok: notify(cleared.reason); return
		load_result={}; show_bridge(),body,true)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if state=="wave": pause_game()

func _process(dt: float) -> void:
	if ui_rebuild_pending: ui_rebuild_pending=false; rebuild_current()
	if toast_time>0:
		toast_time-=dt
		if is_instance_valid(toast): toast.visible=toast_time>0
	if state=="shop": shop_time+=dt
	if state=="wave" and sim:
		if countdown>0: countdown=maxf(0,countdown-dt)
		else:
			combat_time+=dt; notice_time=maxf(0,notice_time-dt)
			var move=joystick_vector
			if move.length()<.01:
				move=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length()
			sim.visible_world=Rect2(screen_to_world(Vector2.ZERO),get_viewport_rect().size/world_scale())
			var events=sim.step(minf(dt,.05),move,commands); commands={}
			for event in events:
				match str(event.get("type","")):
					"wave_end": wave_finished(); break
					"death": finish_result(false); break
					"notice": notice_text=event.get("text",""); notice_time=3.5; sfx("wave","voice")
					"phase": notice_text=event.get("text",""); notice_time=2.5; danger_feedback()
					"life_cost": cost_text="−%d %s"%[ceili(event.get("amount",0)),event.get("text","")]; cost_time=1.5
					"dash": sfx("dash","skill")
					"rescue": if not preview_mode: Save.save_rescue(run)
					"skill":
						sfx("level","skill")
						if settings.get("haptic_skill",true) and OS.has_feature("mobile"): Input.vibrate_handheld(35)
					"damage":
						sfx("hurt","danger")
						if settings.get("haptic_damage",true) and OS.has_feature("mobile"): Input.vibrate_handheld(25)
		if state=="wave":
			update_hud(); audio_feedback(); cost_time=maxf(0,cost_time-dt)
			if settings.get("banter",true) and sim.elapsed-last_banter>=15 and notice_time<=0:
				last_banter=sim.elapsed
				var lines=["保持通道畅通，准备下一批补给。","别把后背留给虫群。","先看预警，再考虑开火位置。","补给信道在线，保持移动。","按你的路线走，别急着停下。","信标还在，我们能找到你。"]
				notice_text=lines[(int(sim.elapsed/15)-1)%6]; notice_time=2.5
			if not low_hp_warned and run.hp<Build.stats(run).max_hp*.3:
				low_hp_warned=true; notice_text="生命危险，先离开攻击范围。"; notice_time=3; danger_feedback()
	queue_redraw()

func schedule_rebuild() -> void:
	ui_rebuild_pending=true

func rebuild_current() -> void:
	match state:
		"bridge": show_bridge()
		"shop": show_shop()
		"wave": show_hud()
		"settings":
			if layout_edit: show_layout_editor()
			else: show_settings(setting_return)
		"paused": show_hud(); show_pause()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == -1: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			handle_escape()
		elif state=="wave":
			if event.keycode==KEY_SPACE: commands.dash=true
			if event.keycode==KEY_E: commands.skill=true
	if state!="wave" and not layout_edit: return
	if is_instance_valid(modal): return
	if event is InputEventScreenTouch: touch_event(event.index,event.position,event.pressed)
	elif event is InputEventScreenDrag: drag_event(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		touch_event(-1,event.position,event.pressed)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): drag_event(-1,event.position)

func touch_event(id: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if countdown>0: countdown=0; return
		var owner="world"
		if pos.distance_to(control_pos("skill"))<=control_radius("skill"): owner="skill"
		elif pos.distance_to(control_pos("dash"))<=control_radius("dash"): owner="dash"
		elif (pos.x > get_viewport_rect().size.x*.62 if settings.left_handed else pos.x < get_viewport_rect().size.x*.38) and pos.y>get_viewport_rect().size.y*.48 and move_finger==-999: owner="move"
		touch_owners[id]={"owner":owner,"start":pos,"last":pos,"time":Time.get_ticks_msec(),"max_distance":0.0}
		if layout_edit: return
		if owner=="move": move_finger=id; joystick_origin=pos; joystick_vector=Vector2.ZERO
		elif owner=="skill": skill_held=true; skill_cancel=false
		elif owner=="dash": dash_held=true
	else:
		if not touch_owners.has(id): return
		var touch=touch_owners[id]; touch_owners.erase(id)
		if layout_edit: save_settings(); return
		match touch.owner:
			"move": if move_finger==id: move_finger=-999; joystick_vector=Vector2.ZERO
			"skill":
				skill_held=false
				if not skill_cancel: commands.skill=true
				skill_cancel=false
			"dash": dash_held=false; commands.dash=true
			"world":
				if Time.get_ticks_msec()-touch.time<=250 and touch.max_distance<8*dp_scale(): mark_at(pos)

func drag_event(id: int, pos: Vector2) -> void:
	if not touch_owners.has(id): return
	var touch=touch_owners[id]; touch.max_distance=maxf(touch.max_distance,pos.distance_to(touch.start))
	if layout_edit and touch.owner in ["skill","dash"]:
		var delta=(pos-touch.last)/dp_scale()
		if settings.left_handed: delta.x=-delta.x
		var key=touch.owner+"_offset"; var old=settings[key].duplicate(); settings[key]=[old[0]+delta.x,old[1]+delta.y]
		if control_pos("skill").distance_to(control_pos("dash"))<control_radius("skill")+control_radius("dash")+12*dp_scale(): settings[key]=old; notify("两个热区至少间隔12dp")
	elif touch.owner=="move" and move_finger==id:
		var delta=pos-joystick_origin; var radius=40*dp_scale()
		if delta.length()>radius: joystick_origin=pos-delta.normalized()*radius; delta=pos-joystick_origin
		joystick_vector=Vector2.ZERO if delta.length()<6*dp_scale() else delta.limit_length(radius)/radius
	elif touch.owner=="skill": skill_cancel=cancel_rect().has_point(pos)
	touch.last=pos

func mark_at(screen_pos: Vector2) -> void:
	if not sim: return
	var best: Dictionary={}; var nearest=INF
	for e in sim.enemies:
		if e.hp<=0: continue
		var distance=world_to_screen(e.p).distance_to(screen_pos)
		var hitradius=maxf(24*dp_scale(),float(e.r)*world_scale())
		if distance<=hitradius and (distance<nearest-.01 or (is_equal_approx(distance,nearest) and e.get("mechanism",false))): best=e; nearest=distance
	if not best.is_empty(): sim.request_mark(int(best.uid))

func find_enemy(uid: int) -> Dictionary:
	if not sim: return {}
	for e in sim.enemies:
		if int(e.uid)==uid: return e
	return {}

func world_scale() -> float:
	return get_viewport_rect().size.y/1080.0

func camera_center() -> Vector2:
	return Vector2(900,clampf(sim.p.y,540,660)) if sim else Vector2(900,600)

func world_to_screen(point: Vector2) -> Vector2:
	return (point-camera_center())*world_scale()+get_viewport_rect().size*.5

func screen_to_world(point: Vector2) -> Vector2:
	return (point-get_viewport_rect().size*.5)/world_scale()+camera_center()

func enemy_name(kind: String) -> String:
	return {"runner":"跳虫","roach":"蟑螂","hydra":"刺蛇","baneling":"毒爆虫","lurker":"潜伏者","infestor":"感染虫","node":"坑道节点","boss":"首领","cocoon":"神经囊"}.get(kind,kind)

func _draw() -> void:
	var screen=get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,screen),BG)
	if sim and state in ["wave","paused","settings"]:
		draw_world()
	elif layout_edit:
		for x in range(0,int(screen.x),64): draw_line(Vector2(x,0),Vector2(x,screen.y),Color("243343"),1)
		for y in range(0,int(screen.y),64): draw_line(Vector2(0,y),Vector2(screen.x,y),Color("243343"),1)
	if (state=="wave" and sim) or layout_edit: draw_controls()

func draw_world() -> void:
	var scale=world_scale(); var origin=world_to_screen(Vector2.ZERO); var world_size=Vector2(1800,1200)*scale
	draw_rect(Rect2(origin,world_size),Color("18252c"))
	for x in range(0,1801,120): draw_line(world_to_screen(Vector2(x,0)),world_to_screen(Vector2(x,1200)),Color("22343d"),1)
	for y in range(0,1201,120): draw_line(world_to_screen(Vector2(0,y)),world_to_screen(Vector2(1800,y)),Color("22343d"),1)
	draw_rect(Rect2(origin,world_size),Color("5b6670"),false,4)
	for n in range(9):
		var p=world_to_screen(Vector2(80+n*205,55)); draw_rect(Rect2(p,Vector2(35,9)*scale),Color("7b6540"))
	# Warning fills remain below units, outlines are repeated after all friendly FX.
	for h in sim.hazards: draw_hazard(h,false)
	for drop in sim.drops:
		var q=world_to_screen(drop.p); draw_colored_polygon(PackedVector2Array([q+Vector2(0,-9),q+Vector2(7,2),q+Vector2(0,8),q+Vector2(-7,2)]),Color("78b8ff"))
	for device in sim.devices:
		var q=world_to_screen(device.p); var r=16*scale
		if device.hp<=0:
			draw_rect(Rect2(q-Vector2(r,r),Vector2(r,r)*2),Color("45535d")); draw_line(q-Vector2(r,r),q+Vector2(r,r),RED,2); continue
		draw_circle(q,r+5,Color("10161c")); draw_rect(Rect2(q-Vector2(r,r),Vector2(r,r)*2),Color("4b8192")); draw_line(q,q+Vector2(25,0)*scale,CYAN,5*scale)
		draw_bar(q+Vector2(-20,-24)*scale,Vector2(40,4)*scale,float(device.hp)/maxf(1,device.max_hp),CYAN)
		if device.get("copy",false): draw_arc(q,24*scale,0,TAU,24,PURPLE,2)
	for e in sim.enemies:
		var q=world_to_screen(e.p); var kind=str(e.kind)
		if kind=="cocoon":
			draw_circle(q,24*scale,Color("75516e")); draw_arc(q,25*scale,0,TAU,20,GOLD,2); draw_line(q-Vector2(12,0)*scale,q+Vector2(12,0)*scale,Color("c5d77a"),6*scale)
		else:
			var visual_kind={"roach":"brute","hydra":"spitter","boss":"boss","node":"brute","lurker":"brute","infestor":"spitter"}.get(kind,"runner")
			Visuals.draw_enemy(self,q,visual_kind,(sim.p-e.p).angle(),0 if settings.reduced_motion else sim.elapsed,0,scale*(1.15 if kind=="boss" else 1.0))
			if kind=="baneling": draw_circle(q,10*scale,Color("98d873"))
		if float(e.hp)<float(e.max_hp) or kind in ["boss","cocoon"]: draw_bar(q+Vector2(-24,-float(e.r)-12)*scale,Vector2(48,5)*scale,float(e.hp)/float(e.max_hp),RED)
		if kind=="cocoon": draw_string(font,q+Vector2(-27,-36)*scale,"%.1fs"%e.get("cocoon_left",8.0),HORIZONTAL_ALIGNMENT_CENTER,60,fs(15),GOLD)
		if float(e.get("warning",0))>0:
			draw_arc(q,float(e.r)*scale+7,0,TAU,20,GOLD,2); draw_string(font,q+Vector2(-6,-30),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,fs(20),GOLD)
	for pending in sim._friendly_pending:
		var q=world_to_screen(pending.p); draw_circle(q,7*scale,CYAN); draw_arc(q,float(pending.r)*scale,0,TAU,32,Color(CYAN,.4),1.5,true)
	for fx in sim.effects:
		var q=world_to_screen(fx.p)
		if fx.kind=="shot": draw_line(q,world_to_screen(fx.get("to",fx.p)),Color("e9bf6f"),1.5,true)
		elif fx.kind=="explosion": draw_arc(q,float(fx.get("r",35))*scale,0,TAU,32,Color(1,.65,.3,.45),2,true)
		elif fx.kind=="heal" and not settings.low_fx: draw_string(font,q,"+",HORIZONTAL_ALIGNMENT_CENTER,20,fs(18),GREEN)
	for h in sim.hazards: draw_hazard(h,true)
	for shot in sim.projectiles:
		var q=world_to_screen(shot.p); draw_circle(q,float(shot.get("r",5))*scale,Color("ffb19b") if shot.get("kind","")=="acid" else CYAN)
		if not Rect2(Vector2(0,100),get_viewport_rect().size-Vector2(0,100)).has_point(q):
			var edge=q.clamp(Vector2(12,112),get_viewport_rect().size-Vector2(12,12)); var dir=(q-get_viewport_rect().size*.5).normalized(); var side=dir.orthogonal(); draw_colored_polygon(PackedVector2Array([edge+dir*10,edge-dir*7+side*6,edge-dir*7-side*6]),RED)
	var player=world_to_screen(sim.p)
	Visuals.draw_marine(self,player,sim.last_dir.angle(),0 if settings.reduced_motion else sim.elapsed,sim.moving,0,scale)
	draw_arc(player,28*scale,.15,TAU-.15,40,Color.WHITE,2,true)
	draw_line(player+sim.last_dir*29*scale,player+sim.last_dir*39*scale,Color.WHITE,3,true)
	if cost_time>0: draw_string(font,player+Vector2(20,-35),cost_text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs(16),GOLD)
	if sim.shield>0: draw_arc(player,35*scale,0,TAU,40,Color("6bcbff"),2,true)
	var target=find_enemy(sim.mark_uid)
	if not target.is_empty():
		var q=world_to_screen(target.p); var r=maxf(float(target.r)*scale+15,24)
		var points=PackedVector2Array([q+Vector2(0,-r),q+Vector2(r,0),q+Vector2(0,r),q+Vector2(-r,0),q+Vector2(0,-r)])
		draw_polyline(points,CYAN,2,true); draw_string(font,q+Vector2(-40,-r-8),"集火 %.1fs"%sim.mark_left,HORIZONTAL_ALIGNMENT_LEFT,-1,fs(15),CYAN)
	if skill_held:
		var preview=sim.skill_preview(); var q=world_to_screen(preview.get("p",sim.p)); var radius=float(preview.get("r",80))*scale
		draw_arc(q,radius,0,TAU,48,RED if skill_cancel else CYAN,2,true)
		var rect=cancel_rect(); draw_rect(rect,Color("33232b") if skill_cancel else PANEL); draw_rect(rect,RED,false,2)
		draw_string(font,rect.position+Vector2(10,rect.size.y*.58),"松开取消" if skill_cancel else "拖入取消",HORIZONTAL_ALIGNMENT_LEFT,-1,fs(18),TEXT)
		var reason=str(preview.get("reason",""))
		if run.class_id=="C01": reason="消耗当前生命12%，保留至少1生命"
		elif run.class_id=="C06": reason="部署新炮台；达到两座时回收最旧炮台"
		draw_string(font,Vector2(30,get_viewport_rect().size.y-100),reason,HORIZONTAL_ALIGNMENT_LEFT,-1,fs(18),GOLD)
	if dash_held:
		var stats=Build.stats(run); var end=sim.p+sim.last_dir*float(stats.get("dash_distance",180)); draw_line(player,world_to_screen(end),CYAN,2,true)

func draw_bar(pos: Vector2, size: Vector2, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos,size),Color("0b1118")); draw_rect(Rect2(pos,Vector2(size.x*clampf(ratio,0,1),size.y)),color)

func draw_hazard(h: Dictionary, outline: bool) -> void:
	var scale=world_scale(); var p=world_to_screen(h.p); var friendly=h.get("friendly",false); var warning=float(h.get("warning",0))+float(h.get("delay",0))>0
	var danger=Color("ffcb70") if settings.color_assist else RED
	var edge=CYAN if friendly else danger
	var fill=Color(edge,.08 if warning else .15)
	var width=3.0 if settings.danger_outline else 2.0
	match str(h.kind):
		"line":
			var angle=float(h.get("angle",0)); var length=float(h.get("length",600))*scale; var half=float(h.get("width",40))*scale*.5
			var dir=Vector2.from_angle(angle); var side=dir.orthogonal()*half
			var pts=PackedVector2Array([p-side,p+dir*length-side,p+dir*length+side,p+side])
			if outline:
				pts.append(pts[0]); draw_polyline(pts,edge,width,true)
				for n in range(1,6):
					var q=p+dir*length*n/6.0; draw_line(q-dir*10-side*.4,q,edge,2); draw_line(q-dir*10+side*.4,q,edge,2)
			else: draw_colored_polygon(pts,fill)
		"beam":
			var angle=float(h.get("angle",0)); var radius=float(h.get("r",h.get("length",1000)))*scale
			var pts=PackedVector2Array([p])
			for n in range(33): pts.append(p+Vector2.from_angle(angle+float(h.get("arc",TAU/3))*n/32.0)*radius)
			pts.append(p)
			if outline:
				draw_polyline(pts,edge,width,true); draw_arc(p,radius*.4,angle+.2,angle+float(h.get("arc",TAU/3))-.2,24,edge,3,true)
				var end_angle=angle+float(h.get("arc",TAU/3))-.2
				var tip=p+Vector2.from_angle(end_angle)*radius*.4; draw_line(tip,tip+Vector2.from_angle(end_angle-PI*.5-.6)*18,edge,3)
				if warning: draw_string(font,p+Vector2(20,-20),"旋转束预警 %.1fs"%(float(h.warning)+float(h.get("delay",0))),HORIZONTAL_ALIGNMENT_LEFT,-1,fs(17),edge)
			else: draw_colored_polygon(pts,fill)
		"edge":
			var radius=float(h.get("r",450))*scale
			if outline: draw_arc(p,radius,0,TAU,64,edge,width,true)
			else:
				for n in range(80):
					var angle=TAU*n/80; var q=p+Vector2.from_angle(angle)*radius; draw_line(q,q+Vector2.from_angle(angle)*160*scale,Color(edge,.15),8)
		_:
			var radius=float(h.get("r",80))*scale
			if outline:
				draw_arc(p,radius,0,TAU,40,edge,width,true)
				if not friendly:
					for n in range(8):
						var a=TAU*n/8; var q=p+Vector2.from_angle(a)*radius; draw_line(q,q+Vector2.from_angle(a+.5)*12,edge,2,true)
				if warning: draw_string(font,p+Vector2(-16,-4),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,fs(20),edge)
			else: draw_circle(p,radius,fill)

func draw_controls() -> void:
	var joy=joystick_origin if move_finger!=-999 else joystick_default(); var unit=dp_scale()
	draw_circle(joy,48*unit,Color(.05,.09,.13,.7)); draw_arc(joy,48*unit,0,TAU,48,Color("8a9ba8"),2,true)
	draw_circle(joy+joystick_vector*40*unit,18*unit,CYAN)
	for kind in ["dash","skill"]:
		var p=control_pos(kind); var radius=control_radius(kind); var held=dash_held if kind=="dash" else skill_held
		var cd=0.0 if not sim else (sim.dash_cd if kind=="dash" else sim.skill_cd)
		draw_circle(p,radius,Color("244653") if held else Color("152530")); draw_arc(p,radius,0,TAU,48,CYAN if cd<=0 else Color("697784"),3,true)
		if cd>0:
			var stats=Build.stats(run); var max_cd=float(stats.dash_cd if kind=="dash" else stats.skill_cd)
			draw_arc(p,radius-5,-PI/2,-PI/2+TAU*clampf(cd/max_cd,0,1),48,Color("6f8391"),5,true)
		var title="冲刺" if kind=="dash" else (Data.CLASSES[run.class_id].skill_name if not run.is_empty() else "职业技能")
		var text=cd_text(cd) if cd>0 else ("≫" if kind=="dash" else "+")
		draw_string(font,p+Vector2(-radius,-2),text,HORIZONTAL_ALIGNMENT_CENTER,radius*2,fs(25),TEXT)
		draw_string(font,p+Vector2(-radius,22),title,HORIZONTAL_ALIGNMENT_CENTER,radius*2,fs(15),MUTED)

func debug_preview(kind: String) -> void:
	preview_mode=true
	if kind=="bridge": show_bridge(); return
	run=Build.new_run("C06",5002026,"campaign"); run.cash=360; run.hp=82; run.wave=2; run.weapons[0].level=2; run.weapons[0].invested=36
	run.supports=["S01"]; run.items={"I11":1,"I31":1}; run.item_invested={"I11":50,"I31":55}
	Build.settle_wave(run,18); run.cash=360
	if kind in ["shop","research","branch"]:
		show_shop()
		if kind=="research": Build.generate_research(run,"工程"); show_research()
		if kind=="branch": upgrade_weapon(int(run.weapons[0].uid))
	elif kind=="settings": show_settings("bridge")
	else:
		run.mode="boss" if kind=="boss" else "pressure"; run.wave=12 if kind=="boss" else 3; run.techs=["T09","T10","T12"]
		start_wave(); countdown=0
		for n in range(120): sim.step(1.0/60,Vector2.RIGHT,{"skill":n==0})
		show_hud()

func sfx(kind: String, category: String) -> void:
	if not sound: return
	var volume=float(settings.get("sound_"+category,.7))
	if volume<=0: return
	sound.play_sfx(kind,linear_to_db(volume))

func danger_feedback() -> void:
	sfx("boss","danger")
	if settings.get("haptic_danger",true) and OS.has_feature("mobile"): Input.vibrate_handheld(45)

func audio_feedback() -> void:
	if not sim: return
	if previous_active_value<sim.active_value and sim.elapsed-last_pickup_sound>=.12:
		last_pickup_sound=sim.elapsed; sfx("pickup","pickup")
	previous_active_value=sim.active_value
	if previous_skill_cd>0 and sim.skill_cd<=0: sfx("level","skill")
	previous_skill_cd=sim.skill_cd
	if not sim.effects.is_empty() and not settings.low_fx: sfx("rifle","weapon")
	if sim.elapsed-last_danger>=1.0:
		for h in sim.hazards:
			if h.get("warning",0)>0 and not h.get("friendly",false) and sim.p.distance_to(h.p)<350:
				last_danger=sim.elapsed; danger_feedback(); break

func preview_capture(kind: String, path: String) -> void:
	debug_preview(kind)
	if path=="" or DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img=get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var error=img.save_png(path)
	print("V5_NATIVE_CAPTURE ",path," result=",error)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		handle_escape()
		get_viewport().set_input_as_handled()

func handle_escape() -> void:
	if is_instance_valid(modal):
		close_dialog()
		if state=="paused": show_pause()
	elif state=="wave":
		pause_game()
	elif state=="paused":
		show_pause()
	elif state=="settings":
		return_settings()
