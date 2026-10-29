extends RefCounted
## Wave-between checkpoint only. Atomic replacement and last-known-good backup.
## SHA-256 detects accidental edits/truncation; it is not an anti-cheat mechanism.
const Build = preload("res://scripts/build_v2.gd")
const VERSION := "2.0.0"
const DEFAULT_PATH := "user://run_v2.json"
const MAX_BYTES := 1048576
const CLASS_IDS := ["marine", "marauder", "reaper", "firebat", "ghost"]
const WEAPON_IDS := ["rifle", "shotgun", "flame", "reaper", "sniper", "grenade", "tesla", "smg", "cannon"]

static func _json_safe(value: Variant, depth: int = 0) -> bool:
	if depth > 12: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING: return true
		TYPE_INT: return absi(value) <= 9007199254740991
		TYPE_FLOAT: return is_finite(value) and absf(value) <= 9007199254740991.0
		TYPE_ARRAY:
			if value.size() > 512: return false
			for element in value:
				if not _json_safe(element, depth + 1): return false
			return true
		TYPE_DICTIONARY:
			if value.size() > 256: return false
			for key in value:
				if not (key is String or key is StringName) or not _json_safe(value[key], depth + 1): return false
			return true
	return false

static func _number(value: Variant, minimum: float, maximum: float, integral: bool = false) -> bool:
	if not (value is int or value is float): return false
	var n := float(value)
	return is_finite(n) and n >= minimum and n <= maximum and (not integral or n == floor(n))

static func validate(data: Dictionary) -> bool:
	if not _json_safe(data): return false
	for key in ["class_id", "wave", "hp", "cash", "level", "xp", "xp_needed", "pending_levels", "weapons", "items", "bonuses", "offers", "locks", "reroll_cost", "level_offers", "level_rerolls", "next_uid", "pending_branch", "revive_used", "total_earned"]:
		if not data.has(key): return false
	if not data.class_id is String or not data.class_id in CLASS_IDS: return false
	if not _number(data.wave, 0, 29, true): return false
	if not _number(data.hp, 0.001, 1000000): return false
	if not _number(data.cash, 0, 100000000, true): return false
	if not _number(data.total_earned, 0, 100000000, true): return false
	if not _number(data.level, 1, 10000, true): return false
	if not _number(data.xp, 0, 100000000, true): return false
	if not _number(data.xp_needed, 15, 100000000, true): return false
	if data.xp >= data.xp_needed: return false
	if not _number(data.pending_levels, 0, 10000, true): return false
	if not _number(data.next_uid, 1, 100000000, true): return false
	if not data.revive_used is bool: return false
	if not data.weapons is Array or data.weapons.size() > 4: return false
	var uids: Array = []
	for weapon in data.weapons:
		if not weapon is Dictionary: return false
		for key in ["id", "level", "branch", "cooldown", "paid", "uid"]:
			if not weapon.has(key): return false
		if not weapon.id in WEAPON_IDS or not _number(weapon.level, 1, 4, true): return false
		if not weapon.branch in ["", "a", "b"]: return false
		if weapon.level < 3 and weapon.branch != "": return false
		if not _number(weapon.cooldown, 0, 3600) or not _number(weapon.paid, 0, 100000000): return false
		if not _number(weapon.uid, 1, data.next_uid - 1, true) or uids.has(weapon.uid): return false
		uids.append(weapon.uid)
	if not _number(data.pending_branch, -1, data.weapons.size() - 1, true): return false
	if data.pending_branch >= 0:
		var selected: Dictionary = data.weapons[int(data.pending_branch)]
		if selected.level != 3 or selected.branch != "": return false
	for i in range(data.weapons.size()):
		if data.weapons[i].level >= 3 and data.weapons[i].branch == "" and i != int(data.pending_branch): return false
	if not data.items is Array or data.items.size() > 64: return false
	var seen: Array = []
	for item in data.items:
		if not item is String or not Build.ITEM_IDS.has(item) or seen.has(item): return false
		seen.append(item)
	if not data.bonuses is Dictionary: return false
	var bonus_keys: Array = []
	for card in Build.LEVEL_CARDS.values():
		for key in card.bonus:
			if not bonus_keys.has(key): bonus_keys.append(key)
	for key in data.bonuses:
		if not bonus_keys.has(key) or not _number(data.bonuses[key], 0, 100000): return false
		if key in ["extra_dash", "turret", "revive"] and data.bonuses[key] > 1: return false
	if not data.offers is Array or not data.offers.size() in [0, 4]: return false
	for offer in data.offers:
		if not offer is Dictionary: return false
		if offer.is_empty(): continue
		if not offer.get("type", "") in ["weapon", "upgrade", "item", "support"]: return false
		if not _number(offer.get("cost"), 0, 100000000, true): return false
		if offer.type == "item":
			if not Build.ITEM_IDS.has(offer.get("id", "")): return false
		elif offer.type=="support":
			if not offer.get("id","") in ["sentry","medic_drone","raven","spider_mine"]: return false
		else:
			if not WEAPON_IDS.has(offer.get("id", "")): return false
		if offer.type == "upgrade":
			if not _number(offer.get("uid"), 1, 100000000, true): return false
			if not _number(offer.get("from_level"), 1, 3, true): return false
	if not data.locks is Array or data.locks.size() != 4: return false
	for locked in data.locks:
		if not locked is bool: return false
	if not _number(data.reroll_cost, 0, 1000000, true): return false
	if not data.level_offers is Array or not data.level_offers.size() in [0, 3]: return false
	seen.clear()
	for card in data.level_offers:
		if not card is String or not Build.LEVEL_CARDS.has(card) or seen.has(card): return false
		seen.append(card)
	if not data.level_offers.is_empty() and data.pending_levels < 1: return false
	if not _number(data.level_rerolls, 0, 3, true): return false
	if data.has("rng_state") and not data.rng_state is String: return false
	if data.has("supports"):
		if not data.supports is Array or data.supports.size()>4: return false
		var unique_supports: Array=[]
		for support in data.supports:
			if not support in ["sentry","medic_drone","raven","spider_mine"] or support in unique_supports: return false
			unique_supports.append(support)
	if data.has("run_id") and not data.run_id is String: return false
	return true

static func _decode(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES: return {}
	var parsed := JSON.new()
	if parsed.parse(file.get_as_text()) != OK: return {}
	if not parsed.data is Dictionary: return {}
	var envelope: Dictionary = parsed.data
	if envelope.get("save_version", "") != VERSION: return {}
	if not envelope.get("payload", null) is String or not envelope.get("sha256", null) is String: return {}
	var payload: String = envelope.payload
	if payload.sha256_text() != envelope.sha256: return {}
	var decoded := JSON.new()
	if decoded.parse(payload) != OK or not decoded.data is Dictionary: return {}
	var state: Dictionary = decoded.data
	return state if validate(state) else {}

static func load_run(path: String = DEFAULT_PATH) -> Dictionary:
	var primary := _decode(path)
	if not primary.is_empty(): return primary
	return _decode(path + ".bak")

static func save_run(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	if not validate(data): return false
	var absolute := ProjectSettings.globalize_path(path)
	var directory := absolute.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return false
	var payload := JSON.stringify(data, "", true, true)
	var envelope := {"save_version":VERSION, "timestamp":int(Time.get_unix_time_from_system()), "payload":payload, "sha256":payload.sha256_text()}
	var text := JSON.stringify(envelope, "", true, true)
	if text.to_utf8_buffer().size() > MAX_BYTES: return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or _decode(temp).is_empty(): return false
	# Only rotate a valid previous checkpoint, never overwrite the backup with corruption.
	if not _decode(path).is_empty():
		var backup_temp := absolute + ".bak.tmp"
		if DirAccess.copy_absolute(absolute, backup_temp) != OK: return false
		if DirAccess.rename_absolute(backup_temp, absolute + ".bak") != OK: return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute) != OK: return false
	return true

static func clear_run(path: String = DEFAULT_PATH) -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		var candidate := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(candidate): DirAccess.remove_absolute(candidate)
