extends Node

const ITEMS := {
	"wheat_seed": {"name": "小麦种子", "category": "种子", "price": 5, "buy_price": 8},
	"carrot_seed": {"name": "胡萝卜种子", "category": "种子", "price": 6, "buy_price": 10},
	"moonberry_seed": {"name": "月莓种子", "category": "种子", "price": 12, "buy_price": 20},
	"wheat": {"name": "小麦", "category": "作物", "price": 18},
	"carrot": {"name": "胡萝卜", "category": "作物", "price": 24},
	"moonberry": {"name": "月莓", "category": "作物", "price": 42},
	"tree": {"name": "树木", "category": "采集物", "price": 10},
	"stone": {"name": "石头", "category": "矿物", "price": 4},
	"copper_ore": {"name": "铜矿", "category": "矿物", "price": 16},
	"iron_ore": {"name": "铁矿", "category": "矿物", "price": 28},
	"moonlight_ore": {"name": "月辉矿", "category": "矿物", "price": 65},
	"wild_berries": {"name": "野生浆果", "category": "采集物", "price": 9},
	"herb": {"name": "草药", "category": "采集物", "price": 12},
	"mushroom": {"name": "蘑菇", "category": "采集物", "price": 14},
	"reed": {"name": "芦苇", "category": "采集物", "price": 7},
	"river_trout": {"name": "河鳟", "category": "鱼", "price": 22},
	"silver_scale_fish": {"name": "银鳞鱼", "category": "鱼", "price": 34},
	"moonlight_fish": {"name": "月光鱼", "category": "鱼", "price": 58},
	"seal_fragment": {"name": "封印碎片", "category": "任务物品", "price": 0},
	"witch_amulet": {"name": "女巫护符", "category": "任务物品", "price": 0},
}

func get_info(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {"name": item_id, "category": "未知", "price": 0})

func get_item_name(item_id: String) -> String:
	return str(get_info(item_id).get("name", item_id))

func get_sell_price(item_id: String) -> int:
	return int(get_info(item_id).get("price", 0))

func get_buy_price(item_id: String) -> int:
	return int(get_info(item_id).get("buy_price", 0))
