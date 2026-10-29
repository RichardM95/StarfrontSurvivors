class_name SFVisuals
extends RefCounted
## Original vector artwork. All actor silhouettes face +X before rotation.

const INK := Color("080e18")
const BLUE_DARK := Color("173856")
const BLUE := Color("2875a5")
const BLUE_LIGHT := Color("5fb9d6")
const CYAN := Color("b5f5f4")
const PURPLE := Color("795480")
const LIME := Color("c4ef6c")

static func _poly(c: CanvasItem, pts: PackedVector2Array, color: Color, edge: Color = INK, width: float = 1.6) -> void:
	c.draw_colored_polygon(pts, color)
	if width > 0.0:
		var ring: PackedVector2Array = pts.duplicate()
		ring.append(pts[0])
		c.draw_polyline(ring, edge, width, true)

static func _ellipse(c: CanvasItem, center: Vector2, radii: Vector2, color: Color, outline: bool = false) -> void:
	var pts := PackedVector2Array()
	for i: int in range(24):
		var a: float = float(i) * TAU / 24.0
		pts.append(center + Vector2(cos(a), sin(a)) * radii)
	_poly(c, pts, color, INK, 1.5 if outline else 0.0)

static func _tint(color: Color, flash: float) -> Color:
	return color.lerp(Color.WHITE, clampf(flash, 0.0, 0.9))

static func draw_marine(c: CanvasItem, p: Vector2, angle: float, time: float, moving: bool, flash: float = 0.0, scale_factor: float = 1.0) -> void:
	c.draw_circle(p + Vector2(0, 7) * scale_factor, 23.0 * scale_factor, Color(0.0, 0.0, 0.0, 0.35))
	c.draw_set_transform(p, angle, Vector2.ONE * scale_factor)
	var step: float = sin(time * 15.0) * (4.5 if moving else 0.5)
	var armor: Color = _tint(BLUE, flash * 0.06)
	var dark: Color = _tint(BLUE_DARK, flash * 0.04)
	var light: Color = _tint(BLUE_LIGHT, flash * 0.08)
	# Heavy articulated boots, visible below the armour.
	_poly(c, PackedVector2Array([Vector2(-17 + step, -11), Vector2(-5 + step, -11), Vector2(-3 + step, -5), Vector2(-17 + step, -4)]), dark)
	_poly(c, PackedVector2Array([Vector2(-17 - step, 4), Vector2(-3 - step, 5), Vector2(-5 - step, 11), Vector2(-17 - step, 11)]), dark)
	c.draw_line(Vector2(-14 + step, -9), Vector2(-6 + step, -9), light, 2.0, true)
	c.draw_line(Vector2(-14 - step, 8), Vector2(-6 - step, 8), light, 2.0, true)
	# Twin exhaust backpack.
	_poly(c, PackedVector2Array([Vector2(-15, -10), Vector2(-7, -14), Vector2(1, -9), Vector2(1, 9), Vector2(-7, 14), Vector2(-15, 10)]), dark)
	c.draw_line(Vector2(-12, -7), Vector2(-12, -2), Color("07141d"), 3.0)
	c.draw_line(Vector2(-12, 2), Vector2(-12, 7), Color("07141d"), 3.0)
	c.draw_circle(Vector2(-14, -7), 1.8, Color("71d4ef"))
	c.draw_circle(Vector2(-14, 7), 1.8, Color("71d4ef"))
	# Chest and rounded pauldrons.
	_poly(c, PackedVector2Array([Vector2(-9, -10), Vector2(5, -12), Vector2(13, -6), Vector2(13, 6), Vector2(5, 12), Vector2(-9, 10)]), armor)
	_poly(c, PackedVector2Array([Vector2(-7, -18), Vector2(4, -20), Vector2(11, -16), Vector2(10, -9), Vector2(-8, -8), Vector2(-12, -13)]), armor)
	_poly(c, PackedVector2Array([Vector2(-8, 8), Vector2(10, 9), Vector2(11, 16), Vector2(4, 20), Vector2(-7, 18), Vector2(-12, 13)]), armor)
	c.draw_polyline(PackedVector2Array([Vector2(-7, -17), Vector2(3, -18), Vector2(8, -15)]), light, 2.0, true)
	c.draw_polyline(PackedVector2Array([Vector2(-7, 16), Vector2(3, 17), Vector2(8, 14)]), light, 2.0, true)
	# White field stripe and little unit chevron.
	c.draw_line(Vector2(-3, -17), Vector2(0, -10), Color("d9e7e8"), 2.4, true)
	c.draw_line(Vector2(-4, 13), Vector2(2, 13), Color("d9e7e8"), 1.5, true)
	c.draw_line(Vector2(-2, 11), Vector2(4, 11), Color("d9e7e8"), 1.5, true)
	# Forearm and long, dark rifle. Aim is aligned with the whole silhouette.
	_poly(c, PackedVector2Array([Vector2(9, 9), Vector2(16, 7), Vector2(22, 9), Vector2(19, 14), Vector2(10, 16)]), dark)
	_poly(c, PackedVector2Array([Vector2(11, 1), Vector2(30, 1), Vector2(33, 4), Vector2(29, 8), Vector2(10, 8)]), Color("132633"))
	c.draw_rect(Rect2(27, 2, 12, 4), Color("718894"))
	c.draw_rect(Rect2(37, 1, 4, 6), Color("0a131d"))
	c.draw_line(Vector2(15, 3), Vector2(28, 3), Color("91a8b4"), 1.5, true)
	c.draw_rect(Rect2(14, 7, 7, 4), Color("c18c48"))
	# Helmet, forward-facing gold visor and raised neck ring.
	_ellipse(c, Vector2(4, -1), Vector2(9, 9), dark, true)
	_poly(c, PackedVector2Array([Vector2(-2, -8), Vector2(8, -9), Vector2(14, -4), Vector2(14, 3), Vector2(8, 7), Vector2(-2, 6), Vector2(-5, 0)]), armor)
	_poly(c, PackedVector2Array([Vector2(8, -6), Vector2(13, -3), Vector2(13, 2), Vector2(8, 4), Vector2(5, 1), Vector2(5, -3)]), Color("f2b961"), Color("5d462a"), 1.2)
	c.draw_line(Vector2(8, -4), Vector2(11, -3), Color("fff0b9"), 1.7, true)
	c.draw_line(Vector2(-1, -6), Vector2(5, -7), light, 1.5, true)
	c.draw_circle(Vector2(4, 6), 1.4, CYAN)
	# The firing pulse belongs at the muzzle, not across the entire armour.
	if flash > 0.6:
		c.draw_circle(Vector2(44, 4), 10.0, Color(1.0, 0.55, 0.12, 0.16))
		_poly(c, PackedVector2Array([Vector2(40, 4), Vector2(46, -2), Vector2(47, 1), Vector2(56, 4), Vector2(47, 7), Vector2(46, 10)]), Color("ffae47"), INK, 0.0)
		_poly(c, PackedVector2Array([Vector2(40, 4), Vector2(46, 1), Vector2(51, 4), Vector2(46, 7)]), Color("fff1bc"), INK, 0.0)
	c.draw_set_transform(Vector2.ZERO)

static func draw_enemy(c: CanvasItem, p: Vector2, kind: String, angle: float, time: float, flash: float = 0.0, scale_factor: float = 1.0) -> void:
	var radius: float = 17.0
	if kind == "spitter":
		radius = 22.0
	elif kind == "brute":
		radius = 30.0
	elif kind == "boss":
		radius = 55.0
	c.draw_circle(p + Vector2(0, radius * 0.25), radius * scale_factor, Color(0.0, 0.0, 0.0, 0.32))
	c.draw_set_transform(p, angle, Vector2.ONE * scale_factor)
	match kind:
		"spitter":
			_draw_spitter(c, time, flash)
		"brute":
			_draw_brute(c, time, flash)
		"boss":
			_draw_boss(c, time, flash)
		_:
			_draw_runner(c, time, flash)
	c.draw_set_transform(Vector2.ZERO)

static func _draw_runner(c: CanvasItem, time: float, flash: float) -> void:
	var skin: Color = _tint(Color("6c457d"), flash)
	var shell: Color = _tint(Color("a4759d"), flash)
	var claw: Color = _tint(Color("efcba8"), flash)
	for side: float in [-1.0, 1.0]:
		var gait: float = sin(time * 17.0 + side) * 3.0
		_poly(c, PackedVector2Array([Vector2(-6, side * 6), Vector2(-15 + gait, side * 13), Vector2(-19 + gait, side * 9), Vector2(-14 + gait, side * 17), Vector2(-8, side * 12), Vector2(0, side * 8)]), skin)
		_poly(c, PackedVector2Array([Vector2(2, side * 5), Vector2(12 + gait, side * 14), Vector2(20 + gait, side * 13), Vector2(12 + gait, side * 19), Vector2(6, side * 16), Vector2(-2, side * 9)]), skin)
		_poly(c, PackedVector2Array([Vector2(9, side * 8), Vector2(19, side * 8), Vector2(25, side * 2), Vector2(20, side * 11), Vector2(12, side * 13)]), claw)
	_poly(c, PackedVector2Array([Vector2(-20, 0), Vector2(-8, -9), Vector2(5, -8), Vector2(13, -3), Vector2(13, 3), Vector2(5, 8), Vector2(-8, 9)]), skin)
	_poly(c, PackedVector2Array([Vector2(-17, 0), Vector2(-6, -6), Vector2(7, -4), Vector2(9, 0), Vector2(7, 4), Vector2(-6, 6)]), shell)
	c.draw_line(Vector2(-14, 0), Vector2(4, 0), Color("4a2e5b"), 2.0, true)
	c.draw_circle(Vector2(10, -4), 2.2, LIME)
	c.draw_circle(Vector2(10, 4), 2.2, LIME)

static func _draw_spitter(c: CanvasItem, time: float, flash: float) -> void:
	var skin: Color = _tint(Color("455c58"), flash)
	var shell: Color = _tint(Color("8c69a2"), flash)
	var acid: Color = _tint(Color("a6d964"), flash)
	for side: float in [-1.0, 1.0]:
		for j: int in range(3):
			var x: float = float(j) * 9.0 - 13.0
			var gait: float = sin(time * 9.0 + float(j) * 2.0 + side) * 2.0
			c.draw_line(Vector2(x, side * 7), Vector2(x - 4 + gait, side * 22), INK, 5.0, true)
			c.draw_line(Vector2(x, side * 7), Vector2(x - 4 + gait, side * 22), shell, 2.5, true)
			c.draw_line(Vector2(x - 4 + gait, side * 22), Vector2(x + gait, side * 24), shell, 2.0, true)
	_ellipse(c, Vector2(-6, 0), Vector2(20, 15), skin, true)
	_ellipse(c, Vector2(-9, 0), Vector2(15, 12), acid, true)
	c.draw_arc(Vector2(-9, 0), 11, PI * 0.65, PI * 1.6, 12, Color("dcf49e"), 2.0, true)
	for x: float in [-17.0, -8.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(x - 3, -13), Vector2(x + 3, -12), Vector2(x + 7, 0), Vector2(x + 3, 12), Vector2(x - 3, 13), Vector2(x, 0)]), shell)
	_poly(c, PackedVector2Array([Vector2(4, -9), Vector2(14, -8), Vector2(20, -4), Vector2(25, -3), Vector2(25, 3), Vector2(20, 4), Vector2(14, 8), Vector2(4, 9), Vector2(9, 0)]), skin)
	c.draw_line(Vector2(18, 0), Vector2(25, 0), Color("c8f27b"), 3.0, true)
	c.draw_circle(Vector2(15, -5), 2.2, LIME)
	c.draw_circle(Vector2(15, 5), 2.2, LIME)

static func _draw_brute(c: CanvasItem, time: float, flash: float) -> void:
	var skin: Color = _tint(Color("593752"), flash)
	var shell: Color = _tint(Color("a75d79"), flash)
	var edge: Color = _tint(Color("d9969d"), flash)
	for side: float in [-1.0, 1.0]:
		var gait: float = sin(time * 7.0 + side) * 3.0
		_poly(c, PackedVector2Array([Vector2(-12, side * 10), Vector2(-26 + gait, side * 16), Vector2(-24 + gait, side * 26), Vector2(-13 + gait, side * 26), Vector2(-11, side * 18)]), skin)
		_poly(c, PackedVector2Array([Vector2(4, side * 13), Vector2(10 - gait, side * 30), Vector2(24 - gait, side * 29), Vector2(21 - gait, side * 17), Vector2(15, side * 12)]), skin)
		_poly(c, PackedVector2Array([Vector2(15, side * 14), Vector2(26, side * 18), Vector2(36, side * 6), Vector2(31, side * 23), Vector2(20, side * 26), Vector2(11, side * 23)]), Color("e5c7aa"))
	_poly(c, PackedVector2Array([Vector2(-28, 0), Vector2(-20, -18), Vector2(-3, -23), Vector2(17, -17), Vector2(26, -7), Vector2(26, 7), Vector2(17, 17), Vector2(-3, 23), Vector2(-20, 18)]), skin)
	_poly(c, PackedVector2Array([Vector2(-25, 0), Vector2(-16, -17), Vector2(0, -20), Vector2(12, -13), Vector2(17, 0), Vector2(12, 13), Vector2(0, 20), Vector2(-16, 17)]), shell)
	for x: float in [-15.0, -3.0, 9.0]:
		c.draw_polyline(PackedVector2Array([Vector2(x - 5, -12), Vector2(x + 3, 0), Vector2(x - 5, 12)]), Color("713d60"), 3.0, true)
		_poly(c, PackedVector2Array([Vector2(x - 4, -3), Vector2(x - 10, 0), Vector2(x - 4, 3), Vector2(x + 4, 0)]), edge)
	_poly(c, PackedVector2Array([Vector2(14, -9), Vector2(27, -7), Vector2(31, 0), Vector2(27, 7), Vector2(14, 9), Vector2(18, 0)]), Color("432e44"))
	c.draw_line(Vector2(22, -5), Vector2(27, -3), Color("ffce7b"), 3.0, true)
	c.draw_line(Vector2(22, 5), Vector2(27, 3), Color("ffce7b"), 3.0, true)

static func _draw_boss(c: CanvasItem, time: float, flash: float) -> void:
	var skin: Color = _tint(Color("4e304e"), flash)
	var shell: Color = _tint(Color("956280"), flash)
	var edge: Color = _tint(Color("d49ba8"), flash)
	var core: Color = _tint(Color("badf69"), flash)
	for side: float in [-1.0, 1.0]:
		for j: int in range(4):
			var x: float = -34.0 + float(j) * 20.0
			var gait: float = sin(time * 5.0 + float(j) * 1.7 + side) * 4.0
			_poly(c, PackedVector2Array([Vector2(x - 10, side * 17), Vector2(x - 17 + gait, side * 39), Vector2(x - 7 + gait, side * 57), Vector2(x + 5 + gait, side * 61), Vector2(x - 1 + gait, side * 43), Vector2(x + 9, side * 23)]), skin)
			c.draw_polyline(PackedVector2Array([Vector2(x - 6, side * 24), Vector2(x - 11 + gait, side * 39), Vector2(x - 1 + gait, side * 54)]), shell, 3.0, true)
		_poly(c, PackedVector2Array([Vector2(18, side * 19), Vector2(42, side * 23), Vector2(62, side * 12), Vector2(72, side * 2), Vector2(62, side * 29), Vector2(46, side * 38), Vector2(23, side * 32)]), Color("c1ad9e"))
		c.draw_line(Vector2(39, side * 28), Vector2(56, side * 21), Color("f2dac1"), 3.0, true)
	_poly(c, PackedVector2Array([Vector2(-60, 0), Vector2(-40, -17), Vector2(-29, -32), Vector2(-4, -39), Vector2(24, -31), Vector2(45, -16), Vector2(50, 0), Vector2(45, 16), Vector2(24, 31), Vector2(-4, 39), Vector2(-29, 32), Vector2(-40, 17)]), skin)
	# Bright dorsal core with segmented chitin ridges.
	_ellipse(c, Vector2(-10, 0), Vector2(32, 27), core, true)
	_ellipse(c, Vector2(-11, 0), Vector2(20, 17), Color("e2f6a1"))
	for j: int in range(4):
		var x: float = -36.0 + float(j) * 18.0
		_poly(c, PackedVector2Array([Vector2(x - 11, -13), Vector2(x - 5, -31), Vector2(x + 9, -32), Vector2(x + 17, -17), Vector2(x + 5, -21), Vector2(x - 3, -12)]), shell)
		_poly(c, PackedVector2Array([Vector2(x - 11, 13), Vector2(x - 5, 31), Vector2(x + 9, 32), Vector2(x + 17, 17), Vector2(x + 5, 21), Vector2(x - 3, 12)]), shell)
		c.draw_line(Vector2(x - 3, -28), Vector2(x + 7, -28), edge, 2.0, true)
		c.draw_line(Vector2(x - 3, 28), Vector2(x + 7, 28), edge, 2.0, true)
		_poly(c, PackedVector2Array([Vector2(x - 8, -5), Vector2(x - 16, 0), Vector2(x - 8, 5), Vector2(x + 9, 0)]), shell)
	_poly(c, PackedVector2Array([Vector2(23, -19), Vector2(40, -17), Vector2(54, -8), Vector2(58, 0), Vector2(54, 8), Vector2(40, 17), Vector2(23, 19), Vector2(32, 0)]), Color("4c344b"))
	_poly(c, PackedVector2Array([Vector2(38, -8), Vector2(47, -5), Vector2(51, 0), Vector2(47, 5), Vector2(38, 8), Vector2(41, 0)]), shell)
	c.draw_line(Vector2(38, -12), Vector2(48, -7), Color("f2ee8c"), 4.0, true)
	c.draw_line(Vector2(38, 12), Vector2(48, 7), Color("f2ee8c"), 4.0, true)
	for side: float in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(47, side * 9), Vector2(56, side * 13), Vector2(62, side * 5), Vector2(58, side * 17), Vector2(48, side * 18)]), Color("e9d2b2"))

static func draw_weapon_icon(c: CanvasItem, p: Vector2, kind: String, scale_factor: float = 1.0) -> void:
	c.draw_set_transform(p, -0.25, Vector2.ONE * scale_factor)
	var metal := Color("8fa9ba")
	var dark := Color("263d51")
	match kind:
		"shotgun":
			_poly(c, PackedVector2Array([Vector2(-30, -3), Vector2(-18, -5), Vector2(-11, -2), Vector2(13, -2), Vector2(13, 8), Vector2(-10, 8), Vector2(-17, 5), Vector2(-29, 10)]), dark)
			c.draw_rect(Rect2(4, -5, 31, 5), metal)
			c.draw_rect(Rect2(4, 1, 31, 5), Color("4e6c83"))
			c.draw_rect(Rect2(-6, -3, 17, 11), Color("b57c4b"))
			for x: int in range(-3, 10, 4):
				c.draw_line(Vector2(x, -1), Vector2(x, 6), Color("694934"), 1.5)
		"flame", "flamethrower":
			_poly(c, PackedVector2Array([Vector2(-25, -8), Vector2(-12, -8), Vector2(-9, -3), Vector2(19, -3), Vector2(26, 0), Vector2(26, 7), Vector2(-13, 7), Vector2(-17, 12), Vector2(-25, 12)]), dark)
			c.draw_rect(Rect2(-17, -10, 10, 17), Color("bb753f"))
			c.draw_rect(Rect2(8, -4, 21, 12), metal)
			c.draw_rect(Rect2(25, -7, 8, 18), Color("4e6c83"))
			c.draw_circle(Vector2(35, 3), 4, Color("ffba62"))
			c.draw_circle(Vector2(36, 3), 2, Color("fff1b2"))
			c.draw_arc(Vector2(-5, 2), 12, 0.2, 2.5, 10, Color("aa723f"), 3.0, true)
		_:
			_poly(c, PackedVector2Array([Vector2(-30, -4), Vector2(-20, -4), Vector2(-13, 0), Vector2(-8, -7), Vector2(16, -7), Vector2(20, -2), Vector2(20, 6), Vector2(-12, 6), Vector2(-28, 11)]), dark)
			c.draw_rect(Rect2(15, -4, 22, 5), metal)
			c.draw_rect(Rect2(34, -6, 5, 9), Color("182c3a"))
			_poly(c, PackedVector2Array([Vector2(-1, 5), Vector2(10, 5), Vector2(8, 16), Vector2(0, 15)]), Color("58758c"))
			c.draw_rect(Rect2(-7, -5, 17, 3), Color("6cc5e7"))
			c.draw_rect(Rect2(-2, -11, 9, 4), metal)
	c.draw_set_transform(Vector2.ZERO)
