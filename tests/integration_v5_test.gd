extends SceneTree
## Independent contract audit, deliberately separate from implementation unit tests.
const Build=preload('res://scripts/build_v5.gd')
const Data=preload('res://scripts/data_v5.gd')
var failures=[]
var checks=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok: failures.append(label);print('FAIL ',label)
func _init():
 call_deferred('run_tests')
func run_tests():
 check(Data.CLASSES.size()==6,'six classes')
 check(Data.WEAPONS.size()==12,'twelve weapons')
 check(Data.SUPPORTS.size()==8,'eight supports')
 check(Data.TECHS.size()==24,'24 technology entries')
 check(Data.ITEMS.size()==40,'40 item entries')
 check(Data.BUILDS.size()==8,'eight build references')
 for id in Data.WEAPONS:
  check(Data.WEAPONS[id].branches.has('A') and Data.WEAPONS[id].branches.has('B'),'two branches '+id)
  check(not Data.WEAPONS[id].branches.A.desc.is_empty() and not Data.WEAPONS[id].branches.B.desc.is_empty(),'branch descriptions '+id)
 for id in Data.CLASSES:check(Data.WEAPONS.has(Data.CLASSES[id].starter),'class starter resolves '+id)
 for cls in ['C01','C03','C06']:
  for seed_value in range(1,51):
   var r=Build.new_run(cls,seed_value)
   check(Build.settle_wave(r,0).ok,'%s/%d settle W1'%[cls,seed_value])
   check(r.cash==67,'%s/%d zero pickup67'%[cls,seed_value])
   var affordable=false
   for offer in r.shop:
    if not offer.bought and Build.price(r,offer.id)<=r.cash:affordable=true
   check(affordable,'%s/%d affordable shop'%[cls,seed_value])
   var once=JSON.stringify(r)
   check(not Build.settle_wave(r,30).ok and JSON.stringify(r)==once,'reward duplicate no mutation')
   var before=JSON.stringify(r)
   check(not Build.buy(r,-1).ok and JSON.stringify(r)==before,'invalid buy no mutation')
   r.cash=300
   check(Build.upgrade(r,1).ok,'upgrade Lv2')
   before=JSON.stringify(r)
   check(not Build.upgrade(r,1).ok and JSON.stringify(r)==before,'Lv3 missing branch does not pay')
   check(Build.upgrade(r,1,'B').ok,'branch confirmation')
   before=JSON.stringify(r)
   check(not Build.upgrade(r,1,'A').ok and JSON.stringify(r)==before,'branch immutable')
   check(Build.sell_value(r,'weapon',1)==45 if cls!='C06' else Build.sell_value(r,'weapon',1)==45,'starter invested-only salvage')
   r.wave=2
   check(Build.settle_wave(r,30).ok and r.gas==20 and r.pending_research,'W2 gas research')
   check(Build.generate_research(r).ok,'generate legal research')
   check(r.research_choices.size()==3,'research three choices')
   var unique={}
   for id in r.research_choices:unique[id]=true;check(Build.legal(r,id),'legal research '+id)
   check(unique.size()==3,'research unique')
   before=JSON.stringify(r)
   Build.generate_research(r,'工程')
   check(JSON.stringify(r)==before,'preference cannot reroll frozen research')
   check(not Build.can_depart(r).ok,'cannot depart pending choices')
   var chosen=str(r.research_choices[0])
   check(Build.research(r,chosen).ok and r.gas==0 and chosen in r.techs,'research20 transaction')
   before=JSON.stringify(r)
   check(not Build.research(r,chosen).ok and JSON.stringify(r)==before,'research cannot repurchase')
   while r.pending_levels>0:Build.choose_level(r,r.level_choices[0])
   check(Build.can_depart(r).ok,'depart after required choices')
 var debt=Build.new_run('C01',9001)
 debt.debt=75;debt.items={'I13':2}
 for w in range(1,4):
  debt.wave=w;Build.settle_wave(debt,0);check(debt.cash>=0,'debt never negative')
 check(debt.debt==0,'debt paid75 over3 guaranteed incomes')
 var fair=[]
 for n in [1,10,50]:
  var r=Build.new_run('C01',123)
  r.items={'I26':1}
  var total=0.0
  for i in range(n):total+=30.0/n
  Build.settle_wave(r,total);fair.append(r.cash)
 check(fair[0]==fair[1] and fair[1]==fair[2],'value decomposition fair settlement')
 var r=Build.new_run('C01',444)
 r.cash=1000;Build.settle_wave(r,0)
 var locked=r.shop[0].duplicate(true)
 check(Build.lock(r,0).ok and Build.lock(r,1).ok,'two locks')
 check(not Build.lock(r,2).ok,'third lock denied')
 locked=r.shop[0].duplicate(true)
 var costs=[]
 for i in range(4):costs.append(Build.reroll_cost(r));Build.reroll(r)
 check(costs==[0,5,8,11],'free5/8/11 refresh')
 check(r.shop[0]==locked,'locked offer unchanged')
 var json_round=JSON.parse_string(JSON.stringify(r))
 Build.reroll(r);Build.reroll(json_round)
 check(r.shop==json_round.shop and r.rng_state==json_round.rng_state,'JSON restored RNG exactly')
 combat_checks()
 controlled_campaign_chain()
 print('V5 independent audit: ',checks,' checks, ',failures.size(),' failures')
 if not failures.is_empty():print(JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)

func combat_checks():
 var Combat=load("res://scripts/combat_v5.gd")
 var samples=[]
 # Fixed seed/class mapping declared before simulations; no seed selection or HP boosts.
 for policy in [0,1]:
  for ci in range(3):
   var cls=["C01","C03","C06"][ci]
   var r=Build.new_run(cls,ci+1)
   var record={"class":cls,"seed":ci+1,"policy":("original orbit+repulsion; unconditional skill" if policy==0 else "continuous tangent+repulsion; C01 stim only hp>40"),"waves":[]}
   for wave in range(1,5):
    r.wave=wave
    var sim=Combat.new();sim.initialize(r)
    var completed=false
    for frame in range(5400):
     var desired=Vector2(900,600)+Vector2.from_angle(sim.elapsed*0.29)*365.0
     var move=(desired-sim.p).normalized()
     for e in sim.enemies:
      var delta=sim.p-Vector2(e.p)
      if delta.length()<160 and delta.length()>0:move+=delta.normalized()*(160-delta.length())/70.0
     if policy==1:
      var radial=sim.p-Vector2(900,600)
      move=Vector2(-radial.y,radial.x).normalized()+radial.normalized()*(365.0-radial.length())/140.0
      for e in sim.enemies:
       var delta=sim.p-Vector2(e.p)
       if delta.length()<185 and delta.length()>0:move+=delta.normalized()*(185-delta.length())/55.0
     var commands={"skill":sim.skill_cd<=0 and (policy==0 or cls!="C01" or r.hp>40),"dash":sim.dash_cd<=0 and frame%90==0}
     var events=sim.step(1.0/30.0,move.normalized(),commands)
     for ev in events:
      if ev.type=="wave_end":completed=true
     if sim.finished:break
    record.waves.append({"wave":wave,"completed":completed,"seconds":snappedf(sim.elapsed,.01),"hp":snappedf(r.hp,.01),"active_pickup":sim.active_value,"damage":snappedf(sim.total_damage,.01),"last_damage":sim.last_damage_source,"peak_enemies":sim.statistics.peak_enemies})
    check(sim.statistics.peak_enemies<=35,'campaign enemy cap35')
    check(sim.statistics.peak_devices<=8,'attackfriend cap8')
    if not completed:break
    Build.settle_wave(r,sim.active_value)
    while r.pending_levels>0:
     var choice=r.level_choices[0]
     if "damage" in r.level_choices:choice="damage"
     elif "health" in r.level_choices:choice="health"
     Build.choose_level(r,choice)
    if r.pending_research:
     Build.generate_research(r)
     Build.research(r,r.research_choices[0])
    var w=r.weapons[0]
    while w.level<3 and r.cash>=Build.upgrade_cost(r,w.uid):Build.upgrade(r,w.uid,"A")
    for i in range(r.shop.size()):
     var o=r.shop[i]
     if o.kind=="weapon" and r.weapons.size()<4:Build.buy(r,i)
    check(Build.can_depart(r).ok,'campaign bot required choices complete')
   samples.append(record)
 print('FIXED_SEED_NO_CHEAT_SAMPLES '+JSON.stringify(samples))
 var r=Build.new_run('C06',12,'boss');r.wave=12;r.techs=['T09','T10','T12']
 var sim=Combat.new();sim.initialize(r)
 var boss=sim.enemies[0]
 for frame in range(11):sim.step(0.1,Vector2.ZERO,{})
 # Controlled mechanism fixture. Direct boss damage below is NOT a gameplay clear.
 sim.hit_enemy(boss,1600,25,{"origin":"weapon","source":"fixture"})
 check(boss.phase==2,'W12 70percent phase2')
 var cocoons=[]
 for e in sim.enemies:
  if e.kind=='cocoon':cocoons.append(e)
 check(cocoons.size()==2,'two100HP cocoons')
 if cocoons.size()==2:
  check(cocoons[0].hp==100 and cocoons[0].cocoon_left==8,'cocoonHP/timer')
  check(sim.request_mark(cocoons[0].uid),'mark cocoon')
  check(sim.target(1000).uid==cocoons[0].uid,'manual mark precedence')
  sim.hit_enemy(cocoons[0],200,25,{"origin":"weapon","source":"fixture"})
  check(sim.mark_uid==-1,'dead mark clears')
 boss.phase_lock=0
 sim.hit_enemy(boss,1400,25,{"origin":"weapon","source":"fixture"})
 check(boss.phase==3,'W12 35percent phase3')
 # No external HP change: damage is suppressed only in this fixture, explicitly labeled.
 for frame in range(90):
  sim.iframe=100
  sim.step(1.0/30.0,Vector2.ZERO,{})
 var beam=false
 for h in sim.hazards:
  if h.kind=='beam':beam=true;check(is_equal_approx(h.arc,deg_to_rad(120)),'beam120degree')
 check(beam,'P3 rotating beam scheduled')
 check(not sim.apply_control(boss,10),'boss CC immune')
 var lethal=Combat.new();var dead_run=Build.new_run('C01',700,'pressure');dead_run.hp=1;dead_run.supports=['S02'];lethal.initialize(dead_run)
 lethal.hurt(100,'fixture')
 lethal.heal(3)
 check(dead_run.hp==0,'no post-lethal sameframe healing revival')
 check(sim.delay_cast(boss,1)<=.3 and sim.delay_cast(boss,1)==0,'bossEMP ratecap')
 print('CONTROLLED_W12_FIXTURE '+JSON.stringify({"phase":boss.phase,"beam":beam,"danger_delays":sim.statistics.danger_delays,"not_a_clear":true}))

func controlled_campaign_chain():
 var Combat=load("res://scripts/combat_v5.gd")
 var Save=load("res://scripts/save_v5.gd")
 var r=Build.new_run('C01',12345)
 var rows=[]
 for wave in range(1,5):
  r.wave=wave;r.phase='wave'
  check(Save.save_wave_start(r,'user://audit_chain_v5.json').ok,'chain wave-startsave')
  var sim=Combat.new();sim.initialize(r)
  var done=false
  for frame in range(9000):
   sim.iframe=1.0 # Explicit invulnerability fixture; NOT balance evidence.
   var desired=Vector2(900,600)+Vector2.from_angle(sim.elapsed*.2)*250
   var events=sim.step(1.0/30,(desired-sim.p).normalized(),{})
   for ev in events:
    if ev.type=='wave_end':done=true
   if sim.finished:break
  rows.append({'wave':wave,'complete':done,'seconds':sim.elapsed})
  check(done,'controlled fullchain complete wave%d'%wave)
  if not done:break
  Build.settle_wave(r,sim.active_value)
  check(Save.save_run(r,'user://audit_chain_v5.json').ok,'chain settle save')
  var loaded=Save.load_run('user://audit_chain_v5.json')
  check(loaded.ok and loaded.run.shop==r.shop,'chain exact shop restore')
  while r.pending_levels>0:Build.choose_level(r,'damage' if 'damage' in r.level_choices else r.level_choices[0])
  if r.pending_research:
   Build.generate_research(r);Build.research(r,r.research_choices[0])
  var w=r.weapons[0]
  while w.level<3 and r.cash>=Build.upgrade_cost(r,w.uid):Build.upgrade(r,w.uid,'A')
  for i in range(r.shop.size()):
   if r.shop[i].kind=='weapon':Build.buy(r,i)
  check(Save.save_run(r,'user://audit_chain_v5.json').ok,'chain transaction save')
 print('CONTROLLED_INVULNERABLE_FOUR_WAVE_CHAIN '+JSON.stringify(rows))
