extends SceneTree
const Combat=preload("res://scripts/combat_v2.gd")
const Build=preload("res://scripts/build_v2.gd")
var g
var passed=0
var failed=0
func _initialize():
 call_deferred("run")
func ck(ok:bool,label:String):
 if not ok:
  push_error("FAIL "+label)
  failed+=1
  return
 passed+=1
 print("PASS "+label)
func fresh(cls="marine"):
 g.selected_class=cls
 g.start_run()
 g.rng.seed=123456
 g.enemies.clear();g.bullets.clear();g.acid.clear();g.hazards.clear()
 g.combat.spawn=999
 g.hurt_timer=0
func target(kind="runner",pos=Vector2(800,440)):
 var e=Combat.spawn_enemy(g,kind,pos)
 e.warmup=0
 return e
func run():
 g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false);g.test_mode=true;g.sound.muted=true
 await process_frame
 fresh()
 for id in ["rifle","shotgun","flame","reaper","sniper"]:
  for branch in ["","a","b"]:
   fresh()
   g.build.weapons=[{"id":id,"level":3,"branch":branch,"cooldown":0.0,"paid":0,"uid":1}]
   g._apply_stats()
   target()
   Combat.update_weapons(g,0.1)
   ck(g.bullets.size()>0,id+branch+" fires")
   for n in range(50): Combat.update_bullets(g,0.016)
   Combat.cleanup(g)
 fresh()
 var enemy=target()
 g.armor=50;Combat.hurt_player(g,20)
 ck(is_equal_approx(g.hp,90.0),"Armor50 halves damage")
 g.hurt_timer=0;g.dash_timer=0.2;Combat.hurt_player(g,20)
 ck(is_equal_approx(g.hp,90.0),"dash avoids damage")
 fresh("reaper")
 Combat.dash_effect(g)
 ck(g.hazards.size()==1 and g.hazards[0].friendly,"Reaper drops mine")
 fresh("ghost")
 g.kills=29
 enemy=target();var other=target("spitter",Vector2(200,200))
 Combat.add_acid(g,Vector2(100,100),Vector2.ONE,3)
 Combat.kill_enemy(g,enemy)
 ck(g.acid.is_empty() and other.stun>=1.5,"Ghost EMP")
 fresh("firebat")
 enemy=target()
 Combat.hit_enemy(g,enemy,10,Vector2.RIGHT,"flame",{"base":10.0})
 ck(enemy.burn>0 and enemy.burn_dmg==2.0,"Firebat burn")
 fresh()
 enemy=target("baneling",g.player+Vector2(30,0))
 Combat.update_enemies(g,0.016)
 ck(enemy.fuse>0,"Baneling arms")
 Combat.update_enemies(g,0.4)
 ck(g.hazards.size()>0,"Baneling explosion")
 fresh()
 enemy=target("lurker",g.player+Vector2(300,0))
 for n in range(80): Combat.update_enemies(g,0.016)
 ck(g.hazards.size()>0 and g.hazards[0].type=="line","Lurker telegraph")
 fresh()
 g.wave=30;g.enemies.clear();Combat.reset_wave(g)
 ck(g.enemies.size()==1 and g.enemies[0].kind=="boss","Boss spawn")
 enemy=g.enemies[0];enemy.warmup=0
 enemy.hp=enemy.max_hp*0.65
 Combat.update_enemies(g,0.1)
 ck(enemy.phase==2,"Boss phase2")
 enemy.pulse=0;Combat.update_enemies(g,0.1)
 ck(g.enemies.filter(func(e):return e.kind=="cocoon").size()==4,"Boss four cocoons")
 enemy.hp=enemy.max_hp*0.3;Combat.update_enemies(g,0.1)
 enemy.pulse=0;Combat.update_enemies(g,0.1)
 ck(g.hazards.any(func(h):return h.type=="laser"),"Boss laser")
 enemy.phase_time=16;Combat.update_enemies(g,0.1)
 ck(g.combat.shrink==60.0,"Boss arena shrink")
 fresh()
 g.wave=3;g.combat.event=0;Combat.spawn_wave_events(g,0.1)
 ck(g.hazards.size()==3,"Wave3 acid rain")
 fresh()
 g.wave=5;g.combat.elapsed=15;Combat.spawn_wave_events(g,0.1)
 ck(g.hazards.is_empty(),"Wave5 sandstorm replaces ambush")
 fresh()
 for n in range(150): target()
 ck(g.enemies.size()==130,"Enemy budget")
 # Regression: sniper backline priority and actual multi-target penetration.
 fresh()
 var front=target("runner",g.player+Vector2(90,0))
 var rear=target("spitter",g.player+Vector2(250,60))
 ck(Combat.sniper_target(g,750)==rear,"Sniper prioritizes ranged backline")
 rear.warmup=1
 ck(Combat.sniper_target(g,750)==front,"Sniper ignores warmup backline")
 fresh()
 g.crit_rate=0;g.synergies={}
 var first=target("runner",g.player+Vector2(110,0))
 var second=target("runner",g.player+Vector2(190,0))
 first.hp=1000;second.hp=1000
 Combat.fire_bullet(g,0,800,100,1,Color.WHITE,999,"sniper",{"branch":"pierce"})
 Combat.update_bullets(g,0.25)
 ck(first.hp<1000 and second.hp<1000,"Piercing bullet hits front and rear")
 ck(first.hp<second.hp,"Piercing decay follows physical hit order")
 fresh()
 g.hurt_timer=2;g.dash_timer=1;g.dodge=1;g.hurt_extra=4;g.armor=100
 var health=g.hp
 Combat.hurt_player(g,10,true,true)
 ck(is_equal_approx(g.hp,health-10) and g.hurt_timer==2,"Zone exact damage bypasses invulnerability without resetting it")
 g.revive=1;g.hp=5
 Combat.hurt_player(g,10,true,true)
 ck(g.hp==1 and g.build.revive_used,"Zone damage preserves revive")
 Combat.hurt_player(g,10,true,true)
 ck(g.state=="dead","Zone damage preserves final death")
 fresh()
 g.turret=1
 var deployed=g.combat.turret_p
 g.player+=Vector2(200,0)
 target("runner",deployed+Vector2(100,0))
 Combat.update(g,0.01)
 var turret_shots=g.bullets.filter(func(b):return b.kind=="turret")
 ck(not turret_shots.is_empty() and turret_shots[0].origin==deployed,"Turret fires from fixed deployment")
 # Integrated full update across each class, enemies and phases.
 for cls in ["marine","marauder","reaper","firebat","ghost"]:
  fresh(cls)
  g.hp=100000;g.max_hp=100000
  g.wave=9
  g.combat.spawn=0.1
  for n in range(1200):
   g.hurt_timer=maxf(0,g.hurt_timer-0.016)
   Combat.update(g,0.016)
  ck(g.telemetry.shots>0,"runtime "+cls)
 print("COMBAT TESTS PASSED ",passed)
 quit(0 if failed==0 else 1)
