extends SceneTree
const B=preload("res://scripts/build_v5.gd")
const D=preload("res://scripts/data_v5.gd")
var checks=0
var failed=0
func check(condition:bool,message:String) -> void:
	checks+=1
	if not condition:failed+=1;push_error(message)
func offer(r:Dictionary,id:String) -> void:
	r.shop=[{"id":id,"kind":"weapon" if id.begins_with("W") else ("support" if id.begins_with("S") else "item"),"locked":false,"bought":false}]
func _initialize() -> void:
	check(D.CLASSES.size()==6 and D.WEAPONS.size()==12 and D.SUPPORTS.size()==8 and D.TECHS.size()==24 and D.ITEMS.size()==40 and D.BUILDS.size()==8,"reference counts")
	for w in D.WEAPONS.values():check(w.branches.size()==2 and w.branches.has("A") and w.branches.has("B"),"branches")
	for d in D.BUILDS.values():
		for id in d.refs:check(not D.entry(id).is_empty(),"unresolved reference "+id)
	for seed in range(300):
		for cls in D.ACTIVE_CLASSES:
			var r=B.new_run(cls,seed);var hp=r.hp
			check(B.settle_wave(r,0).ok,"settle")
			check(r.cash==67,"W1 zero pickup fallback67")
			check(r.hp==hp,"no free wave heal")
			var affordable=false
			for o in r.shop:
				if o.kind=="item" and B.price(r,o.id)<=45 and B.legal(r,o.id):affordable=true
			check(affordable,"affordable compatible item")
			var before=JSON.stringify(r)
			check(not B.settle_wave(r,0).ok and before==JSON.stringify(r),"settlement idempotence")
			check(r.level==2 and r.pending_levels==1 and r.level_choices.size()==3,"level choices")
			var clone=r.duplicate(true);B.reroll(r);B.reroll(clone)
			check(r.shop==clone.shop and r.rng_state==clone.rng_state,"RNG restore exactly")
			B.choose_level(r,r.level_choices[0]);r.wave=2;B.settle_wave(r,30)
			check(r.gas==20 and r.pending_research,"W2 unconditional gas")
			check(B.generate_research(r,"工程").ok,"three research legal")
			check(r.research_choices.size()==3,"research count")
			var seen={}
			for id in r.research_choices:check(B.legal(r,id) and not seen.has(id),"valid distinct research");seen[id]=true
			var frozen=r.research_choices.duplicate();B.generate_research(r,"生化")
			check(r.research_choices==frozen,"preference cannot reroll")
			check(B.research(r,r.research_choices[0]).ok and r.gas==0 and r.techs.size()==1,"research20")
	var r=B.new_run("C01",9);r.cash=1000
	check(B.upgrade(r,1).ok and r.cash==964 and r.weapons[0].invested==36,"upgrade1 exact")
	var snap=JSON.stringify(r)
	check(not B.upgrade(r,1).ok and snap==JSON.stringify(r),"branch preview no charge")
	check(B.upgrade(r,1,"A").ok and r.cash==910 and r.weapons[0].branch=="A","branch54")
	snap=JSON.stringify(r);check(not B.upgrade(r,1,"B").ok and snap==JSON.stringify(r),"permanentbranch")
	check(B.sell_value(r,"weapon",1)==45,"starter investment excludes free base")
	offer(r,"W01");check(B.buy(r,0).ok,"secondsame allowed")
	offer(r,"W01");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"thirdsame rejected")
	for id in ["W02","W03"]:offer(r,id);B.buy(r,0)
	offer(r,"W05");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"fullslot preview no mutation")
	var cash=r.cash;check(B.buy(r,0,1).ok and r.cash==cash+45-85 and r.weapons.size()==4,"atomicreplacement")
	check(B.sell(r,"weapon",r.weapons[0].uid).ok,"sale")
	r=B.new_run("C06",4);r.cash=1000
	for id in ["S01","S02"]:offer(r,id);check(B.buy(r,0).ok,"support purchase")
	offer(r,"S03");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"support preview")
	check(B.buy(r,0,"S01").ok and r.supports==["S02","S03"],"support replacement")
	for id in ["I11","I11"]:offer(r,id);check(B.buy(r,0).ok,"stack2")
	offer(r,"I11");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"stackcap")
	check(is_equal_approx(B.stats(r).armor,21.0) and is_equal_approx(B.stats(r).speed,184.5),"I11 benefit/cost")
	r.hp=10;offer(r,"I12");B.buy(r,0);B.sell(r,"item","I12");check(r.hp==10,"buy/sell no heal")
	r.items={"I21":1,"I22":1};r.class_id="C03";r.techs=["T20"]
	check(is_equal_approx(B.stats(r).dash_cd,4.6*0.92),"cooldown fixed before percentage")
	r.items={"I37":2,"I19":2,"I18":2,"I12":2,"I25":2};r.techs=["T02","T12","T01"]
	var s=B.stats(r);check(is_equal_approx(s.max_hp,49.0),"flat HP arithmetic")
	check(is_equal_approx(s.skill_cd,10.0),"additive CD penalties")
	check(is_equal_approx(s.iframe,0.45),"iframe additive")
	r=B.new_run("C01",1);r.items={"I28":1,"I13":2,"I26":2};r.debt=75;r.hp=50
	for w in range(1,5):
		r.wave=w;check(B.settle_wave(r,0).ok,"debtsettle");check(r.cash>=0,"debt cannotnegative")
	check(r.debt==0,"debt paid exactly75")
	check(not B.sell(r,"item","I28").ok,"debt cannot sell")
	var incomes=[]
	for pieces in [1,10,50]:
		r=B.new_run("C01",100);r.items={"I26":1};var total=0.0
		for i in range(pieces):total+=30.0/pieces
		B.settle_wave(r,total);incomes.append(r.cash)
	check(incomes==[78,78,78],"pickup split invariant (1/10/50 pieces)")
	r=B.new_run("C01",42);B.settle_wave(r,0)
	check(B.lock(r,0).ok and B.lock(r,1).ok and not B.lock(r,2).ok,"lock2")
	var locked=r.shop.slice(0,2).duplicate(true)
	for cost in [0,5,8,11]:
		check(B.reroll_cost(r)==cost,"rerollcost sequence");B.reroll(r)
	check(r.shop.slice(0,2)==locked,"reroll locks stable")
	r.wave=2;B.settle_wave(r,0);check(r.shop.slice(0,2)==locked and B.reroll_cost(r)==0,"crosswave locks and free reset")
	check(not B.can_depart(r).ok,"required choices blockdeparture")
	check(B.validate_enabled(D.ACTIVE_WEAPONS,D.ACTIVE_SUPPORTS,D.ACTIVE_TECHS).ok,"initial pool validated")
	check(not B.validate_enabled(["W01","W03","W05","W06"],D.ACTIVE_SUPPORTS,D.ACTIVE_TECHS).ok,"starter cannot disabled")
	r=B.new_run("C01",1);r.cash=999
	offer(r,"W12");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"archive cannot buy")
	offer(r,"I99");snap=JSON.stringify(r);check(not B.buy(r,0).ok and snap==JSON.stringify(r),"unknown cannot buy")
	for table in [D.CLASSES,D.WEAPONS,D.SUPPORTS,D.TECHS,D.ITEMS,D.BUILDS]:
		for entry in table.values():
			check(not str(entry.desc).is_empty() and not str(entry.source).is_empty(),"full reference description/source")
	r=B.new_run("C01",1);r.bonuses.attack=1.55
	var over=B.weapon_stats(r,r.weapons[0])
	check(is_equal_approx(B.stats(r).attack_raw,2.55) and B.stats(r).attack==2.5,"raw attack preserves above cap")
	check(is_equal_approx(over.raw_attack,2.65) and is_equal_approx(over.base_rate,4),"class attack added before cap")
	check(is_equal_approx(clampf(over.raw_attack-0.25,0.5,2.5),2.4),"negative branch can return raw overcap to2.4")
	r.bonuses.attack=-0.8
	var under=B.weapon_stats(r,r.weapons[0])
	check(is_equal_approx(under.raw_attack,0.3),"raw attack preserves belowfloor beforeclass")
	check(is_equal_approx(clampf(under.raw_attack+0.35,0.5,2.5),0.65),"stim beforecap not0.95")
	r.items={"I12":10}
	check(is_equal_approx(B.stats(r).speed_raw,430) and B.stats(r).speed==360,"speed_raw is world units persecond")
	print("MODEL_V5 checks=%d failed=%d" % [checks,failed]);quit(1 if failed else 0)
