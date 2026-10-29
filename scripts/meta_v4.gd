extends RefCounted
## Local campaign metaprogression. Amounts/costs not supplied by the brief are
## explicit prototype supplements. Rewards are once per run/wave, never per load.
const PATH := "user://starfront_meta_v4.json"
const TECH_IDS := ["health","regen","dash","armor","damage","antenna","salvage","magnet","crit","support"]
const TECH := {
 "health":{"name":"强化骨骼外甲","desc":"每级生命+6；最高+30","max":5,"cost":18,"step":12,"bonus":{"max_hp":6.0}},
 "regen":{"name":"生化反应药剂","desc":"每级秒回+0.3；最高+1.5","max":5,"cost":20,"step":14,"bonus":{"regen":0.3}},
 "dash":{"name":"战术喷气背包","desc":"每级冲刺冷却−5%；最高−25%","max":5,"cost":20,"step":14,"bonus":{}},
 "armor":{"name":"新柯隆装甲","desc":"每级护甲+2；最高+10","max":5,"cost":18,"step":12,"bonus":{"armor":2.0}},
 "damage":{"name":"电磁线圈超频","desc":"每级伤害+3%；最高+15%","max":5,"cost":22,"step":16,"bonus":{"damage_mult":0.03}},
 "antenna":{"name":"战术通信天线","desc":"每级每局免费商店刷新+1；最高2次","max":2,"cost":45,"step":35,"bonus":{"free_shop_rerolls":1.0}},
 "salvage":{"name":"折损挽回","desc":"每级回收率+3%；最高90%","max":5,"cost":20,"step":14,"bonus":{"salvage_rate":0.03}},
 "magnet":{"name":"磁场搜集阵列","desc":"补充设计：每级拾取+10；最高+50","max":5,"cost":16,"step":10,"bonus":{"pickup_radius":10.0}},
 "crit":{"name":"弱点解析芯片","desc":"补充设计：每级暴击+1%；最高+5%","max":5,"cost":20,"step":14,"bonus":{"crit_rate":0.01}},
 "support":{"name":"工程协调网络","desc":"补充设计：每级支援射速+3%；最高+15%","max":5,"cost":18,"step":12,"bonus":{"support_attack_mult":0.03}}
}
const MASTERY_IDS := ["core","pump","rifle"]
const MASTERY := {
 "core":{"name":"贫铀硬芯精研","desc":"三星：射速惩罚−15%减至−7.5%","cost":12,"step":10},
 "pump":{"name":"SCV增压泵精研","desc":"三星：生命扣除15减至5","cost":12,"step":10},
 "rifle":{"name":"磁轨步枪精研","desc":"三星：贯穿单发惩罚−25%减至−10%","cost":15,"step":12}
}

static func new_profile() -> Dictionary:
 return {"version":4,"gas":0,"genes":0,"tech":{},"mastery":{},"claimed":{},"wins":0,"best_wave":0,"last_death":"","last_dialogue":""}

static func _integer_value(value: Variant,low: int,high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=low and float(value)<=high

static func valid(p: Variant) -> bool:
 if not p is Dictionary or int(p.get("version",0))!=4: return false
 for key in ["gas","genes","wins","best_wave"]:
  if not p.has(key) or not _integer_value(p[key],0,1000000000): return false
 for key in ["tech","mastery","claimed"]:
  if not p.get(key) is Dictionary: return false
 for id in p.tech:
  if not TECH.has(id) or not _integer_value(p.tech[id],0,int(TECH[id].max)): return false
 for id in p.mastery:
  if not MASTERY.has(id) or not _integer_value(p.mastery[id],0,3): return false
 for id in p.claimed:
  if not id is String or id.length()>160 or not p.claimed[id] is Dictionary: return false
  var rec: Dictionary=p.claimed[id]
  if not _integer_value(rec.get("wave",-1),0,30) or not rec.get("won",false) is bool: return false
 return true

static func save_profile(profile: Dictionary, path: String = PATH) -> bool:
 if not valid(profile): return false
 var payload:=JSON.stringify(profile)
 var envelope:=JSON.stringify({"payload":payload,"sha256":payload.sha256_text()})
 var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null: return false
 f.store_string(envelope); f.flush(); f.close()
 if _read(path+".tmp").is_empty(): return false
 # Only rotate a previously verified main file, never overwrite a good backup
 # with a corrupted primary.
 if FileAccess.file_exists(path) and not _read(path).is_empty():
  if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(path+".bak")
  if DirAccess.copy_absolute(path,path+".bak")!=OK: return false
 return DirAccess.rename_absolute(path+".tmp",path)==OK

static func _read(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var f:=FileAccess.open(path,FileAccess.READ)
 if f==null or f.get_length()>8000000: return {}
 var parser:=JSON.new()
 var error:=parser.parse(f.get_as_text()); f.close()
 if error!=OK: return {}
 var e=parser.data
 if not e is Dictionary or not e.get("payload") is String or not e.get("sha256") is String: return {}
 if str(e.payload).sha256_text()!=str(e.sha256): return {}
 var data_parser:=JSON.new()
 if data_parser.parse(e.payload)!=OK: return {}
 var p=data_parser.data
 if not valid(p): return {}
 for key in ["version","gas","genes","wins","best_wave"]: p[key]=int(p[key])
 for key in ["tech","mastery"]:
  for id in p[key]: p[key][id]=int(p[key][id])
 for id in p.claimed: p.claimed[id].wave=int(p.claimed[id].wave)
 return p

static func load_profile(path: String = PATH) -> Dictionary:
 var p:=_read(path)
 if not p.is_empty(): return p
 p=_read(path+".bak")
 return p if not p.is_empty() else new_profile()

static func tech_cost(profile: Dictionary,id: String) -> int:
 if not TECH.has(id): return -1
 var level:=int(profile.get("tech",{}).get(id,0))
 return -1 if level>=int(TECH[id].max) else int(TECH[id].cost)+level*int(TECH[id].step)

static func mastery_cost(profile: Dictionary,id: String) -> int:
 if not MASTERY.has(id): return -1
 var level:=int(profile.get("mastery",{}).get(id,0))
 return -1 if level>=3 else int(MASTERY[id].cost)+level*int(MASTERY[id].step)

static func buy_tech(profile: Dictionary,id: String) -> bool:
 var cost:=tech_cost(profile,id)
 if cost<0 or int(profile.get("gas",0))<cost: return false
 profile.gas-=cost; profile.tech[id]=int(profile.tech.get(id,0))+1
 profile.last_dialogue="antenna" if id=="antenna" else ("health_max" if id=="health" and int(profile.tech[id])==5 else "research")
 return true

static func buy_mastery(profile: Dictionary,id: String) -> bool:
 var cost:=mastery_cost(profile,id)
 if cost<0 or int(profile.get("genes",0))<cost: return false
 profile.genes-=cost; profile.mastery[id]=int(profile.mastery.get(id,0))+1
 profile.last_dialogue="mastery"
 return true

static func start_run(profile: Dictionary,build: Dictionary) -> Dictionary:
 var bonuses: Dictionary={}
 for id in TECH_IDS:
  var level:=clampi(int(profile.get("tech",{}).get(id,0)),0,int(TECH[id].max))
  for key in TECH[id].bonus: bonuses[key]=float(bonuses.get(key,0))+float(TECH[id].bonus[key])*level
 var base_cd:=2.4 if build.get("class_id","")=="reaper" else 3.5
 bonuses.dash_cooldown=-base_cd*0.05*clampi(int(profile.get("tech",{}).get("dash",0)),0,5)
 build.meta_bonuses=bonuses
 build.mastery=profile.get("mastery",{}).duplicate(true)
 build.free_rerolls=int(bonuses.get("free_shop_rerolls",0))
 return build

static func reward(profile: Dictionary,run_id: String,wave: int,victory: bool=false) -> Dictionary:
 var out:={"ok":false,"gas":0,"genes":0}
 if run_id.is_empty() or run_id.length()>160 or wave<1 or wave>30: return out
 if not profile.has("claimed"): profile.claimed={}
 var rec: Dictionary=profile.claimed.get(run_id,{"wave":0,"won":false})
 # No skipped-wave backpay. Replaying an old checkpoint cannot farm rewards.
 if wave>int(rec.wave):
  out.gas=3+2*int((wave-1)/10)
  out.genes=1
  if wave%10==0: out.gas+=12; out.genes+=6
  rec.wave=wave
 if victory and wave==30 and not bool(rec.won):
  out.gas+=25; out.genes+=12; rec.won=true; profile.wins=int(profile.get("wins",0))+1
 if int(out.gas)>0 or int(out.genes)>0:
  profile.gas=int(profile.get("gas",0))+int(out.gas)
  profile.genes=int(profile.get("genes",0))+int(out.genes)
  profile.best_wave=maxi(int(profile.get("best_wave",0)),wave)
  profile.claimed[run_id]=rec; out.ok=true
 return out
