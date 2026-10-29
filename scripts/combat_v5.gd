extends RefCounted
## V5 deterministic world simulation. Rendering/input projection never live here.
## Every damage event carries an origin; secondary and summon events cannot recurse.
const Build = preload("res://scripts/build_v5.gd")
const WORLD := Rect2(0, 0, 1800, 1200)
const PLAYER_RADIUS := 14.0
const MAX_PROJECTILES := 300
const MAX_DEVICES := 8
const ENEMY_BASE := {
 "runner":{"hp":18.0,"armor":0.0,"speed":155.0,"r":13.0,"damage":6.0},
 "roach":{"hp":100.0,"armor":15.0,"speed":90.0,"r":23.0,"damage":10.0},
 "hydra":{"hp":40.0,"armor":0.0,"speed":100.0,"r":18.0,"damage":8.0},
 "baneling":{"hp":25.0,"armor":0.0,"speed":170.0,"r":17.0,"damage":20.0},
 "lurker":{"hp":110.0,"armor":10.0,"speed":70.0,"r":24.0,"damage":18.0},
 "infestor":{"hp":80.0,"armor":0.0,"speed":80.0,"r":23.0,"damage":0.0},
 "node":{"hp":160.0,"armor":5.0,"speed":0.0,"r":30.0,"damage":0.0},
 "boss":{"hp":1200.0,"armor":10.0,"speed":37.0,"r":55.0,"damage":12.0},
 "cocoon":{"hp":100.0,"armor":0.0,"speed":0.0,"r":24.0,"damage":0.0}
}
var run: Dictionary = {}
var p := Vector2(900, 600)
var last_dir := Vector2.UP
var moving := false
var visible_world := Rect2()
var enemies: Array = []
var projectiles: Array = []
var hazards: Array = []
var drops: Array = []
var devices: Array = []
var effects: Array = []
var elapsed := 0.0
var skill_cd := 0.0
var dash_cd := 0.0
var dash_left := 0.0
var stim_left := 0.0
var shield := 0.0
var shields: Array = []
var mark_uid := -1
var mark_left := 0.0
var active_value := 0
var finished := false
var iframe := 0.0
var since_hurt := 100.0
var total_damage := 0.0
var damage_taken := 0.0
var last_damage_source := ""
var point_defense_left := 8
var boss_pressure := 0
var statistics: Dictionary = {}
var _uid := 0
var _rng := RandomNumberGenerator.new()
var _events: Array = []
var _shots: Dictionary = {}
var _spawn_timer := 0.8
var _spawned := 0
var _drop_value := 0
var _drop_budget := 30
var _dash_speed := 900.0
var _dash_dir := Vector2.UP
var _pending_skill: Dictionary = {}
var _skill_at := -100.0
var _dash_at := -100.0
var _secondary_second := -1
var _secondary_count := 0
var _secondary_total := 0
var _secondary_queue: Array = []
var _timers: Dictionary = {}
var _healing_hits := 0
var _healing_window := 0.0
var _stationary := 0.0
var _mine_distance := 0.0
var _deploy_count := 0
var _friendly_pending: Array = []
var _pending_spawns: Array = []
var _normal_kills := 0
var _kill_count := 0
var _cooldown_reduction_second := -1
var _cooldown_reduction_used := 0.0
var _cached_stats: Dictionary = {}
var _move_input := Vector2.ZERO
var _frame_dt := 0.0

func initialize(data: Dictionary) -> void:
 run = data
 p = Vector2(900,600)
 last_dir=Vector2.UP; moving=false; total_damage=0.0; damage_taken=0.0; last_damage_source=""
 _cooldown_reduction_second=-1; _cooldown_reduction_used=0.0
 enemies.clear(); projectiles.clear(); hazards.clear(); drops.clear(); devices.clear(); effects.clear(); shields.clear()
 elapsed=0.0; skill_cd=0.0; dash_cd=0.0; dash_left=0.0; stim_left=0.0; shield=0.0
 mark_uid=-1; mark_left=0.0; active_value=0; finished=false; iframe=0; since_hurt=100.0
 _uid=0; _shots={}; _events=[]; _secondary_queue=[]; _timers={}; _pending_skill={}; _friendly_pending=[]; _pending_spawns=[]
 _secondary_second=-1; _secondary_count=0; _secondary_total=0; _spawn_timer=0.8; _spawned=0; _drop_value=0
 _healing_hits=0; _healing_window=0; _stationary=0; _mine_distance=0; _normal_kills=0; _kill_count=0
 _deploy_count=int(run.get("deploy_count",0)); _skill_at=-100; _dash_at=-100
 statistics={"secondary":0,"secondary_dropped":0,"recursive_blocked":0,"damage_by_source":{},"boss_damage_by_source":{},"peak_enemies":0,"peak_projectiles":0,"peak_devices":0,"danger_delays":0,"mark_count":0,"kills":0}
 _rng.seed=int(run.get("rng_seed",1))+int(run.get("wave",1))*100003
 if run.has("combat_rng_state"): _rng.state=int(run.combat_rng_state)
 _cached_stats=Build.stats(run)
 if not run.has("hp"): run.hp=float(_cached_stats.max_hp)
 var boss_mode=is_boss_wave()
 _drop_budget=20 if boss_mode else 30
 point_defense_left=8+(4 if item("I36")>0 else 0)
 if support("S02"): _timers.S02=4.0
 if support("S01"): deploy_device("sentry",p+Vector2(-65,-35),80.0,12.0,3.0,400.0,-1.0)
 if support("S05"): deploy_device("laser",p+Vector2(65,-35),100.0,8.0,4.0,650.0,-1.0)
 if boss_mode:
  var b=spawn_enemy("boss",Vector2(900,240),1.0)
  if is_final_boss(): b.hp=4200.0; b.max_hp=4200.0; b.armor=20.0; b.r=65.0
 elif run.get("mode","")=="pressure":
  _drop_budget=0
  _spawn_timer=0.2

func is_boss_wave() -> bool:
 return int(run.get("wave",1))==4 or run.get("mode","") in ["boss","boss_test","final_boss"] or int(run.get("wave",1))==12

func is_final_boss() -> bool:
 return run.get("mode","") in ["boss","boss_test","final_boss"] or int(run.get("wave",1))==12

func item(id: String) -> int:
 return int(run.get("items",{}).get(id,0))

func tech(id: String) -> bool:
 return id in run.get("techs",[])

func support(id: String) -> bool:
 return id in run.get("supports",[])

func stat(key: String, fallback: float=1.0) -> float:
 return float(_cached_stats.get(key,fallback))

func get_enemy(uid: int) -> Dictionary:
 for e in enemies:
  if int(e.uid)==uid and float(e.hp)>0: return e
 return {}

func target(distance: float, current: int=-1, origin: Vector2=Vector2.INF) -> Dictionary:
 if origin==Vector2.INF: origin=p
 var marked=get_enemy(mark_uid)
 if not marked.is_empty() and float(marked.warning)<=0 and origin.distance_to(marked.p)<=distance: return marked
 var best: Dictionary={}
 var best_d=INF
 var dangerous=false
 for e in enemies:
  if float(e.hp)<=0 or float(e.warning)>0: continue
  var d=origin.distance_to(e.p)
  if d>distance: continue
  var threat=bool(e.get("mechanism",false)) or float(e.get("cast",0))>0
  if not best.is_empty() and dangerous and not threat: continue
  if best.is_empty() or (threat and not dangerous) or d<best_d-0.01 or (absf(d-best_d)<=0.01 and int(e.uid)==current):
   best=e; best_d=d; dangerous=threat
 return best

func request_mark(uid: int) -> bool:
 if uid==mark_uid:
  mark_uid=-1; mark_left=0.0; return true
 var e=get_enemy(uid)
 if e.is_empty() or float(e.warning)>0: return false
 mark_uid=uid; mark_left=4.0+item("I25"); statistics.mark_count+=1
 return true

func skill_preview() -> Dictionary:
 var cls=str(run.get("class_id","C01"))
 if skill_cd>0: return {"ok":false,"reason":"技能冷却中","p":p,"r":0.0,"kind":"self"}
 if cls=="C01": return {"ok":true,"reason":"消耗当前生命12%，至少保留1生命","p":p,"r":0.0,"kind":"self","cost":minf(maxf(1.0,float(run.hp)*0.12),maxf(0,float(run.hp)-1))}
 if cls=="C06":
  var count=0
  for d in devices:
   if d.kind=="turret" and not d.copy and d.hp>0: count+=1
  return {"ok":devices.filter(func(d): return d.hp>0).size()<MAX_DEVICES or count>=2,"reason":"部署新炮台，回收最旧炮台" if count>=2 else "部署炮台：12秒交叉火力","p":p,"r":350.0,"kind":"device"}
 var t=target(600.0)
 if t.is_empty(): return {"ok":false,"reason":"范围内无目标","p":p+last_dir*160.0,"r":90.0,"kind":"circle"}
 return {"ok":true,"reason":"KD8：0.8秒后爆炸，击退非首领目标","p":t.p,"r":90.0,"kind":"circle"}

func step(dt: float, move: Vector2, commands: Dictionary={}) -> Array:
 _events=[]
 if finished: return _events
 dt=clampf(dt,0.0,0.1)
 _frame_dt=dt
 elapsed+=dt
 _cached_stats=Build.stats(run)
 _move_input=move.limit_length(1.0)
 moving=_move_input.length()>0.05
 if moving: last_dir=_move_input.normalized()
 _stationary=0.0 if moving or dash_left>0 else _stationary+dt
 skill_cd=maxf(0,skill_cd-dt); dash_cd=maxf(0,dash_cd-dt); stim_left=maxf(0,stim_left-dt)
 iframe=maxf(0,iframe-dt); since_hurt+=dt; mark_left=maxf(0,mark_left-dt); _healing_window=maxf(0,_healing_window-dt)
 for key in _timers:
  if key not in ["pickup_value","T11_pending"]: _timers[key]=maxf(0,float(_timers[key])-dt)
 _tick_shields(dt)
 if mark_left<=0 or get_enemy(mark_uid).is_empty(): mark_uid=-1; mark_left=0.0
 if bool(commands.get("dash",false)): _start_dash()
 if bool(commands.get("skill",false)):
  if dash_left>0: _pending_skill=commands.duplicate()
  else: _cast_skill(commands)
 var old_p=p
 if dash_left>0:
  var portion=minf(dt,dash_left)
  var intended=p+_dash_dir*_dash_speed*portion
  p=_clamp_world(intended)
  dash_left=0.0 if p.distance_to(intended)>0.01 else maxf(0,dash_left-dt)
  if dash_left<=0:
   _end_dash()
   if not _pending_skill.is_empty():
    var pending=_pending_skill; _pending_skill={}; _cast_skill(pending)
 else:
  var speed=stat("speed_raw",stat("speed",215.0))
  if stim_left>0: speed+=float(Build.Data.CLASSES[str(run.class_id)].speed)*0.15
  if float(_timers.get("dash_slow",0))>0: speed-=float(Build.Data.CLASSES[str(run.class_id)].speed)*0.1
  speed=clampf(speed,140,360)
  var slow=_player_ground_slow()
  p=_clamp_world(p+_move_input*speed*(1.0-slow)*dt)
  _mine_distance+=p.distance_to(old_p)
 _drain_spawns()
 _spawn_update(dt)
 _enemy_update(dt)
 _weapon_update(dt)
 _device_update(dt)
 _support_update(dt)
 _friendly_update(dt)
 _projectile_update(dt)
 _hazard_update(dt)
 _flush_secondary()
 _passives(dt)
 _pickup_update()
 _cleanup(dt)
 if float(run.hp)<=0 and not finished:
  finished=true; _events.append({"type":"death","text":"紧急撤离／任务未完成","source":last_damage_source})
 elif not finished and run.get("mode","")=="pressure" and elapsed>=float(run.get("pressure_seconds",60.0)):
  _finish_wave()
 elif not finished and run.get("mode","")!="pressure":
  if is_boss_wave():
   var alive=false
   for e in enemies:
    if e.boss and e.hp>0: alive=true
   if not alive: _finish_wave()
  elif elapsed>=35.0: _finish_wave()
 statistics.peak_enemies=maxi(int(statistics.peak_enemies),enemies.size())
 statistics.peak_projectiles=maxi(int(statistics.peak_projectiles),projectiles.size())
 statistics.peak_devices=maxi(int(statistics.peak_devices),devices.filter(func(d): return d.hp>0).size())
 run.combat_rng_state=str(_rng.state)
 run.deploy_count=_deploy_count
 return _events.duplicate()

func _clamp_world(pos: Vector2) -> Vector2:
 return Vector2(clampf(pos.x,PLAYER_RADIUS,1800-PLAYER_RADIUS),clampf(pos.y,PLAYER_RADIUS,1200-PLAYER_RADIUS))

func _start_dash() -> bool:
 if dash_cd>0 or dash_left>0: return false
 dash_cd=stat("dash_cd",4.0); _dash_at=elapsed-_frame_dt
 _dash_dir=last_dir.normalized(); dash_left=0.20
 _dash_speed=stat("dash_distance",180.0)/0.20
 _events.append({"type":"dash"})
 return true

func _end_dash() -> void:
 if tech("T02") and float(_timers.get("T02",0))<=0:
  grant_shield("combat_shield",12.0); _timers.T02=6.0
 if tech("T03"):
  queue_secondary("T03",p,80.0,40.0*stat("damage"),{"source":"T03"})
  _timers.dash_slow=1.0

func _cast_skill(commands: Dictionary) -> bool:
 var preview=skill_preview()
 if not preview.ok:
  _events.append({"type":"notice","text":preview.reason}); return false
 var cls=str(run.get("class_id","C01"))
 var success=true
 match cls:
  "C01":
   var cost=minf(maxf(1.0,float(run.hp)*0.12),maxf(0.0,float(run.hp)-1.0))
   run.hp=float(run.hp)-cost
   stim_left=5.0
   _events.append({"type":"life_cost","amount":cost,"text":"兴奋剂"})
  "C03":
   var dest: Vector2=preview.p
   if commands.has("skill_target"): dest=p+(Vector2(commands.skill_target)-p).limit_length(600)
   _friendly_pending.append({"kind":"grenade","p":dest,"r":90.0,"damage":55.0*stat("damage")*stat("skill_damage"),"delay":0.8,"source":"KD8","knockback":60.0})
  "C06":
   var old: Dictionary={}
   var count=0
   for d in devices:
    if d.kind=="turret" and not d.copy and d.hp>0:
     count+=1
     if old.is_empty() or float(d.born)<float(old.born): old=d
   if count>=2:
    devices.erase(old)
    if tech("T10") and float(_timers.get("T10_recycle",0))<=0:
     heal(3.0); _timers.T10_recycle=10.0
   var d=deploy_device("turret",p,60.0,10.0,3.0,350.0,12.0)
   success=not d.is_empty()
  _:
   success=false
 if not success:
  _events.append({"type":"notice","text":"支援已满，等待现有支援消失"}); return false
 skill_cd=stat("skill_cd",12.0); _skill_at=elapsed
 if tech("T01"): _healing_window=4.0; _healing_hits=0
 if tech("T12") and float(_timers.get("T12",0))<=0:
  grant_shield("matrix",15.0)
  var nearest=_nearest_device()
  if not nearest.is_empty(): grant_device_shield(nearest,"matrix",15.0)
  _timers.T12=8.0
 _events.append({"type":"skill","class_id":cls})
 return true

func reduce_cooldowns(seconds: float) -> float:
 var sec=int(floor(elapsed))
 if sec!=_cooldown_reduction_second: _cooldown_reduction_second=sec; _cooldown_reduction_used=0.0
 var amount=clampf(seconds,0.0,0.5-_cooldown_reduction_used)
 _cooldown_reduction_used+=amount
 skill_cd=maxf(maxf(0.0,1.0-(elapsed-_skill_at)),skill_cd-amount)
 dash_cd=maxf(maxf(0.0,1.0-(elapsed-_dash_at)),dash_cd-amount)
 return amount

func grant_shield(name: String, amount: float, duration: float=3.0) -> float:
 amount=maxf(0,amount)*(1.0+0.2*item("I16"))
 var entry: Dictionary={}
 for layer in shields:
  if layer.name==name: entry=layer; break
 var old=0.0
 if not entry.is_empty(): old=float(entry.amount)
 var room=maxf(0,stat("max_hp",100)*0.5-(shield-old))
 var granted=minf(maxf(old,amount),room)
 if entry.is_empty(): shields.append({"name":name,"amount":granted,"left":duration})
 else: entry.amount=granted; entry.left=duration
 _sum_shield()
 return granted

func _sum_shield() -> void:
 shield=0.0
 for layer in shields: shield+=maxf(0,float(layer.amount))

func _tick_shields(dt: float) -> void:
 for layer in shields: layer.left-=dt
 shields=shields.filter(func(s): return s.left>0 and s.amount>0)
 _sum_shield()
 for d in devices:
  for layer in d.get("shields",[]): layer.left-=dt
  d.shields=d.get("shields",[]).filter(func(s): return s.left>0 and s.amount>0)
  d.shield=0.0
  for layer in d.shields: d.shield+=layer.amount

func grant_device_shield(d: Dictionary, name: String, amount: float, duration: float=3.0) -> void:
 if d.is_empty() or d.hp<=0: return
 var layers: Array=d.get("shields",[])
 var found: Dictionary={}
 for layer in layers:
  if layer.name==name: found=layer
 var total=0.0
 for layer in layers: total+=float(layer.amount)
 var old=float(found.get("amount",0))
 var grant=minf(maxf(old,amount),maxf(0,float(d.max_hp)*0.5-total+old))
 if found.is_empty(): layers.append({"name":name,"amount":grant,"left":duration})
 else: found.amount=grant; found.left=duration
 d.shields=layers; d.shield=total-old+grant

static func mitigation(armor: float, temporary: float=0.0) -> float:
 var a=clampf(armor,0,150)
 return maxf(0.15,(1.0-a/(a+50.0))*(1.0-clampf(temporary,0,0.30)))

func hurt(amount: float, source: String="enemy", armor_ignore: float=0.0, temporary: float=0.0, life_cost: bool=false) -> float:
 if finished: return 0.0
 if life_cost:
  var cost=minf(maxf(0,amount),maxf(0,float(run.hp)-1.0))
  run.hp=float(run.hp)-cost
  return cost
 if iframe>0 or elapsed<_dash_at+0.15 or amount<=0: return 0.0
 var incoming=amount
 if source in ["acid_pool","acid_cloud"]: incoming*=maxf(0.0,1.0-0.2*item("I15"))
 elif item("I15")>0: incoming*=1.0+0.05*item("I15")
 var dmg=maxf(amount*0.15,incoming*mitigation(stat("armor",0)-armor_ignore,temporary))
 shields.sort_custom(func(a,b): return a.left<b.left)
 var remain=dmg
 for layer in shields:
  var used=minf(remain,float(layer.amount)); layer.amount-=used; remain-=used
 _sum_shield()
 var rescue=false
 if remain>=float(run.hp) and item("I14")>0 and not bool(run.get("rescue_spent",false)):
  run.rescue_spent=true; run.hp=1.0; rescue=true; grant_shield("emergency",20.0)
  _events.append({"type":"rescue","text":"应急矩阵已用／本局一次"})
 else: run.hp=maxf(0,float(run.hp)-remain)
 since_hurt=0.0
 iframe=0.0 if rescue else stat("iframe",0.45)
 damage_taken+=dmg; last_damage_source=source
 _events.append({"type":"damage","amount":dmg,"source":source})
 if float(run.hp)>0 and support("S06") and float(_timers.get("S06",0))<=0:
  grant_shield("matrix",20.0); _timers.S06=12.0
 return dmg

func heal(amount: float) -> float:
 if float(run.hp)<=0: return 0.0
 var actual=minf(maxf(0,amount*stat("healing")),maxf(0,stat("max_hp",100)-float(run.hp)))
 run.hp=float(run.hp)+actual
 if actual>0: effects.append({"kind":"heal","p":p,"r":24.0,"life":0.3})
 return actual

func apply_slow(e: Dictionary, ratio: float, duration: float) -> void:
 var cap=0.15 if bool(e.get("boss",false)) else 0.5
 if bool(e.get("elite",false)): ratio*=0.5
 if not e.has("slows"): e.slows=[]
 e.slows.append({"ratio":minf(cap,ratio),"left":duration})
 if e.slows.size()>64: e.slows.pop_front()
 e.slow=maxf(float(e.get("slow",0)),minf(cap,ratio))
 e.slow_left=maxf(float(e.get("slow_left",0)),duration)

func apply_control(e: Dictionary, duration: float, knockback: Vector2=Vector2.ZERO) -> bool:
 if bool(e.get("boss",false)) or elapsed<float(e.get("control_until",-100)): return false
 e.stun=minf(duration,0.3 if bool(e.get("elite",false)) else 1.0)
 e.control_until=elapsed+3.0
 if knockback!=Vector2.ZERO: e.p=_clamp_world(Vector2(e.p)+knockback)
 return true

func delay_cast(e: Dictionary, seconds: float) -> float:
 if bool(e.get("boss",false)):
  if elapsed<float(e.get("emp_after",-100)): return 0.0
  seconds=minf(seconds,0.3); e.emp_after=elapsed+10.0
 e.cast=float(e.get("cast",0))+seconds
 return seconds

func _weapon_update(dt: float) -> void:
 for weapon in run.get("weapons",[]):
  var uid=str(weapon.get("uid",weapon.id))
  if not _shots.has(uid): _shots[uid]={"cd":0.0,"rounds":0,"burst":0.0,"pause":0.0,"target":-1,"hits":0,"repair":0.0,"proc_at":-100.0}
  var shot: Dictionary=_shots[uid]
  shot.cd=maxf(0,float(shot.cd)-dt); shot.repair=maxf(0,float(shot.repair)-dt)
  if float(shot.pause)>0: shot.pause=maxf(0,float(shot.pause)-dt); continue
  var ws=Build.weapon_stats(run,weapon)
  var id=str(weapon.id)
  var branch=str(weapon.get("branch","")).to_upper()
  var rate=float(ws.get("base_rate",Build.Data.WEAPONS[id].rate))
  var distance=float(ws.get("range",400.0))
  var attack=float(ws.get("raw_attack",stat("attack_raw",stat("attack"))+(0.1 if str(run.class_id)=="C01" and "实弹" in ws.get("tags",[]) else 0.0)))
  if stim_left>0: attack+=0.35
  if branch=="B" and id in ["W02","W07"]: attack-=0.15
  if branch=="A" and id=="W05": attack-=0.15
  if branch=="B" and id=="W06": attack-=0.25
  if branch=="B" and id=="W01": attack+=0.45
  rate*=clampf(attack,0.5,2.5)
  var t=target(distance,int(shot.target))
  if t.is_empty(): shot.burst=0.0; continue
  if branch=="B" and id=="W01":
   shot.burst+=dt
   if float(shot.burst)>=3.0: shot.pause=0.6; shot.burst=0.0; continue
  if shot.cd>0: continue
  shot.cd=1.0/maxf(0.05,rate)
  shot.rounds+=1
  if int(shot.target)!=int(t.uid): shot.target=t.uid; shot.hits=0
  shot.hits+=1
  var damage=float(ws.get("damage",1.0))
  var base=float(ws.get("base_damage",damage))
  var radius=float(ws.get("radius",0))
  var ignore=float(ws.get("armor_ignore",0))
  var crit=clampf(float(ws.get("crit",stat("crit",0.05))),0,0.75)
  var object_bonus=1.0
  if tech("T05") and bool(t.get("heavy",false)) and id in ["W01","W02","W03","W05","W06","W07"]: object_bonus+=0.15
  match id:
   "W01":
    if branch=="A": damage*=0.85
   "W02":
    if branch=="A": damage*=1.25 if moving else 0.85
   "W03":
    if branch=="A":
     ignore+=10.0; radius*=0.7
     if bool(t.get("heavy",false)): object_bonus+=0.4
    elif branch=="B": damage*=0.8; radius*=1.4
   "W05":
    if branch=="B":
     if t.boss or t.elite: object_bonus+=0.4
     else: damage*=0.8
     if int(t.uid)==mark_uid: crit=minf(0.75,crit+0.15)
   "W06":
    if branch=="A": damage*=0.8
    elif branch=="B": damage*=1.35; ignore+=15; radius*=0.85
   "W07":
    if branch=="A": damage*=0.9
  if tech("T08") and id in ["W03","W06"]:
   if float(t.slow)>0: object_bonus+=0.15
  ignore=minf(25.0,ignore)
  var did_crit=_rng.randf()<crit
  var crit_mult=clampf(float(ws.get("crit_mult",1.5)),1.25,2.5) if did_crit else 1.0
  var shot_meta={"origin":"weapon","direct":true,"source":id,"base":base,"weapon_uid":uid,"crit":did_crit,"proc":true}
  var initial_uid=int(t.uid)
  var end: Vector2=t.p
  hit_enemy(t,damage*object_bonus*crit_mult,ignore,shot_meta)
  _weapon_on_direct(weapon,shot,t,base)
  if id=="W03" and branch=="B": apply_slow(t,0.25,1.0)
  if tech("T08") and id in ["W03","W06"] and elapsed>=float(t.get("T08_after",-100)):
   apply_slow(t,0.30,1.5); t.T08_after=elapsed+1.0
  if radius>0:
   var list=_nearby(end,radius)
   var splash_count=0
   for e in list:
    if int(e.uid)==initial_uid: continue
    if splash_count>=19: break
    splash_count+=1
    var splash_bonus=1.0
    if id=="W03" and branch=="A" and bool(e.get("heavy",false)): splash_bonus+=0.4
    if tech("T08") and float(e.slow)>0: splash_bonus+=0.15
    var splash_ignore=maxf(0,ignore-(10.0 if tech("T05") else 0.0))
    hit_enemy(e,damage*crit_mult*splash_bonus,splash_ignore,{"origin":"weapon_splash","source":id,"proc":false})
   effects.append({"kind":"explosion","p":end,"r":radius,"life":0.18})
  elif (id=="W01" or id=="W05") and branch=="A":
   var count=2
   var attenuation=0.8 if id=="W01" else 0.7
   var dir=(end-p).normalized()
   var candidates=[]
   for e in enemies:
    var delta: Vector2=e.p-p
    var along=delta.dot(dir)
    if e.uid!=initial_uid and e.hp>0 and e.warning<=0 and along>p.distance_to(end) and along<=distance and absf(delta.cross(dir))<=float(e.r)+7.0: candidates.append(e)
   candidates.sort_custom(func(a,b): return p.distance_squared_to(a.p)<p.distance_squared_to(b.p))
   for e in candidates.slice(0,count):
    damage*=attenuation
    hit_enemy(e,damage*crit_mult,ignore,{"origin":"weapon_penetration","source":id,"proc":false})
    end=e.p
  if id=="W06" and branch=="A":
   for n in range(3):
    var offset=Vector2.from_angle(float(n)*TAU/3.0+_rng.randf()*0.3)*48.0
    queue_secondary("W06",Vector2(t.p)+offset,40.0,base*0.25*stat("damage"),{"source":"W06A"})
  effects.append({"kind":"shot","p":p,"to":end,"life":0.11,"weapon":id,"crit":did_crit})

func _weapon_on_direct(weapon: Dictionary, shot: Dictionary, target_enemy: Dictionary, base: float) -> void:
 var id=str(weapon.id)
 var branch=str(weapon.get("branch","")).to_upper()
 if _healing_window>0 and tech("T01"):
  _healing_hits+=1
  if _healing_hits>=8 and float(_timers.get("T01",0))<=0:
   _healing_hits-=8; heal(2.0); _timers.T01=1.0
 if id=="W02" and branch=="B" and int(shot.rounds)%12==0:
  queue_secondary("W02",target_enemy.p,60.0,base*0.6*stat("damage"),{"source":"W02B"})
 if id=="W07" and branch=="A" and int(shot.hits)%5==0:
  queue_secondary("W07",target_enemy.p,0.0,base*0.5*stat("damage"),{"source":"W07A","target":int(target_enemy.uid)})
 if id=="W07" and branch=="B" and int(shot.rounds)%8==0 and float(shot.repair)<=0:
  var device=_nearest_device()
  if not device.is_empty(): device.hp=minf(float(device.max_hp),float(device.hp)+4.0*stat("healing")); shot.repair=1.0
 # These inactive reference-contract paths are tested but never enter slice offers.
 if id in ["W09","W10","W12"]:
  if tech("T18") and int(shot.hits)%5==0 and float(shot.get("T18_after",-100))<=elapsed:
   _queue_arc("T18",target_enemy,base*0.4*stat("damage")); shot.T18_after=elapsed+1.0
  if item("I08")>0 and int(shot.hits)%5==0 and float(_timers.get("I08",0))<=0:
   _queue_arc("I08",target_enemy,base*0.4*stat("damage")); _timers.I08=1.0

func hit_enemy(e: Dictionary, amount: float, armor_ignore: float=0.0, meta: Dictionary={}) -> float:
 if e.is_empty() or float(e.hp)<=0 or float(e.warning)>0: return 0.0
 if float(e.get("phase_lock",0))>0: return 0.0
 var origin=str(meta.get("origin","secondary"))
 if origin in ["secondary","burn","summon"] and bool(meta.get("proc",false)):
  statistics.recursive_blocked+=1
 var dealt=maxf(0,amount)*mitigation(float(e.armor)-clampf(armor_ignore,0,25))
 var before=float(e.hp)
 e.hp=maxf(0,before-dealt); e.flash=0.09
 total_damage+=minf(before,dealt)
 var source=str(meta.get("source",origin))
 var sources: Dictionary=statistics.damage_by_source
 sources[source]=float(sources.get(source,0))+minf(before,dealt)
 if bool(e.boss):
  var boss_sources: Dictionary=statistics.boss_damage_by_source
  boss_sources[source]=float(boss_sources.get(source,0))+minf(before,dealt)
 if e.boss and e.hp>0: _check_boss_phases(e)
 if e.hp<=0:
  _kill_count+=1; statistics.kills=_kill_count
  if not e.boss and e.kind!="cocoon": _normal_kills+=1
  _drop_for_kill(e)
  if int(e.uid)==mark_uid: mark_uid=-1; mark_left=0
  # T04 only recognizes direct weapon/skill kills, never its own ground fire.
  if tech("T04") and origin in ["weapon","skill"] and source in ["W04","fuel"] and _secondary_count<8:
   queue_secondary("T04",e.p,60.0,8.0,{"source":"T04","ground":true})
 return minf(before,dealt)

func queue_secondary(owner: String, position: Vector2, radius: float, damage: float, meta: Dictionary={}) -> bool:
 if str(meta.get("origin","")) in ["secondary","burn","summon"]:
  statistics.recursive_blocked+=1; return false
 var priority=100
 var index=run.get("techs",[]).find(owner)
 if index>=0: priority=index
 elif owner.begins_with("I"): priority=10+int(owner.substr(1))
 elif owner.begins_with("W"): priority=-1
 _secondary_queue.append({"owner":owner,"p":position,"r":radius,"damage":damage,"meta":meta.duplicate(),"priority":priority,"order":_secondary_queue.size()})
 return true

func _queue_arc(owner: String, primary: Dictionary, damage: float) -> void:
 var list=_nearby(primary.p,120.0)
 list=list.filter(func(e): return e.uid!=primary.uid)
 for e in list.slice(0,2): queue_secondary(owner,e.p,0,damage,{"target":int(e.uid),"source":owner})

func _flush_secondary() -> void:
 var sec=int(floor(elapsed))
 if sec!=_secondary_second: _secondary_second=sec; _secondary_count=0
 _secondary_queue.sort_custom(func(a,b): return a.priority<b.priority or (a.priority==b.priority and a.order<b.order))
 var queue=_secondary_queue
 _secondary_queue=[]
 for event in queue:
  if _secondary_count>=8: statistics.secondary_dropped+=1; continue
  _secondary_count+=1; _secondary_total+=1; statistics.secondary=_secondary_total
  var meta: Dictionary=event.meta
  meta.origin="secondary"; meta.proc=false; meta.crit=false
  if bool(meta.get("ground",false)):
   hazards.append({"kind":"circle","p":event.p,"r":event.r,"angle":0.0,"length":0.0,"width":0.0,"warning":0.0,"life":2.0,"damage":event.damage*0.5,"friendly":true,"priority":0,"tick":0.5,"source":"T04"})
  elif meta.has("target"):
   var e=get_enemy(int(meta.target))
   if not e.is_empty(): hit_enemy(e,event.damage,0,meta)
  else:
   for e in _nearby(event.p,event.r): hit_enemy(e,event.damage,0,meta)
  effects.append({"kind":"explosion","p":event.p,"r":maxf(12,event.r),"life":0.18,"secondary":true})

func _nearby(position: Vector2, radius: float) -> Array:
 var result=[]
 for e in enemies:
  if e.hp>0 and e.warning<=0 and Vector2(e.p).distance_to(position)<=radius: result.append(e)
 result.sort_custom(func(a,b): return Vector2(a.p).distance_squared_to(position)<Vector2(b.p).distance_squared_to(position))
 return result.slice(0,20)

func apply_burn(e: Dictionary, source: String, damage_per_second: float, duration: float=3.0) -> void:
 if not e.has("burns"): e.burns=[]
 var found: Dictionary={}
 for burn in e.burns:
  if burn.source==source: found=burn
 if found.is_empty(): e.burns.append({"source":source,"damage":damage_per_second,"left":duration,"tick":0.5})
 else: found.damage=maxf(found.damage,damage_per_second); found.left=duration
 e.burns.sort_custom(func(a,b): return a.damage>b.damage)
 if e.burns.size()>2: e.burns.resize(2)

func _friendly_update(dt: float) -> void:
 for attack in _friendly_pending:
  attack.delay-=dt
  if attack.delay>0: continue
  for e in _nearby(attack.p,attack.r):
   hit_enemy(e,attack.damage,0,{"origin":"skill","source":attack.source,"proc":false})
   if float(attack.get("knockback",0))>0 and not e.boss:
    var dir=(Vector2(e.p)-Vector2(attack.p)).normalized()
    if dir==Vector2.ZERO: dir=last_dir
    e.p=_clamp_world(Vector2(e.p)+dir*float(attack.knockback))
  effects.append({"kind":"explosion","p":attack.p,"r":attack.r,"life":0.25})
 _friendly_pending=_friendly_pending.filter(func(a): return a.delay>0)

func spawn_enemy(kind: String, position: Vector2=Vector2.INF, warning: float=0.8, defer_if_full: bool=true) -> Dictionary:
 var cap=clampi(int(run.get("pressure_count",65)),1,65) if run.get("mode","")=="pressure" else (16 if is_boss_wave() else 35)
 if enemies.filter(func(e): return e.hp>0).size()>=cap:
  if defer_if_full and _pending_spawns.size()<65: _pending_spawns.append({"kind":kind,"p":position,"warning":warning})
  return {}
 if not ENEMY_BASE.has(kind): return {}
 if position==Vector2.INF: position=_spawn_position()
 if warning>0 and kind not in ["cocoon","boss"] and position.distance_to(p)<240:
  position=_spawn_position()
 var base: Dictionary=ENEMY_BASE[kind]
 _uid+=1
 var e={"uid":_uid,"kind":kind,"p":position,"hp":float(base.hp),"max_hp":float(base.hp),"armor":float(base.armor),"speed":float(base.speed),"r":float(base.r),"damage":float(base.damage),"boss":kind=="boss","heavy":kind in ["roach","boss"],"elite":false,"phase":1,"warning":warning,"cast":0.0,"cast_kind":"","angle":0.0,"mechanism":kind in ["cocoon","node"],"slow":0.0,"slow_left":0.0,"stun":0.0,"control_until":-100.0,"cd":1.5,"summon":10.0,"special":8.0,"phase_lock":0.0,"phase_queue":[],"flash":0.0,"burns":[],"batches":0,"cocoon_left":8.0,"pressure":0,"beam_after":0.0}
 enemies.append(e)
 return e

func _drain_spawns() -> void:
 if is_boss_wave() and elapsed>=120.0: _pending_spawns.clear(); return
 if _pending_spawns.is_empty(): return
 var pending: Dictionary=_pending_spawns[0]
 var result=spawn_enemy(pending.kind,pending.p,pending.warning,false)
 if not result.is_empty(): _pending_spawns.pop_front()

func _spawn_position() -> Vector2:
 var result=Vector2.ZERO
 for attempt in range(30):
  match _rng.randi_range(0,3):
   0: result=Vector2(_rng.randf_range(80,1720),65)
   1: result=Vector2(1735,_rng.randf_range(80,1120))
   2: result=Vector2(_rng.randf_range(80,1720),1135)
   _: result=Vector2(65,_rng.randf_range(80,1120))
  if result.distance_to(p)>=240: return result
 return Vector2(1800-p.x,1200-p.y).clamp(Vector2(65,65),Vector2(1735,1135))

func _spawn_update(dt: float) -> void:
 if is_boss_wave(): return
 var pressure=run.get("mode","")=="pressure"
 var settings: Dictionary=run.get("pressure",{})
 var budget=1000000 if pressure else 60
 if _spawned>=budget or (not pressure and elapsed>=35): return
 _spawn_timer-=dt
 if _spawn_timer>0: return
 var interval=clampf(float(settings.get("interval",0.55)),0.15,3.0) if pressure else 35.0/60.0
 _spawn_timer=interval
 var kind="runner"
 if pressure:
  var mix: Array=settings.get("mix",["runner","roach","hydra","baneling","lurker","infestor"])
  if not mix.is_empty(): kind=str(mix[_rng.randi_range(0,mix.size()-1)])
 else:
  var wave=int(run.get("wave",1))
  var roll=_rng.randf()
  if wave>=3 and roll<0.18: kind="hydra"
  elif wave>=2 and roll<0.36: kind="roach"
 var limits={"baneling":4,"lurker":2,"infestor":2,"node":1}
 if limits.has(kind):
  var count=0
  for e in enemies:
   if e.kind==kind and e.hp>0: count+=1
  if count>=int(limits[kind]): kind="runner"
 var e=spawn_enemy(kind,Vector2.INF,0.8,false)
 if not e.is_empty(): _spawned+=1
 else: _spawn_timer=0.25

func _enemy_update(dt: float) -> void:
 # Snapshot prevents summons during iteration from receiving two updates.
 for e in enemies.duplicate():
  if e.hp<=0: continue
  e.flash=maxf(0,float(e.flash)-dt)
  if e.warning>0: e.warning=maxf(0,float(e.warning)-dt); continue
  e.slow=0.0; e.slow_left=0.0
  for slow in e.get("slows",[]):
   slow.left-=dt
   if slow.left>0: e.slow=maxf(float(e.slow),float(slow.ratio)); e.slow_left=maxf(float(e.slow_left),float(slow.left))
  e.slows=e.get("slows",[]).filter(func(s): return s.left>0)
  e.stun=maxf(0,float(e.stun)-dt)
  for burn in e.burns:
   burn.left-=dt; burn.tick-=dt
   if burn.tick<=0:
    burn.tick+=0.5; hit_enemy(e,float(burn.damage)*0.5,0,{"origin":"burn","source":burn.source,"proc":false})
  e.burns=e.burns.filter(func(b): return b.left>0)
  if e.hp<=0 or e.stun>0: continue
  if e.boss: _boss_update(e,dt); continue
  if e.kind=="cocoon":
   e.cocoon_left-=dt
   if e.cocoon_left<=0:
    for i in range(3): spawn_enemy("baneling",Vector2(e.p)+Vector2.from_angle(float(i)*TAU/3)*48,0.8)
    e.hp=0; _events.append({"type":"notice","text":"增援到达"})
   continue
  e.cd-=dt
  if e.cast>0:
   e.cast-=dt
   if e.cast<=0: _complete_enemy_cast(e)
   continue
  if e.kind=="baneling" and e.cast_kind=="baneling": continue
  var goal=p
  var victim: Dictionary={}
  for d in devices:
   if d.hp>0 and Vector2(e.p).distance_to(d.p)<80.0:
    victim=d; goal=d.p; break
  var dir=(goal-Vector2(e.p)).normalized()
  e.angle=dir.angle()
  var distance=Vector2(e.p).distance_to(goal)
  var stop=PLAYER_RADIUS+float(e.r)
  if e.kind=="hydra": stop=380.0
  elif e.kind=="roach": stop=140.0
  elif e.kind in ["lurker","infestor"]: stop=300.0
  if distance>stop:
   # Light local separation prevents collapsing all silhouettes into one point.
   var push=Vector2.ZERO
   for other in enemies:
    if other.uid==e.uid or other.hp<=0: continue
    var delta: Vector2=e.p-other.p
    var length=delta.length()
    var minimum=float(e.r)+float(other.r)
    if length>0.1 and length<minimum: push+=delta/length*(1.0-length/minimum)*50.0
   e.p=_clamp_world(Vector2(e.p)+(dir*float(e.speed)*(1.0-float(e.slow))+push)*dt)
  match str(e.kind):
   "runner":
    if distance<PLAYER_RADIUS+float(e.r)+4 and e.cd<=0:
     if victim.is_empty(): hurt(e.damage,"跳虫接触")
     else: hurt_device(victim,e.damage)
     e.cd=1.0
   "roach":
    if distance<=160.0 and e.cd<=0:
     e.cast=0.6; e.cast_kind="roach"; e.cast_p=goal; e.victim=int(victim.get("uid",-1)); e.cd=1.6
   "hydra":
    if distance<=550.0 and e.cd<=0 and _visible(e.p):
     e.cast=0.7; e.cast_kind="acid"; e.cast_p=goal; e.cd=2.0
   "baneling":
    if distance<=60 and e.cd<=0:
     e.cast=0.8; e.cast_kind="baneling"; e.cast_p=Vector2(e.p); e.cd=100
     add_hazard({"kind":"circle","p":Vector2(e.p),"r":90.0,"warning":0.8,"life":0.1,"damage":20.0,"source":"毒爆虫","owner":int(e.uid),"priority":2})
   "lurker":
    if e.cd<=0 and _visible(e.p):
     e.cast=0.9; e.cast_kind="lurker"; e.cd=4.0
     add_hazard({"kind":"line","p":Vector2(e.p),"angle":dir.angle(),"length":600.0,"width":38.0,"warning":0.9,"life":0.12,"damage":18.0,"source":"潜伏者穿刺","priority":2})
   "infestor":
    if e.cd<=0 and _visible(e.p):
     e.cast=0.9; e.cast_kind="infestor"; e.cd=7.0
     add_hazard({"kind":"circle","p":_clamp_world(p+_move_input*stat("speed",215)*0.6),"r":120.0,"warning":0.9,"life":3.0,"damage":0.0,"slow":0.35,"source":"孢子减速","priority":1})
   "node":
    if e.cd<=0:
     if e.batches>=3: e.hp=0
     else:
      for n in range(3): spawn_enemy("runner",Vector2(e.p)+Vector2.from_angle(float(n)*TAU/3)*42.0,0.8)
      e.batches+=1; e.cd=4.0

func _visible(position: Vector2) -> bool:
 # UI may supply exact visible world Rect2; fallback is conservative 16:9 view.
 var view: Rect2=visible_world if visible_world.size.x>0 else Rect2(p-Vector2(960,540),Vector2(1920,1080))
 return view.has_point(position)

func _complete_enemy_cast(e: Dictionary) -> void:
 match str(e.cast_kind):
  "acid":
   if not _fire_acid(e.p,(Vector2(e.cast_p)-Vector2(e.p)).normalized(),float(e.damage),240.0): e.cast=0.1
  "roach":
   var victim_uid=int(e.get("victim",-1))
   if victim_uid<0:
    if p.distance_to(e.p)<=160: hurt(e.damage,"蟑螂酸击")
   else:
    for d in devices:
     if d.uid==victim_uid and Vector2(d.p).distance_to(e.p)<=160: hurt_device(d,e.damage)
  "baneling":
   # The owned warning hazard applies the one explosion, then removes its owner.
   pass

func _fire_acid(position: Vector2, direction: Vector2, damage: float, speed: float=240.0) -> bool:
 if projectiles.size()>=MAX_PROJECTILES: return false
 projectiles.append({"p":position,"v":direction*speed,"r":7.0,"damage":damage,"kind":"acid","life":6.0})
 return true

func _check_boss_phases(b: Dictionary) -> void:
 var ratio=float(b.hp)/float(b.max_hp)
 var thresholds=[0.70,0.35] if is_final_boss() else [0.50]
 for i in range(thresholds.size()):
  var phase=i+2
  if ratio<=thresholds[i] and int(b.phase)<phase and not phase in b.phase_queue: b.phase_queue.append(phase)
 if b.phase_lock<=0 and not b.phase_queue.is_empty(): _enter_phase(b,int(b.phase_queue.pop_front()))

func _enter_phase(b: Dictionary, phase: int) -> void:
 b.phase=phase; b.phase_lock=0.5; b.cast=0.0; b.cd=maxf(0.6,float(b.cd))
 _events.append({"type":"phase","phase":phase,"text":"阶段%d"%phase})
 if is_final_boss() and phase==2:
  for n in range(2):
   var pos=Vector2(700+400*n,410)
   var cocoon=spawn_enemy("cocoon",pos,0.0)
   if not cocoon.is_empty(): cocoon.cocoon_left=8.0
  _events.append({"type":"notice","text":"击破神经囊可减少增援"})
 if is_final_boss() and phase==3:
  # End old aimed hazards before starting the sole directional mechanism.
  projectiles.clear()
  hazards=hazards.filter(func(h): return bool(h.get("friendly",false)))
  b.beam_after=elapsed+1.0
  add_hazard({"kind":"edge","p":Vector2(900,600),"r":450.0,"warning":1.2,"life":100000.0,"damage":8.0,"source":"边缘菌毯","priority":1})

func _boss_update(b: Dictionary, dt: float) -> void:
 b.phase_lock=maxf(0,float(b.phase_lock)-dt)
 if b.phase_lock>0: return
 if not b.phase_queue.is_empty(): _enter_phase(b,int(b.phase_queue.pop_front())); return
 boss_pressure=clampi(int(floor((elapsed-90.0)/15.0)),0,3) if elapsed>=90 else 0
 b.pressure=boss_pressure
 var mult=1.0+0.10*boss_pressure
 b.cd-=dt; b.special-=dt; b.summon-=dt
 if is_final_boss() and int(b.phase)==3:
  b.angle=(p-Vector2(b.p)).angle()
  if elapsed>=float(b.beam_after):
   var angle=(p-Vector2(b.p)).angle()-PI/3.0
   add_hazard({"kind":"beam","p":Vector2(b.p),"angle":angle,"arc":deg_to_rad(120),"length":1800.0,"r":1800.0,"warning":1.2,"life":6.0,"damage":16.0*mult,"rotate":deg_to_rad(30),"source":"暴君旋转束","priority":0})
   b.beam_after=elapsed+19.2
  return
 var direction=(p-Vector2(b.p)).normalized()
 b.angle=direction.angle()
 if Vector2(b.p).distance_to(p)>240: b.p=_clamp_world(Vector2(b.p)+direction*float(b.speed)*dt)
 if b.cast>0:
  b.cast-=dt
  if b.cast<=0:
   if b.cast_kind=="boss_acid":
    if projectiles.size()+3>MAX_PROJECTILES: b.cast=0.1
    else:
     var aimed=(Vector2(b.cast_p)-Vector2(b.p)).angle()
     for offset in [-0.25,0.0,0.25]: _fire_acid(b.p,Vector2.from_angle(aimed+offset),10.0*mult,220.0)
     b.cd=maxf(float(b.cd),0.6)
  return
 if b.summon<=0 and elapsed<120.0 and not is_final_boss():
  var count=0
  for e in enemies:
   if not e.boss and e.hp>0: count+=1
  for n in range(mini(6,15-count)): spawn_enemy("runner",_spawn_position(),0.8)
  b.summon=10.0
 if b.special<=0:
  if not is_final_boss() and int(b.phase)>=2:
   add_hazard({"kind":"circle","p":p,"r":160.0,"warning":1.0,"life":0.1,"damage":16.0*mult,"source":"巢卫震波","priority":0})
   b.special=8.0; b.cd=maxf(float(b.cd),1.6); return
  elif is_final_boss():
   add_hazard({"kind":"circle","p":p,"r":110.0,"warning":0.9,"life":4.0,"damage":8.0*mult,"source":"acid_pool","priority":1})
   b.special=6.0; b.cd=maxf(float(b.cd),1.5); return
 if b.cd<=0:
  b.cast=1.0; b.cast_kind="boss_acid"; b.cast_p=p; b.cd=3.0

func deploy_device(kind: String, position: Vector2, hp: float, damage: float, rate: float, distance: float, lifetime: float, copy: bool=false) -> Dictionary:
 if devices.filter(func(d): return d.hp>0).size()>=MAX_DEVICES: return {}
 _uid+=1
 var health=hp*stat("device_hp",1.0)
 var d={"uid":_uid,"kind":kind,"p":position,"hp":health,"max_hp":health,"damage":damage,"rate":rate,"range":distance,"life":lifetime,"copy":copy,"born":elapsed,"cd":0.0,"since_hurt":100.0,"shields":[],"shield":0.0,"target":-1,"lock":0.0,"boost":0.0,"shots":0,"crits":0}
 devices.append(d)
 if not copy and kind in ["sentry","laser","turret"]:
  _deploy_count+=1
  if tech("T09") and _deploy_count%2==0 and float(_timers.get("T09",0))<=0:
   var exists=false
   for other in devices:
    if other.copy and other.hp>0: exists=true
   if not exists:
    var duplicate=deploy_device(kind,position+Vector2(35,0),hp,damage*0.5,rate,distance,6.0,true)
    if not duplicate.is_empty(): _timers.T09=10.0
 return d

func _nearest_device(position: Vector2=Vector2.INF) -> Dictionary:
 if position==Vector2.INF: position=p
 var best: Dictionary={}; var distance=INF
 for d in devices:
  if d.hp<=0: continue
  var next=Vector2(d.p).distance_to(position)
  if next<distance: best=d; distance=next
 return best

func hurt_device(d: Dictionary, amount: float) -> void:
 if d.is_empty() or d.hp<=0: return
 var remain=amount
 d.shields.sort_custom(func(a,b): return a.left<b.left)
 for layer in d.shields:
  var used=minf(remain,float(layer.amount)); layer.amount-=used; remain-=used
 d.hp=maxf(0,float(d.hp)-remain); d.since_hurt=0.0
 d.shield=0.0
 for layer in d.shields: d.shield+=layer.amount

func _device_update(dt: float) -> void:
 for d in devices:
  if d.hp<=0: continue
  if d.life>0:
   d.life-=dt
   if d.life<=0: d.hp=0; continue
  d.since_hurt+=dt; d.cd=maxf(0,float(d.cd)-dt); d.boost=maxf(0,float(d.boost)-dt)
  if tech("T10") and d.since_hurt>=4.0: d.hp=minf(float(d.max_hp),float(d.hp)+float(d.max_hp)*0.03*dt)
  if Vector2(d.p).distance_to(p)>600: continue
  var t=target(float(d.range),int(d.target),d.p)
  if t.is_empty(): d.lock=0.0; continue
  if int(t.uid)!=int(d.target): d.target=t.uid; d.lock=0.0
  d.lock+=dt
  if d.kind=="laser" and d.lock<1.0: continue
  if d.cd>0: continue
  var rate=float(d.rate)*stat("device_attack",1.0)*(1.25 if d.boost>0 else 1.0)
  d.cd=1.0/maxf(0.05,rate)
  var damage=float(d.damage)*stat("engineering",1.0)*stat("device_damage",1.0)
  var critical=_rng.randf()<0.05
  d.shots=int(d.get("shots",0))+1
  if critical: damage*=1.5; d.crits=int(d.get("crits",0))+1
  hit_enemy(t,damage,0,{"origin":"summon","source":"装置·"+str(d.kind),"crit":critical,"proc":false})
  effects.append({"kind":"shot","p":d.p,"to":t.p,"life":0.12,"weapon":"device"})

func _support_update(_dt: float) -> void:
 if support("S02") and float(_timers.get("S02",4.0))<=0:
  heal(3.0); _timers.S02=4.0
 elif support("S02") and not _timers.has("S02"): _timers.S02=4.0
 if support("S03") and point_defense_left>0 and float(_timers.get("S03",0))<=0:
  var nearest: Dictionary={}; var distance=130.0
  for shot in projectiles:
   var next=Vector2(shot.p).distance_to(p)
   if shot.kind=="acid" and next<=distance: nearest=shot; distance=next
  if not nearest.is_empty():
   effects.append({"kind":"shot","p":p+Vector2(24,-25),"to":nearest.p,"life":0.12,"weapon":"intercept"})
   projectiles.erase(nearest); point_defense_left-=1; _timers.S03=0.25
 if support("S04") and _mine_distance>=600 and float(_timers.get("S04",0))<=0:
  var count=0
  for h in hazards:
   if h.kind=="mine" and h.life>0: count+=1
  if count<3:
   _mine_distance-=600.0; _timers.S04=2.0
   add_hazard({"kind":"mine","p":p,"r":90.0,"warning":0.0,"life":15.0,"damage":60.0*stat("engineering"),"friendly":true,"source":"S04","priority":0})
  else: _mine_distance=minf(_mine_distance,600.0)
 if bool(_timers.get("T11_pending",0)) and float(_timers.get("T11",0))<=0: _trigger_pickup_boost()

func _trigger_pickup_boost() -> void:
 var nearest=_nearest_device()
 if not nearest.is_empty():
  nearest.boost=3.0; _timers.T11=5.0; _timers.T11_pending=0.0
  statistics["pickup_boosts"]=int(statistics.get("pickup_boosts",0))+1

func collect_value(value: int) -> void:
 # Currency remains in-wave escrow until settle_wave; restart cannot bank it.
 active_value+=maxi(0,value)
 if tech("T11"):
  var accumulated=int(_timers.get("pickup_value",0))+maxi(0,value)
  while accumulated>=20:
   accumulated-=20
   if float(_timers.get("T11",0))<=0: _trigger_pickup_boost()
   else: _timers.T11_pending=1.0
  _timers.pickup_value=float(accumulated)

func _pickup_update() -> void:
 for drop in drops:
  if Vector2(drop.p).distance_to(p)<=stat("pickup",100):
   collect_value(int(drop.value)); drop.value=0
 drops=drops.filter(func(d): return d.value>0)

func _drop_for_kill(e: Dictionary) -> void:
 if e.kind=="cocoon" or bool(e.get("controlled",false)) or _drop_value>=_drop_budget: return
 var value=mini(1,_drop_budget-_drop_value)
 if e.boss: value=_drop_budget-_drop_value
 _drop_value+=value
 var merged=false
 for drop in drops:
  if Vector2(drop.p).distance_to(e.p)<24:
   drop.value+=value; merged=true; break
 if not merged: drops.append({"p":Vector2(e.p),"value":value})

func _passives(dt: float) -> void:
 if str(run.get("class_id",""))=="C03" and since_hurt>=4.0: heal(2.0*dt)
 if item("I17")>0 and since_hurt>=4.0: heal(0.6*item("I17")*dt)

func _projectile_update(dt: float) -> void:
 for shot in projectiles:
  var old: Vector2=shot.p
  shot.p=Vector2(shot.p)+Vector2(shot.v)*dt; shot.life-=dt
  var hit_point=Geometry2D.get_closest_point_to_segment(p,old,shot.p)
  if hit_point.distance_to(p)<=PLAYER_RADIUS+float(shot.r):
   hurt(shot.damage,"刺蛇酸刺"); shot.life=0
  else:
   for d in devices:
    if d.hp>0 and Geometry2D.get_closest_point_to_segment(d.p,old,shot.p).distance_to(d.p)<=18+float(shot.r):
     hurt_device(d,shot.damage); shot.life=0; break
 projectiles=projectiles.filter(func(s): return s.life>0 and WORLD.grow(50).has_point(s.p))

func add_hazard(data: Dictionary) -> Dictionary:
 var h={"kind":"circle","p":Vector2.ZERO,"r":0.0,"angle":0.0,"arc":0.0,"length":0.0,"width":0.0,"warning":0.9,"life":0.1,"damage":0.0,"friendly":false,"priority":2,"tick":0.0,"rotate":0.0,"source":"危险区域","delay":0.0}
 h.merge(data,true)
 if not bool(h.friendly) and not safe_exit_exists(h):
  var deferred=false
  var lower=hazards.duplicate()
  lower.sort_custom(func(a,b): return int(a.priority)>int(b.priority))
  for old in lower:
   if not bool(old.friendly) and int(old.priority)>int(h.priority) and (old.warning>0 or old.delay>0):
    old.delay=float(old.delay)+0.5
    statistics.danger_delays+=1
    if safe_exit_exists(h): deferred=true; break
  if not deferred:
   h.delay=0.5
   statistics.danger_delays+=1
 hazards.append(h)
 return h

func hazard_contains(h: Dictionary, point: Vector2, margin: float=0.0, future: float=0.0) -> bool:
 if bool(h.get("friendly",false)) or float(h.get("delay",0))>future: return false
 var onset=float(h.get("delay",0))+float(h.get("warning",0))
 if onset>future: return false
 if float(h.get("life",0))+onset<future: return false
 var kind=str(h.kind)
 if kind=="edge": return point.distance_to(h.p)>float(h.r)-margin
 if kind=="line":
  var end=Vector2(h.p)+Vector2.from_angle(float(h.angle))*float(h.length)
  return Geometry2D.get_closest_point_to_segment(point,h.p,end).distance_to(point)<=float(h.width)*0.5+margin
 if kind=="beam":
  var delta=point-Vector2(h.p)
  if delta.length()>float(h.length)+margin: return false
  if delta.length()<margin: return true
  var start=float(h.angle)+float(h.get("rotate",0))*maxf(0,future-onset)
  var angle=fposmod(delta.angle()-start,TAU)
  var extra=asin(clampf(margin/maxf(1,delta.length()),0,1))
  return angle<=float(h.arc)+extra or angle>=TAU-extra
 return point.distance_to(h.p)<=float(h.r)+margin

func safe_exit_exists(extra: Dictionary={}) -> bool:
 # Check 32 reachable escape corridors, 120u wide and 180u long.
 # Samples advance with the player rather than requiring the vacated start of
 # a telegraphed circle to stay safe forever. No invisible damage is discarded.
 var all=hazards.duplicate()
 if not extra.is_empty(): all.append(extra)
 for n in range(32):
  var direction=Vector2.from_angle(float(n)*TAU/32)
  var normal=Vector2(-direction.y,direction.x)
  var safe=true
  for distance in [60.0,120.0,180.0]:
   var arrival=minf(1.0,distance/maxf(180.0,stat("speed",215)))
   for side in [-60.0,0.0,60.0]:
    var point=p+direction*distance+normal*side
    if not Rect2(14,14,1772,1172).has_point(point): safe=false; break
    for h in all:
     if bool(h.get("friendly",false)) or h.kind=="mine": continue
     if hazard_contains(h,point,PLAYER_RADIUS,arrival) or (distance==180.0 and hazard_contains(h,point,PLAYER_RADIUS,1.0)):
      safe=false; break
    if not safe: break
   if not safe: break
  if safe: return true
 return false

func _hazard_update(dt: float) -> void:
 # Resolve high-priority mechanics first. A delayed lower-priority warning remains visible.
 hazards.sort_custom(func(a,b): return int(a.priority)<int(b.priority))
 for h in hazards:
  if float(h.get("delay",0))>0:
   h.delay-=dt
   if h.delay<=0:
    var without=hazards.duplicate(); without.erase(h)
    var saved=hazards; hazards=without
    var safe=safe_exit_exists(h)
    hazards=saved
    if not safe: h.delay=0.5; statistics.danger_delays+=1
   continue
  if h.has("owner"):
   var owner=get_enemy(int(h.owner))
   if owner.is_empty(): h.life=0; continue
  if h.kind=="mine":
   h.life-=dt
   var near=_nearby(h.p,60.0)
   if not near.is_empty():
    for e in _nearby(h.p,h.r): hit_enemy(e,h.damage,0,{"origin":"summon","source":"S04","proc":false})
    effects.append({"kind":"explosion","p":h.p,"r":h.r,"life":0.2}); h.life=0
   continue
  if h.warning>0:
   h.warning=maxf(0,float(h.warning)-dt)
   continue
  if h.kind=="beam": h.angle+=float(h.rotate)*dt
  h.tick-=dt
  if h.tick>0: h.life-=dt; continue
  h.tick=0.5
  if h.friendly:
   for e in _nearby(h.p,h.r): hit_enemy(e,h.damage,0,{"origin":"secondary","source":h.source,"proc":false})
  elif hazard_contains(h,p,PLAYER_RADIUS): hurt(float(h.damage),str(h.source))
  if h.has("owner"):
   var owner=get_enemy(int(h.owner))
   if not owner.is_empty(): owner.hp=0
  if not h.friendly:
   for d in devices:
    if d.hp>0 and hazard_contains(h,d.p,16): hurt_device(d,float(h.damage))
  h.life-=dt
 hazards=hazards.filter(func(h): return h.life>0)

func _player_ground_slow() -> float:
 var ratio=0.0
 for h in hazards:
  if float(h.get("slow",0))>0 and hazard_contains(h,p): ratio=maxf(ratio,float(h.slow))
 return minf(ratio,0.5)

func _cleanup(dt: float) -> void:
 enemies=enemies.filter(func(e): return e.hp>0)
 # Dead fixed support remains a HUD status record, but not an attack-cap occupant.
 devices=devices.filter(func(d): return d.hp>0 or (d.kind in ["sentry","laser"] and not d.copy))
 for effect in effects: effect.life-=dt
 effects=effects.filter(func(e): return e.life>0)
 if effects.size()>120: effects=effects.slice(effects.size()-120)
 if get_enemy(mark_uid).is_empty(): mark_uid=-1; mark_left=0

func _finish_wave() -> void:
 finished=true
 # Settlement is safe: all remaining damage sources are removed before UI transition.
 enemies.clear(); projectiles.clear(); hazards.clear(); devices.clear(); _friendly_pending.clear(); _pending_spawns.clear()
 _events.append({"type":"wave_end","active_value":active_value,"elapsed":elapsed,"kills":_kill_count,"damage":total_damage})
