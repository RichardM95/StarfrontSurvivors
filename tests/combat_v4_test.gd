extends SceneTree
const C=preload("res://scripts/combat_v2.gd")
var g
var passed=0
var failed=0
func _initialize(): call_deferred("run")
func ck(ok:bool,label:String):
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; push_error("FAIL "+label)
func fresh(w=1):
 g.selected_class="marine"; g.start_run();g.wave=w;g.rng.seed=42
 g.enemies.clear();g.bullets.clear();g.acid.clear();g.hazards.clear()
 C.reset_wave(g);g.combat.spawn=999;g.hurt_timer=0;g.dodge=0
func target(p:Vector2):
 var e=C.spawn_enemy(g,"runner",p);e.warmup=0;e.hp=10000;e.max_hp=10000
 return e
func run():
 g=load("res://main.tscn").instantiate();root.add_child(g)
 g.set_process(false);g.test_mode=true;g.sound.muted=true
 await process_frame
 ck(C.DURATIONS.size()==30 and C.wave_name(30)=="母巢主宰·暴君体","30 named waves")
 for id in ["rifle","shotgun","flame","sniper","grenade","tesla","smg","cannon"]:
  for branch in ["","a","b"]:
   fresh()
   g.build.weapons=[{"id":id,"level":3,"branch":branch,"cooldown":0.0,"paid":0,"uid":1}]
   g._apply_stats();var e=target(g.player+Vector2(100,0))
   C.update_weapons(g,0.016)
   for n in range(100): C.update_bullets(g,0.016);C.update_hazards(g,0.016)
   ck(e.hp<10000,id+branch+" deals damage")
 for w in [10,20,30]:
  fresh(w);ck(g.enemies[0].hp=={10:2800,20:6500,30:18000}[w],"boss HP "+str(w))
 fresh(20)
 var boss=g.enemies[0];boss.warmup=0;boss.phase_time=5.99
 C.update_enemies(g,0.02)
 ck(boss.underground,"W20 burrows after6sec")
 var before=boss.hp;C.hit_enemy(g,boss,500,Vector2.ZERO,"rifle")
 ck(boss.hp==before,"underground immune")
 for n in range(160):C.update_enemies(g,0.016)
 var nests=g.enemies.filter(func(e):return e.kind=="nest")
 ck(not boss.underground and nests.size()==1 and nests[0].hp==300,"W20 resurfaces and leaves300HP nest")
 nests[0].warmup=0;nests[0].fire=0;C.update_enemies(g,0.016)
 ck(g.enemies.any(func(e):return e.kind=="baneling"),"persistent nest spawns baneling")
 fresh(30);boss=g.enemies[0];boss.warmup=0;boss.hp=12000
 C.update_enemies(g,0.016);boss.pulse=0;C.update_enemies(g,0.016)
 ck(boss.phase==2 and g.enemies.filter(func(e):return e.kind=="cocoon").size()==4,"W30 phase2 cocoons")
 boss.hp=5000;C.update_enemies(g,0.016);boss.pulse=0;C.update_enemies(g,0.016)
 ck(boss.phase==3 and g.hazards.any(func(h):return h.type=="laser"),"W30 phase3 laser")
 fresh();g.build.supports=["sentry","medic_drone","raven","spider_mine"];g._apply_stats()
 target(g.player+Vector2(200,0));g.hp=50;C.update_supports(g,4.01)
 ck(g.bullets.any(func(b):return b.kind=="turret"),"sentry fires independently")
 ck(g.hp==55,"medic heals5 per4sec")
 g.hp=10;C.update_supports(g,0.01);ck(g.hurt_timer>=3 and g.combat.med_shield_used,"medic emergency shield")
 g.hurt_timer=0;g.synergies={}
 for n in range(9):C.add_acid(g,g.player,Vector2.ZERO,1)
 C.update_acid(g,0.01)
 ck(g.combat.drone_charges==0 and g.acid.size()==0 and g.hp<10,"raven intercepts exactly8 before collision")
 g.player+=Vector2(801,0);C.update_supports(g,0.01)
 ck(g.hazards.any(func(h):return h.type=="mine"),"mine after800distance")
 fresh();g.synergies={"engineering":4};var hp=g.hp
 C.hurt_player(g,20);ck(g.hp==hp and g.combat.engineer_shield==10,"engineering absorbs30")
 g.hurt_timer=0;C.hurt_player(g,20);ck(g.hp==hp-10 and g.combat.eng_shield_cd>0,"engineering cooldown prevents invulnerability")
 for w in [12,15,22,27,28]:
  fresh(w);g.combat.elapsed=5;C.spawn_wave_events(g,0.1)
  ck(g.hazards.size()>0 or g.combat.shrink>0,"zone hazard "+str(w))
 fresh(16);C.spawn_wave_events(g,0.1);ck(g.enemies.any(func(e):return e.kind=="nest"),"W16 destroyable nest")
 fresh(1)
 var runner_only=true
 var spawn_total=0
 for n in range(100):
  g.enemies.clear();g.combat.spawn=0
  C.spawn_wave_events(g,0.016)
  spawn_total+=g.enemies.size()
  for e in g.enemies:
   if e.kind!="runner":runner_only=false
 ck(runner_only and spawn_total>=100,"W1 at least100 spawns runner-only")
 fresh(1)
 g.enemies.clear()
 var cooldown_valid=true
 for n in range(120):
  C.update_weapons(g,0.016)
  for w in g.weapons:
   if float(w.cooldown)<0:cooldown_valid=false
 ck(cooldown_valid,"idle weapon cooldown always nonnegative for saves")
 print("V4 COMBAT PASSED ",passed," FAILED ",failed)
 quit(0 if failed==0 else 1)
