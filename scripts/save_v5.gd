extends RefCounted
## Independent v5 saves: never edits v2/v4 saves. Validated atomic checkpoints.
const Data=preload("res://scripts/data_v5.gd")
const Meta=preload("res://scripts/meta_v5.gd")
const RUN_PATH="user://run_v5.json"
const PROFILE_PATH="user://profile_v5.json"
const MAX_BYTES=4000000
static func _result(ok:bool,reason:String="")->Dictionary:return {"ok":ok,"reason":reason}
static func _safe(v:Variant,depth:int=0)->bool:
 if depth>20:return false
 match typeof(v):
  TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_STRING_NAME:return true
  TYPE_INT:return absi(v)<=9007199254740991
  TYPE_FLOAT:return is_finite(v) and absf(v)<=9007199254740991.0
  TYPE_ARRAY:
   if v.size()>10000:return false
   for x in v:
    if not _safe(x,depth+1):return false
   return true
  TYPE_DICTIONARY:
   if v.size()>10000:return false
   for k in v:
    if not (k is String or k is StringName) or not _safe(v[k],depth+1):return false
   return true
 return false
static func _integer(v:Variant,lo:int,hi:int)->bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=lo and v<=hi
static func _rng_string(value:Variant)->bool:
 if not value is String or not value.is_valid_int():return false
 var unsigned=value.trim_prefix("-")
 var maximum="9223372036854775808" if value.begins_with("-") else "9223372036854775807"
 if unsigned.length()>19 or (unsigned.length()==19 and unsigned>maximum):return false
 return str(int(value))==value
static func validate_run(r:Dictionary)->bool:
 if not _safe(r) or int(r.get("version",0))!=5:return false
 for key in ["run_id","class_id","wave","hp","cash","gas","level","xp","weapons","supports","techs","items","bonuses","shop","pending_levels","pending_research","rng_seed","rng_state","rescue_spent","reward_ids"]:
  if not r.has(key):return false
 if not r.run_id is String or r.run_id.is_empty() or not Data.CLASSES.has(r.class_id):return false
 if not _integer(r.wave,1,12) or not _integer(r.cash,0,100000000) or not _integer(r.gas,0,100000) or not _integer(r.level,1,10000) or not _integer(r.xp,0,10000000):return false
 if not (r.hp is float or r.hp is int) or r.hp<0 or r.hp>100000:return false
 if not r.rescue_spent is bool or not r.bonuses is Dictionary or not r.reward_ids is Array:return false
 if not _rng_string(r.rng_state) or not _rng_string(r.rng_seed):return false
 if r.has("combat_rng_state") and not _rng_string(r.combat_rng_state):return false
 if not r.get("phase","wave") in ["wave","shop","result","ended"]:return false
 if not r.pending_research is bool or not _integer(r.pending_levels,0,100):return false
 if not r.get("level_choices",[]) is Array or not r.get("research_choices",[]) is Array:return false
 if not r.get("mode","campaign") in ["campaign","pressure","boss","training","boss_test"]:return false
 if not _integer(r.get("debt",0),0,1000000):return false
 for cid in r.get("level_choices",[]):
  if not cid in ["health","damage","attack","armor","engineering","pickup","cash"]:return false
 if not r.weapons is Array or r.weapons.size()>4:return false
 var seen=[]
 var counts={}
 for w in r.weapons:
  if not w is Dictionary or not Data.WEAPONS.has(w.get("id","")):return false
  if not _integer(w.get("uid",-1),0,10000000) or w.uid in seen:return false
  seen.append(w.uid);counts[w.id]=int(counts.get(w.id,0))+1
  if counts[w.id]>2:return false
  if not _integer(w.get("level",0),1,3) or not w.get("branch","") in ["","A","B"] or not _integer(w.get("invested",-1),0,10000000):return false
  if (w.level==3 and w.branch=="") or (w.level<3 and w.branch!=""):return false
 for pair in [["supports",Data.SUPPORTS,2],["techs",Data.TECHS,3]]:
  if not r[pair[0]] is Array or r[pair[0]].size()>pair[2]:return false
  seen=[]
  for id in r[pair[0]]:
   if not pair[1].has(id) or id in seen:return false
   seen.append(id)
 if not r.items is Dictionary or r.items.size()>12:return false
 for id in r.items:
  if not Data.ITEMS.has(id) or not _integer(r.items[id],1,int(Data.ITEMS[id].get("max",Data.ITEMS[id].get("cap",2)))):return false
 if not r.shop is Array or r.shop.size()>4:return false
 for offer in r.shop:
  if not offer is Dictionary:return false
  if offer.is_empty():continue
  var table={"weapon":Data.WEAPONS,"support":Data.SUPPORTS,"item":Data.ITEMS}.get(offer.get("kind",""),{})
  if offer.get("id","")=="" and offer.get("bought",false):continue
  if not table.has(offer.get("id","")):return false
  if not offer.get("locked",false) is bool or not offer.get("bought",false) is bool:return false
 seen=[]
 for tid in r.get("research_choices",[]):
  if not Data.TECHS.has(tid) or tid in seen:return false
  seen.append(tid)
 return true
static func validate_profile(p:Dictionary)->bool:
 if not _safe(p) or int(p.get("version",0))!=5 or not _integer(p.get("research_data",-1),0,100000000):return false
 for k in ["unlocked","enabled","settings","run_rewards"]:
  if not p.get(k) is Dictionary:return false
 for k in ["reward_ids","first_bosses"]:
  if not p.get(k) is Array:return false
 for id in p.reward_ids:
  if not id is String:return false
 for id in p.first_bosses:
  if not id in ["4","8","12"]:return false
 for id in p.run_rewards:
  if not _integer(p.run_rewards[id],0,30):return false
 for group in ["unlocked","enabled"]:
  for kind in ["classes","weapons","supports","techs"]:
   if not p[group].get(kind) is Array:return false
   var table={"classes":Data.CLASSES,"weapons":Data.WEAPONS,"supports":Data.SUPPORTS,"techs":Data.TECHS}[kind]
   var seen=[]
   for id in p[group][kind]:
    if not table.has(id) or id in seen:return false
    seen.append(id)
    if group=="enabled" and not id in p.unlocked[kind]:return false
 return true
static func _decode(path:String,kind:String)->Dictionary:
 if not FileAccess.file_exists(path):return {}
 var f=FileAccess.open(path,FileAccess.READ)
 if f==null or f.get_length()>MAX_BYTES:return {}
 var parser=JSON.new();var parse_error=parser.parse(f.get_as_text());f.close()
 if parse_error!=OK:return {}
 var e=parser.data
 if not e is Dictionary or e.get("format","")!="starfront-v5" or not e.get("payload") is String:return {}
 if e.payload.sha256_text()!=e.get("sha256",""):return {}
 var decoded=JSON.new()
 if decoded.parse(e.payload)!=OK:return {}
 var d=decoded.data
 if not d is Dictionary:return {}
 if kind=="run" and not validate_run(d):return {}
 if kind=="profile" and not validate_profile(d):return {}
 if kind=="rescue" and (not d.get("spent",false) or not d.get("run_id") is String):return {}
 return d
static func _write(d:Dictionary,path:String,kind:String)->Dictionary:
 if not _safe(d):return _result(false,"存档包含不支持的数据，原档未替换")
 var full=ProjectSettings.globalize_path(path)
 if DirAccess.make_dir_recursive_absolute(full.get_base_dir())!=OK:return _result(false,"无法建立存档目录，请重试")
 var payload=JSON.stringify(d,"",true,true)
 if payload.to_utf8_buffer().size()>MAX_BYTES:return _result(false,"存档过大，未替换原档")
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return _result(false,"保存失败，请重试；不能离开整备")
 f.store_string(JSON.stringify({"format":"starfront-v5","payload":payload,"sha256":payload.sha256_text()}));f.flush()
 var err=f.get_error();f.close()
 if err!=OK or _decode(path+".tmp",kind).is_empty():return _result(false,"临时存档校验失败，原档保留")
 if not _decode(path,kind).is_empty():
  if DirAccess.copy_absolute(full,full+".bak.tmp")!=OK:return _result(false,"备份失败，原档保留；请重试")
  if DirAccess.rename_absolute(full+".bak.tmp",full+".bak")!=OK:return _result(false,"备份替换失败，原档保留；请重试")
 if DirAccess.rename_absolute(full+".tmp",full)!=OK:return _result(false,"保存替换失败，原档保留；请重试")
 return _result(true,"已保存")
static func save_run(r:Dictionary,path:String=RUN_PATH)->Dictionary:
 if not validate_run(r):return _result(false,"内容版本或装备无法识别；原存档保留，不能离开整备")
 if r.rescue_spent:
  var rescue=save_rescue(r,path)
  if not rescue.ok:return rescue
 return _write(r,path,"run")
static func _load(path:String,kind:String)->Dictionary:
 var d=_decode(path,kind)
 if not d.is_empty():return {"ok":true,"run":d,"reason":"","recovered":false}
 d=_decode(path+".bak",kind)
 if not d.is_empty():return {"ok":true,"run":d,"reason":"主存档异常，已恢复上一份有效快照","recovered":true}
 return {"ok":false,"run":{},"reason":"存档损坏或内容版本不兼容；原档仍保留" if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak") else "暂无v5存档","recovered":false}
static func load_run(path:String=RUN_PATH)->Dictionary:
 var result=_load(path,"run")
 if result.ok:
  var spent=_decode(path+".rescue","rescue")
  if spent.is_empty():spent=_decode(path+".rescue.bak","rescue")
  if not spent.is_empty() and spent.run_id==result.run.run_id:result.run.rescue_spent=true
  elif FileAccess.file_exists(path+".rescue") and _decode(path+".rescue","rescue").is_empty():
   result.run.rescue_spent=true;result.reason+="；救命记录异常，按已使用保守恢复";result.recovered=true
  if result.recovered:result.reason+="（第%d波%s）"%[result.run.wave,"整备" if result.run.get("phase","")=="shop" else "波前"]
 return result
static func save_wave_start(r:Dictionary,path:String=RUN_PATH)->Dictionary:
 var snapshot=r.duplicate(true);snapshot.phase="wave"
 return save_run(snapshot,path)
static func save_rescue(r:Dictionary,path:String=RUN_PATH)->Dictionary:
 if not r.get("rescue_spent",false):return _result(true,"未消耗救命")
 var old=_decode(path+".rescue","rescue")
 if old.get("run_id","")==r.get("run_id",""):return _result(true,"救命消耗已记录")
 return _write({"run_id":str(r.get("run_id","")),"spent":true},path+".rescue","rescue")
static func restore_wave(path:String=RUN_PATH)->Dictionary:return load_run(path)
static func get_compatibility_notice()->String:
 for old in ["user://run_v2.json","user://starfront_meta_v4.json","user://profile_v4.json"]:
  if FileAccess.file_exists(old):return "检测到旧版档案：已原样保留。v5使用独立新档案，旧装备、资源、永久属性与精研不导入；旧版行动不能直接续玩。"
 return "v5使用独立档案；局外研究数据只解锁选择，不增加永久属性。"
static func save_profile(p:Dictionary,path:String=PROFILE_PATH)->Dictionary:
 if p.has("load_error"):return _result(false,"档案异常尚未处理，拒绝覆盖原档")
 if not validate_profile(p):return _result(false,"研究档案无效，原档保留")
 var clean=p.duplicate(true)
 for k in ["recovered","notice"]:clean.erase(k)
 clean.revision=int(p.get("revision",0))+1
 # Independent verified ledger protects claimed rewards across main/backup recovery.
 var ledger=_write(clean,path+".ledger","profile")
 if not ledger.ok:return ledger
 var result=_write(clean,path,"profile")
 if result.ok:p.revision=clean.revision
 return result
static func load_profile(path:String=PROFILE_PATH)->Dictionary:
 var normal=_load(path,"profile")
 var ledger=_load(path+".ledger","profile")
 if ledger.ok and (not normal.ok or int(ledger.run.get("revision",0))>int(normal.run.get("revision",0))):
  var p:Dictionary=ledger.run;p.recovered=true;p.notice="研究主档异常，已恢复最新结算记录";return p
 if normal.ok:
  normal.run.recovered=normal.recovered;normal.run.notice=normal.reason;return normal.run
 if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak") or FileAccess.file_exists(path+".ledger"):
  return {"version":5,"load_error":"研究档案损坏，未创建替代档案；请保留原档并恢复备份"}
 return Meta.new_profile()
static func clear_run(path:String=RUN_PATH)->Dictionary:
 for suffix in ["",".bak",".tmp",".bak.tmp",".rescue",".rescue.bak",".rescue.tmp",".rescue.bak.tmp"]:
  var p=ProjectSettings.globalize_path(path+suffix)
  if FileAccess.file_exists(p) and DirAccess.remove_absolute(p)!=OK:return _result(false,"无法清除本次v5行动，请重试")
 return _result(true,"本次v5行动已放弃；局外和旧档未删除")
