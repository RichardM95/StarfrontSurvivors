extends RefCounted
## Pure run/progression model. No scene access, filesystem or global RNG.
## Decisions: four slots; one copy of each trade-off item; armor uses points with
## no arbitrary DR cap (15%/10% class armor converted exactly); Lv3 branches a/b.
## Buying an existing gun is explicit: new-slot cards and targeted upgrade cards
## are separate. Sale refunds half cumulative spend; class starter costs zero.
## Each level permits one free + two paid rerolls (5/10). Gold effects are unique.
const CLASS_IDS := ["marine", "marauder", "reaper", "firebat", "ghost"]
const CLASS_NAMES := {"marine":"游骑兵步兵", "marauder":"重装劫掠者", "reaper":"死神特战员", "firebat":"火蝠净化者", "ghost":"幽灵特工"}
const CLASS_DESCRIPTIONS := {"marine":"兴奋剂：消耗当前15%生命，5秒移速+35%、射速+45%，冷却12秒", "marauder":"命中40%概率减速35%持续1.8秒；击退+50%", "reaper":"冲刺冷却2.4秒；原地留下一枚延迟0.6秒的45伤害跳雷", "firebat":"喷焰点燃3秒，每秒基础攻击20%伤害；燃烧敌人死亡热能殉爆", "ghost":"每击杀30敌人触发EMP：清酸弹，定身与哑火1.5秒"}
const WEAPON_IDS := ["rifle", "shotgun", "flame", "sniper", "grenade", "tesla", "smg", "cannon"]
const ALL_WEAPON_IDS := ["rifle", "shotgun", "flame", "reaper", "sniper", "grenade", "tesla", "smg", "cannon"]
const WEAPON_NAMES := {"rifle":"磁轨步枪", "shotgun":"破阵霰弹枪", "flame":"等离子喷焰器", "reaper":"双持穿甲刺针", "sniper":"C-10高能狙击枪", "grenade":"集束榴弹发射器", "tesla":"电磁特斯拉发生器", "smg":"穿甲微型冲锋枪", "cannon":"等离子热能重炮"}
const TAGS := {"rifle":["ballistic","hightech"], "shotgun":["ballistic","explosive"], "flame":["plasma"], "reaper":["ballistic"], "sniper":["hightech"], "grenade":["explosive"], "tesla":["hightech","engineering"], "smg":["ballistic"], "cannon":["plasma","engineering"]}
const TAG_NAMES := {"ballistic":"实弹", "plasma":"等离子", "explosive":"高爆", "hightech":"高科", "engineering":"工程"}
const SUPPORT_IDS := ["sentry","medic_drone","raven","spider_mine"]
const SUPPORTS := {
 "sentry":{"name":"自动哨戒机枪塔","desc":"固定部署 · 每秒6发\n继承50%玩家伤害 · 不占武器槽","cost":70},
 "medic_drone":{"name":"蜂鸟医疗支援无人机","desc":"每4秒恢复5生命\n低于20%生命护盾3秒（每波一次）","cost":75},
 "raven":{"name":"渡鸦点防御无人机","desc":"130范围拦截敌方酸弹\n每波限8次 · 不占武器槽","cost":65},
 "spider_mine":{"name":"重力震荡蜘蛛雷","desc":"每移动800埋雷 · 爆炸半径140\n减速60% · 不占武器槽","cost":65}
}
const ITEM_IDS := ["pump","core","reactor","exoskeleton","nanobot","scope","tissue","storage","tripod","injector",
 "crystal","metabolic","capacitor","ceramic","stim_filter","wide_lens","recoil_brace","salvage_claw","vital_reserve","micro_servos",
 "pulse_coil","bio_pump","heavy_barrel","target_chip","field_rations","carbon_mesh","flux_anchor","coolant","combat_sensor","shock_liner",
 "long_magazine","siphon","reactive_weave","hollow_shell","gamma_cells","med_reserve","lucky_circuit","magnet_core","kinetic_belt","optical_veil",
 "war_chest","safety_limiter"]
const ITEMS := {
 "pump":{"name":"SCV辅助增压泵","desc":"移速+18% · 拾取+50\n最大生命−15","cost":38},
 "core":{"name":"贫铀穿甲硬芯","desc":"实弹伤害+30% · 穿透+1\n所有武器射速−15%","cost":48},
 "reactor":{"name":"超频核动力堆","desc":"所有武器射速+25%\n每次受击额外承受4点伤害","cost":48},
 "exoskeleton":{"name":"新柯隆合金外骨骼","desc":"护甲+20 · 受击无敌1秒\n移速−10%","cost":48},
 "nanobot":{"name":"医疗纳米母机","desc":"每秒恢复2.5生命\n全局伤害−12%","cost":46},
 "scope":{"name":"电磁聚能瞄具","desc":"暴击+15% · 射程+20%\n拾取半径−40","cost":42},
 "tissue":{"name":"异虫组织样本","desc":"吸血概率+8% · 生命+20\n波间治疗费用+50%","cost":42},
 "storage":{"name":"高能战备储存罐","desc":"每波补贴+25矿晶\n后续敌人生命与移速+5%","cost":55},
 "tripod":{"name":"折叠攻城支架","desc":"静止0.6秒伤害+45%、护甲+25\n移动时伤害−15%","cost":42},
 "injector":{"name":"黑市兴奋剂注射器","desc":"低于半血暴击、射速各+30%\n最大生命−10","cost":40},
 "crystal":{"name":"凯达林水晶碎片","desc":"暴击+12% · 暴伤至少2.2倍\n最大生命−20%","cost":55,"bonus":{"crit_rate":0.12},"hp_mult":0.8,"crit_floor":2.2},
 "metabolic":{"name":"恶性代谢分泌腺","desc":"移速+25%\n受击无敌缩短至0.35秒","cost":40,"bonus":{"speed_mult":0.25},"invuln_cap":0.35},
 "capacitor":{"name":"脉冲蓄能电容","desc":"伤害+18%\n射速−8%","cost":34,"bonus":{"damage_mult":0.18,"attack_mult":-0.08}},
 "ceramic":{"name":"蜂巢陶瓷护板","desc":"护甲+12\n生命上限−10","cost":34,"bonus":{"armor":12,"max_hp":-10}},
 "stim_filter":{"name":"兴奋剂过滤芯","desc":"秒回+1.2\n射速−8%","cost":38,"bonus":{"regen":1.2,"attack_mult":-0.08}},
 "wide_lens":{"name":"广域衍射镜","desc":"射程+25%\n伤害−10%","cost":32,"bonus":{"range_mult":0.25,"damage_mult":-0.1}},
 "recoil_brace":{"name":"后坐液压撑杆","desc":"实弹伤害+18%\n移速−8%","cost":32,"bonus":{"ballistic_damage_mult":0.18,"speed_mult":-0.08}},
 "salvage_claw":{"name":"SCV废料钩爪","desc":"矿晶价值+20%\n闪避−5%","cost":38,"bonus":{"harvesting":0.2,"dodge":-0.05}},
 "vital_reserve":{"name":"战备血浆储囊","desc":"生命+30\n移速−10%","cost":35,"bonus":{"max_hp":30,"speed_mult":-0.1}},
 "micro_servos":{"name":"微型伺服关节","desc":"闪避+10%\n护甲−8","cost":40,"bonus":{"dodge":0.1,"armor":-8}},
 "pulse_coil":{"name":"高速脉冲线圈","desc":"射速+18%\n暴击−5%","cost":36,"bonus":{"attack_mult":0.18,"crit_rate":-0.05}},
 "bio_pump":{"name":"生化循环泵","desc":"吸血+6%\n秒回−0.5","cost":40,"bonus":{"lifesteal":0.06,"regen":-0.5}},
 "heavy_barrel":{"name":"钨钢重型枪管","desc":"伤害+25%\n移速−12%","cost":42,"bonus":{"damage_mult":0.25,"speed_mult":-0.12}},
 "target_chip":{"name":"决斗索敌芯片","desc":"暴击+10%\n射程−15%","cost":34,"bonus":{"crit_rate":0.1,"range_mult":-0.15}},
 "field_rations":{"name":"高能战地口粮","desc":"生命+18 · 秒回+0.4\n伤害−8%","cost":32,"bonus":{"max_hp":18,"regen":0.4,"damage_mult":-0.08}},
 "carbon_mesh":{"name":"碳纤维战术网","desc":"闪避+8% · 移速+5%\n生命−15","cost":38,"bonus":{"dodge":0.08,"speed_mult":0.05,"max_hp":-15}},
 "flux_anchor":{"name":"磁通稳定锚","desc":"拾取+80\n移速−8%","cost":30,"bonus":{"pickup_radius":80,"speed_mult":-0.08}},
 "coolant":{"name":"低温冷却液","desc":"射速+15%\n伤害−8%","cost":30,"bonus":{"attack_mult":0.15,"damage_mult":-0.08}},
 "combat_sensor":{"name":"战损预警感应器","desc":"闪避+12%\n每次受击额外+2伤害","cost":42,"bonus":{"dodge":0.12,"hurt_extra":2}},
 "shock_liner":{"name":"震荡吸收内衬","desc":"护甲+15\n拾取−35","cost":35,"bonus":{"armor":15,"pickup_radius":-35}},
 "long_magazine":{"name":"延伸供弹链","desc":"实弹射速+22%\n移速−8%","cost":35,"bonus":{"ballistic_attack_mult":0.22,"speed_mult":-0.08}},
 "siphon":{"name":"异化吸收触须","desc":"吸血+10%\n全局伤害−15%","cost":45,"bonus":{"lifesteal":0.1,"damage_mult":-0.15}},
 "reactive_weave":{"name":"反应装甲织物","desc":"护甲+18\n闪避−8%","cost":38,"bonus":{"armor":18,"dodge":-0.08}},
 "hollow_shell":{"name":"空心高速弹壳","desc":"实弹射速+25%\n实弹伤害−15%","cost":34,"bonus":{"ballistic_attack_mult":0.25,"ballistic_damage_mult":-0.15}},
 "gamma_cells":{"name":"伽马能量电池","desc":"全局伤害+20%\n秒回−0.6","cost":38,"bonus":{"damage_mult":0.2,"regen":-0.6}},
 "med_reserve":{"name":"战地应急血库","desc":"生命+40\n治疗费用+25%","cost":38,"bonus":{"max_hp":40,"heal_cost_mult":0.25}},
 "lucky_circuit":{"name":"量子偏转电路","desc":"暴击+8% · 闪避+6%\n生命−15","cost":40,"bonus":{"crit_rate":0.08,"dodge":0.06,"max_hp":-15}},
 "magnet_core":{"name":"强磁聚矿核心","desc":"拾取+60 · 矿晶价值+10%\n射程−15%","cost":38,"bonus":{"pickup_radius":60,"harvesting":0.1,"range_mult":-0.15}},
 "kinetic_belt":{"name":"动能牵引腰带","desc":"移速+15%\n护甲−6","cost":30,"bonus":{"speed_mult":0.15,"armor":-6}},
 "optical_veil":{"name":"折光战术披风","desc":"闪避+15%\n伤害−12%","cost":45,"bonus":{"dodge":0.15,"damage_mult":-0.12}},
 "war_chest":{"name":"军需战备箱","desc":"每波补贴+18\n最大生命−12","cost":42,"bonus":{"wave_subsidy":18,"max_hp":-12}},
 "safety_limiter":{"name":"保险功率限制器","desc":"护甲+10 · 秒回+0.6\n射速−10%","cost":36,"bonus":{"armor":10,"regen":0.6,"attack_mult":-0.1}}
}
const LEVEL_CARDS := {
 "damage":{"name":"高密度弹药","desc":"全局伤害 +8%","rarity":0,"bonus":{"damage_mult":0.08}},
 "attack":{"name":"精密供弹","desc":"射速 +6%","rarity":0,"bonus":{"attack_mult":0.06}},
 "health":{"name":"战地体能","desc":"最大生命 +12，并恢复12点","rarity":0,"bonus":{"max_hp":12.0}},
 "armor":{"name":"陶瓷衬板","desc":"护甲 +4 点","rarity":0,"bonus":{"armor":4.0}},
 "crit":{"name":"弱点扫描","desc":"暴击率 +3%","rarity":0,"bonus":{"crit_rate":0.03}},
 "speed":{"name":"机动伺服","desc":"移速 +6%（上限170%）","rarity":0,"bonus":{"speed_mult":0.06}},
 "regen":{"name":"自愈凝胶","desc":"每秒生命恢复 +0.5","rarity":0,"bonus":{"regen":0.5}},
 "dodge":{"name":"紧急规避","desc":"闪避概率 +4%（上限50%）","rarity":0,"bonus":{"dodge":0.04}},
 "range":{"name":"校准瞄具","desc":"射程 +8%","rarity":0,"bonus":{"range_mult":0.08}},
 "lifesteal":{"name":"微粒回收","desc":"命中恢复1血概率 +3%","rarity":0,"bonus":{"lifesteal":0.03}},
 "ballistic":{"name":"实弹供弹链","desc":"实弹武器射速 +15%","rarity":1,"bonus":{"ballistic_attack_mult":0.15}},
 "magnet":{"name":"磁力回收器","desc":"拾取+50 · 矿晶价值+10%\n拾取20%概率额外超频点","rarity":1,"bonus":{"pickup_radius":50.0,"harvesting":0.1,"magnet_bonus":1.0}},
 "fortress":{"name":"堡垒协议","desc":"最大生命+18 · 护甲+6","rarity":1,"bonus":{"max_hp":18.0,"armor":6.0}},
 "focus":{"name":"战术聚焦","desc":"暴击+6% · 射程+12%","rarity":1,"bonus":{"crit_rate":0.06,"range_mult":0.12}},
 "extra_dash":{"name":"双冲刺协议","desc":"额外储存1次冲刺充能","rarity":2,"bonus":{"extra_dash":1.0}},
 "turret":{"name":"前哨自动炮台","desc":"获得随行自动防卫炮台","rarity":2,"bonus":{"turret":1.0}},
 "revive":{"name":"最后生机","desc":"一次致命伤保留1血\n并触发全屏击退","rarity":2,"bonus":{"revive":1.0}}
}

static func weapon_tags(id: String) -> Array:
 return TAGS.get(id, []).duplicate()

static func class_info(id: String) -> Dictionary:
 return {"name":CLASS_NAMES.get(id,CLASS_NAMES.marine),"desc":CLASS_DESCRIPTIONS.get(id,CLASS_DESCRIPTIONS.marine)}

static func new_run(class_id: String = "marine") -> Dictionary:
 if not CLASS_IDS.has(class_id): class_id = "marine"
 var starter: String = {"marine":"rifle","marauder":"shotgun","reaper":"reaper","firebat":"flame","ghost":"sniper"}[class_id]
 var s := {"class_id":class_id,"hp":100.0,"cash":35,"wave":0,"level":1,"xp":0,"xp_needed":15,"pending_levels":0,"items":[],"bonuses":{},"weapons":[{"id":starter,"level":1,"branch":"","cooldown":0.0,"paid":0,"uid":1}],"next_uid":2,"supports":[],"meta_bonuses":{},"mastery":{},"free_rerolls":0,"offers":[],"locks":[false,false,false,false],"reroll_cost":8,"level_offers":[],"level_rerolls":0,"pending_branch":-1,"revive_used":false,"total_earned":0}
 s.hp = recompute(s).max_hp
 return s

static func recompute(s: Dictionary) -> Dictionary:
 var cls: String = s.get("class_id","marine")
 var base := {"max_hp":100.0,"armor":0.0,"base_speed":215.0,"damage_mult":1.0,"attack_mult":1.0,"speed_mult":1.0,"pickup_radius":100.0,"regen":0.0,"crit_rate":0.05,"crit_mult":1.5,"lifesteal":0.0,"dodge":0.0,"range_mult":1.0,"harvesting":1.0,"ballistic_damage_mult":1.0,"ballistic_attack_mult":1.0,"pierce_bonus":0,"hurt_extra":0.0,"hurt_invuln":0.65,"heal_cost_mult":1.0,"wave_subsidy":0,"enemy_scale":1.0,"extra_dash":0,"turret":0,"revive":0,"magnet_bonus":0,"dash_cooldown":3.5,"salvage_rate":0.75,"free_shop_rerolls":0,"support_attack_mult":1.0,"engineering_shield":0.0,"rifle_branch_penalty":0.75}
 match cls:
  "marauder": base.max_hp=140.0; base.armor=50.0*0.15/0.85; base.base_speed=185.0; base.pickup_radius=120.0
  "reaper": base.max_hp=75.0; base.base_speed=245.0; base.dash_cooldown=2.4
  "firebat": base.max_hp=125.0; base.armor=50.0*0.10/0.90; base.base_speed=200.0
  "ghost": base.max_hp=85.0; base.base_speed=210.0; base.crit_rate=0.15; base.crit_mult=2.0
 for key in s.get("bonuses",{}):
  if base.has(key): base[key] += float(s.bonuses[key])
 for key in s.get("meta_bonuses",{}):
  if base.has(key): base[key] += float(s.meta_bonuses[key])
 var mastery: Dictionary=s.get("mastery",{})
 for item in s.get("items",[]):
  match str(item):
   "pump": base.speed_mult+=0.18; base.pickup_radius+=50; base.max_hp-=15.0-10.0*clampf(float(mastery.get("pump",0))/3.0,0,1)
   "core": base.ballistic_damage_mult+=0.30; base.pierce_bonus+=1
   "reactor": base.attack_mult+=0.25; base.hurt_extra+=4.0
   "exoskeleton": base.armor+=20.0; base.hurt_invuln=1.0; base.speed_mult-=0.1
   "nanobot": base.regen+=2.5; base.damage_mult-=0.12
   "scope": base.crit_rate+=0.15; base.range_mult+=0.20; base.pickup_radius-=40.0
   "tissue": base.lifesteal+=0.08; base.max_hp+=20.0; base.heal_cost_mult=1.5
   "storage": base.wave_subsidy+=25; base.enemy_scale=1.05
   "tripod","injector": pass # Conditional effects are applied in combat, never baked into saved stats.
  if ITEMS.has(item):
   for key in ITEMS[item].get("bonus",{}):
    if base.has(key): base[key]+=float(ITEMS[item].bonus[key])

   if ITEMS[item].has("crit_floor"): base.crit_mult=maxf(base.crit_mult,float(ITEMS[item].crit_floor))
 # The metabolic penalty wins over every source of invulnerability extension.
 if s.get("items",[]).has("crystal"): base.max_hp*=0.8
 if s.get("items",[]).has("metabolic"): base.hurt_invuln=minf(base.hurt_invuln,0.35)
 if s.get("items",[]).has("injector"): base.max_hp-=10
 if s.get("items",[]).has("core"): base.attack_mult*=1.0-(0.15-0.075*clampf(float(mastery.get("core",0))/3.0,0,1))
 base.rifle_branch_penalty=0.75+0.15*clampf(float(mastery.get("rifle",0))/3.0,0,1)
 var synergy := {"ballistic":0,"plasma":0,"explosive":0,"hightech":0,"engineering":0}
 for w in s.get("weapons",[]):
  for tag in weapon_tags(str(w.get("id",""))): synergy[tag] += 1
 for support in s.get("supports",[]):
  if SUPPORT_IDS.has(support): synergy.engineering+=1
 if synergy.engineering>=2: base.support_attack_mult+=0.25
 if synergy.engineering>=4: base.engineering_shield=30.0
 base.support_count=s.get("supports",[]).size()
 # Combat consumes counts and applies each synergy exactly once.
 base.synergies=synergy
 base.regen=maxf(0,base.regen)
 base.ballistic_damage_mult=maxf(0.1,base.ballistic_damage_mult)
 base.ballistic_attack_mult=maxf(0.15,base.ballistic_attack_mult)
 base.salvage_rate=clampf(base.salvage_rate,0.75,0.90)
 base.dash_cooldown=maxf(0.5,base.dash_cooldown)
 base.max_hp=maxf(1,base.max_hp)
 base.armor=maxf(0,base.armor)
 base.damage_mult=maxf(0.1,base.damage_mult)
 base.attack_mult=clampf(base.attack_mult,0.15,5.0)
 base.speed_mult=clampf(base.speed_mult,0.3,1.7)
 base.pickup_radius=clampf(base.pickup_radius,30,450)
 base.crit_rate=clampf(base.crit_rate,0,1)
 base.lifesteal=clampf(base.lifesteal,0,0.75)
 base.dodge=clampf(base.dodge,0,0.5)
 base.range_mult=clampf(base.range_mult,0.3,2.5)
 base.extra_dash=mini(1,int(base.extra_dash)); base.turret=mini(1,int(base.turret)); base.revive=mini(1,int(base.revive))
 return base

static func branch_names(id: String) -> Array:
 match id:
  "shotgun": return ["粉碎破片","震荡平推重弹"]
  "flame": return ["凝固地狱火","超低温冷焰"]
  "sniper": return ["反器材穿甲弹","猎杀弱点协议"]
  "grenade": return ["广域集束爆破","震撼榴霰弹"]
  "tesla": return ["过载连锁电网","强电压瘫痪"]
  "smg": return ["超频供弹组件","穿甲针刺弹匣"]
  "cannon": return ["聚焦热能长束","宽幅等离子扫荡"]
 return ["贫铀贯穿刺针","战术蓄力狙击"]

static func branch_descriptions(id: String) -> Array:
 match id:
  "shotgun": return ["12弹丸，扩散+30%；射程≤200，120内伤害翻倍","3枚重弹，强击退120；连带碰撞眩晕0.5秒"]
  "flame": return ["留下1.5秒焦土，每0.2秒伤害并点燃","范围减速40%，无限穿透；伤害−20%"]
  "sniper": return ["穿透4敌；伤害+25%，射速−15%","暴击+25%，暴伤+0.5；基础伤害−10%"]
  "grenade": return ["爆炸范围+40%；单发伤害−15%","爆炸击晕0.6秒；射速−20%"]
  "tesla": return ["连锁增加至7目标；单次伤害−15%","麻痹延长至0.8秒；连锁减少为3目标"]
  "smg": return ["射速+35%；伤害−15%","穿透+2，伤害+15%；射速−20%"]
  "cannon": return ["光束伤害+35%；宽度−35%","光束宽度+80%；伤害−20%"]
 return ["无限贯穿、射程+15%；伤害−25%，每穿透衰减10%最低40%","射程750，间隔0.85秒；伤害+240%，暴击+30%，击杀冲击波"]

static func _uid_index(s: Dictionary, uid: int) -> int:
 for i in range(s.weapons.size()):
  if int(s.weapons[i].get("uid",i+1)) == uid: return i
 return -1

static func _eligible(s: Dictionary, offer: Dictionary) -> bool:
 if offer.is_empty(): return false
 match str(offer.get("type","")):
  "weapon": return s.weapons.size() < 4 and WEAPON_IDS.has(offer.get("id",""))
  "support": return SUPPORT_IDS.has(offer.get("id","")) and not s.get("supports",[]).has(offer.get("id",""))
  "upgrade":
   var i := _uid_index(s,int(offer.get("uid",-1)))
   return i >= 0 and int(s.weapons[i].level) < 4 and int(s.weapons[i].level)==int(offer.get("from_level",-1))
  "item":
   var id: String = offer.get("id","")
   if not ITEMS.has(id) or s.items.has(id): return false
   var stats := recompute(s)
   if id=="pump" and (stats.max_hp<=15 or stats.speed_mult>=1.7 and stats.pickup_radius>=450): return false
   if id=="injector" and stats.max_hp<=10: return false
   if ITEMS[id].has("bonus"):
    var trial:=s.duplicate(true)
    trial.items.append(id)
    var after:=recompute(trial)
    var useful:=false
    for key in ITEMS[id].bonus:
     if key not in ["hurt_extra","heal_cost_mult","enemy_scale"] and float(ITEMS[id].bonus[key])>0 and float(after.get(key,0))>float(stats.get(key,0))+0.00001: useful=true
    if ITEMS[id].has("crit_floor") and after.crit_mult>stats.crit_mult: useful=true
    if not useful: return false
   return true
 return false

static func _pool(s: Dictionary) -> Array:
 var pool: Array = []
 var wv := int(s.get("wave",1))
 if s.weapons.size()<4:
  for id in WEAPON_IDS: pool.append({"type":"weapon","id":id,"cost":30+wv*3})
 for w in s.weapons:
  if int(w.level)<4:
   pool.append({"type":"upgrade","id":w.id,"uid":w.uid,"from_level":int(w.level),"cost":24+int(w.level)*22+wv*2})
 for id in SUPPORT_IDS:
  if not s.get("supports",[]).has(id): pool.append({"type":"support","id":id,"cost":SUPPORTS[id].cost+wv*2})
 for id in ITEM_IDS:
  var offer := {"type":"item","id":id,"cost":int(ITEMS[id].cost)+wv*2}
  if _eligible(s,offer): pool.append(offer)
 return pool

static func _same_offer(a: Dictionary,b: Dictionary) -> bool:
 return a.get("type","")==b.get("type","") and a.get("id","")==b.get("id","") and a.get("uid",-1)==b.get("uid",-1)

static func _draw_offer(pool: Array, chosen: Array, rng: RandomNumberGenerator) -> Dictionary:
 var available: Array = []
 for entry in pool:
  var duplicate := false
  for old in chosen:
   if _same_offer(entry,old): duplicate=true; break
  if not duplicate: available.append(entry)
 if available.is_empty(): return {}
 return available[rng.randi_range(0,available.size()-1)].duplicate(true)

static func roll_shop(s: Dictionary, rng: RandomNumberGenerator) -> void:
 var old: Array = s.get("offers",[])
 var locks: Array = s.get("locks",[false,false,false,false])
 locks.resize(4)
 var result: Array = [{},{},{},{}]
 var chosen: Array = []
 var pool := _pool(s)
 for i in range(4):
  if bool(locks[i]) and i<old.size() and _eligible(s,old[i]):
   result[i]=old[i].duplicate(true); chosen.append(result[i])
  else: locks[i]=false
 for i in range(4):
  if result[i].is_empty():
   result[i]=_draw_offer(pool,chosen,rng)
   if not result[i].is_empty(): chosen.append(result[i])
 s.offers=result; s.locks=locks

static func clean_offers(s: Dictionary) -> void:
 for i in range(s.offers.size()):
  if not _eligible(s,s.offers[i]):
   s.offers[i]={}
   if i<s.locks.size(): s.locks[i]=false

static func buy(s: Dictionary, index: int) -> Dictionary:
 var fail := {"ok":false,"reason":"商品不可购买","branch_slot":-1}
 if int(s.get("pending_branch",-1))>=0:
  fail.reason="请先完成武器专精"; return fail
 if index<0 or index>=s.offers.size(): return fail
 var offer: Dictionary=s.offers[index]
 if not _eligible(s,offer): return fail
 var cost := int(offer.get("cost",0))
 if int(s.cash)<cost:
  fail.reason="矿晶不足"; return fail
 var before_hp := float(recompute(s).max_hp)
 s.cash-=cost
 var branch_slot := -1
 match str(offer.type):
  "weapon":
   s.weapons.append({"id":offer.id,"level":1,"branch":"","cooldown":0.0,"paid":cost,"uid":int(s.next_uid)})
   s.next_uid+=1
  "upgrade":
   var i := _uid_index(s,int(offer.uid))
   s.weapons[i].level+=1; s.weapons[i].paid+=cost
   if int(s.weapons[i].level)==3:
    s.pending_branch=i; branch_slot=i
  "item": s.items.append(offer.id)
  "support":
   if not s.has("supports"): s.supports=[]
   s.supports.append(offer.id)
 var after_hp := float(recompute(s).max_hp)
 s.hp=clampf(float(s.hp)+maxf(0,after_hp-before_hp),1,after_hp)
 s.offers[index]={}; s.locks[index]=false
 clean_offers(s)
 return {"ok":true,"reason":"","branch_slot":branch_slot}

static func select_branch(s: Dictionary, slot: int, branch: String) -> bool:
 if slot!=int(s.get("pending_branch",-1)) or slot<0 or slot>=s.weapons.size() or not ["a","b"].has(branch): return false
 if int(s.weapons[slot].level)!=3 or not str(s.weapons[slot].branch).is_empty(): return false
 s.weapons[slot].branch=branch; s.pending_branch=-1
 return true

static func sell(s: Dictionary, slot: int) -> int:
 if int(s.get("pending_branch",-1))>=0 or slot<0 or slot>=s.weapons.size() or s.weapons.size()<=1: return -1
 # Never sell the last weapon: avoids an unwinnable empty-wallet run.
 var refund := int(floor(float(s.weapons[slot].paid)*0.5))
 s.weapons.remove_at(slot); s.cash+=refund
 clean_offers(s)
 return refund

static func toggle_lock(s: Dictionary,index: int) -> bool:
 if index<0 or index>=s.offers.size() or s.offers[index].is_empty(): return false
 s.locks[index]=not bool(s.locks[index]); return true

static func reroll_shop(s: Dictionary,rng: RandomNumberGenerator) -> bool:
 if int(s.get("pending_branch",-1))>=0 or (int(s.get("free_rerolls",0))<=0 and int(s.cash)<int(s.reroll_cost)): return false
 var unlocked := false
 for lock in s.locks:
  if not bool(lock): unlocked=true
 if not unlocked: return false
 if int(s.get("free_rerolls",0))>0: s.free_rerolls-=1
 else: s.cash-=int(s.reroll_cost); s.reroll_cost+=4
 roll_shop(s,rng)
 return true

static func begin_shop(s: Dictionary,rng: RandomNumberGenerator) -> void:
 s.reroll_cost=8
 roll_shop(s,rng)
 if int(s.pending_levels)>0 and s.level_offers.is_empty(): roll_level(s,rng)

static func _level_eligible(s: Dictionary,id: String) -> bool:
 var stats := recompute(s)
 match id:
  "speed": return stats.speed_mult<1.7
  "crit": return stats.crit_rate<1.0
  "dodge": return stats.dodge<0.5
  "range": return stats.range_mult<2.5
  "lifesteal": return stats.lifesteal<0.75
  "extra_dash","turret","revive": return float(s.bonuses.get(id,0))<1.0
  "focus": return stats.crit_rate<1.0 or stats.range_mult<2.5
  "magnet": return stats.pickup_radius<450.0 or stats.harvesting<3.0
 return true

static func roll_level(s: Dictionary,rng: RandomNumberGenerator) -> void:
 var selected: Array = []
 for slot in range(3):
  var chance := rng.randf()
  var rarity := 0 if chance<0.70 else (1 if chance<0.95 else 2)
  var pool: Array = []
  for id in LEVEL_CARDS:
   if int(LEVEL_CARDS[id].rarity)==rarity and not selected.has(id) and _level_eligible(s,id): pool.append(id)
  if pool.is_empty():
   for id in LEVEL_CARDS:
    if not selected.has(id) and _level_eligible(s,id): pool.append(id)
  if not pool.is_empty(): selected.append(pool[rng.randi_range(0,pool.size()-1)])
 s.level_offers=selected

static func level_reroll_cost(s: Dictionary) -> int:
 var n:=int(s.get("level_rerolls",0))
 return 0 if n==0 else (5 if n==1 else (10 if n==2 else -1))

static func reroll_level(s: Dictionary,rng: RandomNumberGenerator) -> bool:
 var cost:=level_reroll_cost(s)
 if int(s.pending_levels)<=0 or cost<0 or int(s.cash)<cost: return false
 s.cash-=cost; s.level_rerolls+=1
 roll_level(s,rng)
 return true

static func apply_level(s: Dictionary,index: int) -> bool:
 if int(s.pending_levels)<=0 or index<0 or index>=s.level_offers.size(): return false
 var id: String=s.level_offers[index]
 if not LEVEL_CARDS.has(id) or not _level_eligible(s,id): return false
 var old_hp:=float(recompute(s).max_hp)
 for key in LEVEL_CARDS[id].bonus:
  s.bonuses[key]=float(s.bonuses.get(key,0))+float(LEVEL_CARDS[id].bonus[key])
 var new_hp:=float(recompute(s).max_hp)
 s.hp=minf(new_hp,float(s.hp)+maxf(0,new_hp-old_hp))
 s.pending_levels-=1; s.level_offers=[]; s.level_rerolls=0
 return true

static func gain_xp(s: Dictionary,amount: int) -> void:
 s.xp+=maxi(0,amount)
 while int(s.xp)>=int(s.xp_needed):
  s.xp-=int(s.xp_needed); s.level+=1; s.pending_levels+=1
  s.xp_needed=15+int(s.level-1)*10

static func offer_label(offer: Dictionary) -> String:
 if offer.is_empty(): return "已售罄"
 var id: String=offer.get("id","")
 if offer.get("type","")=="support": return str(SUPPORTS.get(id,{}).get("name",id))
 if offer.get("type","")=="item": return str(ITEMS.get(id,{}).get("name",id))
 var prefix := "新装备 " if offer.get("type","")=="weapon" else "强化 "
 return prefix+str(WEAPON_NAMES.get(id,id))

static func offer_description(offer: Dictionary) -> String:
 if offer.is_empty(): return "刷新补给或进入下一波"
 var id: String=offer.get("id","")
 if offer.get("type","")=="support": return str(SUPPORTS.get(id,{}).get("desc",""))
 if offer.get("type","")=="item": return str(ITEMS.get(id,{}).get("desc",""))
 var tag_names: Array[String]=[]
 for tag in weapon_tags(id): tag_names.append(TAG_NAMES[tag])
 if offer.get("type","")=="upgrade":
  var next := int(offer.get("from_level",1))+1
  return "升级至 Lv.%d%s\n%s" % [next," · 选择专精" if next==3 else ""," / ".join(tag_names)]
 return "占用1个武器槽 · 可重复装备\n"+" / ".join(tag_names)
