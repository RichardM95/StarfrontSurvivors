extends CanvasLayer
## Nonblocking radio captions. Synthetic static only, no recorded/spoken dialogue.
signal line_started(speaker: String, text: String)
signal history_opened
signal history_closed
const UISkin = preload("res://scripts/ui_skin.gd")
const LOG_PATH = "user://radio_history_v4.json"
const MAX_HISTORY = 600
var history: Array = []
var pending: Array = []
var current: Dictionary = {}
var panel: PanelContainer
var speaker_label: Label
var portrait: Control
var portrait_id := "adjutant"
var visual_time := 0.0
var slide: Tween
var text_label: Label
var next_button: Button
var log_button: Button
var history_window: PanelContainer
var history_text: RichTextLabel
var hold := 0.0
var chars := 0.0
var enabled := true
var muted := false
var font_resource: Font
var audio: AudioStreamPlayer
var _initialized := false
var _history_loaded := false

func setup(font: Font = null) -> void:
	if _initialized: return
	_initialized=true
	font_resource=font
	layer=15
	var theme=Theme.new()
	if font: theme.default_font=font
	theme.default_font_size=18
	panel=PanelContainer.new()
	panel.position=Vector2(64,146)
	panel.size=Vector2(720,140)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.theme=theme
	var style=StyleBoxFlat.new()
	style.bg_color=Color.TRANSPARENT
	style.border_color=Color.TRANSPARENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left=12; style.content_margin_right=12
	style.content_margin_top=8; style.content_margin_bottom=8
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	panel.draw.connect(func(): UISkin.draw_panel(panel,Rect2(Vector2.ZERO,panel.size),Color("3d4c5e"),Color("0e1217"),10))
	var row=HBoxContainer.new(); row.mouse_filter=Control.MOUSE_FILTER_IGNORE; panel.add_child(row)
	portrait=Control.new(); portrait.custom_minimum_size=Vector2(96,116); portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	portrait.draw.connect(func(): UISkin.portrait(portrait,portrait_id,Rect2(Vector2(0,10),Vector2(96,96)),visual_time,int(chars)<str(current.get("text", "")).length()))
	var col=VBoxContainer.new(); col.size_flags_horizontal=Control.SIZE_EXPAND_FILL; col.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(col)
	speaker_label=Label.new(); speaker_label.add_theme_color_override("font_color",Color("ffa940")); col.add_child(speaker_label)
	text_label=Label.new(); text_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text_label.custom_minimum_size=Vector2(470,76)
	text_label.mouse_filter=Control.MOUSE_FILTER_IGNORE; col.add_child(text_label)
	var buttons=VBoxContainer.new(); row.add_child(buttons)
	next_button=Button.new(); next_button.text="快进"; next_button.custom_minimum_size=Vector2(82,56); next_button.pressed.connect(advance); buttons.add_child(next_button); _skin_button(next_button)
	log_button=Button.new(); log_button.text="记录"; log_button.custom_minimum_size=Vector2(82,56); log_button.pressed.connect(show_history); buttons.add_child(log_button); _skin_button(log_button)
	audio=AudioStreamPlayer.new(); audio.volume_db=-24; audio.stream=_static_sound(); add_child(audio)
	panel.hide()
	load_history()

func _skin_button(button: Button) -> void:
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_color_override("font_color",Color("00d2ff"))
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	for mode in ["normal","hover","pressed"]: button.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	var plate:=Control.new(); plate.show_behind_parent=true; plate.mouse_filter=Control.MOUSE_FILTER_IGNORE; button.add_child(plate)
	plate.draw.connect(func(): UISkin.draw_panel(plate,Rect2(Vector2.ZERO,button.size),Color("ffa940") if button.button_pressed else Color("3d4c5e"),Color("0e1217") if button.button_pressed else Color("26313d"),6))
	button.mouse_entered.connect(plate.queue_redraw); button.mouse_exited.connect(plate.queue_redraw)
	button.button_down.connect(plate.queue_redraw); button.button_up.connect(plate.queue_redraw)

func _speaker_portrait(speaker: String) -> String:
	if speaker.contains("泰隆"): return "tyron"
	if speaker.contains("柯林斯"): return "collins"
	if speaker.contains("汉克"): return "hank"
	if speaker.contains("艾拉"): return "ella"
	return "adjutant"

func _static_sound() -> AudioStreamWAV:
	var wav=AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050
	var bytes=PackedByteArray(); bytes.resize(2205*2)
	var random=RandomNumberGenerator.new(); random.seed=23
	for i in range(2205):
		var value=int(random.randf_range(-1,1)*2200.0*(1.0-float(i)/2205.0))
		bytes.encode_s16(i*2,value)
	wav.data=bytes
	return wav

func play(lines: Array, priority: bool = false) -> void:
	if not _initialized: setup()
	var valid: Array=[]
	for entry in lines:
		if not entry is Dictionary or str(entry.get("text","")).is_empty(): continue
		var line={"speaker":str(entry.get("speaker","通讯")),"text":str(entry.text)}
		valid.append(line)
		history.append(line.duplicate(true))
	while history.size()>MAX_HISTORY: history.pop_front()
	if valid.is_empty(): return
	save_history()
	if priority:
		# Do not discard existing speech: preempt once and replay that complete line later.
		if not current.is_empty(): pending.push_front(current.duplicate(true)); current={}
		pending=valid+pending
	else: pending.append_array(valid)
	if current.is_empty(): _next()

func _next() -> void:
	if pending.is_empty():
		current={}; panel.hide(); return
	current=pending.pop_front(); chars=0.0; hold=0.0
	speaker_label.text="RADIO  /  "+str(current.speaker)
	portrait_id=_speaker_portrait(str(current.speaker))
	portrait.queue_redraw()
	text_label.text=str(current.text); text_label.visible_characters=0
	next_button.text="快进"
	var appearing:=not panel.visible
	panel.visible=enabled
	if appearing and enabled:
		if slide and slide.is_valid(): slide.kill()
		panel.position.x=-panel.size.x
		slide=create_tween()
		slide.tween_property(panel,"position:x",64.0,0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	line_started.emit(str(current.speaker),str(current.text))
	if not muted and audio.is_inside_tree(): audio.play()

func _process(dt: float) -> void:
	if not _initialized or not enabled or current.is_empty() or (is_instance_valid(history_window) and history_window.visible): return
	visual_time+=dt
	portrait.queue_redraw()
	chars+=dt*27.0
	text_label.visible_characters=mini(int(chars),str(current.text).length())
	if int(chars)>=str(current.text).length():
		next_button.text="下一句"; hold+=dt
		if hold>=maxf(2.5,float(str(current.text).length())*0.055): _next()

func advance() -> void:
	if current.is_empty(): return
	if int(chars)<str(current.text).length():
		chars=float(str(current.text).length()); text_label.visible_characters=-1
	else: _next()

func set_display_enabled(value: bool) -> void:
	enabled=value
	if _initialized: panel.visible=value and not current.is_empty()

func clear_queue() -> void:
	pending.clear(); current={}
	if _initialized: panel.hide()

func export_history() -> Array:
	return history.duplicate(true)

func import_history(entries: Array) -> void:
	history=[]
	for line in entries:
		if line is Dictionary and line.get("speaker") is String and line.get("text") is String:
			history.append({"speaker":line.speaker,"text":line.text})
	while history.size()>MAX_HISTORY: history.pop_front()

func save_history() -> bool:
	var file=FileAccess.open(LOG_PATH+".tmp",FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify({"version":1,"lines":history})); file.flush(); file.close()
	if FileAccess.file_exists(LOG_PATH): DirAccess.copy_absolute(LOG_PATH,LOG_PATH+".bak")
	return DirAccess.rename_absolute(LOG_PATH+".tmp",LOG_PATH)==OK

func load_history() -> void:
	if _history_loaded: return
	_history_loaded=true
	for path in [LOG_PATH,LOG_PATH+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("lines") is Array:
			import_history(parsed.lines); return

func show_history() -> void:
	if not _initialized: setup()
	if not is_instance_valid(history_window):
		history_window=PanelContainer.new(); history_window.position=Vector2(110,130); history_window.size=Vector2(1060,590)
		history_window.theme=panel.theme; history_window.add_theme_stylebox_override("panel",panel.get_theme_stylebox("panel")); add_child(history_window)
		history_window.draw.connect(func(): UISkin.draw_panel(history_window,Rect2(Vector2.ZERO,history_window.size),Color("00d2ff"),Color("1a2026"),12))
		var col=VBoxContainer.new(); history_window.add_child(col)
		var header=HBoxContainer.new(); col.add_child(header)
		var label=Label.new(); label.text="战地通讯记录 · 字幕 / 合成电台音效"; label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(label)
		var close=Button.new(); close.text="关闭记录"; close.custom_minimum_size=Vector2(150,56); close.pressed.connect(close_history); header.add_child(close); _skin_button(close)
		history_text=RichTextLabel.new(); history_text.bbcode_enabled=false; history_text.size_flags_vertical=Control.SIZE_EXPAND_FILL
		history_text.custom_minimum_size=Vector2(1000,500); col.add_child(history_text)
	var lines=PackedStringArray()
	for line in history: lines.append(str(line.speaker)+"："+str(line.text))
	history_text.text="\n\n".join(lines)
	history_window.show()
	history_opened.emit()

func close_history() -> void:
	if is_instance_valid(history_window): history_window.hide()
	history_closed.emit()

func apply_safe_area(left: float, right: float, top: float, bottom: float) -> void:
	# Same logical 1280x800 canvas as game; keeps log and radio within device insets.
	transform=Transform2D(Vector2((1280-left-right)/1280.0,0),Vector2(0,(800-top-bottom)/800.0),Vector2(left,top))

func blocks_pointer(position: Vector2) -> bool:
	var local=transform.affine_inverse()*position
	if is_instance_valid(history_window) and history_window.visible: return true
	if not _initialized or not panel.visible: return false
	return next_button.get_global_rect().has_point(local) or log_button.get_global_rect().has_point(local)
