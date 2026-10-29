extends RefCounted
## Pure v5 model: commands mutate only after all checks; caller persists each success.
const Data = preload("res://scripts/data_v5.gd")
const LEVEL_CHOICES = {
 "health":{"name":"体能强化","desc":"最大生命 +8（不治疗）","key":"max_hp","value":8.0},
 "damage":{"name":"弹药改良","desc":"全局伤害 +6%","key":"damage","value":0.06},
 "attack":{"name":"供弹优化","desc":"武器攻速 +6%","key":"attack","value":0.06},
 "armor":{"name":"防护衬层","desc":"护甲 +4","key":"armor","value":4.0},
 "engineering":{"name":"工程优化","desc":"工程倍率 +8个百分点","key":"engineering","value":0.08},
 "pickup":{"name":"回收天线","desc":"拾取半径 +20u","key":"pickup","value":20.0},
 "cash":{"name":"补给矿晶","desc":"矿晶 +15","key":"cash","value":15.0}}
static func result(ok:bool,reason:String="") -> Dictionary: return {"ok":ok,"reason":reason}
static func count(r:Dictionary,id:String) -> int: return int(r.get("items",{}).get(id,0))
static func tech(r:Dictionary,id:String) -> bool: return id in r.get("techs",[])
static func new_run(class_id:String,seed_value:int,mode:String="campaign") -> Dictionary:
	if not class_id in Data.ACTIVE_CLASSES: class_id="C01"
	var rng=RandomNumberGenerator.new(); rng.seed=seed_value
	var r={"version":5,"content_version":"v5.0.0","run_id":"%s-%s" % [Time.get_unix_time_from_system(),seed_value],"class_id":class_id,"mode":mode,"phase":"wave","wave":1,"completed_wave":0,"hp":float(Data.CLASSES[class_id].hp),"cash":0,"gas":0,"level":1,"xp":0,"weapons":[{"id":Data.CLASSES[class_id].starter,"level":1,"branch":"","invested":0,"uid":1}],"next_uid":2,"supports":[],"support_invested":{},"techs":[],"items":{},"item_invested":{},"bonuses":{},"shop":[],"level_choices":[],"pending_levels":0,"research_choices":[],"pending_research":false,"research_preference":"","seen_techs":[],"rng_seed":str(rng.seed),"rng_state":str(rng.state),"rescue_spent":false,"debt":0,"debt_due":0,"reward_ids":[],"rerolls":0,"active_pickup":0,"deploy_count":0,"research_earned":0}
	return r
static func stats(r:Dictionary) -> Dictionary:
	var c=Data.CLASSES.get(r.get("class_id","C01"),Data.CLASSES.C01)
	var b=r.get("bonuses",{})
	var hp=float(c.hp)+float(b.get("max_hp",0))+15*int(tech(r,"T02"))-8*count(r,"I12")-10*count(r,"I14")-10*count(r,"I18")-5*count(r,"I25")
	hp=maxf(30,hp*(1.0-0.1*count(r,"I38")-0.1*int(tech(r,"T17"))))
	var damage=1.0+float(b.get("damage",0))-0.06*count(r,"I02")-0.05*count(r,"I22")+0.15*count(r,"I37")-0.08*count(r,"I36")-0.08*count(r,"I39")-0.1*int(tech(r,"T09"))-0.08*int(tech(r,"T07"))-0.08*int(tech(r,"T15"))-0.1*int(tech(r,"T24"))
	var attack=1.0+float(b.get("attack",0))-0.05*count(r,"I01")+0.12*count(r,"I02")-0.06*count(r,"I31")-0.08*count(r,"I07")-0.1*int(tech(r,"T05"))
	var speed=float(c.speed)*(1-0.05*count(r,"I11")+0.1*count(r,"I12")-0.05*count(r,"I03")-0.05*count(r,"I24")+0.12*count(r,"I29")-0.08*int(tech(r,"T22")))
	var healing=1.0+0.2*count(r,"I18")-0.1*count(r,"I16")-0.1*count(r,"I20")-0.12*count(r,"I29")-0.15*int(tech(r,"T21"))
	var dash_base=(3.2 if r.class_id=="C03" else 4.0)+0.4*count(r,"I21")+0.3*count(r,"I19")+0.5*int(tech(r,"T02"))+int(tech(r,"T20"))
	var skill_increase=0.1*int(tech(r,"T01"))+0.15*int(tech(r,"T12"))+0.2*int(tech(r,"T16"))+0.15*int(tech(r,"T19"))+0.05*count(r,"I35")
	return {"max_hp":hp,"armor":clampf(float(c.armor)+float(b.get("armor",0))+8*count(r,"I11")-4*count(r,"I17"),0,150),"speed_raw":speed,"speed":clampf(speed,140,360),"crit":clampf(float(c.crit)+0.08*count(r,"I38")-0.05*count(r,"I30"),0,0.75),"crit_mult":1.5,"damage":damage,"attack_raw":attack,"attack":clampf(attack,0.5,2.5),"engineering":maxf(0,1.0+float(b.get("engineering",0))+0.15*int(r.class_id=="C06")-0.08*count(r,"I32")),"device_attack":1+0.15*count(r,"I31"),"device_hp":1+0.25*count(r,"I32"),"device_damage":1-0.1*int(tech(r,"T10"))+0.3*count(r,"I34"),"device_range":60*count(r,"I33"),"range":1.0,"healing":maxf(0,healing),"pickup":clampf((100.0+float(b.get("pickup",0))+35*count(r,"I25"))*(0.85 if tech(r,"T11") else 1.0),0,220),"dash_cd":dash_base*(1-minf(0.4,0.08*count(r,"I22"))),"skill_cd":float(c.skill_cd)*(1+skill_increase)*(1-minf(0.4,0.1*count(r,"I23"))),"dash_distance":180*(1+0.15*count(r,"I21")+0.3*int(tech(r,"T03"))),"iframe":clampf(0.45+0.05*count(r,"I19")-0.05*count(r,"I37"),0.3,0.6),"shield_mult":1+0.2*count(r,"I16"),"mark_duration":4.0+count(r,"I25"),"skill_damage":1-0.1*count(r,"I23")-0.15*int(tech(r,"T13")),"weapon_capacity":3 if count(r,"I40") else 4}
static func weapon_stats(r:Dictionary,w:Dictionary) -> Dictionary:
	var d=Data.WEAPONS[w.id]; var s=stats(r); var tags=d.tags
	var category=0.0
	if "实弹" in tags: category=maxf(category,0.18*count(r,"I03"))
	if "能量" in tags: category=maxf(category,0.18*count(r,"I07"))
	var penalty=0.0
	if "爆破" in tags: penalty-=0.08*count(r,"I05")
	if "热能" in tags: penalty-=0.08*count(r,"I06")+0.1*int(tech(r,"T04"))
	if "能量" in tags: penalty-=0.1*count(r,"I08")+0.1*int(tech(r,"T18"))
	if not "精密" in tags: penalty-=0.06*count(r,"I04")
	if tech(r,"T23"): penalty-=0.1
	var base=float(d.damage)*(1+0.25*(int(w.level)-1))
	var armor_ignore=5*count(r,"I01") if "实弹" in tags else 0
	if tech(r,"T05") and ("实弹" in tags or "爆破" in tags): armor_ignore+=10
	var attack=s.attack_raw+0.1*int(r.class_id=="C01" and "实弹" in tags)
	return {"id":w.id,"damage":base*maxf(0,s.damage+category+penalty),"base_damage":base,"raw_attack":attack,"base_rate":float(d.rate),"rate":float(d.rate)*clampf(attack,0.5,2.5),"range":maxf(120,float(d.range)*s.range-30*count(r,"I33")),"radius":float(d.radius)*(1+0.15*count(r,"I05")-0.1*int(tech(r,"T08"))),"crit":clampf(s.crit+0.08*count(r,"I04")*int("精密" in tags),0,0.75),"crit_mult":s.crit_mult,"armor_ignore":mini(25,armor_ignore),"tags":tags,"branch":w.get("branch",""),"level":w.level}
static func has_tag(r:Dictionary,tag:String) -> bool:
	for w in r.weapons:
		if tag in Data.WEAPONS[w.id].tags: return true
	return false
static func has_device(r:Dictionary) -> bool: return r.class_id=="C06" or "S01" in r.supports or "S05" in r.supports
static func legal(r:Dictionary,id:String) -> bool:
	match id:
		"T01":return not r.weapons.is_empty()
		"T04":return r.class_id=="C04" or has_weapon(r,"W04")
		"T05","I10":return has_tag(r,"实弹") or has_tag(r,"爆破")
		"T06":return has_tag(r,"爆破") or has_device(r)
		"T07":
			for w in r.weapons:
				if w.id in ["W05","W08","W09"] or (w.id=="W01" and w.branch=="B"):return true
			return "S05" in r.supports
		"T08","I05":return has_tag(r,"爆破")
		"T09","T10","T11","T23","I31","I32","I33","I34":return has_device(r)
		"T14","I04":return has_tag(r,"精密")
		"T18","I07","I08":return has_tag(r,"能量")
		"I01","I03":return has_tag(r,"实弹")
		"I06":return has_tag(r,"热能")
		"I28":return int(r.wave)<=7 and not count(r,id)
		"I40":return r.weapons.size()<=3
	return true
static func has_weapon(r:Dictionary,id:String) -> bool:
	for w in r.weapons:
		if w.id==id:return true
	return false
static func _rng(r:Dictionary) -> RandomNumberGenerator:
	var rng=RandomNumberGenerator.new();rng.seed=int(r.rng_seed);rng.state=int(r.rng_state);return rng
static func _pick(r:Dictionary,arr:Array):
	if arr.is_empty():return ""
	var rng=_rng(r);var picked=arr[rng.randi_range(0,arr.size()-1)];r.rng_state=str(rng.state);return picked
static func _clamp_hp(r:Dictionary) -> void: r.hp=minf(float(r.hp),float(stats(r).max_hp))
static func find_weapon(r:Dictionary,uid) -> int:
	for i in range(r.weapons.size()):
		if int(r.weapons[i].uid)==int(uid):return i
	return -1
static func price(r:Dictionary,id:String) -> int:
	var p=int(Data.entry(id).get("cost",0))
	if id.begins_with("W") and count(r,"I27"):p=ceili(p*1.1)
	return p
static func upgrade_cost(r:Dictionary,uid) -> int:
	var i=find_weapon(r,uid)
	if i<0 or int(r.weapons[i].level)>=3:return 0
	return ceili(float(Data.WEAPONS[r.weapons[i].id].cost)*(0.6 if int(r.weapons[i].level)==1 else 0.9))
static func sell_value(r:Dictionary,kind:String,key) -> int:
	match kind:
		"weapon":
			var i=find_weapon(r,key);return floori(float(r.weapons[i].invested)*0.5) if i>=0 else 0
		"support":return floori(float(r.support_invested.get(str(key),0))*0.5)
		"item":return 0 if str(key)=="I28" else floori(float(r.item_invested.get(str(key),0))*0.5)
	return 0
static func buy(r:Dictionary,index:int,replace_uid=-1) -> Dictionary:
	if index<0 or index>=r.shop.size():return result(false,"货架不存在")
	var offer=r.shop[index];var id=str(offer.id);var kind=str(offer.kind)
	if offer.bought:return result(false,"此格已购买")
	if Data.entry(id).is_empty():return result(false,"未知内容ID，无法购买")
	if Data.entry(id).get("reference_only",true):return result(false,"此内容仅供档案参考，验证切片未开放")
	if (kind=="weapon" and not Data.WEAPONS.has(id)) or (kind=="support" and not Data.SUPPORTS.has(id)) or (kind=="item" and not Data.ITEMS.has(id)):return result(false,"货品类别不匹配，无法购买")
	if not legal(r,id):return result(false,"装备前提未满足")
	var cost=price(r,id);var refund=0;var replacement=-1
	if kind=="weapon":
		var same=0
		for w in r.weapons:
			if w.id==id:same+=1
		if same>=2:return result(false,"同型号上限2")
		if r.weapons.size()>=int(stats(r).weapon_capacity):
			replacement=find_weapon(r,replace_uid)
			if replacement<0:return result(false,"武器已满，请比较并确认替换")
			refund=sell_value(r,"weapon",replace_uid)
	elif kind=="support":
		if id in r.supports:return result(false,"同支援唯一")
		if r.supports.size()>=2:
			replacement=r.supports.find(str(replace_uid))
			if replacement<0:return result(false,"支援已满，请比较并确认替换")
			refund=sell_value(r,"support",str(replace_uid))
	elif kind=="item":
		if count(r,id)>=int(Data.ITEMS[id].cap):return result(false,"道具已达叠加上限")
		if not r.items.has(id) and r.items.size()>=12:return result(false,"先回收一种道具")
	else:return result(false,"未知货品类别")
	if int(r.cash)+refund<cost:return result(false,"还差%d矿晶" % (cost-int(r.cash)-refund))
	# Commit: validation complete, no failing operations below.
	r.cash=int(r.cash)+refund-cost
	if kind=="weapon":
		if replacement>=0:r.weapons.remove_at(replacement)
		r.weapons.append({"id":id,"level":1,"branch":"","invested":cost,"uid":int(r.next_uid)});r.next_uid=int(r.next_uid)+1
	elif kind=="support":
		if replacement>=0:
			r.support_invested.erase(r.supports[replacement]);r.supports.remove_at(replacement)
		r.supports.append(id);r.support_invested[id]=cost
	else:
		r.items[id]=count(r,id)+1;r.item_invested[id]=int(r.item_invested.get(id,0))+cost
		if id=="I28":r.cash+=60;r.debt=75;r.debt_due=0
	offer.bought=true;offer.locked=false;_clamp_hp(r)
	return result(true,"购买完成")
static func upgrade(r:Dictionary,uid,branch:String="") -> Dictionary:
	var i=find_weapon(r,uid)
	if i<0:return result(false,"武器不存在")
	var w=r.weapons[i];var cost=upgrade_cost(r,uid)
	if int(w.level)>=3:return result(false,"本局终阶分支固定")
	if int(w.level)==2 and not branch in ["A","B"]:return result(false,"请比较并确认A/B分支")
	if int(r.cash)<cost:return result(false,"还差%d矿晶" % (cost-int(r.cash)))
	r.cash-=cost;w.invested=int(w.invested)+cost;w.level=int(w.level)+1
	if w.level==3:w.branch=branch
	return result(true,"升级完成")
static func sell(r:Dictionary,kind:String,key) -> Dictionary:
	var refund=sell_value(r,kind,key)
	match kind:
		"weapon":
			var i=find_weapon(r,key)
			if i<0:return result(false,"武器不存在")
			r.weapons.remove_at(i)
		"support":
			if not str(key) in r.supports:return result(false,"支援不存在")
			r.supports.erase(str(key));r.support_invested.erase(str(key))
		"item":
			if str(key)=="I28":return result(false,"合同不可回收，债务仍需偿还")
			if not r.items.has(str(key)):return result(false,"道具不存在")
			r.items.erase(str(key));r.item_invested.erase(str(key))
		_:return result(false,"此类别不可回收")
	r.cash=int(r.cash)+refund;_clamp_hp(r);return result(true,"回收%d矿晶" % refund)
static func _pool(r:Dictionary,kind:String) -> Array:
	var out=[];var ids=[]
	match kind:
		"weapon":ids=r.get("enabled_weapons",Data.ACTIVE_WEAPONS)
		"support":ids=r.get("enabled_supports",Data.ACTIVE_SUPPORTS)
		"item":ids=Data.ACTIVE_ITEMS
	for id in ids:
		if Data.entry(id).is_empty() or Data.entry(id).get("reference_only",true):continue
		if not legal(r,id):continue
		if kind=="support" and id in r.supports:continue
		if kind=="item" and count(r,id)>=int(Data.ITEMS[id].cap):continue
		if kind=="weapon":
			var same=0
			for w in r.weapons:
				if w.id==id:same+=1
			if same>=2:continue
		out.append(id)
	return out
static func generate_shop(r:Dictionary,new_shop:bool=true) -> void:
	var old=r.shop.duplicate(true);var kinds=["weapon","item","item","support"]
	if r.supports.size()>=2:kinds[3]="item"
	var fresh=[]
	for i in range(4):
		if i<old.size() and old[i].locked and not old[i].bought:
			fresh.append(old[i]);continue
		if not new_shop and i<old.size() and old[i].bought:
			fresh.append(old[i]);continue
		var kind=kinds[i];var pool=_pool(r,kind)
		if pool.is_empty():kind="item";pool=_pool(r,kind)
		var id=_pick(r,pool)
		fresh.append({"id":id,"kind":kind,"locked":false,"bought":id==""})
	# Guarantee an affordable legal item unless locked/bought state makes all item slots immutable.
	var affordable=false
	for o in fresh:
		if o.kind=="item" and not o.bought and price(r,o.id)<=guaranteed(int(r.wave)) and legal(r,o.id):affordable=true
	if not affordable:
		var pool=[]
		for id in _pool(r,"item"):
			if price(r,id)<=guaranteed(int(r.wave)):pool.append(id)
		if not pool.is_empty():
			for i in [1,2,3,0]:
				if not fresh[i].locked and not fresh[i].bought:
					fresh[i]={"id":_pick(r,pool),"kind":"item","locked":false,"bought":false};break
	r.shop=fresh
static func reroll_cost(r:Dictionary) -> int:
	var n=int(r.rerolls)
	if n==0:return 0
	return maxi(0,5+3*(n-1)-(3 if n==1 and count(r,"I27") else 0))
static func reroll(r:Dictionary) -> Dictionary:
	var eligible=0
	for o in r.shop:
		if not o.locked and not o.bought:eligible+=1
	if eligible==0:return result(false,"全部货格已锁定或已购买")
	var cost=reroll_cost(r)
	if int(r.cash)<cost:return result(false,"矿晶不足")
	r.cash-=cost;generate_shop(r,false);r.rerolls=int(r.rerolls)+1;return result(true,"已刷新%d格" % eligible)
static func lock(r:Dictionary,index:int) -> Dictionary:
	if index<0 or index>=r.shop.size():return result(false,"货架不存在")
	var o=r.shop[index]
	if o.bought:return result(false,"已购买货格不能锁定")
	var n=0
	for x in r.shop:
		if x.locked:n+=1
	if not o.locked and n>=2:return result(false,"最多保留2件")
	o.locked=not o.locked;return result(true,"下波保留" if o.locked else "已解锁")
static func guaranteed(w:int) -> int:
	if w<=3:return 45
	if w==4:return 70
	if w<=7:return 55
	if w==8:return 90
	if w<=11:return 65
	return 0
static func drop_budget(w:int) -> int:
	if w<=3:return 30
	if w==4:return 20
	if w<=7:return 40
	if w==8:return 25
	if w<=11:return 50
	return 0
static func settle_wave(r:Dictionary,active_value:float=0) -> Dictionary:
	var reward_id=str(r.run_id)+":"+str(r.wave)
	if reward_id in r.reward_ids:return result(false,"本波已结算，不重复发放")
	var base=guaranteed(int(r.wave));var active=clampf(active_value,0,drop_budget(int(r.wave)))
	var income=maxi(0,base-floori(base*0.05)*count(r,"I13")+(floori(base*0.1) if "S07" in r.supports else 0))
	if int(r.debt)>0:
		var due=mini(int(r.debt),25+int(r.debt_due));var paid=mini(income,due);income-=paid;r.debt=int(r.debt)-paid;r.debt_due=due-paid
	var recovery=floori((drop_budget(int(r.wave))-active)*(0.75-0.05*count(r,"I26")))
	var pickup_bonus=floori(active*0.1*count(r,"I26"))
	r.cash=int(r.cash)+income+floori(active)+recovery+pickup_bonus
	if int(r.wave) in [2,5,8]:r.gas=int(r.gas)+20;r.pending_research=true;r.research_choices=[];r.research_preference=""
	r.xp=int(r.xp)+(150 if int(r.wave) in [4,8,12] else 100)
	while int(r.xp)>=100:
		r.xp=int(r.xp)-100;r.level=int(r.level)+1
		if int(r.wave)<12:r.pending_levels=int(r.pending_levels)+1
	var s=stats(r);r.hp=minf(s.max_hp,float(r.hp)+s.max_hp*0.08*count(r,"I13")*s.healing)
	r.reward_ids.append(reward_id);r.completed_wave=r.wave;r.phase="shop";r.rerolls=0;r.active_pickup=0
	generate_shop(r,true);generate_levels(r)
	r.last_income={"guaranteed":income,"active":active,"recovery":recovery,"bonus":pickup_bonus,"total":income+floori(active)+recovery+pickup_bonus}
	return result(true,"结算完成")
static func generate_levels(r:Dictionary) -> void:
	if int(r.pending_levels)<=0:r.level_choices=[];return
	if not r.level_choices.is_empty():return
	var s=stats(r);var pool=["health","damage"]
	if s.attack<2.5:pool.append("attack")
	if s.armor<150:pool.append("armor")
	if has_device(r):pool.append("engineering")
	if s.pickup<220:pool.append("pickup")
	while r.level_choices.size()<3:
		var id=_pick(r,pool)
		if id=="":id="cash"
		r.level_choices.append(id);pool.erase(id)
static func choose_level(r:Dictionary,id:String) -> Dictionary:
	if int(r.pending_levels)<=0 or not id in r.level_choices:return result(false,"此升级选项不可用")
	var d=LEVEL_CHOICES[id]
	if id=="cash":r.cash+=15
	else:r.bonuses[d.key]=float(r.bonuses.get(d.key,0))+float(d.value)
	r.pending_levels=int(r.pending_levels)-1;r.level_choices=[];generate_levels(r);_clamp_hp(r);return result(true,"升级已选择")
static func generate_research(r:Dictionary,preference:String="") -> Dictionary:
	if not r.pending_research:return result(false,"本次没有待研究项目")
	if not r.research_choices.is_empty():return result(true,"本次研究选项已固定")
	var pool=[]
	for id in r.get("enabled_techs",Data.ACTIVE_TECHS):
		if id in Data.ACTIVE_TECHS and not id in r.techs and legal(r,id):pool.append(id)
	if pool.size()<3:return result(false,"合法科技不足三项，请检查启用内容池")
	var chosen=[];var first=[]
	for id in pool:
		if Data.TECHS[id].group==preference:first.append(id)
	if first.is_empty():
		var preferred={"C01":["T01","T02"],"C03":["T03","T02"],"C06":["T09","T10","T12"]}.get(r.class_id,[])
		for id in pool:
			if id in preferred:first.append(id)
	var a=_pick(r,first if not first.is_empty() else pool);chosen.append(a);pool.erase(a)
	var equipment=[]
	for id in pool:
		if Data.TECHS[id].prerequisite!="通用":equipment.append(id)
	var b=_pick(r,equipment if not equipment.is_empty() else pool);chosen.append(b);pool.erase(b)
	var last=[]
	for id in pool:
		if not id in r.seen_techs and Data.TECHS[id].prerequisite=="通用":last.append(id)
	if last.is_empty():
		for id in pool:
			if Data.TECHS[id].prerequisite=="通用":last.append(id)
	if last.is_empty():last=pool.duplicate()
	var weighted=last.duplicate()
	for id in last:
		if Data.TECHS[id].group in ["星灵","异虫"]:weighted.append(id)
	chosen.append(_pick(r,weighted));r.research_choices=chosen;r.research_preference=preference
	for id in chosen:
		if not id in r.seen_techs:r.seen_techs.append(id)
	return result(true,"研究选项已固定，可预览后确认")
static func research(r:Dictionary,id:String) -> Dictionary:
	if not r.pending_research or not id in r.research_choices:return result(false,"此研究选项不可用")
	if id in r.techs or r.techs.size()>=3:return result(false,"核心科技最多3项且不能重复")
	if not legal(r,id):return result(false,"当前装备不满足前提；可先恢复对应装备")
	if int(r.gas)<20:return result(false,"需要20本局瓦斯")
	r.gas-=20;r.techs.append(id);r.pending_research=false;_clamp_hp(r);return result(true,"本局研究固定")
static func can_depart(r:Dictionary) -> Dictionary:
	if int(r.pending_levels)>0:return result(false,"还有%d项升级" % int(r.pending_levels))
	if r.pending_research:return result(false,"还有1项研究")
	if r.weapons.is_empty():return result(false,"请至少装备一把武器")
	return result(true)
static func validate_enabled(weapons:Array,supports:Array,techs:Array,classes:Array=Data.ACTIVE_CLASSES) -> Dictionary:
	if weapons.size()<4:return result(false,"至少启用4种武器")
	if supports.size()<4:return result(false,"至少启用4种支援")
	if techs.size()<6:return result(false,"至少启用6项核心科技")
	for pair in [[weapons,Data.ACTIVE_WEAPONS],[supports,Data.ACTIVE_SUPPORTS],[techs,Data.ACTIVE_TECHS]]:
		var seen={}
		for id in pair[0]:
			if not id in pair[1]:return result(false,"档案参考内容尚未开放")
			if seen.has(id):return result(false,"启用内容不能重复")
			seen[id]=true
	for cls in classes:
		if not cls in Data.ACTIVE_CLASSES:return result(false,"此职业尚未开放")
		if not Data.CLASSES[cls].starter in weapons:return result(false,"不能关闭%s的初始武器" % Data.name_of(cls))
		var preferred={"C01":["T01","T02","T05"],"C03":["T01","T02","T03"],"C06":["T09","T10","T12"]}[cls]
		var compatible=0
		for id in techs:
			if id in preferred:compatible+=1
		if compatible<2:return result(false,"%s至少保留2项适配科技" % Data.name_of(cls))
		var r=new_run(cls,1);var valid=0
		for id in techs:
			if legal(r,id):valid+=1
		if valid<3:return result(false,"%s开局合法研究不足3项" % Data.name_of(cls))
	return result(true)
