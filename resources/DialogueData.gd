extends Resource
class_name DialogueData

# ============================================================
# 所有台词数据（按场景分组）
# ============================================================

const DIALOGUES: Dictionary = {
	# ---- 第一层 ----
	"floor1_mirror": {
		"speaker": "女伴",
		"lines": [
			"这镜子……好像有什么不对劲。",
			"别照太久，林晚姐姐说过……",
			"……千万不要回头看。"
		]
	},
	"floor1_elevator_locked": {
		"speaker": "旁白",
		"lines": [
			"电梯门紧锁着，需要电梯卡才能启动。"
		]
	},

	# ---- 第二层 ----
	"floor2_npc_death": {
		"speaker": "旁白",
		"lines": [
			"走廊深处传来一阵凄厉的惨叫声……男路人死了。"
		]
	},
	"floor2_boy_plead": {
		"speaker": "男伴",
		"lines": [
			"别乱跑，跟着阿柚！"
		]
	},
	"floor2_girl_rebel": {
		"speaker": "女伴",
		"lines": [
			"我受够了，这里有鬼，我要自己找出口！"
		]
	},
	"floor2_girl_locked": {
		"speaker": "女伴",
		"lines": [
			"我听到高跟鞋声越来越近了！救命啊！……（寂静）"
		]
	},
	"floor2_girl_last_words": {
		"speaker": "女伴",
		"lines": [
			"救……救命……啊……"
		]
	},

	# ---- 第三层 ----
	"floor3_boy_see_monster": {
		"speaker": "男伴",
		"lines": [
			"是人形！快跑！"
		]
	},
	"floor3_boy_death": {
		"speaker": "旁白",
		"lines": [
			"男伴拔腿就跑，却忘了这里的规则……",
			"巨嘴从地面冲出，将他吞噬。"
		]
	},
	"floor3_cool_rule": {
		"speaker": "高冷NPC",
		"lines": [
			"这楼里的东西不是用眼睛看的。",
			"不要问我为什么戴墨镜。"
		]
	},
	"floor3_cheer_rule": {
		"speaker": "开朗NPC",
		"lines": [
			"我听到高跟鞋声越来越近了！"
		]
	},
	"floor3_human_monster_eye_contact": {
		"speaker": "旁白",
		"lines": [
			"人形怪物停下了脚步……它与你对视。",
			"禁时段规则触发，灵魂互换……"
		]
	},
	"floor3_bind_success": {
		"speaker": "旁白",
		"lines": [
			"高冷NPC和开朗NPC将你的身体绑住……",
			"你在怪物身体里，抬起脚……用力奔跑！"
		]
	},
	"floor3_monster_death": {
		"speaker": "旁白",
		"lines": [
			"巨嘴冲出，将怪物身体吞噬……",
			"07:00 到来，怪物彻底死亡。"
		]
	},
	"floor3_elevator_final": {
		"speaker": "阿柚",
		"lines": [
			"终于……可以离开这里了。"
		]
	},

	# ---- 结局 ----
	"ending_final": {
		"speaker": "旁白",
		"lines": [
			"终于安全了……"
		]
	},
	"ending_revelation": {
		"speaker": "纸条",
		"lines": [
			"她在说谎"
		]
	}
}

# ============================================================
# 查询接口
# ============================================================

static func get_dialogue(key: String) -> Dictionary:
	return DIALOGUES.get(key, {})

static func has_dialogue(key: String) -> bool:
	return DIALOGUES.has(key)
