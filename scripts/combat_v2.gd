extends RefCounted
## V2 arena combat. Fixed-cap data arrays, shared draw calls and spatial hashing.
const DURATIONS = [25.0,28.0,30.0,32.0,35.0,35.0,38.0,38.0,40.0,0.0,35.0,36.0,36.0,38.0,38.0,40.0,40.0,40.0,42.0,0.0,38.0,40.0,40.0,42.0,42.0,42.0,44.0,44.0,45.0,0.0]
const WAVE_NAMES = ["接触确认","围追堵截","酸蚀阵线","装甲推进","离子沙暴","四角合围","破防穿刺","狂乱虫潮","决死防线","虫群之心·前哨分体","熔岩初坠","地热喷涌","绿潮毒爆","双重压制","强震涌动","坑道突袭","焦土突围","钢铁碰撞","绝望火线","坑道穿地巨兽","踏入深渊","毒雾弥漫","异化狂暴","地刺死廊","灵能尖啸","巨兽狂潮","极限走位","菌毯沸腾","黎明前夕","母巢主宰·暴君体"]
static func wave_name(w:int) -> String: return WAVE_NAMES[clampi(w-1,0,29)]
static func zone(w:int) -> int: return clampi(int((w-1)/10),0,2)
static func is_boss_wave(w:int) -> bool: return w in [10,20,30]
static func event(g,id:String) -> void:
	if g.has_method("v4_event"): g.v4_event(id)
static func support(g,id:String) -> bool: return id in g.build.get("supports",[])

const TAGS = {"rifle":["ballistic","hightech"],"shotgun":["ballistic","explosive"],"flame":["plasma"],"reaper":["ballistic"],"sniper":["hightech"],"grenade":["explosive"],"tesla":["hightech","engineering"],"smg":["ballistic"],"cannon":["plasma","engineering"]}
const MAX_ENEMIES = 130
const MAX_BULLETS = 300
const MAX_ACID = 150
const MAX_DROPS = 250
const MAX_HAZARDS = 100

static func item(g, id: String) -> bool:
	return id in g.items

static func tag(g, id: String) -> int:
	return int(g.synergies.get(id,0))

static func reset_wave(g) -> void:
	g.combat = {"elapsed":0.0,"event":0.0,"spawn":0.8,"grid":{},"regen":0.0,"aura":0.0,"turret":0.0,"phase3":0.0,"shrink":0.0,"shrink_tick":0.0,"center_done":false,"lurker_done":false,"shot_sound":0.0,"lifesteal_cd":0.0,"shooter_index":0}
	g.combat.turret_p=g.player+Vector2(60,0)
	g.combat.last_player=g.player
	g.combat.mine_distance=0.0
	g.combat.med_timer=4.0
	g.combat.med_shield_used=false
	g.combat.drone_charges=8
	g.combat.eng_shield_cd=0.0
	g.combat.engineer_shield=0.0
	g.combat.death_source="enemy"
	g.hazards.clear()
	g.combat.bullet_pool=[]
	g.combat.acid_pool=[]
	g.combat.drop_pool=[]
	for n in range(MAX_BULLETS): g.combat.bullet_pool.append({})
	for n in range(MAX_ACID): g.combat.acid_pool.append({})
	for n in range(MAX_DROPS): g.combat.drop_pool.append({})
	if is_boss_wave(g.wave):
		spawn_enemy(g,"boss",Vector2(640,260))
		g.boss_spawned=true

static func update(g, dt: float) -> void:
	if g.combat.is_empty(): reset_wave(g)
	g.combat.elapsed += dt
	g.combat.shot_sound = maxf(0.0,g.combat.shot_sound-dt)
	g.combat.lifesteal_cd = maxf(0.0,g.combat.lifesteal_cd-dt)
	spawn_wave_events(g,dt)
	update_enemies(g,dt)
	if g.state != "wave": return
	update_weapons(g,dt)
	update_bullets(g,dt)
	update_hazards(g,dt)
	if g.overcharge_timer>0:
		g.combat.aura -= dt
		if g.combat.aura<=0:
			g.combat.aura=0.25
			for e in g.enemies:
				if e.p.distance_to(g.player)<52: hit_enemy(g,e,2.0,Vector2.ZERO,"aura",{"proc":false})
	update_supports(g,dt)
	cleanup(g)

static func spawn_wave_events(g, dt: float) -> void:
	g.combat.spawn-=dt; g.combat.event-=dt
	if not is_boss_wave(g.wave) and g.combat.spawn<=0 and g.enemies.size()<MAX_ENEMIES:
		g.combat.spawn=maxf(0.30,0.95-mini(g.wave,20)*0.035)
		var count=1+int(mini(g.wave,22)/5)
		for n in range(count):
			var r=g.rng.randf(); var kind="runner"
			match g.wave:
				1: kind="runner"
				2: kind="spitter" if r<0.15 else "runner"
				3: kind="spitter" if r<0.30 else "runner"
				4: kind="brute" if r<0.2 else ("spitter" if r<0.4 else "runner")
				5,6: kind="spitter" if r<0.20 else "runner"
				7: kind="lurker" if r<0.10 else ("spitter" if r<0.30 else "runner")
				8: kind="brute" if r<0.2 else "runner"
				11,12,15: kind="brute" if r<0.25 else ("spitter" if r<0.45 else "runner")
				13,17,23: kind="baneling" if r<0.45 else "runner"
				14: kind="lurker" if r<0.25 else ("brute" if r<0.55 else "runner")
				18: kind="brute" if r<0.4 else "runner"
				19: kind="spitter" if r<0.6 else "runner"
				24: kind="lurker" if r<0.25 else "runner"
				26: kind="brute" if r<0.5 else "baneling"
				_: kind=["runner","spitter","brute","baneling","lurker"][g.rng.randi_range(0,4)]
			spawn_enemy(g,kind)
	if g.wave==2 and g.combat.event<=0:
		g.combat.event=9.0; spawn_enemy(g,"spitter",corner(g,int(g.combat.elapsed/9)%4))
	if g.wave==3 and g.combat.event<=0:
		g.combat.event=8.0
		for n in range(3): add_hazard(g,{"type":"pool","p":random_point(g),"r":63.0,"warning":1.0,"life":4.0,"dmg":9.0,"tick":0.0,"friendly":false})
	if g.wave==6 and g.combat.event<=0:
		g.combat.event=7.0
		for n in range(4):
			spawn_enemy(g,"runner",corner(g,n)); spawn_enemy(g,"spitter",corner(g,n)+Vector2(24,0))
	if g.wave in [7,24] and g.combat.elapsed>=2 and not g.combat.lurker_done:
		g.combat.lurker_done=true
		for n in range(4 if g.wave==24 else 2): spawn_enemy(g,"lurker",corner(g,n*2 if g.wave==7 else n))
		g._notify("地刺封锁 · 横向躲避红线",2.5)
	if g.wave==18 and g.combat.event<=0:
		g.combat.event=9.0
		for n in range(4):
			var charger=spawn_enemy(g,"brute",corner(g,n))
			if not charger.is_empty(): charger.charge_dir=(g.player-charger.p).normalized(); charger.charge_time=0.0
	if g.wave==16 and not g.combat.center_done:
		g.combat.center_done=true; spawn_enemy(g,"nest",g.ARENA.get_center())
	if g.wave in [12,15,27] and g.combat.event<=0:
		g.combat.event=5.5 if g.wave==15 else 8.0
		var center=random_point(g)
		for direction in [Vector2.RIGHT,Vector2.DOWN]: add_hazard(g,{"type":"line","p":center-direction*260,"end":center+direction*260,"width":48.0,"warning":1.2,"life":1.8,"dmg":22.0,"source":"lava"})
	if g.wave in [22,27] and float(g.combat.get("cloud_event",0.0))<=g.combat.elapsed:
		g.combat.cloud_event=g.combat.elapsed+6.0
		add_hazard(g,{"type":"pool","p":Vector2(70,g.rng.randf_range(230,650)),"v":Vector2(45,0),"r":90.0,"warning":1.0,"life":24.0,"dmg":8.0,"tick":0.0,"friendly":false,"piercing":true,"source":"cloud"})
	if g.wave==28:
		g.combat.shrink=minf(220,g.combat.elapsed*4)
		shrink_damage(g,dt)

static func shrink_damage(g,dt:float) -> void:
	if float(g.combat.shrink)<=0: return
	var safe=g.ARENA.grow(-g.combat.shrink)
	if not safe.has_point(g.player):
		g.combat.shrink_tick+=dt
		while g.combat.shrink_tick>=1.0 and g.state=="wave":
			g.combat.shrink_tick-=1.0; g.combat.death_source="creep"; hurt_player(g,10.0,true,true)
	else: g.combat.shrink_tick=0.0

static func corner(g, n:int) -> Vector2:
	var a=g.ARENA.grow(-40)
	return [a.position,Vector2(a.end.x,a.position.y),a.end,Vector2(a.position.x,a.end.y)][n%4]

static func random_point(g) -> Vector2:
	return Vector2(g.rng.randf_range(g.ARENA.position.x+55,g.ARENA.end.x-55),g.rng.randf_range(g.ARENA.position.y+55,g.ARENA.end.y-55))

static func spawn_enemy(g, kind: String, point:Vector2=Vector2(-999,-999)) -> Dictionary:
	if g.enemies.size()>=MAX_ENEMIES: return {}
	var p=point
	if p.x< -900:
		p=corner(g,g.rng.randi_range(0,3))
		if g.rng.randf()<0.5: p.x=g.rng.randf_range(g.ARENA.position.x+20,g.ARENA.end.x-20)
		else: p.y=g.rng.randf_range(g.ARENA.position.y+20,g.ARENA.end.y-20)
		if p.distance_to(g.player)<160: p=g.ARENA.get_center()*2-p
	var health=20.0+g.wave*4.0
	var speed=62.0+g.wave*4.0
	var radius=16.0
	var damage=9.0
	var value=2
	var enemy_armor=0.0
	match kind:
		"spitter":
			health*=1.3; speed*=0.65; radius=20.0; value=3
		"brute":
			health*=3.7; speed*=0.62; radius=28.0; damage=17.0; value=5; enemy_armor=0.20
		"baneling":
			health*=0.65; speed=140.0; radius=18.0; damage=28.0; value=3
		"lurker":
			health*=2.5; speed=75.0; radius=25.0; damage=23.0; value=6
		"cocoon":
			health=150.0; speed=0.0; radius=24.0; damage=0.0; value=10
		"nest":
			health=300.0; speed=0.0; radius=30.0; damage=0.0; value=15
		"boss":
			health={10:2800.0,20:6500.0,30:18000.0}.get(g.wave,2800.0); speed=55.0; radius=57.0; damage=26.0; value=50
	if kind not in ["boss","nest","cocoon"]: health*=g.enemy_scale
	speed*=g.enemy_scale
	if g.wave==2: speed*=1.15
	if g.wave==8: speed*=1.15
	if g.wave==23 and kind=="baneling": speed*=1.2
	g.next_id+=1
	var e={"id":g.next_id,"kind":kind,"p":p,"hp":health,"max_hp":health,"speed":speed,"r":radius,"dmg":damage,"cash":value,"flash":0.0,"fire":g.rng.randf_range(1.0,2.8),"warmup":0.6,"knock":Vector2.ZERO,"angle":0.0,"pulse":4.0,"burn":0.0,"burn_dmg":0.0,"burn_tick":0.0,"slow":0.0,"slow_mult":1.0,"stun":0.0,"armor":enemy_armor,"shred":0,"fuse":-1.0,"burrow":0.0,"shots":0,"phase":1,"phase_time":0.0,"skill":0,"dead_handled":false,"hatched":false}
	g.enemies.append(e)
	return e

static func build_grid(g) -> Dictionary:
	var grid={}
	for e in g.enemies:
		if e.hp<=0: continue
		var cell=Vector2i(floori(e.p.x/75),floori(e.p.y/75))
		if not grid.has(cell): grid[cell]=[]
		grid[cell].append(e)
	return grid

static func update_enemies(g, dt:float) -> void:
	var grid=build_grid(g)
	g.combat.grid=grid
	# Duplicate array prevents newly spawned cocoons from changing this iteration.
	for e in g.enemies.duplicate():
		if e.hp<=0: continue
		e.flash=maxf(0,e.flash-dt*5)
		e.warmup=maxf(0,e.warmup-dt)
		e.stun=maxf(0,e.stun-dt)
		e.slow=maxf(0,e.slow-dt)
		if e.burn>0 and not e.get("underground",false):
			e.burn-=dt; e.burn_tick-=dt
			if e.burn_tick<=0:
				e.burn_tick=0.5
				var burn=float(e.burn_dmg)*0.5
				if tag(g,"plasma")>=4 and g.rng.randf()<g.crit_rate: burn*=g.crit_mult
				e.hp-=burn; g.telemetry.damage_dealt+=burn
		if e.hp<=0 or e.warmup>0: continue
		if e.kind=="nest":
			e.fire-=dt
			if e.fire<=0:
				e.fire=4.0
				spawn_enemy(g,"baneling",e.p+Vector2(45,0))
			continue
		if e.kind=="cocoon":
			e.fire+=dt
			if e.fire>=6.0:
				e.hatched=true; e.hp=0
				spawn_enemy(g,"baneling",e.p)
			continue
		if e.stun>0: continue
		var direction:Vector2=g.player-e.p
		var distance=direction.length()
		e.angle=direction.angle()
		var dir=direction.normalized()
		var motion=dir*float(e.speed)
		if e.kind=="spitter" and distance<265: motion*= -0.2 if distance<180 else 0.15
		if e.kind=="baneling":
			if distance<60 and e.fuse<0: e.fuse=0.3
			if e.fuse>=0:
				e.fuse-=dt; motion=Vector2.ZERO
				if e.fuse<=0:
					e.hp=0; e.hatched=true
					add_hazard(g,{"type":"blast","p":e.p,"r":120.0,"warning":0.0,"life":0.12,"dmg":28.0,"friendly":false,"source":"baneling"})
		if e.kind=="lurker":
			if distance<430 and e.burrow==0:
				e.burrow=1.0; e.shots=0; e.fire=1.0
			if e.burrow>0:
				motion=Vector2.ZERO
				e.fire-=dt
				if e.fire<=0:
					e.fire=2.0; e.shots+=1
					add_hazard(g,{"type":"line","p":e.p,"end":e.p+dir*350.0,"width":40.0,"warning":0.8,"life":0.18,"dmg":23.0,"source":"lurker"})
					if e.shots>=3: e.burrow= -2.0
			elif e.burrow<0: e.burrow=minf(0.0,e.burrow+dt)
		if e.has("charge_dir"):
			e.charge_time+=dt
			if e.charge_time<0.9:
				motion=Vector2.ZERO
			elif e.charge_time<3.5: motion=e.charge_dir*260
			else: e.erase("charge_dir")
		if e.kind=="boss": motion=boss_update(g,e,dt,dir,distance)
		if e.slow>0: motion*=float(e.slow_mult)
		var cell=Vector2i(floori(e.p.x/75),floori(e.p.y/75))
		for dx in range(-1,2):
			for dy in range(-1,2):
				for other in grid.get(cell+Vector2i(dx,dy),[]):
					if other.id==e.id: continue
					var offset:Vector2=e.p-other.p
					var minimum=(e.r+other.r)*0.72
					if offset.length_squared()<minimum*minimum and offset.length_squared()>0.01: motion+=offset.normalized()*42.0
		e.p+=(motion+e.knock)*dt
		e.p=e.p.clamp(g.ARENA.position+Vector2.ONE*e.r,g.ARENA.end-Vector2.ONE*e.r)
		e.knock=e.knock.move_toward(Vector2.ZERO,dt*450)
		if distance<e.r+18 and e.kind not in ["baneling","cocoon","nest"] and not e.get("underground",false):
			g.combat.death_source="boss" if e.kind=="boss" else e.kind
			hurt_player(g,e.dmg*(0.8 if e.burn>0 and tag(g,"plasma")>=4 else 1.0))
		if e.kind=="spitter":
			e.fire-=dt
			if e.fire<=0: e.fire=2.6*(0.85 if g.wave==25 else 1.0); add_acid(g,e.p,dir*170,8)
	update_acid(g,dt)

static func boss_update(g,e:Dictionary,dt:float,dir:Vector2,distance:float) -> Vector2:
	if g.wave==10:
		e.fire-=dt; e.pulse-=dt; e.phase_time+=dt
		if e.fire<=0:
			e.fire=3.4; add_hazard(g,{"type":"fan","p":e.p,"angle":dir.angle(),"r":380.0,"warning":0.8,"life":0.1,"dmg":13.0})
		if e.pulse<=0:
			e.pulse=6.0
			for n in range(3): spawn_enemy(g,"runner",e.p+Vector2.from_angle(n*TAU/3)*85)
			if distance<180: add_hazard(g,{"type":"stomp","p":e.p,"r":250.0,"warning":0.9,"life":0.1,"dmg":20.0})
		return dir*55.0 if distance>260 else Vector2.ZERO
	if g.wave==20:
		e.phase_time+=dt
		if not e.get("underground",false) and e.phase_time>=6.0:
			e.underground=true; e.phase_time=0.0; e.burrow_target=g.player
			add_hazard(g,{"type":"blast","p":g.player,"r":105.0,"warning":2.5,"life":0.15,"dmg":32.0,"source":"boss"})
			event(g,"boss20_burrow")
		elif e.get("underground",false) and e.phase_time>=2.5:
			e.underground=false; e.phase_time=0.0; e.p=e.burrow_target
			spawn_enemy(g,"nest",e.p+Vector2(60,0))
		return Vector2.ZERO if e.get("underground",false) else dir*68.0
	var phase=1 if e.hp/e.max_hp>0.70 else (2 if e.hp/e.max_hp>0.35 else 3)
	if phase!=e.phase:
		e.phase=phase; e.phase_time=0.0; e.fire=1.5; e.pulse=1.0
		recycle_projectiles(g,true); g.shake=9.0
		g._notify("母巢暴君 · 阶段 %d" % phase,2.5)
		event(g,"phase%d"%phase)
		g.sound.play_sfx("boss")
		e.speed=68.0 if phase==2 else 82.0
	e.phase_time+=dt; e.fire-=dt; e.pulse-=dt
	if phase==1:
		if e.fire<=0:
			e.fire=3.4
			add_hazard(g,{"type":"fan","p":e.p,"angle":dir.angle(),"r":380.0,"warning":0.8,"life":0.1,"dmg":13.0})
		if e.pulse<=0:
			e.pulse=4.0
			add_hazard(g,{"type":"pool","p":g.player,"r":70.0,"warning":1.2,"life":5.0,"dmg":11.0,"tick":0.0,"friendly":false})
			if distance<250: add_hazard(g,{"type":"stomp","p":e.p,"r":250.0,"warning":0.9,"life":0.1,"dmg":20.0})
		return dir*e.speed if distance>300 else Vector2.ZERO
	if phase==2:
		if e.pulse<=0:
			e.pulse=14.0
			for n in range(4):
				var egg=spawn_enemy(g,"cocoon",corner(g,n))
				if not egg.is_empty(): egg.fire=0.0
			g._notify("6 秒击破孵化囊 · 掉落医疗包",3.0)
		if e.fire<=0:
			e.fire=4.0
			for n in range(3):
				var p=g.player+Vector2.from_angle(n*TAU/3.0)*50.0
				add_hazard(g,{"type":"pool","p":p,"r":70.0,"warning":1.2+n*0.18,"life":5.0,"dmg":11.0,"tick":0.0,"friendly":false})
		return dir*e.speed
	if e.pulse<=0:
		e.pulse=13.0
		e.p=g.ARENA.get_center()
		add_hazard(g,{"type":"laser","p":e.p,"angle":dir.angle(),"warning":1.5,"life":8.0,"dmg":22.0,"tick":0.0,"rot":0.0})
		g._notify("死光预警 · 顺时针绕行",2.0)
	if e.fire<=0:
		e.fire=5.0
		for n in range(2): spawn_enemy(g,"runner",e.p+Vector2.from_angle(n*PI)*100)
	g.combat.phase3=e.phase_time
	g.combat.shrink=minf(300.0,floorf(e.phase_time/15.0)*60.0)
	shrink_damage(g,dt)
	for h in g.hazards:
		if h.type=="laser": return Vector2.ZERO
	return dir*e.speed

static func recycle_projectiles(g,include_bullets:bool) -> void:
	if g.combat.has("acid_pool"): g.combat.acid_pool.append_array(g.acid)
	g.acid.clear()
	if include_bullets:
		if g.combat.has("bullet_pool"): g.combat.bullet_pool.append_array(g.bullets)
		g.bullets.clear()

static func add_acid(g,pos:Vector2,velocity:Vector2,damage:float,split:bool=false) -> void:
	if g.acid.size()>=MAX_ACID: return
	var a:Dictionary=g.combat.acid_pool.pop_back() if not g.combat.acid_pool.is_empty() else {}
	a.clear()
	a.merge({"p":pos,"v":velocity,"life":2.0 if split else 7.0,"r":10.0 if split else 7.0,"dmg":damage,"split":split})
	g.acid.append(a)

static func update_acid(g,dt:float) -> void:
	for i in range(g.acid.size()-1,-1,-1):
		var a=g.acid[i]
		a.p+=a.v*dt; a.life-=dt
		if support(g,"raven") and g.combat.drone_charges>0 and a.p.distance_to(g.player)<=130:
			g.acid.remove_at(i); g.combat.acid_pool.append(a); g.combat.drone_charges-=1
			continue
		if a.p.distance_to(g.player)<a.r+16 and g.dash_timer<=0:
			g.combat.death_source="acid"; hurt_player(g,a.dmg); g.acid.remove_at(i); g.combat.acid_pool.append(a)
		elif a.life<=0 or not g.ARENA.grow(30).has_point(a.p):
			g.acid.remove_at(i)
			if a.get("split",false):
				add_acid(g,a.p,a.v.rotated(PI/2)*0.7,a.dmg*0.55)
				add_acid(g,a.p,a.v.rotated(-PI/2)*0.7,a.dmg*0.55)
			g.combat.acid_pool.append(a)

static func resolve_branch(id:String,branch:String) -> String:
	if branch not in ["a","b"]: return branch
	if id=="shotgun": return "shrapnel" if branch=="a" else "slug"
	if id=="flame": return "napalm" if branch=="a" else "cryo"
	if id in ["sniper","grenade","tesla","smg","cannon"]: return branch
	return "pierce" if branch=="a" else "sniper"

static func nearest(g,limit:float) -> Dictionary:
	var found={}; var best=limit*limit
	for e in g.enemies:
		if e.hp<=0 or e.warmup>0 or e.get("underground",false): continue
		var distance=g.player.distance_squared_to(e.p)
		if distance<best: best=distance; found=e
	return found

static func sniper_target(g,limit:float) -> Dictionary:
	# Prefer artillery/ranged backline, then fall back to nearest viable target.
	var found={}; var best=limit*limit
	for e in g.enemies:
		if e.hp<=0 or e.warmup>0 or e.get("underground",false) or e.kind not in ["spitter","lurker"]: continue
		var distance=g.player.distance_squared_to(e.p)
		if distance<best: best=distance; found=e
	return nearest(g,limit) if found.is_empty() else found

static func update_weapons(g,dt:float) -> void:
	var aim=nearest(g,800)
	if not aim.is_empty(): g.facing=lerp_angle(g.facing,(aim.p-g.player).angle(),minf(1,dt*18))
	for w in g.weapons:
		w.cooldown=maxf(-dt,float(w.get("cooldown",0.0))-dt)
		if w.cooldown>0: continue
		var id=String(w.id); var branch=resolve_branch(id,String(w.get("branch",""))); var lv=int(w.level)
		var reach=610.0; var interval=0.32; var damage=15.0; var count=1; var spread=0.0; var velocity=800.0; var pierce=2; var color=Color("64e5ed")
		match id:
			"reaper": interval=0.18; damage=10.0; spread=0.09; reach=450
			"sniper": interval=0.9; damage=55.0; reach=780; color=Color("b99dff")
			"grenade": interval=1.2; damage=34.0; reach=600; velocity=420; color=Color("ffb36b")
			"tesla": interval=0.8; damage=22.0; reach=420; color=Color("8fbdff")
			"smg": interval=1.0/22.0; damage=4.0; reach=430; velocity=900; spread=0.06; pierce=1
			"cannon": interval=2.5; damage=16.0; reach=1400; color=Color("e69bff")
			"shotgun": interval=0.96; damage=10.0; count=7; spread=0.095; velocity=590; reach=310; pierce=1; color=Color("ffc66b")
			"flame": interval=0.14; damage=5.0; count=2; spread=0.25; velocity=340; reach=200; pierce=8; color=Color("ff9652")
		if branch in ["pierce","depleted_uranium"]: damage*=float(g.rifle_branch_penalty); reach*=1.15; pierce=999
		if branch in ["sniper","sniper_protocol"]: reach=750; interval=0.85; damage*=3.4; color=Color("b99dff")
		if branch in ["shrapnel","point_blank"]: count=12; spread*=1.3; reach=minf(200,reach*0.75)
		if branch in ["slug","slugs"]: count=3; spread=0.12; damage*=2.3; color=Color("fff1a1")
		if branch in ["cryo","cryo_plasma"]: damage*=0.8; pierce=999; color=Color("8df0ff")
		if id=="sniper" and branch=="a": damage*=1.25; interval/=0.85; pierce=4
		if id=="sniper" and branch=="b": damage*=0.9
		if id=="grenade" and branch=="a": damage*=0.85
		if id=="grenade" and branch=="b": interval/=0.8
		if id=="tesla" and branch=="a": damage*=0.85
		if id=="smg" and branch=="a": interval/=1.35; damage*=0.85
		if id=="smg" and branch=="b": pierce+=2; damage*=1.15; interval/=0.8
		if id=="cannon" and branch=="a": damage*=1.35
		if id=="cannon" and branch=="b": damage*=0.8
		reach*=g.range_mult*(0.7 if g.wave==5 else 1.0)
		if branch in ["shrapnel","point_blank"]: reach=minf(200.0,reach)
		var target=sniper_target(g,reach) if id=="sniper" or branch in ["sniper","sniper_protocol"] else nearest(g,reach)
		if target.is_empty():
			w.cooldown=0.0
			continue
		var power=g.damage_mult*(1+(lv-1)*0.42)
		var fire_rate=g.attack_mult*(1+(lv-1)*0.12)
		var tags=TAGS.get(id,[])
		if tag(g,"ballistic")>=2: fire_rate*=1.15; velocity*=1.2
		if "ballistic" in tags: power*=g.ballistic_damage_mult
		pierce+=int(g.pierce_bonus)
		if item(g,"tripod"): power*=1.45 if g.stationary_time>=0.6 else 0.85
		if item(g,"injector") and g.hp<g.max_hp*0.5: fire_rate*=1.3
		if g.stim_timer>0: fire_rate*=1.45
		if g.overcharge_timer>0: fire_rate*=1.10
		if "ballistic" in tags: fire_rate*=g.ballistic_attack_mult
		w.cooldown=maxf(0.0,float(w.cooldown)+interval/maxf(0.2,fire_rate))
		var angle=(target.p-g.player).angle()
		if id=="tesla":
			g.telemetry.shots+=1
			chain_lightning(g,target,damage*power,7 if branch=="a" else (3 if branch=="b" else 4),0.8 if branch=="b" else 0.25)
			continue
		if id=="cannon":
			g.telemetry.shots+=1
			add_hazard(g,{"type":"beam","p":g.player,"end":g.player+Vector2.from_angle(angle)*1400,"width":22.0*(0.65 if branch=="a" else (1.8 if branch=="b" else 1.0)),"warning":0.0,"life":0.8,"dmg":damage*power,"tick":0.0,"friendly":true})
			continue
		if id=="grenade":
			g.telemetry.shots+=1
			add_hazard(g,{"type":"grenade","p":g.player,"end":target.p,"r":90.0*(1.4 if branch=="a" else 1.0)*(1.15 if tag(g,"explosive")>=2 else 1.0),"warning":0.65,"flight":0.65,"life":0.15,"dmg":damage*power,"friendly":true,"stun":0.6 if branch=="b" else 0.0})
			continue
		for n in range(count):
			var shot_angle=angle+(n-(count-1)/2.0)*spread if id!="flame" else angle+g.rng.randf_range(-spread,spread)
			if id=="reaper": shot_angle+=g.rng.randf_range(-spread,spread)
			fire_bullet(g,shot_angle,velocity,damage*power,reach/velocity,color,pierce,id,{"branch":branch,"tags":tags,"base":damage*power})
		if branch in ["napalm","napalm_blaze"]:
			add_hazard(g,{"type":"pool","p":g.player+Vector2.from_angle(angle)*95,"r":52.0*(1.2 if tag(g,"plasma")>=2 else 1.0),"warning":0.0,"life":1.5,"dmg":damage*power*0.45,"tick":0.0,"friendly":true})
		g.weapon_flash=1.0
		if g.combat.shot_sound<=0:
			g.sound.play_sfx("flame" if id=="flame" else ("shotgun" if id=="shotgun" else "rifle"),-7.0)
			g.combat.shot_sound=0.08

static func fire_bullet(g,angle:float,speed:float,damage:float,life:float,color:Color,pierce:int,kind:String,meta:Dictionary) -> void:
	if g.bullets.size()>=MAX_BULLETS: return
	var dir=Vector2.from_angle(angle)
	var radius=14.0 if kind=="flame" else 4.0
	if kind=="flame" and tag(g,"plasma")>=2: radius*=1.2
	var origin:Vector2=meta.get("origin",g.player)
	var b:Dictionary=g.combat.bullet_pool.pop_back() if not g.combat.bullet_pool.is_empty() else {}
	b.clear()
	b.merge({"p":origin+dir*27,"prev":origin+dir*27,"v":dir*speed,"origin":origin,"dmg":damage,"life":life,"max_life":life,"color":color,"pierce":pierce,"kind":kind,"hit":[],"r":radius,"meta":meta.duplicate()})
	g.bullets.append(b)
	g.telemetry.shots+=1

static func update_bullets(g,dt:float) -> void:
	var hit_grid=build_grid(g)
	for i in range(g.bullets.size()-1,-1,-1):
		var b=g.bullets[i]
		b.prev=b.p; b.p+=b.v*dt; b.life-=dt
		if b.kind=="flame": b.r+=dt*18
		var candidates=bullet_candidates(hit_grid,b.prev,b.p,float(b.r)+60)
		candidates.sort_custom(func(a,b_enemy): return b.prev.distance_squared_to(a.p)<b.prev.distance_squared_to(b_enemy.p))
		for e in candidates:
			if e.hp<=0 or e.warmup>0 or e.get("underground",false) or e.id in b.hit: continue
			var closest=Geometry2D.get_closest_point_to_segment(e.p,b.prev,b.p)
			if closest.distance_squared_to(e.p)<pow(e.r+b.r,2):
				var meta:Dictionary=b.meta.duplicate()
				meta.distance=b.origin.distance_to(e.p)
				var damage=b.dmg
				if meta.get("branch","") in ["pierce","depleted_uranium"]: damage*=maxf(0.4,pow(0.9,b.hit.size()))
				b.hit.append(e.id); b.pierce-=1
				hit_enemy(g,e,damage,b.v.normalized(),b.kind,meta)
				if b.pierce<=0: break
		if b.life<=0 or b.pierce<=0 or not g.ARENA.grow(80).has_point(b.p):
			g.bullets.remove_at(i)
			g.combat.bullet_pool.append(b)

static func bullet_candidates(grid:Dictionary,from:Vector2,to:Vector2,padding:float) -> Array:
	var found=[]
	var low=Vector2i(floori((minf(from.x,to.x)-padding)/75),floori((minf(from.y,to.y)-padding)/75))
	var high=Vector2i(floori((maxf(from.x,to.x)+padding)/75),floori((maxf(from.y,to.y)+padding)/75))
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			found.append_array(grid.get(Vector2i(x,y),[]))
	return found

static func hit_enemy(g,e:Dictionary,damage:float,direction:Vector2,kind:String,meta:Dictionary={}) -> void:
	if e.hp<=0 or e.get("underground",false): return
	var branch=String(meta.get("branch",""))
	var crit=g.crit_rate
	if kind=="sniper": crit+=0.20+(0.25 if branch=="b" else 0.0)
	if tag(g,"hightech")>=2: crit+=0.08
	if item(g,"injector") and g.hp<g.max_hp*0.5: crit+=0.30
	if branch in ["sniper","sniper_protocol"]: crit=maxf(crit,0.30)
	var critical=g.rng.randf()<clampf(crit,0.0,1.0) and meta.get("proc",true)
	if critical: damage*=g.crit_mult+(0.5 if kind=="sniper" and branch=="b" else 0.0)
	if branch in ["shrapnel","point_blank"] and float(meta.get("distance",999))<120: damage*=2.0
	if tag(g,"explosive")>=4 and e.hp<e.max_hp*0.35: damage*=1.5
	if tag(g,"ballistic")>=4 and kind in ["rifle","shotgun","reaper","smg"]: e.shred=mini(3,int(e.shred)+1)
	damage*=1.0-maxf(0.0,float(e.armor)-0.1*e.shred)
	e.hp-=damage; e.flash=0.8; e.last_weapon=kind
	var knock=120.0 if branch in ["slug","slugs"] else (55.0 if kind!="flame" else 32.0)
	if g.class_id=="marauder":
		knock*=1.5
		if g.rng.randf()<0.40: e.slow=1.8; e.slow_mult=0.65
	if tag(g,"explosive")>=2: knock*=1.30
	e.knock+=direction*knock
	if branch in ["slug","slugs"]:
		if e.p.x<g.ARENA.position.x+e.r+25 or e.p.x>g.ARENA.end.x-e.r-25 or e.p.y<g.ARENA.position.y+e.r+25 or e.p.y>g.ARENA.end.y-e.r-25: e.stun=maxf(e.stun,0.5)
		for other in g.enemies:
			if other.id!=e.id and other.p.distance_to(e.p)<e.r+other.r+30: other.stun=maxf(other.stun,0.5)
	if branch in ["cryo","cryo_plasma"]: e.slow=1.2; e.slow_mult=0.60
	if (g.class_id=="firebat" and kind=="flame") or (tag(g,"plasma")>=2 and g.rng.randf()<0.10):
		e.burn=3.0; e.burn_dmg=maxf(e.burn_dmg,float(meta.get("base",damage))*0.20)
	if branch in ["napalm","napalm_blaze"]: e.burn=3.0; e.burn_dmg=minf(30.0,e.burn_dmg+damage*0.10)
	if g.combat.get("lifesteal_cd",0.0)<=0 and g.rng.randf()<g.lifesteal and meta.get("proc",true):
		g.hp=minf(g.max_hp,g.hp+1); g.combat.lifesteal_cd=0.05
	if tag(g,"hightech")>=2 and g.rng.randf()<0.05 and meta.get("proc",true):
		var linked=0
		for other in g.enemies:
			if other.id!=e.id and other.p.distance_to(e.p)<180 and other.hp>0 and not other.get("underground",false):
				other.hp-=damage*0.35; other.flash=1.0
				add_hazard(g,{"type":"arc","p":e.p,"end":other.p,"warning":0.0,"life":0.18,"dmg":0})
				linked+=1
				if linked>=2: break
	if e.hp<=0 and branch in ["sniper","sniper_protocol"]:
		for other in g.enemies:
			if other.id!=e.id and other.p.distance_to(e.p)<140: other.knock+=(other.p-e.p).normalized()*150
	g.telemetry.damage_dealt+=damage
	g._emit(e.p,direction*50,Color("ffc66b"),2.5,0.18,2)
	if critical and g.popups.size()<60: g.popups.append({"p":e.p+Vector2(0,-20),"text":str(int(damage))+"!","color":Color("ffe598"),"life":0.55})

static func kill_enemy(g,e:Dictionary) -> void:
	if e.get("dead_handled",false): return
	e.dead_handled=true
	if e.kind=="cocoon" and e.hatched: return
	g.kills+=1
	if e.get("last_weapon","")=="sniper": event(g,"sniper")
	if e.kind=="lurker": event(g,"lurker")
	if e.kind=="baneling": event(g,"baneling")
	if e.kind=="brute" and e.get("last_weapon","")=="shotgun" and e.p.distance_to(g.player)<120: event(g,"shotgun")
	if e.burn>0: event(g,"flame")
	g._emit(e.p,Vector2.ZERO,Color("b68dd5"),4,0.5,6 if e.kind!="boss" else 35)
	if g.drops.size()<MAX_DROPS:
		var drop:Dictionary=g.combat.drop_pool.pop_back() if not g.combat.drop_pool.is_empty() else {}
		drop.clear(); drop.merge({"p":e.p,"value":e.cash,"age":0.0})
		g.drops.append(drop)
	else:
		# Merge values, never auto-pickup overflow; preserves the salvage risk.
		g.drops[0].value+=e.cash
	g._gain_xp(2 if e.kind=="runner" else (8 if e.kind=="cocoon" else 4))
	if e.kind=="baneling" and not e.hatched: add_hazard(g,{"type":"blast","p":e.p,"r":120.0,"warning":0.3,"life":0.12,"dmg":28.0,"friendly":false,"source":"baneling"})
	if e.kind=="cocoon":
		if g.drops.size()<MAX_DROPS:
			var med:Dictionary=g.combat.drop_pool.pop_back() if not g.combat.drop_pool.is_empty() else {}
			med.clear(); med.merge({"p":e.p+Vector2(12,0),"value":0,"age":0.0,"heal":15.0})
			g.drops.append(med)
		g._notify("孵化囊击破 · 医疗包已掉落",1.2)
	if g.class_id=="firebat" and e.burn>0: add_hazard(g,{"type":"blast","p":e.p,"r":65.0,"warning":0.0,"life":0.1,"dmg":12.0,"friendly":true})
	if g.class_id=="ghost" and g.kills%30==0:
		recycle_projectiles(g,false)
		for other in g.enemies: other.stun=maxf(other.stun,1.5)
		g._notify("EMP 脉冲 · 弹幕清除",1.5)
	if e.kind=="boss": g.boss_dead=true; g.shake=13.0
	if g.has_method("v4_event") and g.hp<=g.max_hp*0.3: event(g,"low_hp")
	if g.kills%3==0: g.sound.play_sfx("kill",-12.0)

static func cleanup(g) -> void:
	for e in g.enemies.duplicate():
		if e.hp<=0: kill_enemy(g,e)
	for i in range(g.enemies.size()-1,-1,-1):
		if g.enemies[i].hp<=0: g.enemies.remove_at(i)

static func hurt_player(g,amount:float,piercing:bool=false,environmental:bool=false) -> void:
	if g.state!="wave": return
	if not environmental and (g.hurt_timer>0 or g.dash_timer>0): return
	if not environmental and g.rng.randf()<minf(0.5,g.dodge): return
	var damage=amount if piercing else amount*50.0/(maxf(0,g.armor+(25.0 if item(g,"tripod") and g.stationary_time>=0.6 else 0.0))+50.0)
	if not environmental: damage+=g.hurt_extra
	damage=maxf(1.0,damage)
	if tag(g,"engineering")>=4 and float(g.combat.get("eng_shield_cd",0.0))<=0:
		g.combat.engineer_shield=30.0; g.combat.eng_shield_cd=12.0
	if float(g.combat.get("engineer_shield",0.0))>0:
		var absorbed=minf(damage,g.combat.engineer_shield)
		g.combat.engineer_shield-=absorbed; damage-=absorbed
	g.hp-=damage
	if not environmental: g.hurt_timer=g.hurt_invuln
	g.shake=7.0; g.telemetry.damage_taken+=damage
	g.popups.append({"p":g.player+Vector2(0,-38),"text":"−%d"%int(damage),"color":Color("ff677a"),"life":0.8})
	g.sound.play_sfx("hurt")
	if g.hp<=0:
		if g.revive>0 and not g.build.get("revive_used",false):
			g.build.revive_used=true; g.hp=1; g.hurt_timer=3.0
			recycle_projectiles(g,false)
			for e in g.enemies: e.knock=(e.p-g.player).normalized()*350; e.stun=1.0
			g._notify("绝境保命协议已触发",2.0)
			event(g,"revive")
		else:
			g.hp=0; g.last_damage_source=str(g.combat.get("death_source","enemy")); event(g,"death_"+g.last_damage_source); g._end_run(false)

static func dash_effect(g) -> void:
	if g.class_id=="reaper": add_hazard(g,{"type":"blast","p":g.player,"r":125.0*(1.15 if tag(g,"explosive")>=2 else 1.0),"warning":0.6,"life":0.1,"dmg":45.0*g.damage_mult,"friendly":true})

static func add_hazard(g,h:Dictionary) -> void:
	if g.hazards.size()>=MAX_HAZARDS: return
	h.done=false
	g.hazards.append(h)

static func update_hazards(g,dt:float) -> void:
	# Iterate snapshot: explosions can create additional hazards during death handling.
	for h in g.hazards.duplicate():
		if h.warning>0:
			h.warning-=dt
			continue
		h.life-=dt
		if h.has("v"): h.p+=h.v*dt
		if not h.get("friendly",false): g.combat.death_source=h.get("source","boss" if is_boss_wave(g.wave) else "hazard")
		match h.type:
			"fan":
				if not h.done:
					for n in range(5): add_acid(g,h.p,Vector2.from_angle(h.angle+(n-2)*0.18)*240,h.dmg,true)
					h.done=true
			"ambush":
				if not h.done:
					for n in range(6): spawn_enemy(g,"baneling" if n%3==0 else "runner",h.p+Vector2.from_angle(n*TAU/6)*70)
					h.done=true
			"beam":
				h.tick-=dt
				if h.tick<=0:
					h.tick=0.1
					for e in g.enemies:
						if Geometry2D.get_closest_point_to_segment(e.p,h.p,h.end).distance_to(e.p)<h.width+e.r: hit_enemy(g,e,h.dmg,(h.end-h.p).normalized(),"beam")
			"grenade":
				if not h.done:
					for e in g.enemies:
						if e.p.distance_to(h.end)<h.r: hit_enemy(g,e,h.dmg,(e.p-h.end).normalized(),"grenade"); e.knock+=(e.p-h.end).normalized()*160; e.stun=maxf(e.stun,float(h.get("stun",0.0)))
					h.done=true
			"mine":
				if not h.done:
					for target in g.enemies:
						if target.hp>0 and target.p.distance_to(h.p)<40:
							h.done=true; h.life=0.1
							for e in g.enemies:
								if e.p.distance_to(h.p)<140: hit_enemy(g,e,45*g.damage_mult,Vector2.ZERO,"mine"); e.slow=2.0; e.slow_mult=0.4
							break
			"blast","stomp":
				if not h.done:
					if h.get("friendly",false):
						for e in g.enemies:
							if e.p.distance_to(h.p)<h.r:
								hit_enemy(g,e,h.dmg,(e.p-h.p).normalized(),"explosion",{"proc":false})
								e.knock+=(e.p-h.p).normalized()*140
					elif g.player.distance_to(h.p)<h.r:
						hurt_player(g,h.dmg)
						if h.type=="stomp" and not (item(g,"tripod") and g.stationary_time>=0.5) and g.dash_timer<=0: g.player=(g.player+(g.player-h.p).normalized()*75).clamp(g.ARENA.position+Vector2.ONE*24,g.ARENA.end-Vector2.ONE*24)
					h.done=true
			"line":
				if Geometry2D.get_closest_point_to_segment(g.player,h.p,h.end).distance_to(g.player)<h.width*0.5+16: hurt_player(g,h.dmg)
			"pool":
				h.tick-=dt
				if h.tick<=0:
					h.tick=0.2 if h.get("friendly",false) else 0.65
					if h.get("friendly",false):
						for e in g.enemies:
							if e.p.distance_to(h.p)<h.r:
								e.hp-=h.dmg; e.burn=3.0; e.burn_dmg=minf(30,e.burn_dmg+h.dmg*0.1)
					elif g.player.distance_to(h.p)<h.r: hurt_player(g,h.dmg,h.get("piercing",false))
			"laser":
				h.rot+=dt*PI/4
				var end=h.p+Vector2.from_angle(h.angle+h.rot)*1500
				if Geometry2D.get_closest_point_to_segment(g.player,h.p,end).distance_to(g.player)<26: hurt_player(g,h.dmg)
	for i in range(g.hazards.size()-1,-1,-1):
		if g.hazards[i].warning<=0 and g.hazards[i].life<=0: g.hazards.remove_at(i)

static func draw_hazards(g) -> void:
	if (g.turret>0 or support(g,"sentry")) and g.combat.has("turret_p"):
		var p:Vector2=g.combat.turret_p
		g.draw_circle(p,19,Color("314f69"))
		g.draw_rect(Rect2(p-Vector2(12,12),Vector2(24,24)),Color("85a9bf"))
		g.draw_line(p,p+Vector2(0,-27),Color("d9f0ff"),7)
	if support(g,"medic_drone"):
		g.draw_circle(g.player+Vector2(-40,-45),12,Color("89e3b2")); g.draw_line(g.player+Vector2(-46,-45),g.player+Vector2(-34,-45),Color.WHITE,3)
	if support(g,"raven"):
		g.draw_arc(g.player,130,0,TAU,48,Color(0.4,0.7,1,0.25),2)
		g.draw_circle(g.player+Vector2(40,-45),12,Color("7aa5e6"))
	if float(g.combat.get("engineer_shield",0))>0: g.draw_arc(g.player,33,0,TAU,40,Color("8ebfff"),4)
	if float(g.combat.get("shrink",0))>0:
		var s=float(g.combat.shrink); var a=g.ARENA
		g.draw_rect(Rect2(a.position,Vector2(a.size.x,s)),Color(0.6,0.1,0.4,0.32))
		g.draw_rect(Rect2(Vector2(a.position.x,a.end.y-s),Vector2(a.size.x,s)),Color(0.6,0.1,0.4,0.32))
		g.draw_rect(Rect2(a.position,Vector2(s,a.size.y)),Color(0.6,0.1,0.4,0.32))
		g.draw_rect(Rect2(Vector2(a.end.x-s,a.position.y),Vector2(s,a.size.y)),Color(0.6,0.1,0.4,0.32))
	for h in g.hazards:
		var warning=h.warning>0
		var color=Color(1,0.18,0.3,0.35 if warning else 0.85)
		if h.get("friendly",false): color=Color(1,0.6,0.1,0.25)
		match h.type:
			"blast","stomp","pool","ambush","mine":
				g.draw_circle(h.p,h.r,Color(color,0.12 if warning else 0.23))
				g.draw_arc(h.p,h.r,0,TAU,48,color,3.0 if warning else 5.0)
				if h.type=="pool" and not h.get("friendly",false):
					# Toxic zones use a stable, high-contrast rim, not rapid flashes.
					g.draw_circle(h.p,h.r,Color(0.29,0.89,0.27,0.10))
					g.draw_arc(h.p,h.r,0,TAU,48,Color("73d13d"),2.5)
					g.draw_arc(h.p,h.r*(0.78+0.07*sin(g.total_time*2.0)),0,TAU,40,Color(0.45,0.82,0.24,0.28),1.5)
				if warning:
					var duration:float=0.3 if h.get("source","")=="baneling" else 1.2
					var fraction:float=clampf(float(h.warning)/duration,0,1)
					g.draw_arc(h.p,h.r*maxf(0.06,fraction),0,TAU,40,Color(1,0.84,0.76,0.8),2)
					# Four ticks anchor the actual damage radius while the timer contracts.
					for n in range(4):
						var radial:=Vector2.from_angle(n*PI/2)
						g.draw_line(h.p+radial*(h.r-7),h.p+radial*(h.r+5),color,3)
			"grenade":
				var f=clampf(1.0-h.warning/h.flight,0,1)
				var p:Vector2=h.p.lerp(h.end,f)+Vector2(0,-sin(f*PI)*85)
				g.draw_circle(p,8,Color("ffd38a")); g.draw_arc(h.end,h.r,0,TAU,32,Color(1,0.65,0.2,0.4),2)
			"beam":
				g.draw_line(h.p,h.end,Color(0.8,0.4,1,0.5),h.width); g.draw_line(h.p,h.end,Color("fff1ff"),4)
			"line","arc":
				if h.type=="arc":
					g.draw_line(h.p,h.end,Color("a0ecff"),3)
				elif warning:
					var direction:Vector2=(h.end-h.p).normalized()
					var side:=direction.orthogonal()
					var length:float=h.p.distance_to(h.end)
					var half_width:float=float(h.width)*0.5
					var lava:bool=h.get("source","")=="lava"
					var ink:=Color("ffa940") if lava else Color("ff3344")
					g.draw_line(h.p,h.end,Color(ink,0.12),h.width)
					g.draw_line(h.p-side*half_width,h.end-side*half_width,Color(ink,0.65),1.5)
					g.draw_line(h.p+side*half_width,h.end+side*half_width,Color(ink,0.65),1.5)
					for n in range(int(length/36.0)):
						var at:Vector2=h.p+direction*(n*36.0+12.0)
						if lava:
							g.draw_line(at-side*(half_width-3),at+direction*14+side*(half_width-3),Color(ink,0.5),3)
						else:
							g.draw_line(at-direction*8,at+direction*8,ink,2.5)
							g.draw_polyline(PackedVector2Array([at-direction*2-side*6,at+direction*7,at-direction*2+side*6]),ink,2)
				else:
					g.draw_line(h.p,h.end,color,h.width)
					g.draw_line(h.p,h.end,Color("ffe2b4") if h.get("source","")=="lava" else Color("ffc0c7"),3)
			"fan":
				var points=PackedVector2Array([h.p])
				for n in range(13): points.append(h.p+Vector2.from_angle(h.angle-0.48+n*0.08)*h.r)
				g.draw_colored_polygon(points,Color(1,0.15,0.25,0.15))
				g.draw_line(h.p,points[1],color,3); g.draw_line(h.p,points[-1],color,3)
			"laser":
				var end=h.p+Vector2.from_angle(h.angle+h.rot)*1500
				g.draw_line(h.p,end,color,3 if warning else 38)
				if not warning: g.draw_line(h.p,end,Color(1,0.75,0.8,0.9),8)
	if g.overcharge_timer>0: g.draw_arc(g.player,52,0,TAU,40,Color(0.4,0.9,1,0.65),2)

static func draw_enemy(g,e:Dictionary) -> bool:
	if e.has("charge_dir") and e.get("charge_time",0.0)<0.9:
		g.draw_line(e.p,e.p+e.charge_dir*650,Color(1,0.2,0.2,0.65),3)
	if e.kind=="boss" and g.wave==20:
		g.draw_circle(e.p,57,Color("c3925d") if not e.get("underground",false) else Color(0.7,0.4,0.2,0.25))
		for n in range(6): g.draw_arc(e.p,18+n*7,0,TAU,24,Color("714b42"),4)
		return true
	if e.kind=="baneling":
		var pulse:float=0.5+0.5*sin(g.total_time*3.0+float(e.id))
		g.draw_circle(e.p,25+3*pulse,Color(0.29,0.89,0.27,0.10+0.04*pulse))
		for n in range(6):
			var limb:=Vector2.from_angle(n*TAU/6)
			g.draw_line(e.p+limb*15,e.p+limb*25,Color("34503a"),4)
		g.draw_circle(e.p,20,Color("26492d")); g.draw_circle(e.p,15,Color("49e344"))
		for n in range(5): g.draw_circle(e.p+Vector2.from_angle(n*TAU/5)*11,4,Color("ceff84"))
		g.draw_arc(e.p,20,0,TAU,24,Color("73d13d"),1.5)
		if e.fuse>=0:
			g.draw_circle(e.p,120,Color(1,0.20,0.27,0.065))
			g.draw_arc(e.p,120,0,TAU,48,Color("ff3344"),2.5)
			g.draw_arc(e.p,120*clampf(float(e.fuse)/0.3,0.05,1),0,TAU,40,Color("ffe4ad"),3)
			for n in range(4):
				var radial:=Vector2.from_angle(n*PI/2)
				g.draw_line(e.p+radial*114,e.p+radial*125,Color("ff3344"),3)
		return true
	if e.kind=="lurker":
		g.draw_circle(e.p,28,Color(0.21,0.14,0.23,0.7)); g.draw_circle(e.p,25,Color("62475f"))
		for n in range(8):
			var dir=Vector2.from_angle(n*TAU/8)
			g.draw_line(e.p+dir*18,e.p+dir*(34 if e.burrow>0 else 27),Color("d6c4dd"),4)
		if e.burrow>0: g.draw_arc(e.p,29,0,TAU,30,Color("ff677a"),2)
		return true
	if e.kind in ["cocoon","nest"]:
		g.draw_circle(e.p,26,Color("633f65")); g.draw_circle(e.p,19,Color("bb80a1"))
		g.draw_arc(e.p,32,-PI/2,-PI/2+TAU*clampf(1-e.fire/6,0,1),32,Color("ffcf7a"),4)
		g.draw_string(g.font,e.p+Vector2(-7,-38),"巢" if e.kind=="nest" else str(maxi(0,ceili(6.0-e.fire))),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffdf9f"))
		return true
	return false

static func update_supports(g,dt:float) -> void:
	g.combat.eng_shield_cd=maxf(0,float(g.combat.get("eng_shield_cd",0.0))-dt)
	if g.turret>0 or support(g,"sentry"):
		g.combat.turret-=dt
		if g.combat.turret<=0:
			g.combat.turret+=(1.0/6.0)/float(g.support_attack_mult)
			var origin:Vector2=g.combat.turret_p
			var target={}; var best=700.0*700.0
			for e in g.enemies:
				if e.hp>0 and e.warmup<=0 and not e.get("underground",false) and origin.distance_squared_to(e.p)<best:
					best=origin.distance_squared_to(e.p); target=e
			if not target.is_empty():
				fire_bullet(g,(target.p-origin).angle(),850,7.5*g.damage_mult,0.9,Color("bbecff"),1,"turret",{"origin":origin})
				event(g,"turret")
	if support(g,"medic_drone"):
		g.combat.med_timer-=dt
		if g.combat.med_timer<=0:
			g.combat.med_timer+=4.0; g.hp=minf(g.max_hp,g.hp+5)
		if g.hp<g.max_hp*0.2 and not g.combat.med_shield_used:
			g.combat.med_shield_used=true; g.hurt_timer=maxf(g.hurt_timer,3.0); event(g,"medic_shield")
	if support(g,"raven") and g.combat.drone_charges>0:
		for i in range(g.acid.size()-1,-1,-1):
			if g.combat.drone_charges<=0: break
			var a=g.acid[i]
			if a.p.distance_to(g.player)<=130:
				g.acid.remove_at(i); g.combat.acid_pool.append(a); g.combat.drone_charges-=1
	if support(g,"spider_mine"):
		g.combat.mine_distance+=g.player.distance_to(g.combat.last_player)
		if g.combat.mine_distance>=800:
			g.combat.mine_distance-=800
			add_hazard(g,{"type":"mine","p":g.player,"r":140.0,"warning":0.6,"life":30.0,"dmg":45.0,"friendly":true})
	g.combat.last_player=g.player

static func chain_lightning(g,first:Dictionary,damage:float,count:int,stun:float) -> void:
	var current=first; var hit=[]; var from:Vector2=g.player
	for n in range(count):
		if current.is_empty(): break
		hit.append(current.id)
		add_hazard(g,{"type":"arc","p":from,"end":current.p,"warning":0.0,"life":0.22,"dmg":0})
		hit_enemy(g,current,damage,Vector2.ZERO,"tesla")
		current.stun=maxf(current.stun,stun)
		from=current.p
		var next={}; var best=210.0*210.0
		for e in g.enemies:
			if e.hp>0 and e.id not in hit and not e.get("underground",false) and from.distance_squared_to(e.p)<best:
				best=from.distance_squared_to(e.p); next=e
		current=next
