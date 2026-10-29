extends RefCounted
## Choice-only progression. Archived content is never sold as implemented.
const Data = preload("res://scripts/data_v5.gd")
const START_WEAPONS = ["W01","W02","W03","W04","W05","W06","W07","W08"]
const START_SUPPORTS = ["S01","S02","S03","S04","S06"]
const START_TECHS = ["T01","T02","T03","T05","T08","T09","T10","T12","T14","T17"]
static func new_profile() -> Dictionary:
 return {"version":5,"research_data":0,"unlocked":{"classes":Data.ACTIVE_CLASSES.duplicate(),"weapons":START_WEAPONS.duplicate(),"supports":START_SUPPORTS.duplicate(),"techs":START_TECHS.duplicate()},"enabled":{"classes":Data.ACTIVE_CLASSES.duplicate(),"weapons":Data.ACTIVE_WEAPONS.duplicate(),"supports":Data.ACTIVE_SUPPORTS.duplicate(),"techs":Data.ACTIVE_TECHS.duplicate()},"reward_ids":[],"first_bosses":[],"run_rewards":{},"settings":{"large_font":false,"left_handed":false,"low_fx":false,"reduced_motion":false,"banter":true,"control_scale":1.0,"dash_offset":[0,0],"skill_offset":[0,0]},"compatibility_ack":false,"revision":0}
static func category(id:String)->String:
 if Data.CLASSES.has(id):return "classes"
 if Data.WEAPONS.has(id):return "weapons"
 if Data.SUPPORTS.has(id):return "supports"
 if Data.TECHS.has(id):return "techs"
 if Data.ITEMS.has(id):return "items"
 return ""
static func is_active(id:String)->bool:
 return id in Data.ACTIVE_CLASSES or id in Data.ACTIVE_WEAPONS or id in Data.ACTIVE_SUPPORTS or id in Data.ACTIVE_TECHS or id in Data.ACTIVE_ITEMS
static func is_unlocked(profile:Dictionary,id:String)->bool:
 if Data.ITEMS.has(id):return true
 return id in profile.get("unlocked",{}).get(category(id),[])
static func unlock(profile:Dictionary,id:String)->Dictionary:
 if category(id)=="":return {"ok":false,"reason":"无法识别的内容，未扣研究数据"}
 if not is_active(id):return {"ok":false,"reason":"完整设计档案：本验证切片尚未开放，暂不收费"}
 if is_unlocked(profile,id):return {"ok":false,"reason":"已解锁，无需重复付费"}
 var kind=category(id)
 var cost=20 if kind=="classes" else (5 if kind=="techs" else 10)
 if int(profile.get("research_data",0))<cost:return {"ok":false,"reason":"研究数据不足：还差%d"%(cost-int(profile.research_data))}
 profile.research_data-=cost
 profile.unlocked[kind].append(id)
 profile.enabled[kind].append(id)
 if kind=="classes":
  var starter=Data.CLASSES[id].starter
  if not starter in profile.unlocked.weapons:profile.unlocked.weapons.append(starter)
 return {"ok":true,"reason":"已解锁新选项，不增加永久属性"}
static func set_enabled(profile:Dictionary,id:String,enable:bool)->Dictionary:
 var kind=category(id)
 if not is_active(id) or not is_unlocked(profile,id):return {"ok":false,"reason":"该内容尚未开放"}
 if not kind in ["weapons","supports","techs"]:return {"ok":false,"reason":"此分类无需配置随机池"}
 var candidate:Dictionary=profile.enabled.duplicate(true)
 if enable:
  if not id in candidate[kind]:candidate[kind].append(id)
 else:candidate[kind].erase(id)
 for key in ["weapons","supports","techs"]:
  var minimum={"weapons":4,"supports":4,"techs":6}[key]
  if candidate[key].size()<minimum:return {"ok":false,"reason":"至少保留%d项%s"%[minimum,{"weapons":"武器","supports":"支援","techs":"科技"}[key]]}
 for cid in profile.unlocked.classes:
  if not is_active(cid):continue
  if not Data.CLASSES[cid].starter in candidate.weapons:return {"ok":false,"reason":"不能停用已开放职业的初始武器"}
  var legal=[]
  var adapted=[]
  for tid in candidate.techs:
   if tid in ["T01","T02","T03","T05","T12"] or (cid=="C06" and tid in ["T09","T10"]):legal.append(tid)
   if tid in {"C01":["T01","T02","T05"],"C03":["T02","T03","T05"],"C06":["T09","T10","T12"]}.get(cid,[]):adapted.append(tid)
  if legal.size()<3 or adapted.size()<2:return {"ok":false,"reason":"每职业需至少三项合法科技及两项适配科技"}
 profile.enabled=candidate
 return {"ok":true,"reason":"已保存启用池，下次出击生效"}
static func award(profile:Dictionary,run:Dictionary,wave:int,completed:bool=true)->Dictionary:
 if not completed or run.get("mode","campaign")!="campaign" or not wave in [4,8,12]:return {"ok":true,"reason":"未完成幕或训练不产研究数据","earned":0}
 var key=str(run.get("run_id",""))+":"+str(wave)
 if str(run.get("run_id","")).is_empty():return {"ok":false,"reason":"行动标识缺失，未发奖","earned":0}
 if key in profile.reward_ids:return {"ok":true,"reason":"已领取","earned":0}
 var earned=5
 var boss=str(wave)
 if not boss in profile.first_bosses:earned+=5
 var previous=int(profile.run_rewards.get(run.run_id,0))
 earned=mini(earned,maxi(0,30-previous))
 profile.research_data+=earned
 profile.reward_ids.append(key)
 if not boss in profile.first_bosses:profile.first_bosses.append(boss)
 profile.run_rewards[run.run_id]=previous+earned
 return {"ok":true,"reason":"完成幕奖励5＋首次首领奖励（如适用）","earned":earned}
