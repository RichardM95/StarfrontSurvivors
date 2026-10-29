class_name SFSkin
extends RefCounted
## Original code-native industrial UI kit. No gameplay state is modified.
const CYAN := Color("00d2ff")
const AMBER := Color("ffa940")
const STEEL := Color("1a2026")
const INK := Color("0e1217")
const LIGHT := Color("e6f7ff")
static var _portraits: Dictionary = {}

static func _chamfer(r: Rect2, cut: float) -> PackedVector2Array:
	var d := minf(cut, minf(r.size.x, r.size.y) * 0.3)
	var p := r.position
	var e := r.end
	return PackedVector2Array([p + Vector2(d,0),Vector2(e.x-d,p.y),Vector2(e.x,p.y+d),e-Vector2(0,d),e-Vector2(d,0),Vector2(p.x+d,e.y),Vector2(p.x,e.y-d),p+Vector2(0,d)])

static func _outline(c: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var loop := points.duplicate()
	loop.append(points[0])
	c.draw_polyline(loop, color, width, true)

static func draw_panel(c: CanvasItem, rect: Rect2, accent: Color = CYAN, fill: Color = STEEL, cut: float = 10.0) -> void:
	if rect.size.x <= 2 or rect.size.y <= 2:
		return
	c.draw_colored_polygon(_chamfer(Rect2(rect.position+Vector2(0,3),rect.size), cut), Color(0,0,0,0.38))
	c.draw_colored_polygon(_chamfer(rect,cut), Color("3d4c5e"))
	var inner := rect.grow(-3)
	c.draw_colored_polygon(_chamfer(inner,maxf(2,cut-2)), fill)
	_outline(c,_chamfer(rect,cut),Color("080c11"),1.4)
	# Machined upper bevel and illuminated inner seal.
	c.draw_line(rect.position+Vector2(cut,1),Vector2(rect.end.x-cut,rect.position.y+1),Color("66798a"),1.0,true)
	_outline(c,_chamfer(inner.grow(-2),maxf(2,cut-4)),Color(accent,0.30),1.0)
	if rect.size.y > 32:
		for y: int in range(int(rect.position.y+11),int(rect.end.y-8),6):
			c.draw_line(Vector2(rect.position.x+8,y),Vector2(rect.end.x-8,y),Color(0.58,0.72,0.82,0.025),1.0)
	if rect.size.x > 75 and rect.size.y > 38:
		for p: Vector2 in [rect.position+Vector2(9,9),Vector2(rect.end.x-9,rect.position.y+9),rect.end-Vector2(9,9),Vector2(rect.position.x+9,rect.end.y-9)]:
			c.draw_circle(p,2.4,Color("080d12"),true,-1,true)
			c.draw_line(p-Vector2(1.2,0.6),p+Vector2(1.2,-0.6),Color("718090"),1.0,true)
		# Short, deliberately subdued machining marks.
		c.draw_line(rect.position+Vector2(19,5),rect.position+Vector2(35,5),Color(0.8,0.9,1,0.10),1)
		c.draw_line(rect.end-Vector2(40,6),rect.end-Vector2(22,6),Color(0.8,0.9,1,0.08),1)
	c.draw_line(rect.position+Vector2(cut+5,3),rect.position+Vector2(minf(rect.size.x*0.25,60),3),accent,2.0,true)

static func draw_hazard(c: CanvasItem, rect: Rect2, color: Color = AMBER) -> void:
	c.draw_rect(rect,Color("11161b"))
	var x := rect.position.x
	while x < rect.end.x:
		var w := minf(7,rect.end.x-x)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x,rect.position.y),Vector2(x+w,rect.position.y),Vector2(minf(rect.end.x,x+w-3),rect.end.y),Vector2(maxf(rect.position.x,x-3),rect.end.y)]),Color(color,0.35))
		x += 13

static func _p(c: CanvasItem, points: Array, col: Color, edge: Color = INK, width: float = 1.3) -> void:
	var a := PackedVector2Array()
	for p: Vector2 in points:
		a.append(p)
	c.draw_colored_polygon(a,col)
	if width > 0:
		_outline(c,a,edge,width)

static func _line(c: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float = 2.5) -> void:
	c.draw_line(a,b,col,width,true)

static func draw_icon(c: CanvasItem, id: String, rect: Rect2, color: Color = CYAN) -> void:
	# All silhouettes use a common 64px design box and scale to HUD sizes.
	var scale_factor := minf(rect.size.x,rect.size.y)/64.0
	var origin := rect.get_center()-Vector2(32,32)*scale_factor
	c.draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	var key := id.to_lower()
	# Semantic equipment families: item IDs may be passed directly by shop/upgrade UI.
	if key in ["marine", "injector", "stim_filter"]: key="stim"
	elif key in ["nanobot", "tissue", "metabolic", "vital_reserve", "bio_pump", "field_rations", "siphon", "med_reserve", "health", "regen", "lifesteal", "revive"]: key="medical"
	elif key in ["core", "heavy_barrel", "long_magazine", "hollow_shell", "damage", "attack"]: key="ballistic"
	elif key in ["exoskeleton", "ceramic", "carbon_mesh", "shock_liner", "reactive_weave", "safety_limiter", "armor", "fortress"]: key="armor_plate"
	elif key in ["scope", "wide_lens", "target_chip", "combat_sensor", "optical_veil", "crit", "range", "focus", "dodge"]: key="optics"
	elif key in ["reactor", "capacitor", "pulse_coil", "gamma_cells", "lucky_circuit", "coolant"]: key="power_core"
	elif key in ["pump", "tripod", "recoil_brace", "micro_servos", "kinetic_belt", "speed"]: key="servo"
	elif key in ["salvage_claw", "flux_anchor", "magnet_core", "magnet"]: key="magnet_device"
	elif key in ["storage", "war_chest"]: key="supply_case"
	elif key == "extra_dash": key="dash"
	elif key in ["sentry", "turret"]: key="turret_icon"
	elif key == "spider_mine": key="mine"
	if key.contains("sniper"): key="sniper"
	elif key.contains("shotgun"): key="shotgun"
	elif key.contains("flame") or key.contains("incinerator"): key="flame"
	elif key.contains("grenade"): key="grenade"
	elif key.contains("tesla"): key="tesla"
	elif key.contains("smg"): key="smg"
	elif key.contains("beam") or key.contains("cannon"): key="beam"
	elif key == "weapon_reaper": key="smg"
	elif key.contains("rifle") or key.contains("railgun"): key="rifle"
	var metal := Color("a5bdc9")
	var dark := Color("364a59")
	match key:
		"rifle", "smg", "sniper", "shotgun":
			# Distinct stock, receiver, magazine, barrel and sights.
			var short := key == "smg"
			var barrel := 45.0 if short else 56.0
			_p(c,[Vector2(5,28),Vector2(15,25),Vector2(20,28),Vector2(39,25),Vector2(43,30),Vector2(40,38),Vector2(19,38),Vector2(11,43),Vector2(5,41)],dark)
			c.draw_rect(Rect2(37,28,barrel-37,7),metal)
			c.draw_rect(Rect2(barrel-2,26,5,11),dark)
			_p(c,[Vector2(25,36),Vector2(34,36),Vector2(31,49),Vector2(24,49)],metal)
			_line(c,Vector2(17,29),Vector2(36,29),color,3)
			_line(c,Vector2(7,31),Vector2(15,31),metal,2)
			if key == "sniper":
				c.draw_rect(Rect2(23,17,17,7),dark)
				c.draw_circle(Vector2(39,20),4,color)
				_line(c,Vector2(26,24),Vector2(26,27),metal,2)
				_line(c,Vector2(34,24),Vector2(34,27),metal,2)
			elif key == "shotgun":
				c.draw_rect(Rect2(37,36,20,4),metal)
				for x in [22,27,32]: _line(c,Vector2(x,32),Vector2(x,38),AMBER,2)
			elif key == "smg":
				_line(c,Vector2(29,19),Vector2(40,19),color,3)
				_line(c,Vector2(45,19),Vector2(56,19),color,3)
				_line(c,Vector2(48,24),Vector2(59,24),color,3)
		"flame", "firebat":
			_p(c,[Vector2(7,29),Vector2(29,24),Vector2(37,29),Vector2(37,39),Vector2(10,41)],dark)
			c.draw_rect(Rect2(13,37,10,13),metal)
			c.draw_rect(Rect2(29,27,10,5),metal)
			c.draw_rect(Rect2(29,36,10,5),metal)
			_p(c,[Vector2(38,34),Vector2(47,17),Vector2(46,29),Vector2(58,22),Vector2(55,35),Vector2(60,42),Vector2(45,47)],Color("ff8c00"))
			_p(c,[Vector2(40,35),Vector2(49,27),Vector2(48,36),Vector2(54,39),Vector2(43,41)],Color("ffdf7a"),INK,0)
		"grenade", "explosive":
			_p(c,[Vector2(23,19),Vector2(39,19),Vector2(45,31),Vector2(39,48),Vector2(22,48),Vector2(17,31)],dark)
			c.draw_rect(Rect2(25,12,13,7),metal)
			_line(c,Vector2(38,15),Vector2(45,22),metal,3)
			for y in [27,34,41]: _line(c,Vector2(22,y),Vector2(40,y),AMBER,3)
			for a: float in [-0.8,0.0,0.8,2.3,3.14,3.9]: _line(c,Vector2(32,32)+Vector2.from_angle(a)*24,Vector2(32,32)+Vector2.from_angle(a)*30,color,2)
		"tesla", "ghost", "hightech", "high-tech":
			c.draw_arc(Vector2(32,32),21,0,TAU,32,Color(color,0.5),2,true)
			_p(c,[Vector2(35,8),Vector2(19,33),Vector2(31,33),Vector2(25,56),Vector2(47,27),Vector2(35,27)],color)
			for a: float in [0.0,PI/2,PI,PI*1.5]:
				var v := Vector2.from_angle(a)
				_line(c,Vector2(32,32)+v*23,Vector2(32,32)+v*29,metal,2)
		"beam", "plasma":
			c.draw_circle(Vector2(32,32),10,Color(color,0.2))
			c.draw_circle(Vector2(32,32),5,color)
			c.draw_arc(Vector2(32,32),18,-1.2,1.2,18,metal,5,true)
			c.draw_arc(Vector2(32,32),18,PI-1.2,PI+1.2,18,metal,5,true)
			_line(c,Vector2(4,32),Vector2(60,32),Color(color,0.25),8)
			_line(c,Vector2(5,32),Vector2(59,32),color,2)
		"stim", "marine":
			# Brass syringe with clear medicine core.
			_p(c,[Vector2(18,13),Vector2(25,9),Vector2(48,36),Vector2(42,42)],Color("bd8d4e"))
			_p(c,[Vector2(23,19),Vector2(28,15),Vector2(43,33),Vector2(38,37)],Color("49e344"))
			_line(c,Vector2(43,39),Vector2(55,54),metal,2)
			_line(c,Vector2(12,16),Vector2(25,5),metal,4)
			c.draw_circle(Vector2(54,57),2.8,Color("49e344"))
		"marauder", "fist":
			_p(c,[Vector2(16,14),Vector2(25,11),Vector2(31,16),Vector2(40,14),Vector2(47,23),Vector2(44,38),Vector2(33,45),Vector2(19,39),Vector2(13,25)],metal)
			for x in [21,28,35,42]: _line(c,Vector2(x,18),Vector2(x+2,28),dark,3)
			c.draw_arc(Vector2(31,38),16,0.1,PI-0.1,20,AMBER,3,true)
			c.draw_arc(Vector2(31,38),23,0.1,PI-0.1,20,color,2,true)
		"reaper", "mine":
			for a: float in [-PI/2,PI/6,PI*5/6]:
				var v := Vector2.from_angle(a)
				_line(c,Vector2(32,32)+v*10,Vector2(32,32)+v*27,metal,7)
				c.draw_circle(Vector2(32,32)+v*27,4,dark)
			c.draw_circle(Vector2(32,32),17,dark)
			c.draw_arc(Vector2(32,32),14,0,TAU,32,metal,2,true)
			c.draw_circle(Vector2(32,32),6,Color("ff3344"))
		"ballistic":
			for i in range(3):
				var x := 12.0 + i*15.0
				_p(c,[Vector2(x,24),Vector2(x+5,13-i*3),Vector2(x+10,24),Vector2(x+10,48),Vector2(x,48)],Color("d5a661"))
				_line(c,Vector2(x+2,27),Vector2(x+2,44),Color("ffe1a4"),2)
				_line(c,Vector2(x,43),Vector2(x+10,43),dark,2)
		"engineering", "wrench":
			var pts: Array = []
			for i in range(6): pts.append(Vector2(32,32)+Vector2.from_angle(i*TAU/6)*23)
			_p(c,pts,Color("bf9447"))
			c.draw_circle(Vector2(32,32),11,INK)
			_line(c,Vector2(17,48),Vector2(44,21),metal,7)
			_p(c,[Vector2(36,16),Vector2(42,11),Vector2(41,20),Vector2(47,24),Vector2(55,20),Vector2(51,30),Vector2(42,31),Vector2(34,23)],metal)
		"mineral", "minerals", "crystal":
			for pair: Vector2 in [Vector2(13,23),Vector2(28,10),Vector2(42,20)]:
				_p(c,[pair, pair+Vector2(7,-8),pair+Vector2(14,0),Vector2(pair.x+10,51),Vector2(pair.x+3,54)],Color("40a9ff"))
				_line(c,pair+Vector2(7,-6),Vector2(pair.x+7,48),Color("b5f3ff"),2)
		"gas", "vespene":
			for x in [13,34]:
				c.draw_rect(Rect2(x+5,10,9,6),metal)
				_p(c,[Vector2(x+3,17),Vector2(x+16,17),Vector2(x+20,24),Vector2(x+20,49),Vector2(x,49),Vector2(x,24)],dark)
				c.draw_rect(Rect2(x+5,25,10,17),Color("49e344"))
				_line(c,Vector2(x+6,27),Vector2(x+6,40),Color("c9ffc1"),2)
		"medical":
			_p(c,[Vector2(16,12),Vector2(48,12),Vector2(53,18),Vector2(53,50),Vector2(11,50),Vector2(11,18)],dark)
			c.draw_rect(Rect2(24,7,16,6),metal)
			c.draw_rect(Rect2(26,22,12,23),Color("6de6ad"))
			c.draw_rect(Rect2(20,28,24,11),Color("6de6ad"))
			_line(c,Vector2(16,46),Vector2(22,46),metal,2)
		"armor_plate":
			_p(c,[Vector2(11,12),Vector2(24,8),Vector2(32,17),Vector2(40,8),Vector2(53,12),Vector2(49,38),Vector2(32,56),Vector2(15,38)],metal)
			_p(c,[Vector2(20,20),Vector2(32,26),Vector2(44,20),Vector2(42,36),Vector2(32,47),Vector2(22,36)],dark)
			_line(c,Vector2(32,27),Vector2(32,44),color,3)
			_line(c,Vector2(25,34),Vector2(39,34),color,3)
		"optics":
			c.draw_circle(Vector2(32,32),23,dark)
			c.draw_arc(Vector2(32,32),21,0,TAU,32,metal,3,true)
			c.draw_circle(Vector2(32,32),14,Color(color,0.25))
			for a: float in [0.0,PI/2,PI,PI*1.5]:
				var v := Vector2.from_angle(a)
				_line(c,Vector2(32,32)+v*8,Vector2(32,32)+v*27,color,2)
			c.draw_circle(Vector2(32,32),3,AMBER)
		"power_core":
			_p(c,[Vector2(19,10),Vector2(45,10),Vector2(51,20),Vector2(51,44),Vector2(45,54),Vector2(19,54),Vector2(13,44),Vector2(13,20)],dark)
			for y in [17,26,35,44]:
				_line(c,Vector2(8,y),Vector2(16,y),metal,3)
				_line(c,Vector2(48,y),Vector2(56,y),metal,3)
			_p(c,[Vector2(35,15),Vector2(23,33),Vector2(32,33),Vector2(28,49),Vector2(42,28),Vector2(33,28)],AMBER,INK,1)
		"servo":
			_p(c,[Vector2(17,9),Vector2(30,9),Vector2(30,28),Vector2(43,38),Vector2(39,51),Vector2(19,36)],metal)
			c.draw_circle(Vector2(25,29),10,dark)
			c.draw_circle(Vector2(25,29),5,color)
			_p(c,[Vector2(39,41),Vector2(48,43),Vector2(55,53),Vector2(28,53),Vector2(28,47)],dark)
			_line(c,Vector2(16,16),Vector2(29,16),AMBER,3)
		"magnet_device":
			c.draw_arc(Vector2(32,31),18,0,PI,24,metal,11,true)
			c.draw_rect(Rect2(8,13,12,20),metal)
			c.draw_rect(Rect2(44,13,12,20),metal)
			c.draw_rect(Rect2(8,10,12,9),Color("ff6c59"))
			c.draw_rect(Rect2(44,10,12,9),color)
			_line(c,Vector2(25,20),Vector2(29,25),AMBER,2)
			_line(c,Vector2(39,20),Vector2(35,25),AMBER,2)
			c.draw_circle(Vector2(32,17),3,color)
		"supply_case":
			_p(c,[Vector2(10,19),Vector2(17,12),Vector2(47,12),Vector2(54,19),Vector2(54,49),Vector2(10,49)],dark)
			c.draw_rect(Rect2(24,7,16,6),metal)
			for x in [17,43]: c.draw_rect(Rect2(x,15,5,31),metal)
			c.draw_rect(Rect2(10,25,44,5),AMBER)
			c.draw_rect(Rect2(28,23,8,10),metal)
		"turret_icon":
			c.draw_rect(Rect2(15,18,30,12),dark)
			c.draw_rect(Rect2(38,20,21,6),metal)
			c.draw_circle(Vector2(29,32),9,metal)
			for x in [10,32,53]: _line(c,Vector2(29,36),Vector2(x,54),metal,5)
			_line(c,Vector2(19,21),Vector2(32,21),color,3)
		"medic_drone", "raven":
			c.draw_circle(Vector2(32,32),13,dark)
			for x in [12,52]:
				_line(c,Vector2(32,32),Vector2(x,22),metal,5)
				c.draw_arc(Vector2(x,22),9,0,TAU,20,color,2,true)
			if key == "medic_drone":
				c.draw_rect(Rect2(29,23,6,18),Color("6de6ad"))
				c.draw_rect(Rect2(23,29,18,6),Color("6de6ad"))
			else:
				_p(c,[Vector2(23,29),Vector2(32,23),Vector2(41,29),Vector2(32,43)],AMBER)
		"lock":
			c.draw_arc(Vector2(32,26),13,PI,TAU,24,AMBER,6,true)
			c.draw_rect(Rect2(16,26,32,26),AMBER)
			c.draw_circle(Vector2(32,36),4,INK)
			c.draw_rect(Rect2(30,36,4,10),INK)
		"dash":
			for x in [8,25,42]:
				c.draw_polyline(PackedVector2Array([Vector2(x,15),Vector2(x+14,32),Vector2(x,49)]),color,5,true)
		_:
			# Item families retain a visible mechanical chip silhouette, never a text monogram.
			c.draw_rect(Rect2(18,18,28,28),dark)
			c.draw_rect(Rect2(24,24,16,16),color)
			for n in [23,32,41]:
				_line(c,Vector2(n,10),Vector2(n,18),metal,2)
				_line(c,Vector2(n,46),Vector2(n,54),metal,2)
				_line(c,Vector2(10,n),Vector2(18,n),metal,2)
				_line(c,Vector2(46,n),Vector2(54,n),metal,2)
	c.draw_set_transform(Vector2.ZERO)

static func portrait(c: CanvasItem, id: String, rect: Rect2, time: float = 0.0, talking: bool = false) -> void:
	var key := id.to_lower()
	if key.contains("23") or key.contains("副官"): key="adjutant"
	elif key.contains("柯林") or key.contains("capt"): key="collins"
	elif key.contains("汉克") or key.contains("chief"): key="hank"
	elif key.contains("艾拉") or key.contains("doc"): key="ella"
	elif key.contains("泰隆") or key in ["marine","marauder","reaper","firebat","ghost"]: key="tyron"
	if not _portraits.has(key) or _portraits[key] == null:
		var path := "res://assets/ui/portraits/%s.webp" % key
		_portraits[key] = load(path) if ResourceLoader.exists(path) else null
	draw_panel(c,rect,CYAN,INK,9)
	var view := rect.grow(-5)
	var texture: Texture2D = _portraits[key] as Texture2D
	if texture != null:
		c.draw_texture_rect(texture,view,false,Color(0.90,0.98,1,1))
	else:
		# Explicit inactive channel visual while asset is not yet available.
		c.draw_rect(view,Color("142936"))
		c.draw_arc(view.get_center(),minf(view.size.x,view.size.y)*0.24,0,TAU,32,Color(CYAN,0.3),2,true)
		c.draw_line(view.position,view.end,Color(CYAN,0.15),1)
		c.draw_line(Vector2(view.end.x,view.position.y),Vector2(view.position.x,view.end.y),Color(CYAN,0.15),1)
	for y: int in range(int(view.position.y),int(view.end.y),4):
		c.draw_line(Vector2(view.position.x,y),Vector2(view.end.x,y),Color(0,0.05,0.07,0.16),1)
	var scan_y := view.position.y + fmod(time*12,view.size.y)
	c.draw_line(Vector2(view.position.x,scan_y),Vector2(view.end.x,scan_y),Color(CYAN,0.13),2)
	# Video monitor accents and animated waveform, not claimed as facial lip-sync.
	c.draw_rect(Rect2(view.position+Vector2(0,view.size.y-11),Vector2(view.size.x,11)),Color(0.02,0.05,0.08,0.78))
	var base := view.end.y-5
	var start := view.position.x+4
	for i in range(16):
		var amplitude := 1.0 + (absf(sin(time*8+i*1.7))*3.5 if talking else 0.4)
		var x := start + i*(view.size.x-8)/16
		c.draw_line(Vector2(x,base-amplitude),Vector2(x,base+amplitude),Color(CYAN,0.8),1.2,true)
	_outline(c,_chamfer(rect.grow(-2),7),Color(CYAN,0.55),1)
