extends RefCounted
## v5 reference content. Inactive entries are archive-only, not a full campaign claim.
const CLASSES = {
 "C01": {
  "id": "C01",
  "name": "泰隆·陆战队员",
  "desc": "100／0／215／5%\n被动：实弹武器攻速+10%，不影响装置。兴奋剂 CD12秒：支付当前生命12%，最低扣1且生命不低于1；5秒攻速+35%、移速+15%。期间再次施放不可叠加\nW01；T01治疗循环、T02盾牌；低血装备需承担生命成本\n对战／战役：兴奋剂消耗生命换射速与机动；此处数值原创",
  "source": "对战／战役：兴奋剂消耗生命换射速与机动；此处数值原创",
  "icon": "C01",
  "description_key": "C01.description",
  "reference_only": false,
  "hp": 100,
  "armor": 0,
  "speed": 215,
  "crit": 0.05,
  "starter": "W01",
  "skill_cd": 12,
  "skill_name": "兴奋剂",
  "benefit": "被动：实弹武器攻速+10%，不影响装置。兴奋剂 CD12秒：支付当前生命12%，最低扣1且生命不低于1；5秒攻速+35%、移速+15%。期间再次施放不可叠加",
  "cost": 0
 },
 "C02": {
  "id": "C02",
  "name": "“壁垒”·劫掠者",
  "desc": "135／10／190／5%\n被动：爆破直接命中使目标减速20%持续1秒。震荡弹 CD10秒：目标点120u爆炸，70伤害并减速40%持续2秒\nW03；T05破甲、T08震撼；不适合靠高攻速触发\n对战：震撼弹减速；范围主动是改编",
  "source": "对战：震撼弹减速；范围主动是改编",
  "icon": "C02",
  "description_key": "C02.description",
  "reference_only": true,
  "hp": 135,
  "armor": 10,
  "speed": 190,
  "crit": 0.05,
  "starter": "W03",
  "skill_cd": 10,
  "skill_name": "震荡弹",
  "benefit": "被动：爆破直接命中使目标减速20%持续1秒。震荡弹 CD10秒：目标点120u爆炸，70伤害并减速40%持续2秒",
  "cost": 0
 },
 "C03": {
  "id": "C03",
  "name": "“火花”·死神",
  "desc": "80／0／245／5%\n被动：4秒未受外部伤害后每秒回复2生命。KD8 CD8秒：前方／标记处投雷，0.8秒后90u爆炸，55伤害、击退60u\nW02；冲刺CD基础3.2秒，T03机动、T20冲刺；地面持续伤害压制脱战恢复\n对战死神恢复、KD8；按冲刺改编喷射背包",
  "source": "对战死神恢复、KD8；按冲刺改编喷射背包",
  "icon": "C03",
  "description_key": "C03.description",
  "reference_only": false,
  "hp": 80,
  "armor": 0,
  "speed": 245,
  "crit": 0.05,
  "starter": "W02",
  "skill_cd": 8,
  "skill_name": "KD8投雷",
  "benefit": "被动：4秒未受外部伤害后每秒回复2生命。KD8 CD8秒：前方／标记处投雷，0.8秒后90u爆炸，55伤害、击退60u",
  "cost": 0
 },
 "C04": {
  "id": "C04",
  "name": "“熔炉”·火蝠",
  "desc": "125／8／200／5%\n被动：热能直接命中附加燃烧，每秒为该次未暴击伤害20%。燃料喷射 CD12秒：朝向前方140u扇区留下3秒焦土，每秒25伤害；自身在焦土不受伤但移速-10%\nW04；T04燃料、T06攻城；不提供死亡后才有收益的被动\n战役火蝠喷火／升级；焦土主动原创",
  "source": "战役火蝠喷火／升级；焦土主动原创",
  "icon": "C04",
  "description_key": "C04.description",
  "reference_only": true,
  "hp": 125,
  "armor": 8,
  "speed": 200,
  "crit": 0.05,
  "starter": "W04",
  "skill_cd": 12,
  "skill_name": "燃料喷射",
  "benefit": "被动：热能直接命中附加燃烧，每秒为该次未暴击伤害20%。燃料喷射 CD12秒：朝向前方140u扇区留下3秒焦土，每秒25伤害；自身在焦土不受伤但移速-10%",
  "cost": 0
 },
 "C05": {
  "id": "C05",
  "name": "“夜莺”·幽灵",
  "desc": "85／0／210／12%\n被动：对集火标记目标直接伤害+10%。战术隐形 CD14秒：2秒不被普通索敌选中，既有弹丸、碰撞、地面伤害仍有效；期间第一发精密武器伤害+60%后结束隐形\nW05；T13EMP、T14狙击；没有精密武器仍可隐形脱困，开局保证精密武器\n对战／战役幽灵与诺娃隐形题材；短隐形与标记为改编",
  "source": "对战／战役幽灵与诺娃隐形题材；短隐形与标记为改编",
  "icon": "C05",
  "description_key": "C05.description",
  "reference_only": true,
  "hp": 85,
  "armor": 0,
  "speed": 210,
  "crit": 0.12,
  "starter": "W05",
  "skill_cd": 14,
  "skill_name": "战术隐形",
  "benefit": "被动：对集火标记目标直接伤害+10%。战术隐形 CD14秒：2秒不被普通索敌选中，既有弹丸、碰撞、地面伤害仍有效；期间第一发精密武器伤害+60%后结束隐形",
  "cost": 0
 },
 "C06": {
  "id": "C06",
  "name": "“铆钉”·工程兵",
  "desc": "105／5／205／5%\n被动：工程倍率+15%。部署炮台 CD10秒：脚下生成60生命、持续12秒炮台，射程350u、10伤害×3发/秒，最多2座；第三座回收最旧炮台且不返资源\nW07；T09双工、T10修复、T12矩阵；召唤多但本人清场弱\n对战渡鸦炮台、合作斯旺机械作战；便携部署与容量原创",
  "source": "对战渡鸦炮台、合作斯旺机械作战；便携部署与容量原创",
  "icon": "C06",
  "description_key": "C06.description",
  "reference_only": false,
  "hp": 105,
  "armor": 5,
  "speed": 205,
  "crit": 0.05,
  "starter": "W07",
  "skill_cd": 10,
  "skill_name": "部署炮台",
  "benefit": "被动：工程倍率+15%。部署炮台 CD10秒：脚下生成60生命、持续12秒炮台，射程350u、10伤害×3发/秒，最多2座；第三座回收最旧炮台且不返资源",
  "cost": 0
 }
}
const WEAPONS = {
 "W01": {
  "id": "W01",
  "name": "C-14刺针步枪",
  "desc": "60；9×4；480u\n穿透弹：穿透3目标，每次后续命中伤害×0.8；基础伤害-15%\n超频供弹：攻速+45%；连续射击3秒后停火0.6秒\n陆战队步枪；A清群、B兴奋剂；非原版同名升级",
  "source": "陆战队步枪；A清群、B兴奋剂；非原版同名升级",
  "icon": "W01",
  "description_key": "W01.description",
  "reference_only": false,
  "tags": [
   "实弹"
  ],
  "cost": 60,
  "damage": 9,
  "rate": 4,
  "range": 480,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W01A",
    "name": "穿透弹",
    "desc": "穿透弹：穿透3目标，每次后续命中伤害×0.8；基础伤害-15%"
   },
   "B": {
    "id": "W01B",
    "name": "超频供弹",
    "desc": "超频供弹：攻速+45%；连续射击3秒后停火0.6秒"
   }
  },
  "benefit": "60；9×4；480u",
  "penalty": "终阶分支各有代价"
 },
 "W02": {
  "id": "W02",
  "name": "死神双枪",
  "desc": "60；6×6；340u\n走射：移动时伤害+25%；站定伤害-15%\n爆破弹匣：每第12发生成一次60%基础伤害、60u爆炸；射速-15%\n死神双枪；T03／T08；爆炸是次级事件",
  "source": "死神双枪；T03／T08；爆炸是次级事件",
  "icon": "W02",
  "description_key": "W02.description",
  "reference_only": false,
  "tags": [
   "实弹",
   "机动"
  ],
  "cost": 60,
  "damage": 6,
  "rate": 6,
  "range": 340,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W02A",
    "name": "走射",
    "desc": "走射：移动时伤害+25%；站定伤害-15%"
   },
   "B": {
    "id": "W02B",
    "name": "爆破弹匣",
    "desc": "爆破弹匣：每第12发生成一次60%基础伤害、60u爆炸；射速-15%"
   }
  },
  "benefit": "60；6×6；340u",
  "penalty": "终阶分支各有代价"
 },
 "W03": {
  "id": "W03",
  "name": "劫掠者榴弹",
  "desc": "75；25×1.5；430u，爆炸50u\n穿甲弹：对重甲+40%、忽略10护甲；爆炸半径-30%\n震荡榴弹：半径+40%、减速25%1秒；伤害-20%\n劫掠者榴弹；T05／T08；A不等于真实伤害",
  "source": "劫掠者榴弹；T05／T08；A不等于真实伤害",
  "icon": "W03",
  "description_key": "W03.description",
  "reference_only": false,
  "tags": [
   "爆破"
  ],
  "cost": 75,
  "damage": 25,
  "rate": 1.5,
  "range": 430,
  "radius": 50,
  "branches": {
   "A": {
    "id": "W03A",
    "name": "穿甲弹",
    "desc": "穿甲弹：对重甲+40%、忽略10护甲；爆炸半径-30%"
   },
   "B": {
    "id": "W03B",
    "name": "震荡榴弹",
    "desc": "震荡榴弹：半径+40%、减速25%1秒；伤害-20%"
   }
  },
  "benefit": "75；25×1.5；430u，爆炸50u",
  "penalty": "终阶分支各有代价"
 },
 "W04": {
  "id": "W04",
  "name": "火蝠喷焰器",
  "desc": "65；每次8×4；180u、60°扇形\n地狱火：范围内目标附3秒燃烧，每秒为单次基础伤害40%；直接伤害-15%\n压缩火舌：射程+70%、扇角变25°；直接伤害+10%\n战役火蝠；T04；不套用恶火的原版升级名，B损失横向覆盖",
  "source": "战役火蝠；T04；不套用恶火的原版升级名，B损失横向覆盖",
  "icon": "W04",
  "description_key": "W04.description",
  "reference_only": true,
  "tags": [
   "热能"
  ],
  "cost": 65,
  "damage": 8,
  "rate": 4,
  "range": 180,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W04A",
    "name": "地狱火",
    "desc": "地狱火：范围内目标附3秒燃烧，每秒为单次基础伤害40%；直接伤害-15%"
   },
   "B": {
    "id": "W04B",
    "name": "压缩火舌",
    "desc": "压缩火舌：射程+70%、扇角变25°；直接伤害+10%"
   }
  },
  "benefit": "65；每次8×4；180u、60°扇形",
  "penalty": "终阶分支各有代价"
 },
 "W05": {
  "id": "W05",
  "name": "C-10狙击枪",
  "desc": "85；65×0.7；720u\n穿透狙击：穿透2次、后续伤害70%；射速-15%\n弱点锁定：首领／精英+40%，对标记目标暴击率+15个百分点；普通怪伤害-20%\n幽灵狙击；T14；不是把原版狙击技能当枪械属性",
  "source": "幽灵狙击；T14；不是把原版狙击技能当枪械属性",
  "icon": "W05",
  "description_key": "W05.description",
  "reference_only": false,
  "tags": [
   "实弹",
   "精密"
  ],
  "cost": 85,
  "damage": 65,
  "rate": 0.7,
  "range": 720,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W05A",
    "name": "穿透狙击",
    "desc": "穿透狙击：穿透2次、后续伤害70%；射速-15%"
   },
   "B": {
    "id": "W05B",
    "name": "弱点锁定",
    "desc": "弱点锁定：首领／精英+40%，对标记目标暴击率+15个百分点；普通怪伤害-20%"
   }
  },
  "benefit": "85；65×0.7；720u",
  "penalty": "终阶分支各有代价"
 },
 "W06": {
  "id": "W06",
  "name": "集束发射器",
  "desc": "90；38×1；520u、半径85u\n子母弹：附3颗25%伤害子弹，半径40u；主爆伤害-20%，次级不可递归\n破城弹：主伤害+35%，忽略15护甲；射速-25%、半径-15%\n掠夺者／坦克爆破题材的原创便携武器；T06站定",
  "source": "掠夺者／坦克爆破题材的原创便携武器；T06站定",
  "icon": "W06",
  "description_key": "W06.description",
  "reference_only": false,
  "tags": [
   "爆破"
  ],
  "cost": 90,
  "damage": 38,
  "rate": 1,
  "range": 520,
  "radius": 85,
  "branches": {
   "A": {
    "id": "W06A",
    "name": "子母弹",
    "desc": "子母弹：附3颗25%伤害子弹，半径40u；主爆伤害-20%，次级不可递归"
   },
   "B": {
    "id": "W06B",
    "name": "破城弹",
    "desc": "破城弹：主伤害+35%，忽略15护甲；射速-25%、半径-15%"
   }
  },
  "benefit": "90；38×1；520u、半径85u",
  "penalty": "终阶分支各有代价"
 },
 "W07": {
  "id": "W07",
  "name": "轨道钉枪",
  "desc": "60；14×2.5；430u\n铆接：同一目标第5次直击额外50%伤害；基础伤害-10%\n维修射线：每累计8次直击修最近装置4生命；射速-15%，每秒最多修一次\n原创SCV工具武器；T09／T10；没有装置时B仅有代价，分支预警",
  "source": "原创SCV工具武器；T09／T10；没有装置时B仅有代价，分支预警",
  "icon": "W07",
  "description_key": "W07.description",
  "reference_only": false,
  "tags": [
   "实弹",
   "工程"
  ],
  "cost": 60,
  "damage": 14,
  "rate": 2.5,
  "range": 430,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W07A",
    "name": "铆接",
    "desc": "铆接：同一目标第5次直击额外50%伤害；基础伤害-10%"
   },
   "B": {
    "id": "W07B",
    "name": "维修射线",
    "desc": "维修射线：每累计8次直击修最近装置4生命；射速-15%，每秒最多修一次"
   }
  },
  "benefit": "60；14×2.5；430u",
  "penalty": "终阶分支各有代价"
 },
 "W08": {
  "id": "W08",
  "name": "微型攻城炮",
  "desc": "100；60×0.65；600u、半径100u\n攻城型：站定0.8秒伤害+60%、射程+100u；移动时不能开火\n突击型：移动可开火、射速+25%；半径-25%、伤害-15%\n对战攻城坦克模式；T06；A与持续跑动路线冲突",
  "source": "对战攻城坦克模式；T06；A与持续跑动路线冲突",
  "icon": "W08",
  "description_key": "W08.description",
  "reference_only": true,
  "tags": [
   "爆破",
   "机械"
  ],
  "cost": 100,
  "damage": 60,
  "rate": 0.65,
  "range": 600,
  "radius": 100,
  "branches": {
   "A": {
    "id": "W08A",
    "name": "攻城型",
    "desc": "攻城型：站定0.8秒伤害+60%、射程+100u；移动时不能开火"
   },
   "B": {
    "id": "W08B",
    "name": "突击型",
    "desc": "突击型：移动可开火、射速+25%；半径-25%、伤害-15%"
   }
  },
  "benefit": "100；60×0.65；600u、半径100u",
  "penalty": "终阶分支各有代价"
 },
 "W09": {
  "id": "W09",
  "name": "磁约束光束",
  "desc": "100；每次13×4，射0.8秒休1.2秒；620u\n聚焦：每连续命中0.25秒伤害+10%，最多50%；换目标重置、宽度减半\n切割：宽度+100%、穿透3个目标；伤害-20%\n星灵光束视觉的逆向研究原创；T17／T18；射击周期不因次级命中重置",
  "source": "星灵光束视觉的逆向研究原创；T17／T18；射击周期不因次级命中重置",
  "icon": "W09",
  "description_key": "W09.description",
  "reference_only": true,
  "tags": [
   "能量"
  ],
  "cost": 100,
  "damage": 13,
  "rate": 4,
  "range": 620,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W09A",
    "name": "聚焦",
    "desc": "聚焦：每连续命中0.25秒伤害+10%，最多50%；换目标重置、宽度减半"
   },
   "B": {
    "id": "W09B",
    "name": "切割",
    "desc": "切割：宽度+100%、穿透3个目标；伤害-20%"
   }
  },
  "benefit": "100；每次13×4，射0.8秒休1.2秒；620u",
  "penalty": "终阶分支各有代价"
 },
 "W10": {
  "id": "W10",
  "name": "电弧发生器",
  "desc": "85；18×1.6；400u，跳3次各120u\n链路：多跳2次；每跳衰减从20%变30%\n蓄能：跳跃减至1次，首目标伤害+70%；射速-15%\n原创武器，借鉴能量链路；T18；不得宣称雷神有此原版武器",
  "source": "原创武器，借鉴能量链路；T18；不得宣称雷神有此原版武器",
  "icon": "W10",
  "description_key": "W10.description",
  "reference_only": true,
  "tags": [
   "能量"
  ],
  "cost": 85,
  "damage": 18,
  "rate": 1.6,
  "range": 400,
  "radius": 0,
  "branches": {
   "A": {
    "id": "W10A",
    "name": "链路",
    "desc": "链路：多跳2次；每跳衰减从20%变30%"
   },
   "B": {
    "id": "W10B",
    "name": "蓄能",
    "desc": "蓄能：跳跃减至1次，首目标伤害+70%；射速-15%"
   }
  },
  "benefit": "85；18×1.6；400u，跳3次各120u",
  "penalty": "终阶分支各有代价"
 },
 "W11": {
  "id": "W11",
  "name": "地狱火火箭",
  "desc": "90；20×2枚×1；560u、半径55u\n齐射：每次4枚；单枚伤害-35%、射速-15%\n追猎：自动追踪标记目标，对精英+30%；每次仅1枚、伤害+40%\n歌利亚导弹题材；允许对地是本作改编；T05，齐射只检定一次触发",
  "source": "歌利亚导弹题材；允许对地是本作改编；T05，齐射只检定一次触发",
  "icon": "W11",
  "description_key": "W11.description",
  "reference_only": true,
  "tags": [
   "爆破",
   "机械"
  ],
  "cost": 90,
  "damage": 20,
  "rate": 1,
  "range": 560,
  "radius": 55,
  "branches": {
   "A": {
    "id": "W11A",
    "name": "齐射",
    "desc": "齐射：每次4枚；单枚伤害-35%、射速-15%"
   },
   "B": {
    "id": "W11B",
    "name": "追猎",
    "desc": "追猎：自动追踪标记目标，对精英+30%；每次仅1枚、伤害+40%"
   }
  },
  "benefit": "90；20×2枚×1；560u、半径55u",
  "penalty": "终阶分支各有代价"
 },
 "W12": {
  "id": "W12",
  "name": "辐照投射器",
  "desc": "95；每次7×4；380u、半径70u\n扩散：半径+50%；伤害-20%\n蚀甲：连续命中1秒后减5护甲持续2秒，最多3层；半径-25%\n科学船辐照题材；对所有敌种有效是改编；T21；自身不触发燃烧",
  "source": "科学船辐照题材；对所有敌种有效是改编；T21；自身不触发燃烧",
  "icon": "W12",
  "description_key": "W12.description",
  "reference_only": true,
  "tags": [
   "能量",
   "工程"
  ],
  "cost": 95,
  "damage": 7,
  "rate": 4,
  "range": 380,
  "radius": 70,
  "branches": {
   "A": {
    "id": "W12A",
    "name": "扩散",
    "desc": "扩散：半径+50%；伤害-20%"
   },
   "B": {
    "id": "W12B",
    "name": "蚀甲",
    "desc": "蚀甲：连续命中1秒后减5护甲持续2秒，最多3层；半径-25%"
   }
  },
  "benefit": "95；每次7×4；380u、半径70u",
  "penalty": "终阶分支各有代价"
 }
}
const SUPPORTS = {
 "S01": {
  "id": "S01",
  "name": "哨戒炮台",
  "desc": "每波开始在出生点部署，80生命，12伤害×3/秒，射程400u\n固定位置；离玩家600u外停止攻击，最多1座\n渡鸦炮台；T09，机动流需要绕回防区",
  "source": "渡鸦炮台；T09，机动流需要绕回防区",
  "icon": "S01",
  "description_key": "S01.description",
  "reference_only": false,
  "cost": 100,
  "benefit": "每波开始在出生点部署，80生命，12伤害×3/秒，射程400u",
  "penalty": "固定位置；离玩家600u外停止攻击，最多1座",
  "tags": [
   "工程"
  ],
  "hp": 80,
  "damage": 12,
  "rate": 3,
  "range": 400
 },
 "S02": {
  "id": "S02",
  "name": "医疗无人机",
  "desc": "每4秒治疗玩家3生命\n无攻击；低血不自动无敌；唯一\n诺娃维修无人机题材；T01，满血无收益",
  "source": "诺娃维修无人机题材；T01，满血无收益",
  "icon": "S02",
  "description_key": "S02.description",
  "reference_only": false,
  "cost": 100,
  "benefit": "每4秒治疗玩家3生命",
  "penalty": "无攻击；低血不自动无敌；唯一",
  "tags": [
   "工程"
  ],
  "heal": 3,
  "interval": 4
 },
 "S03": {
  "id": "S03",
  "name": "点防御无人机",
  "desc": "拦截130u内最近酸弹，每0.25秒一发，每波8发配额\n不挡光束／爆炸／地刺；配额不会由冷却缩减恢复\n渡鸦历史版本点防御；移动脆皮适配",
  "source": "渡鸦历史版本点防御；移动脆皮适配",
  "icon": "S03",
  "description_key": "S03.description",
  "reference_only": false,
  "cost": 110,
  "benefit": "拦截130u内最近酸弹，每0.25秒一发，每波8发配额",
  "penalty": "不挡光束／爆炸／地刺；配额不会由冷却缩减恢复",
  "tags": [
   "工程"
  ],
  "range": 130,
  "interval": 0.25,
  "quota": 8
 },
 "S04": {
  "id": "S04",
  "name": "蜘蛛雷匣",
  "desc": "每移动600u放1雷，60伤害、90u爆炸\n最多3雷、15秒消失；冲刺距离不计；2秒放置间隔\n战役秃鹫蜘蛛雷；T03，站定无收益",
  "source": "战役秃鹫蜘蛛雷；T03，站定无收益",
  "icon": "S04",
  "description_key": "S04.description",
  "reference_only": false,
  "cost": 90,
  "benefit": "每移动600u放1雷，60伤害、90u爆炸",
  "penalty": "最多3雷、15秒消失；冲刺距离不计；2秒放置间隔",
  "tags": [
   "工程"
  ],
  "distance": 600,
  "damage": 60,
  "radius": 90,
  "cap": 3,
  "lifetime": 15,
  "interval": 2
 },
 "S05": {
  "id": "S05",
  "name": "采矿激光支架",
  "desc": "每波出生点部署，100生命；射程650u，对标记／最强目标每0.25秒造成8伤害\n锁定1秒后开火，换目标重锁；离玩家600u停火，唯一\n合作斯旺钻机概念；T06／T09；缩小便携化原创",
  "source": "合作斯旺钻机概念；T06／T09；缩小便携化原创",
  "icon": "S05",
  "description_key": "S05.description",
  "reference_only": true,
  "cost": 120,
  "benefit": "每波出生点部署，100生命；射程650u，对标记／最强目标每0.25秒造成8伤害",
  "penalty": "锁定1秒后开火，换目标重锁；离玩家600u停火，唯一",
  "tags": [
   "工程"
  ],
  "hp": 100,
  "damage": 8,
  "rate": 4,
  "range": 650,
  "lock_time": 1
 },
 "S06": {
  "id": "S06",
  "name": "防御矩阵无人机",
  "desc": "玩家外部受伤后给20护盾，3秒\n内置12秒CD、唯一；本次伤害先结算，致死不能被事后护盾救回\n科学船矩阵／诺娃防御无人机题材；T12；不能靠扣血刷盾",
  "source": "科学船矩阵／诺娃防御无人机题材；T12；不能靠扣血刷盾",
  "icon": "S06",
  "description_key": "S06.description",
  "reference_only": true,
  "cost": 110,
  "benefit": "玩家外部受伤后给20护盾，3秒",
  "penalty": "内置12秒CD、唯一；本次伤害先结算，致死不能被事后护盾救回",
  "tags": [
   "工程"
  ],
  "shield": 20,
  "duration": 3,
  "cooldown": 12
 },
 "S07": {
  "id": "S07",
  "name": "MULE回收终端",
  "desc": "每波结束额外矿晶=本波保证收入10%，向下取整\n占支援槽无战力；不放大主动拾取、售卖、任务收入\n对战MULE采矿；每波一次，T11，无复利",
  "source": "对战MULE采矿；每波一次，T11，无复利",
  "icon": "S07",
  "description_key": "S07.description",
  "reference_only": true,
  "cost": 80,
  "benefit": "每波结束额外矿晶=本波保证收入10%，向下取整",
  "penalty": "占支援槽无战力；不放大主动拾取、售卖、任务收入",
  "tags": [
   "工程"
  ],
  "income_bonus": 0.1
 },
 "S08": {
  "id": "S08",
  "name": "侦测器",
  "desc": "350u内潜伏者可提前1秒看见轮廓；每5秒使最近精英／首领暴露3秒，受到玩家直击+10%\n无伤害，无硬控；同目标暴露不叠加\n科学船／渡鸦侦测题材；T14；未装备仍可反制潜伏者",
  "source": "科学船／渡鸦侦测题材；T14；未装备仍可反制潜伏者",
  "icon": "S08",
  "description_key": "S08.description",
  "reference_only": true,
  "cost": 80,
  "benefit": "350u内潜伏者可提前1秒看见轮廓；每5秒使最近精英／首领暴露3秒，受到玩家直击+10%",
  "penalty": "无伤害，无硬控；同目标暴露不叠加",
  "tags": [
   "工程"
  ],
  "range": 350,
  "interval": 5,
  "duration": 3
 }
}
const TECHS = {
 "T01": {
  "id": "T01",
  "name": "战地救护",
  "desc": "战役医疗兵治疗\n职业技能后4秒内每命中8次回复2生命；每秒最多1次\n技能CD+10%；适配兴奋剂，单发慢枪收益低",
  "source": "战役医疗兵治疗",
  "icon": "T01",
  "description_key": "T01.description",
  "reference_only": false,
  "group": "生化",
  "cost": 20,
  "benefit": "职业技能后4秒内每命中8次回复2生命；每秒最多1次",
  "penalty": "技能CD+10%；适配兴奋剂，单发慢枪收益低",
  "tags": [
   "生化"
  ],
  "prerequisite": "直击武器"
 },
 "T02": {
  "id": "T02",
  "name": "战斗盾牌",
  "desc": "对战陆战队生命升级\n生命+15；冲刺结束获得12护盾\n冲刺CD+0.5秒；护盾6秒内仅一次，不与自身叠加",
  "source": "对战陆战队生命升级",
  "icon": "T02",
  "description_key": "T02.description",
  "reference_only": false,
  "group": "生化",
  "cost": 20,
  "benefit": "生命+15；冲刺结束获得12护盾",
  "penalty": "冲刺CD+0.5秒；护盾6秒内仅一次，不与自身叠加",
  "tags": [
   "生化"
  ],
  "prerequisite": "通用"
 },
 "T03": {
  "id": "T03",
  "name": "喷射背包",
  "desc": "死神跨越地形的机动\n冲刺距离+30%，终点留40伤害、80u爆炸\n冲刺结束1秒内移速-10%；爆炸每次一次，不穿墙",
  "source": "死神跨越地形的机动",
  "icon": "T03",
  "description_key": "T03.description",
  "reference_only": false,
  "group": "生化",
  "cost": 20,
  "benefit": "冲刺距离+30%，终点留40伤害、80u爆炸",
  "penalty": "冲刺结束1秒内移速-10%；爆炸每次一次，不穿墙",
  "tags": [
   "生化"
  ],
  "prerequisite": "通用"
 },
 "T04": {
  "id": "T04",
  "name": "燃料调配",
  "desc": "战役火蝠升级题材\n燃烧持续+1秒，火焰区域击杀留60u焦土2秒、每秒8伤害\n直接热能伤害-10%；最多2片焦土／秒，焦土不再生成焦土",
  "source": "战役火蝠升级题材",
  "icon": "T04",
  "description_key": "T04.description",
  "reference_only": true,
  "group": "生化",
  "cost": 20,
  "benefit": "燃烧持续+1秒，火焰区域击杀留60u焦土2秒、每秒8伤害",
  "penalty": "直接热能伤害-10%；最多2片焦土／秒，焦土不再生成焦土",
  "tags": [
   "生化"
  ],
  "prerequisite": "C04或W04"
 },
 "T05": {
  "id": "T05",
  "name": "贫铀弹芯",
  "desc": "人族穿甲弹药题材\n实弹／爆破直击忽略10护甲，对重甲+15%\n全武器攻速-10%；穿甲与W03A/W06B相加，最多忽略25",
  "source": "人族穿甲弹药题材",
  "icon": "T05",
  "description_key": "T05.description",
  "reference_only": false,
  "group": "军械",
  "cost": 20,
  "benefit": "实弹／爆破直击忽略10护甲，对重甲+15%",
  "penalty": "全武器攻速-10%；穿甲与W03A/W06B相加，最多忽略25",
  "tags": [
   "军械"
  ],
  "prerequisite": "实弹或爆破"
 },
 "T06": {
  "id": "T06",
  "name": "攻城协议",
  "desc": "对战坦克架起模式\n站定0.8秒后爆破伤害+35%、装置射程+100u\n移动时爆破伤害-15%；开始移动立即清除增益",
  "source": "对战坦克架起模式",
  "icon": "T06",
  "description_key": "T06.description",
  "reference_only": true,
  "group": "军械",
  "cost": 20,
  "benefit": "站定0.8秒后爆破伤害+35%、装置射程+100u",
  "penalty": "移动时爆破伤害-15%；开始移动立即清除增益",
  "tags": [
   "军械"
  ],
  "prerequisite": "爆破或攻击装置"
 },
 "T07": {
  "id": "T07",
  "name": "智能伺服",
  "desc": "诺娃机械单位快速变形题材\n武器长周期停火／重锁时间-30%，移动后首次射击+20%\n全局伤害-8%；移动首次射击有2秒间隔；不改变技能冷却",
  "source": "诺娃机械单位快速变形题材",
  "icon": "T07",
  "description_key": "T07.description",
  "reference_only": true,
  "group": "军械",
  "cost": 20,
  "benefit": "武器长周期停火／重锁时间-30%，移动后首次射击+20%",
  "penalty": "全局伤害-8%；移动首次射击有2秒间隔；不改变技能冷却",
  "tags": [
   "军械"
  ],
  "prerequisite": "W01B/W05/W08/W09或S05"
 },
 "T08": {
  "id": "T08",
  "name": "震撼弹",
  "desc": "对战劫掠者减速弹\n爆破直击减速30%持续1.5秒；对已减速目标+15%伤害\n爆炸半径-10%；每目标1秒一次；范围伤害不追加减速",
  "source": "对战劫掠者减速弹",
  "icon": "T08",
  "description_key": "T08.description",
  "reference_only": false,
  "group": "军械",
  "cost": 20,
  "benefit": "爆破直击减速30%持续1.5秒；对已减速目标+15%伤害",
  "penalty": "爆炸半径-10%；每目标1秒一次；范围伤害不追加减速",
  "tags": [
   "军械"
  ],
  "prerequisite": "爆破"
 },
 "T09": {
  "id": "T09",
  "name": "双工反应堆",
  "desc": "战役科技反应堆双队列概念\n每部署第2座攻击装置，复制该装置6秒、伤害50%\n玩家全局伤害-10%；复制CD10秒，最多1复制体；不复制复制体",
  "source": "战役科技反应堆双队列概念",
  "icon": "T09",
  "description_key": "T09.description",
  "reference_only": false,
  "group": "工程",
  "cost": 20,
  "benefit": "每部署第2座攻击装置，复制该装置6秒、伤害50%",
  "penalty": "玩家全局伤害-10%；复制CD10秒，最多1复制体；不复制复制体",
  "tags": [
   "工程"
  ],
  "prerequisite": "攻击装置"
 },
 "T10": {
  "id": "T10",
  "name": "再生生物钢",
  "desc": "自由之翼机械自修研究\n装置4秒未受伤后每秒恢复最大生命3%；回收职业旧炮台时治疗玩家3\n装置基础伤害-10%；回收治疗CD10秒；不复活毁坏装置",
  "source": "自由之翼机械自修研究",
  "icon": "T10",
  "description_key": "T10.description",
  "reference_only": false,
  "group": "工程",
  "cost": 20,
  "benefit": "装置4秒未受伤后每秒恢复最大生命3%；回收职业旧炮台时治疗玩家3",
  "penalty": "装置基础伤害-10%；回收治疗CD10秒；不复活毁坏装置",
  "tags": [
   "工程"
  ],
  "prerequisite": "攻击装置"
 },
 "T11": {
  "id": "T11",
  "name": "自动回收",
  "desc": "原创，MULE后勤题材\n主动拾取每累计20矿晶价值，最近装置攻速+25%持续3秒\n拾取范围-15%；CD5秒，最多一次待触发，不存无限层；S07不触发",
  "source": "原创，MULE后勤题材",
  "icon": "T11",
  "description_key": "T11.description",
  "reference_only": true,
  "group": "工程",
  "cost": 20,
  "benefit": "主动拾取每累计20矿晶价值，最近装置攻速+25%持续3秒",
  "penalty": "拾取范围-15%；CD5秒，最多一次待触发，不存无限层；S07不触发",
  "tags": [
   "工程"
  ],
  "prerequisite": "攻击装置"
 },
 "T12": {
  "id": "T12",
  "name": "防御矩阵",
  "desc": "战役科学船吸收护盾\n职业技能后给予玩家及最近装置各15护盾\n技能CD+15%；触发CD8秒；与S06同名矩阵取高，不相加",
  "source": "战役科学船吸收护盾",
  "icon": "T12",
  "description_key": "T12.description",
  "reference_only": false,
  "group": "工程",
  "cost": 20,
  "benefit": "职业技能后给予玩家及最近装置各15护盾",
  "penalty": "技能CD+15%；触发CD8秒；与S06同名矩阵取高，不相加",
  "tags": [
   "工程"
  ],
  "prerequisite": "通用"
 },
 "T13": {
  "id": "T13",
  "name": "EMP弹",
  "desc": "对战／诺娃：耗能与削盾\n职业技能额外在目标点释放120uEMP：破10护甲2秒、延后施法1秒\n技能伤害-15%；CD10秒；首领按控制契约；不全屏清弹",
  "source": "对战／诺娃：耗能与削盾",
  "icon": "T13",
  "description_key": "T13.description",
  "reference_only": true,
  "group": "幽灵",
  "cost": 20,
  "benefit": "职业技能额外在目标点释放120uEMP：破10护甲2秒、延后施法1秒",
  "penalty": "技能伤害-15%；CD10秒；首领按控制契约；不全屏清弹",
  "tags": [
   "幽灵"
  ],
  "prerequisite": "通用"
 },
 "T14": {
  "id": "T14",
  "name": "狙击协议",
  "desc": "幽灵单体狙击\n精密直击标记目标每第3击追加基础伤害60%\n对未标记普通目标伤害-10%；目标死亡清零，追加CD1秒",
  "source": "幽灵单体狙击",
  "icon": "T14",
  "description_key": "T14.description",
  "reference_only": true,
  "group": "幽灵",
  "cost": 20,
  "benefit": "精密直击标记目标每第3击追加基础伤害60%",
  "penalty": "对未标记普通目标伤害-10%；目标死亡清零，追加CD1秒",
  "tags": [
   "幽灵"
  ],
  "prerequisite": "精密"
 },
 "T15": {
  "id": "T15",
  "name": "全息诱饵",
  "desc": "诺娃全息复制\n冲刺终点生成诱饵3秒，10伤害×2/秒、射程350u，吸引普通敌人\n玩家全局伤害-8%；CD10秒、最多1，不吸引首领，吃工程倍率",
  "source": "诺娃全息复制",
  "icon": "T15",
  "description_key": "T15.description",
  "reference_only": true,
  "group": "幽灵",
  "cost": 20,
  "benefit": "冲刺终点生成诱饵3秒，10伤害×2/秒、射程350u，吸引普通敌人",
  "penalty": "玩家全局伤害-8%；CD10秒、最多1，不吸引首领，吃工程倍率",
  "tags": [
   "幽灵"
  ],
  "prerequisite": "通用"
 },
 "T16": {
  "id": "T16",
  "name": "战术核信标",
  "desc": "幽灵延迟核打击\n每第3次职业技能在标记处／当前目标处设信标，2秒后220u、180伤害\n职业技能CD+20%；内置CD20秒，信标期敌人可移动；无友伤",
  "source": "幽灵延迟核打击",
  "icon": "T16",
  "description_key": "T16.description",
  "reference_only": true,
  "group": "幽灵",
  "cost": 20,
  "benefit": "每第3次职业技能在标记处／当前目标处设信标，2秒后220u、180伤害",
  "penalty": "职业技能CD+20%；内置CD20秒，信标期敌人可移动；无友伤",
  "tags": [
   "幽灵"
  ],
  "prerequisite": "通用"
 },
 "T17": {
  "id": "T17",
  "name": "相位电容",
  "desc": "星灵护盾概念，逆向适配原创\n4秒未受伤后获得最大生命15%护盾，持续至受击或波末\n最大生命-10%；CD8秒；该护盾特例不按默认3秒消失，无生命治疗",
  "source": "星灵护盾概念，逆向适配原创",
  "icon": "T17",
  "description_key": "T17.description",
  "reference_only": true,
  "group": "星灵",
  "cost": 20,
  "benefit": "4秒未受伤后获得最大生命15%护盾，持续至受击或波末",
  "penalty": "最大生命-10%；CD8秒；该护盾特例不按默认3秒消失，无生命治疗",
  "tags": [
   "星灵"
  ],
  "prerequisite": "通用"
 },
 "T18": {
  "id": "T18",
  "name": "共振链路",
  "desc": "原创，灵能能量链路题材\n能量直击同一目标累计5次，跳向2个附近目标各造成原基础伤害40%\n能量首目标伤害-10%；每武器CD1秒，跳跃无递归",
  "source": "原创，灵能能量链路题材",
  "icon": "T18",
  "description_key": "T18.description",
  "reference_only": true,
  "group": "星灵",
  "cost": 20,
  "benefit": "能量直击同一目标累计5次，跳向2个附近目标各造成原基础伤害40%",
  "penalty": "能量首目标伤害-10%；每武器CD1秒，跳跃无递归",
  "tags": [
   "星灵"
  ],
  "prerequisite": "能量"
 },
 "T19": {
  "id": "T19",
  "name": "时空余波",
  "desc": "星灵时间操纵概念，弱化改编\n职业技能后留下150u减速场3秒，减速35%\n职业技能CD+15%；CD10秒，最多1场；不停止首领时间",
  "source": "星灵时间操纵概念，弱化改编",
  "icon": "T19",
  "description_key": "T19.description",
  "reference_only": true,
  "group": "星灵",
  "cost": 20,
  "benefit": "职业技能后留下150u减速场3秒，减速35%",
  "penalty": "职业技能CD+15%；CD10秒，最多1场；不停止首领时间",
  "tags": [
   "星灵"
  ],
  "prerequisite": "通用"
 },
 "T20": {
  "id": "T20",
  "name": "相位跃迁",
  "desc": "诺娃突击服闪现＋星灵相位概念\n冲刺改为同距离瞬移，终点获得10护盾\n冲刺基础CD+1秒；仍不可穿墙、落点危险仍伤人，T03爆炸仍可触发",
  "source": "诺娃突击服闪现＋星灵相位概念",
  "icon": "T20",
  "description_key": "T20.description",
  "reference_only": true,
  "group": "星灵",
  "cost": 20,
  "benefit": "冲刺改为同距离瞬移，终点获得10护盾",
  "penalty": "冲刺基础CD+1秒；仍不可穿墙、落点危险仍伤人，T03爆炸仍可触发",
  "tags": [
   "星灵"
  ],
  "prerequisite": "通用"
 },
 "T21": {
  "id": "T21",
  "name": "细胞吞噬",
  "desc": "异虫组织再生题材原创\n每累计击杀15普通敌人治疗最大生命3%\n全部治疗倍率-15%；CD5秒；召唤物击杀计入，首领阶段小怪不足即弱势",
  "source": "异虫组织再生题材原创",
  "icon": "T21",
  "description_key": "T21.description",
  "reference_only": true,
  "group": "异虫",
  "cost": 20,
  "benefit": "每累计击杀15普通敌人治疗最大生命3%",
  "penalty": "全部治疗倍率-15%；CD5秒；召唤物击杀计入，首领阶段小怪不足即弱势",
  "tags": [
   "异虫"
  ],
  "prerequisite": "通用"
 },
 "T22": {
  "id": "T22",
  "name": "活性甲壳",
  "desc": "异虫甲壳升级概念\n外部受伤后护甲+15持续3秒，并释放60u、15伤害酸圈\n移速-8%；CD6秒，酸圈不触发；不能靠生命成本触发",
  "source": "异虫甲壳升级概念",
  "icon": "T22",
  "description_key": "T22.description",
  "reference_only": true,
  "group": "异虫",
  "cost": 20,
  "benefit": "外部受伤后护甲+15持续3秒，并释放60u、15伤害酸圈",
  "penalty": "移速-8%；CD6秒，酸圈不触发；不能靠生命成本触发",
  "tags": [
   "异虫"
  ],
  "prerequisite": "通用"
 },
 "T23": {
  "id": "T23",
  "name": "灵能干扰器",
  "desc": "自由之翼减缓异虫研究\n玩家周围180u内普通异虫减速25%，装置对其伤害+15%\n玩家武器伤害-10%；首领仅减速10%；与其他减速取高",
  "source": "自由之翼减缓异虫研究",
  "icon": "T23",
  "description_key": "T23.description",
  "reference_only": true,
  "group": "异虫",
  "cost": 20,
  "benefit": "玩家周围180u内普通异虫减速25%，装置对其伤害+15%",
  "penalty": "玩家武器伤害-10%；首领仅减速10%；与其他减速取高",
  "tags": [
   "异虫"
  ],
  "prerequisite": "攻击装置"
 },
 "T24": {
  "id": "T24",
  "name": "蜂巢心智模拟器",
  "desc": "自由之翼控制异虫研究\n每12秒控制250u内最低生命普通异虫8秒，以20生命、8伤害×2/秒近战作战\n玩家全局伤害-10%；最多1、普通怪专用，精英首领不可控；无合格目标不进入CD",
  "source": "自由之翼控制异虫研究",
  "icon": "T24",
  "description_key": "T24.description",
  "reference_only": true,
  "group": "异虫",
  "cost": 20,
  "benefit": "每12秒控制250u内最低生命普通异虫8秒，以20生命、8伤害×2/秒近战作战",
  "penalty": "玩家全局伤害-10%；最多1、普通怪专用，精英首领不可控；无合格目标不进入CD",
  "tags": [
   "异虫"
  ],
  "prerequisite": "通用"
 }
}
const ITEMS = {
 "I01": {
  "id": "I01",
  "name": "穿甲硬芯",
  "desc": "实弹忽略5护甲\n武器攻速-5%；总穿甲≤25\n人族弹药；重甲关，低甲收益小",
  "source": "人族弹药；重甲关，低甲收益小",
  "icon": "I01",
  "description_key": "I01.description",
  "reference_only": false,
  "cost": 55,
  "cap": 2,
  "benefit": "实弹忽略5护甲",
  "penalty": "武器攻速-5%；总穿甲≤25",
  "tags": []
 },
 "I02": {
  "id": "I02",
  "name": "扩容弹匣",
  "desc": "武器攻速+12%\n全局伤害-6%\n原创军械；命中流，慢枪需算总伤",
  "source": "原创军械；命中流，慢枪需算总伤",
  "icon": "I02",
  "description_key": "I02.description",
  "reference_only": false,
  "cost": 45,
  "cap": 2,
  "benefit": "武器攻速+12%",
  "penalty": "全局伤害-6%",
  "tags": []
 },
 "I03": {
  "id": "I03",
  "name": "重型枪管",
  "desc": "实弹伤害+18%\n移速-5%\n人族军械；站定流，冲刺流损机动",
  "source": "人族军械；站定流，冲刺流损机动",
  "icon": "I03",
  "description_key": "I03.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "实弹伤害+18%",
  "penalty": "移速-5%",
  "tags": []
 },
 "I04": {
  "id": "I04",
  "name": "高精瞄具",
  "desc": "精密暴击+8个百分点\n其他武器伤害-6%\n幽灵瞄具；精密限定，不提高装置暴击",
  "source": "幽灵瞄具；精密限定，不提高装置暴击",
  "icon": "I04",
  "description_key": "I04.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "精密暴击+8个百分点",
  "penalty": "其他武器伤害-6%",
  "tags": []
 },
 "I05": {
  "id": "I05",
  "name": "破片衬层",
  "desc": "爆破半径+15%\n爆破伤害-8%\n坦克爆破；清群，单体收益弱",
  "source": "坦克爆破；清群，单体收益弱",
  "icon": "I05",
  "description_key": "I05.description",
  "reference_only": true,
  "cost": 55,
  "cap": 2,
  "benefit": "爆破半径+15%",
  "penalty": "爆破伤害-8%",
  "tags": []
 },
 "I06": {
  "id": "I06",
  "name": "稳压燃料",
  "desc": "燃烧伤害+20%\n热能直击-8%\n火蝠；持续流，短战损失",
  "source": "火蝠；持续流，短战损失",
  "icon": "I06",
  "description_key": "I06.description",
  "reference_only": true,
  "cost": 45,
  "cap": 2,
  "benefit": "燃烧伤害+20%",
  "penalty": "热能直击-8%",
  "tags": []
 },
 "I07": {
  "id": "I07",
  "name": "蓄能电池",
  "desc": "能量伤害+18%\n武器攻速-8%\n星灵电容题材；慢能量流",
  "source": "星灵电容题材；慢能量流",
  "icon": "I07",
  "description_key": "I07.description",
  "reference_only": true,
  "cost": 55,
  "cap": 2,
  "benefit": "能量伤害+18%",
  "penalty": "武器攻速-8%",
  "tags": []
 },
 "I08": {
  "id": "I08",
  "name": "电弧线圈",
  "desc": "能量首目标每5次直击追加一次40%电弧，1秒CD\n能量直击-10%；次级不触发次级\n原创；T18兼容但共用事件预算",
  "source": "原创；T18兼容但共用事件预算",
  "icon": "I08",
  "description_key": "I08.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "能量首目标每5次直击追加一次40%电弧，1秒CD",
  "penalty": "能量直击-10%；次级不触发次级",
  "tags": []
 },
 "I09": {
  "id": "I09",
  "name": "单兵弹链",
  "desc": "站定0.5秒后攻速+20%\n移动时攻速-8%\n陆战队供弹；攻城，跑动冲突",
  "source": "陆战队供弹；攻城，跑动冲突",
  "icon": "I09",
  "description_key": "I09.description",
  "reference_only": true,
  "cost": 45,
  "cap": 2,
  "benefit": "站定0.5秒后攻速+20%",
  "penalty": "移动时攻速-8%",
  "tags": []
 },
 "I10": {
  "id": "I10",
  "name": "智能弹头",
  "desc": "实弹／爆破对标记目标+20%\n未标记目标-8%\n制导军械；首领集火",
  "source": "制导军械；首领集火",
  "icon": "I10",
  "description_key": "I10.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "实弹／爆破对标记目标+20%",
  "penalty": "未标记目标-8%",
  "tags": []
 },
 "I11": {
  "id": "I11",
  "name": "钛钢胸板",
  "desc": "护甲+8\n移速-5%\n人族装甲；生存，低机动风险",
  "source": "人族装甲；生存，低机动风险",
  "icon": "I11",
  "description_key": "I11.description",
  "reference_only": false,
  "cost": 50,
  "cap": 2,
  "benefit": "护甲+8",
  "penalty": "移速-5%",
  "tags": []
 },
 "I12": {
  "id": "I12",
  "name": "轻质骨架",
  "desc": "移速+10%\n最大生命-8\n动力装甲；机动流",
  "source": "动力装甲；机动流",
  "icon": "I12",
  "description_key": "I12.description",
  "reference_only": false,
  "cost": 45,
  "cap": 2,
  "benefit": "移速+10%",
  "penalty": "最大生命-8",
  "tags": []
 },
 "I13": {
  "id": "I13",
  "name": "战地药箱",
  "desc": "波末治疗最大生命8%\n本波保证收入-5%，按结算前基础额算\n战役医疗；容错，经济代价",
  "source": "战役医疗；容错，经济代价",
  "icon": "I13",
  "description_key": "I13.description",
  "reference_only": false,
  "cost": 50,
  "cap": 2,
  "benefit": "波末治疗最大生命8%",
  "penalty": "本波保证收入-5%，按结算前基础额算",
  "tags": []
 },
 "I14": {
  "id": "I14",
  "name": "应急矩阵",
  "desc": "外部致死伤害改为生命1＋20护盾\n最大生命-10；每局一次，消耗后代价保留\n科学船矩阵题材；不提供无敌，救命共用次数",
  "source": "科学船矩阵题材；不提供无敌，救命共用次数",
  "icon": "I14",
  "description_key": "I14.description",
  "reference_only": true,
  "cost": 70,
  "cap": 1,
  "benefit": "外部致死伤害改为生命1＋20护盾",
  "penalty": "最大生命-10；每局一次，消耗后代价保留",
  "tags": []
 },
 "I15": {
  "id": "I15",
  "name": "耐酸镀层",
  "desc": "酸潭／酸云伤害-20%\n其他外部伤害+5%；危险减免计入85%总上限\n原创人族防护；环境关",
  "source": "原创人族防护；环境关",
  "icon": "I15",
  "description_key": "I15.description",
  "reference_only": true,
  "cost": 45,
  "cap": 2,
  "benefit": "酸潭／酸云伤害-20%",
  "penalty": "其他外部伤害+5%；危险减免计入85%总上限",
  "tags": []
 },
 "I16": {
  "id": "I16",
  "name": "热交换器",
  "desc": "护盾授予量+20%\n治疗倍率-10%\n原创机械；护盾流，与回血冲突",
  "source": "原创机械；护盾流，与回血冲突",
  "icon": "I16",
  "description_key": "I16.description",
  "reference_only": true,
  "cost": 45,
  "cap": 2,
  "benefit": "护盾授予量+20%",
  "penalty": "治疗倍率-10%",
  "tags": []
 },
 "I17": {
  "id": "I17",
  "name": "自愈凝胶",
  "desc": "4秒未受伤后每秒回复0.6生命\n护甲-4\n异虫组织研究；脱战流，低甲不返收益",
  "source": "异虫组织研究；脱战流，低甲不返收益",
  "icon": "I17",
  "description_key": "I17.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "4秒未受伤后每秒回复0.6生命",
  "penalty": "护甲-4",
  "tags": []
 },
 "I18": {
  "id": "I18",
  "name": "纳米缝合",
  "desc": "治疗倍率+20%\n最大生命-10\n战役医疗题材；T01，瞬伤承受差",
  "source": "战役医疗题材；T01，瞬伤承受差",
  "icon": "I18",
  "description_key": "I18.description",
  "reference_only": false,
  "cost": 55,
  "cap": 2,
  "benefit": "治疗倍率+20%",
  "penalty": "最大生命-10",
  "tags": []
 },
 "I19": {
  "id": "I19",
  "name": "复合缓冲",
  "desc": "外部受伤无敌帧+0.05秒\n冲刺CD+0.3秒；无敌帧总≤0.6秒\n原创装甲；容错，机动代价",
  "source": "原创装甲；容错，机动代价",
  "icon": "I19",
  "description_key": "I19.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "外部受伤无敌帧+0.05秒",
  "penalty": "冲刺CD+0.3秒；无敌帧总≤0.6秒",
  "tags": []
 },
 "I20": {
  "id": "I20",
  "name": "反应装甲",
  "desc": "外部受伤后60u反伤20，CD3秒\n所有治疗-10%；反伤不可触发\n人族装甲；近距，不能靠扣血触发",
  "source": "人族装甲；近距，不能靠扣血触发",
  "icon": "I20",
  "description_key": "I20.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "外部受伤后60u反伤20，CD3秒",
  "penalty": "所有治疗-10%；反伤不可触发",
  "tags": []
 },
 "I21": {
  "id": "I21",
  "name": "喷气喷嘴",
  "desc": "冲刺距离+15%\n冲刺CD+0.4秒\n死神机动；越距，短场地难控",
  "source": "死神机动；越距，短场地难控",
  "icon": "I21",
  "description_key": "I21.description",
  "reference_only": false,
  "cost": 50,
  "cap": 2,
  "benefit": "冲刺距离+15%",
  "penalty": "冲刺CD+0.4秒",
  "tags": []
 },
 "I22": {
  "id": "I22",
  "name": "灵敏伺服",
  "desc": "冲刺CD缩减8个百分点\n全局伤害-5%\n原创动力甲；走位流，计入40%冷却上限",
  "source": "原创动力甲；走位流，计入40%冷却上限",
  "icon": "I22",
  "description_key": "I22.description",
  "reference_only": false,
  "cost": 55,
  "cap": 2,
  "benefit": "冲刺CD缩减8个百分点",
  "penalty": "全局伤害-5%",
  "tags": []
 },
 "I23": {
  "id": "I23",
  "name": "战术电容",
  "desc": "职业技能CD缩减10个百分点\n技能伤害-10%\n原创幽灵设备；功能技能收益高",
  "source": "原创幽灵设备；功能技能收益高",
  "icon": "I23",
  "description_key": "I23.description",
  "reference_only": true,
  "cost": 60,
  "cap": 2,
  "benefit": "职业技能CD缩减10个百分点",
  "penalty": "技能伤害-10%",
  "tags": []
 },
 "I24": {
  "id": "I24",
  "name": "重力锚",
  "desc": "玩家直击击退+20u\n移速-5%；每目标0.5秒CD，不推首领\n星灵逆向设备原创；近距脱困",
  "source": "星灵逆向设备原创；近距脱困",
  "icon": "I24",
  "description_key": "I24.description",
  "reference_only": true,
  "cost": 45,
  "cap": 2,
  "benefit": "玩家直击击退+20u",
  "penalty": "移速-5%；每目标0.5秒CD，不推首领",
  "tags": []
 },
 "I25": {
  "id": "I25",
  "name": "侦察天线",
  "desc": "拾取半径+35u，标记持续+1秒\n最大生命-5；拾取半径≤220u\n人族侦察；拾取流",
  "source": "人族侦察；拾取流",
  "icon": "I25",
  "description_key": "I25.description",
  "reference_only": false,
  "cost": 40,
  "cap": 2,
  "benefit": "拾取半径+35u，标记持续+1秒",
  "penalty": "最大生命-5；拾取半径≤220u",
  "tags": []
 },
 "I26": {
  "id": "I26",
  "name": "拾荒磁轨",
  "desc": "主动拾取奖励矿晶+10%，波末一次向下取整\n波末未拾取回收率-5个百分点\n原创后勤；拆分掉落不增收益",
  "source": "原创后勤；拆分掉落不增收益",
  "icon": "I26",
  "description_key": "I26.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "主动拾取奖励矿晶+10%，波末一次向下取整",
  "penalty": "波末未拾取回收率-5个百分点",
  "tags": []
 },
 "I27": {
  "id": "I27",
  "name": "备用信道",
  "desc": "每次整备首次付费刷新减价3矿晶\n武器购买价+10%，升级价不变\n原创后勤；商店控制，不出现负价",
  "source": "原创后勤；商店控制，不出现负价",
  "icon": "I27",
  "description_key": "I27.description",
  "reference_only": true,
  "cost": 55,
  "cap": 1,
  "benefit": "每次整备首次付费刷新减价3矿晶",
  "penalty": "武器购买价+10%，升级价不变",
  "tags": []
 },
 "I28": {
  "id": "I28",
  "name": "合同预支",
  "desc": "购买时立得60矿晶\n此后3次保证收入各扣25，不能重复／卖掉免债\n原创后勤；仅W1–7货架出现，净成本15",
  "source": "原创后勤；仅W1–7货架出现，净成本15",
  "icon": "I28",
  "description_key": "I28.description",
  "reference_only": true,
  "cost": 0,
  "cap": 1,
  "benefit": "购买时立得60矿晶",
  "penalty": "此后3次保证收入各扣25，不能重复／卖掉免债",
  "tags": []
 },
 "I29": {
  "id": "I29",
  "name": "强行军药剂",
  "desc": "移速+12%\n治疗倍率-12%\n兴奋剂题材；走位流",
  "source": "兴奋剂题材；走位流",
  "icon": "I29",
  "description_key": "I29.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "移速+12%",
  "penalty": "治疗倍率-12%",
  "tags": []
 },
 "I30": {
  "id": "I30",
  "name": "战斗记录器",
  "desc": "对标记目标每10次直击给玩家8护盾，CD5秒\n暴击率-5个百分点\n幽灵记录设备原创；快枪，护盾受总上限",
  "source": "幽灵记录设备原创；快枪，护盾受总上限",
  "icon": "I30",
  "description_key": "I30.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "对标记目标每10次直击给玩家8护盾，CD5秒",
  "penalty": "暴击率-5个百分点",
  "tags": []
 },
 "I31": {
  "id": "I31",
  "name": "高扭矩马达",
  "desc": "装置攻速+15%\n玩家武器攻速-6%\nSCV工程；召唤流",
  "source": "SCV工程；召唤流",
  "icon": "I31",
  "description_key": "I31.description",
  "reference_only": false,
  "cost": 55,
  "cap": 2,
  "benefit": "装置攻速+15%",
  "penalty": "玩家武器攻速-6%",
  "tags": []
 },
 "I32": {
  "id": "I32",
  "name": "再生钢片",
  "desc": "装置生命+25%\n工程倍率-8个百分点\n战役再生钢概念；装置生存",
  "source": "战役再生钢概念；装置生存",
  "icon": "I32",
  "description_key": "I32.description",
  "reference_only": false,
  "cost": 50,
  "cap": 2,
  "benefit": "装置生命+25%",
  "penalty": "工程倍率-8个百分点",
  "tags": []
 },
 "I33": {
  "id": "I33",
  "name": "远程中继",
  "desc": "装置射程+60u\n玩家武器射程-30u，最低120u\n人族通讯；阵地流",
  "source": "人族通讯；阵地流",
  "icon": "I33",
  "description_key": "I33.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "装置射程+60u",
  "penalty": "玩家武器射程-30u，最低120u",
  "tags": []
 },
 "I34": {
  "id": "I34",
  "name": "报废超频器",
  "desc": "装置伤害+30%\n装置每秒失去最大生命2%，最低降至1生命\n工程超频原创；T10可抵偿，但代价依旧结算",
  "source": "工程超频原创；T10可抵偿，但代价依旧结算",
  "icon": "I34",
  "description_key": "I34.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "装置伤害+30%",
  "penalty": "装置每秒失去最大生命2%，最低降至1生命",
  "tags": []
 },
 "I35": {
  "id": "I35",
  "name": "自动润滑",
  "desc": "工程职业炮台持续+3秒；其他攻击装置伤害+8%\n职业技能CD+5%\n原创工程；无职业炮台也有收益",
  "source": "原创工程；无职业炮台也有收益",
  "icon": "I35",
  "description_key": "I35.description",
  "reference_only": true,
  "cost": 50,
  "cap": 2,
  "benefit": "工程职业炮台持续+3秒；其他攻击装置伤害+8%",
  "penalty": "职业技能CD+5%",
  "tags": []
 },
 "I36": {
  "id": "I36",
  "name": "导流网",
  "desc": "S03配额+4；没S03时职业技能后拦截最近1酸弹，CD12秒\n全局伤害-8%\n渡鸦点防御；不能拦地面技能",
  "source": "渡鸦点防御；不能拦地面技能",
  "icon": "I36",
  "description_key": "I36.description",
  "reference_only": true,
  "cost": 60,
  "cap": 1,
  "benefit": "S03配额+4；没S03时职业技能后拦截最近1酸弹，CD12秒",
  "penalty": "全局伤害-8%",
  "tags": []
 },
 "I37": {
  "id": "I37",
  "name": "异化腺体",
  "desc": "全局伤害+15%\n外部受伤无敌帧-0.05秒，最低0.3秒\n异虫研究原创；高风险输出",
  "source": "异虫研究原创；高风险输出",
  "icon": "I37",
  "description_key": "I37.description",
  "reference_only": false,
  "cost": 55,
  "cap": 2,
  "benefit": "全局伤害+15%",
  "penalty": "外部受伤无敌帧-0.05秒，最低0.3秒",
  "tags": []
 },
 "I38": {
  "id": "I38",
  "name": "凯达林碎片",
  "desc": "暴击率+8个百分点\n最大生命-10%\n星灵水晶题材；暴击流",
  "source": "星灵水晶题材；暴击流",
  "icon": "I38",
  "description_key": "I38.description",
  "reference_only": true,
  "cost": 60,
  "cap": 2,
  "benefit": "暴击率+8个百分点",
  "penalty": "最大生命-10%",
  "tags": []
 },
 "I39": {
  "id": "I39",
  "name": "吸能触须",
  "desc": "玩家直接武器命中每累计造成100伤害治疗1，CD1秒\n全局伤害-8%；不计护盾伤害、次级和召唤伤害\n异虫研究原创；不随怪数量无限吸血",
  "source": "异虫研究原创；不随怪数量无限吸血",
  "icon": "I39",
  "description_key": "I39.description",
  "reference_only": true,
  "cost": 65,
  "cap": 1,
  "benefit": "玩家直接武器命中每累计造成100伤害治疗1，CD1秒",
  "penalty": "全局伤害-8%；不计护盾伤害、次级和召唤伤害",
  "tags": []
 },
 "I40": {
  "id": "I40",
  "name": "共生甲片",
  "desc": "每20秒获得一次最大生命20%的护盾\n武器槽上限从4降为3；只在持有≤3武器时出现\n异虫研究原创；盾满仍重置CD，卖出恢复槽位",
  "source": "异虫研究原创；盾满仍重置CD，卖出恢复槽位",
  "icon": "I40",
  "description_key": "I40.description",
  "reference_only": true,
  "cost": 65,
  "cap": 1,
  "benefit": "每20秒获得一次最大生命20%的护盾",
  "penalty": "武器槽上限从4降为3；只在持有≤3武器时出现",
  "tags": []
 }
}
const BUILDS = {
 "B01": {
  "id": "B01",
  "name": "兴奋剂战线",
  "desc": "C01+W01；T01→T02→T07；S02；I02/I18\nW2治疗循环成型，5秒爆发后走位拾取；快枪清杂，狙击补首领\n兴奋剂不能救已低血；T01未出选T02，S02换S06，W05补慢枪",
  "source": "兴奋剂不能救已低血；T01未出选T02，S02换S06，W05补慢枪",
  "icon": "B01",
  "description_key": "B01.description",
  "reference_only": true,
  "refs": [
   "C01",
   "I02",
   "I18",
   "S02",
   "S06",
   "T01",
   "T02",
   "T07",
   "W01",
   "W05"
  ]
 },
 "B02": {
  "id": "B02",
  "name": "重甲拆解",
  "desc": "C02+W03A/W06B；T05→T08→T13；S08；I01/I10\nW2破甲成型，先减速再集火；群伤中等，重甲首领强\n大量轻怪需W04；T05缺失改T08，普通道具穿甲兜底",
  "source": "大量轻怪需W04；T05缺失改T08，普通道具穿甲兜底",
  "icon": "B02",
  "description_key": "B02.description",
  "reference_only": true,
  "refs": [
   "C02",
   "I01",
   "I10",
   "S08",
   "T05",
   "T08",
   "T13",
   "W03",
   "W04",
   "W06"
  ]
 },
 "B03": {
  "id": "B03",
  "name": "死神雷径",
  "desc": "C03+W02A；T03→T15→T20；S04；I21/I22\nW2冲刺爆破成型，跑动布雷，脱战回血；群伤强、单体依赖枪\n雷区位置可失效；S04没出用W06，T20没出选T02",
  "source": "雷区位置可失效；S04没出用W06，T20没出选T02",
  "icon": "B03",
  "description_key": "B03.description",
  "reference_only": true,
  "refs": [
   "C03",
   "I21",
   "I22",
   "S04",
   "T02",
   "T03",
   "T15",
   "T20",
   "W02",
   "W06"
  ]
 },
 "B04": {
  "id": "B04",
  "name": "燃烧防区",
  "desc": "C04+W04A/W06；T04→T06→T22；S06；I06/I15\nW2焦土循环，短站定后转移；虫群强、首领较慢\n不能用回血硬吃毒爆；T04缺失选T06，W04自身燃烧仍可玩",
  "source": "不能用回血硬吃毒爆；T04缺失选T06，W04自身燃烧仍可玩",
  "icon": "B04",
  "description_key": "B04.description",
  "reference_only": true,
  "refs": [
   "C04",
   "I06",
   "I15",
   "S06",
   "T04",
   "T06",
   "T22",
   "W04",
   "W06"
  ]
 },
 "B05": {
  "id": "B05",
  "name": "隐形狙杀",
  "desc": "C05+W05B/W01A；T14→T13→T15；S08；I04/I10\nW2标记狙击成型，隐形换位后首发爆发；首领强，穿透枪清杂\n多方向围堵薄弱；T14没出选T13，S08换S03",
  "source": "多方向围堵薄弱；T14没出选T13，S08换S03",
  "icon": "B05",
  "description_key": "B05.description",
  "reference_only": true,
  "refs": [
   "C05",
   "I04",
   "I10",
   "S03",
   "S08",
   "T13",
   "T14",
   "T15",
   "W01",
   "W05"
  ]
 },
 "B06": {
  "id": "B06",
  "name": "双工阵地",
  "desc": "C06+W07B/W08A；T09→T10→T12；S01/S05；I31/I33\nC06开局已有部署循环；W2双工成型，围炮台活动；对群稳定、首领钻机强\n固定阵地与地面封路冲突；T09缺失选T10，S05换W05",
  "source": "固定阵地与地面封路冲突；T09缺失选T10，S05换W05",
  "icon": "B06",
  "description_key": "B06.description",
  "reference_only": true,
  "refs": [
   "C06",
   "I31",
   "I33",
   "S01",
   "S05",
   "T09",
   "T10",
   "T12",
   "W05",
   "W07",
   "W08"
  ]
 },
 "B07": {
  "id": "B07",
  "name": "相位共振",
  "desc": "C01或C05+W10/W09A；T18→T17→T19；S06；I07/I08\n有能量武器后成型，W5前重点找一把；能量链清群、聚焦打首领\n开局未找到能量武器时先靠职业枪；W2没有能量前提则改选T17，T18延至W5",
  "source": "开局未找到能量武器时先靠职业枪；W2没有能量前提则改选T17，T18延至W5",
  "icon": "B07",
  "description_key": "B07.description",
  "reference_only": true,
  "refs": [
   "C01",
   "C05",
   "I07",
   "I08",
   "S06",
   "T17",
   "T18",
   "T19",
   "W09",
   "W10"
  ]
 },
 "B08": {
  "id": "B08",
  "name": "巢群逆用",
  "desc": "C06+W12B/W07；T23→T24→T21；S01/S02；I32/I39\nW2减速防区成型；W5控制一只普通怪补前排，群战稳\n首领无小怪时心控与击杀回血弱；T24缺失选T12，W12换W03",
  "source": "首领无小怪时心控与击杀回血弱；T24缺失选T12，W12换W03",
  "icon": "B08",
  "description_key": "B08.description",
  "reference_only": true,
  "refs": [
   "C06",
   "I32",
   "I39",
   "S01",
   "S02",
   "T12",
   "T21",
   "T23",
   "T24",
   "W03",
   "W07",
   "W12"
  ]
 }
}
const ACTIVE_CLASSES = ["C01", "C03", "C06"]
const ACTIVE_WEAPONS = ["W01", "W02", "W03", "W05", "W06", "W07"]
const ACTIVE_SUPPORTS = ["S01", "S02", "S03", "S04"]
const ACTIVE_TECHS = ["T01", "T02", "T03", "T05", "T08", "T09", "T10", "T12"]
const ACTIVE_ITEMS = ["I01", "I02", "I11", "I12", "I13", "I18", "I21", "I22", "I25", "I31", "I32", "I37"]

static func entry(id:String) -> Dictionary:
	for table in [CLASSES,WEAPONS,SUPPORTS,TECHS,ITEMS,BUILDS]:
		if table.has(id): return table[id]
	return {}
static func name_of(id:String) -> String:
	return str(entry(id).get("name",id))
