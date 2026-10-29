extends SceneTree
const Combat=preload("res://scripts/combat_v5.gd")
const Build=preload("res://scripts/build_v5.gd")
var checks=0
var failed=0
func check(value:bool,name:String):
 checks+=1
 if not value:
  failed+=1;printerr("FAIL ",name)
func equal(a:float,b:float,name:String,epsilon:float=0.001): check(absf(a-b)<epsilon,name+" [%s vs %s]"%[a,b])
func sim(cls:String="C01"):
 var c=Combat.new(); var r=Build.new_run(cls,123,"pressure");r.pressure_seconds=10000;c.initialize(r); c._spawn_timer=100000
 return c
func dummy(c,pos:Vector2=Vector2(1100,600),kind:String="roach"):
 var e=c.spawn_enemy(kind,pos,0); e.hp=100000.0;e.max_hp=100000.0;e.speed=0;e.cd=10000
 return e
func _initialize():
 contact_test(); armor_shields(); mark_controls(); inputs(); devices(); triggers(); weapons(); hazards_test(); bosses(); reference_contract_loops(); calibration(); loadout_diagnostics(); pressure_loop()
 print("V5_COMBAT checks=",checks," failed=",failed)
 quit(1 if failed else 0)
func armor_shields():
 equal(Combat.mitigation(150),0.25,"armor150cap")
 equal(Combat.mitigation(999,0.9),0.175,"tempDR30cap")
 equal(Combat.mitigation(-5),1.0,"negativearmorclamped")
 var c=sim(); c.grant_shield("matrix",20);c.grant_shield("matrix",15)
 equal(c.shield,20,"same shield max notadd")
 c.grant_shield("other",100)
 equal(c.shield,50,"shield halfHPcap")
 c.hurt(30,"external");equal(c.shield,20,"shieldfirst");equal(c.run.hp,100,"HPuntouched")
 c.hurt(50,"external");equal(c.shield,20,"iframeprevent")
 c.iframe=0;c.hurt(25,"external");equal(c.run.hp,95,"overflowHP")
 c._tick_shields(3.1);equal(c.shield,0,"expiry")
 c.run.items={"I14":1};c._cached_stats=Build.stats(c.run);c.run.hp=5;c.iframe=0
 c.hurt(100,"external");check(c.run.rescue_spent,"sharedrescueconsumed");equal(c.run.hp,1,"rescueHP1");equal(c.iframe,0,"rescuenoinvuln")
 c.hurt(100,"external");equal(c.run.hp,0,"rescuecannotrepeat")
 c=sim();c.run.items={"I14":1};c.run.hp=1;c.grant_shield("matrix",20)
 c.hurt(100,"cost",0,0,true)
 equal(c.run.hp,1,"costneverkill");equal(c.shield,20,"costdoesnotspendshield");check(not c.run.rescue_spent,"costnorescue");equal(c.iframe,0,"costnoiframe")
 c.run.hp=1;c.shields=[];c.shield=0;c.run.items={};c.hurt(2,"external");c.heal(20);equal(c.run.hp,0,"lethalnotrevivedbysameframeheal")
func mark_controls():
 var c=sim();var near=dummy(c,Vector2(950,600));var far=dummy(c,Vector2(1200,600));far.mechanism=true
 check(c.target(400).uid==far.uid,"dangerbeforeclosest")
 c.request_mark(near.uid);check(c.target(400).uid==near.uid,"markbeforemechanism")
 c.request_mark(near.uid);check(c.mark_uid==-1,"retaptoggle")
 c.request_mark(far.uid);check(c.target(100).uid==near.uid,"markoutofrangenotlockguns")
 c.hit_enemy(far,1000000);check(c.mark_uid==-1,"markclearbydeath")
 near.elite=true;c.apply_slow(near,0.8,1);equal(near.slow,0.4,"eliteslowhalf")
 c.apply_control(near,10);equal(near.stun,0.3,"elitestunlimit");check(not c.apply_control(near,1),"controlrefractory")
 var boss=dummy(c,Vector2(1500,600),"boss");c.apply_slow(boss,0.5,3);equal(boss.slow,0.15,"bossslowcap")
 check(not c.apply_control(boss,1,Vector2(50,0)),"bossimmuneCC")
 var slow_target=dummy(c,Vector2(1200,800),"runner")
 c.apply_slow(slow_target,0.5,0.1);c.apply_slow(slow_target,0.2,2)
 c._enemy_update(0.2);equal(slow_target.slow,0.2,"slow_layers_independent_expiry")
 equal(c.delay_cast(boss,1),0.3,"EMPboss03");equal(c.delay_cast(boss,1),0,"EMPboss10s")
func inputs():
 var c=sim("C03");var hp=c.run.hp
 check(not c.skill_preview().ok,"KD8notarget")
 c.step(0.01,Vector2.ZERO,{"skill":true});equal(c.skill_cd,0,"notargetnocooldown")
 var t=dummy(c,Vector2(950,500));c.run.weapons=[]
 c.step(0.01,Vector2.ZERO,{})
 equal(c.skill_cd,0,"previewcancelnoeffect")
 var start=c.p
 c.step(0.1,Vector2.RIGHT,{"dash":true,"skill":true})
 equal(c.skill_cd,0,"skillwaitsdash")
 c.step(0.1,Vector2.RIGHT,{})
 equal(c.p.x,start.x+180,"dash180")
 check(c.elapsed>=c._dash_at+0.15,"dash_end_no_invulnerability_tail")
 check(c.skill_cd>7.9,"skillcastendpoint")
 check(c._friendly_pending.size()==1,"KD8scheduledonce")
 equal(c._friendly_pending[0].delay,0.7,"KD8warningaftercast")
 c=sim();c.run.weapons=[];c.run.hp=50;c.step(0.01,Vector2.ZERO,{"skill":true})
 equal(c.run.hp,44,"stim12current");equal(c.stim_left,5,"stim5sec")
 c._skill_at=c.elapsed;c.skill_cd=0.2
 c.reduce_cooldowns(5);equal(c.skill_cd,1.0,"cannotreadybefore1sec");equal(c.reduce_cooldowns(5),0,"CDreducebudget")
 c=sim();c.run.weapons=[];c.stim_left=5;c._timers.dash_slow=1;start=c.p;c.step(0.1,Vector2.RIGHT)
 equal(c.p.x-start.x,215*1.05*0.1,"stim_and_postdash_speed_additive")
func devices():
 var c=sim("C06");c.run.weapons=[];c.run.techs=["T09","T10","T12"];c._cached_stats=Build.stats(c.run)
 c.step(0.01,Vector2.ZERO,{"skill":true});equal(c.shield,15,"T12skillshield")
 c.skill_cd=0;c.step(0.01,Vector2.ZERO,{"skill":true})
 check(c.devices.size()==3,"secondturretcopy")
 var copies=0
 for d in c.devices:
  if d.copy:copies+=1
 check(copies==1,"singlecopy")
 c.run.hp=70;c.skill_cd=0;c.step(0.01,Vector2.ZERO,{"skill":true})
 check(c.devices.size()==3,"thirdreplacesoldest");equal(c.run.hp,73,"T10recycleheal")
 for i in range(20):c.deploy_device("sentry",c.p,80,12,3,400,100)
 check(c.devices.size()==8,"friendly8cap")
 var d=c.devices[0];d.hp=10;d.since_hurt=4;c._device_update(1)
 check(d.hp>10,"T10regen")
 d.p=c.p+Vector2(700,0);dummy(c,d.p+Vector2(10,0));var before=c.total_damage;c._device_update(0.5)
 # Other devices may attack; inspect distant device cooldown remains ready.
 d.cd=0;c._device_update(0.01);equal(d.cd,0,"device600stop")
 c=sim("C06");c.run.weapons=[];c.run.supports=["S03","S04"];c.point_defense_left=8
 for i in range(12):c._fire_acid(c.p+Vector2(80,0),Vector2.RIGHT,8)
 for i in range(40):c._support_update(0.1);c._timers.S03=maxf(0,float(c._timers.get("S03",0))-0.1)
 check(c.point_defense_left==0,"S03exact8");check(c.projectiles.size()==4,"S03doesnotclearall")
 c._mine_distance=600;c._support_update(0.1)
 check(c.hazards.size()==1 and c.hazards[0].kind=="mine","S04after600")
 var expired=sim("C06");expired.run.weapons=[];expired.deploy_device("turret",expired.p,60,10,3,350,0.01)
 expired._device_update(0.02);expired._cleanup(0)
 check(expired.devices.is_empty(),"expired_class_turret_not_retained_as_fixed_support")
 expired.deploy_device("sentry",expired.p,80,12,3,400,-1);expired.devices[0].hp=0;expired._cleanup(0)
 check(expired.devices.size()==1 and expired.devices[0].hp==0,"dead_fixed_support_retained_for_HUD")
func triggers():
 var c=sim();c.run.techs=["T18","T04"];c.run.items={"I08":1};var e=dummy(c)
 for second in range(60):
  c.elapsed=float(second)+0.05
  for i in range(12):c.queue_secondary("I08",e.p,0,1,{"target":e.uid,"source":"I08"})
  for i in range(4):c.queue_secondary("T18",e.p,0,1,{"target":e.uid,"source":"T18"})
  c._flush_secondary()
  check(c._secondary_count==8,"8/sec_%d"%second)
 check(c._secondary_total==480,"60sec480events")
 check(c.statistics.secondary_dropped==480,"overflowdiscardnobacklog")
 var count=c._secondary_queue.size()
 check(not c.queue_secondary("T18",e.p,30,2,{"origin":"secondary"}),"nonrecursivequeue")
 check(c._secondary_queue.size()==count,"nonrecursiveunchanged")
 c.apply_burn(e,"a",10);c.apply_burn(e,"a",5);c.apply_burn(e,"b",20);c.apply_burn(e,"c",30)
 check(e.burns.size()==2,"strongest2burns");check(e.burns[0].damage==30 and e.burns[1].damage==20,"burnnoadd")
 var results=[]
 for pieces in [1,10,50]:
  var s=sim("C06");s.run.techs=["T11"];s.deploy_device("turret",s.p,60,10,3,350,12)
  for i in range(pieces):s.collect_value(100/pieces)
  results.append([s.active_value,s.statistics.get("pickup_boosts",0),s._timers.get("T11_pending",0),s._timers.get("pickup_value",0)])
 check(results[0]==results[1] and results[1]==results[2],"1_10_50valuefair")
func weapons():
 for id in ["W01","W02","W03","W05","W06","W07"]:
  for branch in ["A","B"]:
   var c=sim("C01");c.run.weapons=[{"id":id,"level":3,"branch":branch,"uid":1,"invested":0}]
   c.run.techs=["T05","T08"] if id in ["W03","W06"] else []
   var e=dummy(c);e.armor=0
   for n in range(100):c.step(0.1,Vector2.ZERO)
   check(c.total_damage>0,id+branch+"fires")
   check(c._secondary_count<=8,id+branch+"budget")
 var c=sim();c.run.weapons=[{"id":"W03","level":1,"branch":"","uid":1,"invested":0}];c.run.bonuses={"damage":100.0};c._cached_stats=Build.stats(c.run)
 for i in range(25):dummy(c,Vector2(1000,600)+Vector2(i%5,i/5))
 c._weapon_update(0.01)
 var touched=0
 for e in c.enemies:
  if e.hp<100000:touched+=1
 check(touched==20,"AOEexact20max")
 c=sim();c.run.weapons=[{"id":"W01","level":3,"branch":"B","uid":1,"invested":0}];c.stim_left=5
 dummy(c);c._weapon_update(0.01);equal(c._shots["1"].cd,1.0/(4*1.9),"C01_W01B_stim_AS_additive")
 c.run.bonuses={"attack":10.0};c._cached_stats=Build.stats(c.run);c._shots["1"].cd=0;c._weapon_update(0.01)
 equal(c._shots["1"].cd,0.1,"AS_max2_5_after_branch_stim")
func hazards_test():
 var c=sim();c.run.weapons=[]
 var h=c.add_hazard({"p":c.p,"r":160.0,"warning":1.0,"life":0.1,"damage":16,"priority":0})
 equal(h.delay,0,"normalcircleescapable")
 for n in range(12):c._hazard_update(0.1)
 equal(c.run.hp,84,"one_shot_damage_not_expired_beforehit")
 var future={"kind":"circle","p":c.p,"r":50,"delay":0.5,"warning":0.9,"life":1.0,"friendly":false}
 check(not c.hazard_contains(future,c.p,0,1.0),"delayonsetadded")
 check(c.hazard_contains(future,c.p,0,1.5),"delayedactive")
 c=sim();var owner=dummy(c,c.p,"baneling")
 c.add_hazard({"p":c.p,"r":90,"warning":0.8,"life":0.1,"damage":20,"owner":owner.uid})
 c.hit_enemy(owner,1000000)
 for n in range(10):c._hazard_update(0.1)
 equal(c.run.hp,100,"killedbanelingcancels")
func bosses():
 var r=Build.new_run("C01",44,"boss");r.wave=12;var c=Combat.new();c.initialize(r)
 var b=c.enemies[0];b.warning=0
 c.hit_enemy(b,2100,25,{"origin":"weapon","source":"test"})
 check(b.phase==2,"W12phase70")
 var cocoons=0
 for e in c.enemies:
  if e.kind=="cocoon":cocoons+=1
 check(cocoons==2,"two100HPcocoons")
 b.phase_lock=0;c.hit_enemy(b,1500,25,{"origin":"weapon","source":"test"})
 check(b.phase==3,"W12phase35")
 b.phase_lock=0;b.beam_after=0;c._boss_update(b,0.01)
 var beam:Dictionary={}
 for h in c.hazards:
  if h.kind=="beam":beam=h
 check(not beam.is_empty(),"beamcreated")
 if not beam.is_empty():equal(beam.warning,1.2,"beamwarning");equal(beam.arc,deg_to_rad(120),"beam120deg")
 c.elapsed=91;c._boss_update(b,0.01);check(c.boss_pressure==0,"pressure90_window_before_increment")
 c.elapsed=105;c._boss_update(b,0.01);check(c.boss_pressure==1,"pressure_first15seconds")
 c.elapsed=150;c._boss_update(b,0.01);check(c.boss_pressure==3,"pressurecap30")
 check(not c.finished,"bossnotautowinbytime")
func pressure_loop():
 var c=sim("C06");c.run.pressure_count=65;c.run.pressure_seconds=60;c.run.weapons=[];c.run.hp=100000
 c._spawn_timer=0
 # Deliberately invulnerable workload probe, not balance/performance acceptance.
 for i in range(600):
  c.iframe=1;c.step(0.1,Vector2.from_angle(i*0.04))
 check(c.statistics.peak_enemies<=65,"pressureenemycap")
 check(c.statistics.peak_projectiles<=300,"projectilecap")
 check(c.statistics.peak_devices<=8,"devicecap")
 check(c.finished,"pressureterminal")
 var cap=sim()
 for i in range(310):cap._fire_acid(cap.p,Vector2.RIGHT,1)
 check(cap.projectiles.size()==300,"projectile300_exact_cap")
 check(not cap._fire_acid(cap.p,Vector2.RIGHT,1),"projectile_overflow_must_retry")
 for i in range(70):cap.spawn_enemy("runner",Vector2(100,100),0)
 check(cap.enemies.size()==65 and cap._pending_spawns.size()==5,"enemy_overflow_deferred")
 cap.enemies[0].hp=0;cap._cleanup(0);cap._drain_spawns()
 check(cap.enemies.size()==65 and cap._pending_spawns.size()==4,"deferred_enemy_eventually_spawn")
 cap.step(0.01,Vector2.ZERO)
 var packed=JSON.parse_string(JSON.stringify(cap.run))
 check(str(packed.combat_rng_state)==str(cap.run.combat_rng_state),"combat_RNG_int64_string_roundtrip")
 print("PRESSURE actual_peaks ",c.statistics," elapsed=",c.elapsed)

func contact_test():
 var c=sim();c.run.weapons=[]
 var e=c.spawn_enemy("runner",c.p+Vector2(100,0),0);e.cd=0
 for i in range(20):c.step(0.05,Vector2.ZERO)
 check(c.run.hp<=94,"runner_reaches_contact_range")
 var g=sim("C06");g.run.weapons=[];g.run.techs=["T11"];g.deploy_device("turret",g.p,60,10,3,350,100)
 g.collect_value(10)
 for i in range(10):g.step(0.1,Vector2.ZERO)
 g.collect_value(10);check(g.statistics.get("pickup_boosts",0)==1,"T11_value_survives_elapsed")
 g.collect_value(20)
 for i in range(51):g.step(0.1,Vector2.ZERO)
 check(g.statistics.get("pickup_boosts",0)==2,"T11_pending_survives5sec")

func reference_contract_loops():
 # Inactive content is a contract harness, not a claim of playable W10/W04 content.
 var c=sim();c.run.techs=["T18"];c.run.items={"I08":1}
 c.run.weapons=[{"id":"W10","level":1,"branch":"","uid":1,"invested":0}]
 for i in range(4):dummy(c,Vector2(1100,600)+Vector2(0,i*25))
 var max_events=0
 for i in range(600):
  c.iframe=1;c.step(0.1,Vector2.ZERO);max_events=maxi(max_events,c._secondary_count)
 check(c._secondary_total>0,"W10_T18_I08_actual_primary_to_secondary")
 check(max_events<=8,"W10_T18_I08_60sec_cap")
 check(c.statistics.recursive_blocked==0,"W10_events_never_request_recursion")
 var b=sim();b.run.weapons=[];b.run.techs=["T04"]
 for i in range(600):
  var e=b.spawn_enemy("runner",Vector2(1100,600),0)
  if not e.is_empty():
   b.apply_burn(e,"W04",100,3)
   e.cd=1000;e.speed=0
  b.iframe=1;b.step(0.1,Vector2.ZERO)
 check(b.statistics.kills>0,"burn60sec_kills")
 check(b._secondary_total==0,"burnkills_cannot_spawn_T04_ground")
 var q=sim();var e=dummy(q)
 q.run.techs=["T18"]
 for i in range(8):q.queue_secondary("I08",e.p,0,1,{"target":e.uid,"source":"item"})
 q.queue_secondary("T18",e.p,0,10,{"target":e.uid,"source":"tech"});q._flush_secondary()
 check(q.statistics.damage_by_source.has("tech"),"tech_slot_before_item_budget")
 check(q.statistics.secondary_dropped==1,"priority_overflow_dropped")

func calibration():
 # Isolated armor10 target, no movement/phase lock and no crit (I30 removes5pp).
 # Actual shot counts are compared to analytic rates, NOT tuned to60s boss TTK.
 var cases=[
  {"name":"C01_W01_Lv1","id":"W01","level":1,"branch":"","stim":false,"attack":0.0,"damage":0.0,"rate":4.4,"per":7.5},
  {"name":"C01_W01_Lv3A","id":"W01","level":3,"branch":"A","stim":false,"attack":0.0,"damage":0.0,"rate":4.4,"per":9.5625},
  {"name":"C01_W01_stim5s","id":"W01","level":1,"branch":"","stim":true,"attack":0.0,"damage":0.0,"rate":5.1,"per":7.5},
  {"name":"C01_globalAS24_damage18","id":"W01","level":1,"branch":"","stim":false,"attack":0.24,"damage":0.18,"rate":5.36,"per":8.85},
  {"name":"C01_W03_Lv1_AOE","id":"W03","level":1,"branch":"","stim":false,"attack":0.0,"damage":0.0,"rate":1.5,"per":25.0/1.2}
 ]
 for scenario in cases:
  var c=sim();c.run.items={"I30":1};c.run.weapons=[{"id":scenario.id,"level":scenario.level,"branch":scenario.branch,"uid":1,"invested":0}]
  c.run.bonuses={"attack":scenario.attack,"damage":scenario.damage};c._cached_stats=Build.stats(c.run)
  var boss=dummy(c,Vector2(1100,600),"boss");boss.armor=10;boss.max_hp=1000000000.0;boss.hp=boss.max_hp
  if scenario.id=="W03":
   for x in [1120,1130]:
    var neighbor=dummy(c,Vector2(x,600));neighbor.armor=10
  var before=float(boss.hp)
  var dt=1.0/2000.0
  for i in range(20000):
   c.elapsed=(i+1)*dt;c.stim_left=maxf(0,5-c.elapsed) if scenario.stim else 0
   c._weapon_update(dt)
  var shots=int(c._shots["1"].rounds);var actual=before-float(boss.hp)
  equal(actual,shots*float(scenario.per),scenario.name+"_no_double_damage",0.01)
  check(absf(shots-float(scenario.rate)*10)<=1.01,scenario.name+"_shot_rate")
  if scenario.id=="W03":equal(c.total_damage,actual*3,"AOE_each_target_once",0.02)
  print("DPS_CALIBRATION ",JSON.stringify({"name":scenario.name,"seconds":10,"shots":shots,"expected_rate":scenario.rate,"boss_damage":actual,"expected_per_shot":scenario.per,"actual_DPS":actual/10,"analytic_DPS":float(scenario.rate)*float(scenario.per)}))
 var eng=sim("C06");eng.run.weapons=[];var boss=dummy(eng,Vector2(1100,600),"boss");boss.armor=10;boss.max_hp=1000000000.0;boss.hp=boss.max_hp
 var turret=eng.deploy_device("turret",eng.p,60,10,3,350,12)
 var before=float(boss.hp)
 for i in range(20000):eng.elapsed=(i+1)/2000.0;eng._device_update(1.0/2000.0)
 var expected=(float(turret.shots)+0.5*float(turret.crits))*10*1.15/1.2
 equal(before-float(boss.hp),expected,"C06_turret_damage_inheritance",0.01)
 check(absf(turret.shots-30)<=1,"C06_turret_rate3")
 print("DPS_CALIBRATION ",JSON.stringify({"name":"C06_single_turret","seconds":10,"shots":turret.shots,"crits":turret.crits,"boss_damage":before-float(boss.hp),"expected_damage":expected,"analytic_noncrit_DPS":28.75}))

func loadout_diagnostics():
 for ci in range(3):
  var cls=["C01","C03","C06"][ci];var r=Build.new_run(cls,ci+1)
  for wave in range(1,5):
   r.wave=wave;var c=Combat.new();c.initialize(r)
   var setup={"class":cls,"seed":ci+1,"weapons":r.weapons.duplicate(true),"techs":r.techs.duplicate(),"items":r.items.duplicate(),"bonuses":r.bonuses.duplicate()}
   var complete=false
   for frame in range(5400):
    var radial=c.p-Vector2(900,600)
    var move=Vector2(-radial.y,radial.x).normalized()+radial.normalized()*(365.0-radial.length())/140.0
    for e in c.enemies:
     var delta=c.p-Vector2(e.p)
     if delta.length()<185 and delta.length()>0:move+=delta.normalized()*(185-delta.length())/55.0
    var events=c.step(1.0/30.0,move.normalized(),{"skill":c.skill_cd<=0 and (cls!="C01" or r.hp>40),"dash":c.dash_cd<=0 and frame%90==0})
    for event in events:
     if event.type=="wave_end":complete=true
    if c.finished:break
   if wave==4 or not complete:
    setup["wave"]=wave;setup["completed"]=complete;setup["seconds"]=c.elapsed;setup["boss_damage_by_source"]=c.statistics.boss_damage_by_source;setup["all_damage_by_source"]=c.statistics.damage_by_source
    print("FIXED_LOADOUT_DIAGNOSTIC ",JSON.stringify(setup))
   if not complete:break
   Build.settle_wave(r,c.active_value)
   while r.pending_levels>0:
    var choice=r.level_choices[0]
    if "damage" in r.level_choices:choice="damage"
    elif "health" in r.level_choices:choice="health"
    Build.choose_level(r,choice)
   if r.pending_research:
    Build.generate_research(r);Build.research(r,r.research_choices[0])
   var w=r.weapons[0]
   while w.level<3 and r.cash>=Build.upgrade_cost(r,w.uid):Build.upgrade(r,w.uid,"A")
   for index in range(r.shop.size()):
    var offer=r.shop[index]
    if offer.kind=="weapon" and r.weapons.size()<4:Build.buy(r,index)
