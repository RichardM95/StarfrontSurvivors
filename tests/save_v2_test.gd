extends SceneTree
const Save = preload("res://scripts/save_v2.gd")
const PATH := "user://test_save_v2/checkpoint.json"
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("run_tests")
func check(value: bool, description: String) -> void:
	if value:
		passed += 1
		print("PASS ", description)
	else:
		failed += 1
		push_error("FAIL " + description)
func fixture() -> Dictionary:
	return {"class_id":"marine", "wave":6, "hp":118.0, "cash":348, "level":14, "xp":85, "xp_needed":127, "pending_levels":2,
		"weapons":[{"id":"rifle", "level":3, "branch":"a", "cooldown":0.0, "paid":90, "uid":1}],
		"items":["core", "reactor"], "bonuses":{"damage_mult":0.48},
		"offers":[{"id":"flame", "type":"weapon", "cost":40},{},{},{}], "locks":[true,false,false,false],
		"reroll_cost":13, "level_offers":["health", "armor", "damage"], "level_rerolls":1, "rng_state":"9223372036854775807", "next_uid":2, "pending_branch":-1, "revive_used":false, "total_earned":500}
func raw(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()
func run_tests() -> void:
	Save.clear_run(PATH)
	check(Save.load_run(PATH).is_empty(), "Missing save yields empty result")
	var state := fixture()
	check(Save.validate(state), "Complete checkpoint validates")
	check(Save.save_run(state, PATH), "First atomic save succeeds")
	var recovered := Save.load_run(PATH)
	check(recovered.get("wave") == 6, "Completed wave roundtrips")
	check(recovered.get("cash") == 348, "Economy roundtrips")
	check(recovered.get("weapons", [])[0].branch == "a", "Mutually exclusive weapon choice persists")
	check(recovered.get("locks", []) == [true,false,false,false], "Shop lock persists")
	check(recovered.get("offers", [])[0].id == "flame", "Exact offer cache persists")
	check(recovered.get("pending_levels") == 2 and recovered.get("level_rerolls") == 1, "Pending choices and reroll counter persist")
	check(recovered.get("rng_state") == "9223372036854775807", "64-bit RNG identity remains exact string")
	state.cash = 400
	check(Save.save_run(state, PATH), "Replacing a checkpoint succeeds")
	check(Save.load_run(PATH).cash == 400, "Most recent purchase balance preferred")
	check(FileAccess.file_exists(PATH + ".bak"), "Last-known-good backup exists")
	raw(PATH, "{truncated")
	check(Save.load_run(PATH).cash == 348, "Truncation recovers previous valid checkpoint")
	state.cash = 450
	check(Save.save_run(state, PATH), "Save can replace corrupt primary")
	check(Save.load_run(PATH).cash == 450, "New good checkpoint takes precedence")
	raw(PATH, JSON.stringify({"save_version":"99.0", "payload":"{}", "sha256":"bad"}))
	check(Save.load_run(PATH).cash == 348, "Unknown primary version falls back to known backup")
	Save.clear_run(PATH)
	raw(PATH, "{truncated")
	check(Save.load_run(PATH).is_empty(), "Corruption without backup fails safely")
	check(Save.save_run(fixture(), PATH), "Valid state replaces malformed primary")
	var altered := fixture()
	altered.cash = -1
	check(not Save.save_run(altered, PATH), "Negative currency rejected before disk mutation")
	check(Save.load_run(PATH).cash == 348, "Invalid state does not destroy valid checkpoint")
	altered = fixture(); altered.erase("weapons")
	check(not Save.validate(altered), "Truncated model rejected")
	altered = fixture(); altered.hp = NAN
	check(not Save.validate(altered), "NaN rejected")
	altered = fixture(); altered.hp = INF
	check(not Save.validate(altered), "Infinity rejected")
	altered = fixture(); altered.class_id = "unknown"
	check(not Save.validate(altered), "Unknown class rejected")
	altered = fixture(); altered.wave = 30
	check(not Save.validate(altered), "Victory is not a resumable checkpoint")
	altered = fixture(); altered.weapons[0].level = 1; altered.weapons[0].branch = "a"
	check(not Save.validate(altered), "Premature specialization rejected")
	altered = fixture(); altered.weapons[0].branch = "both"
	check(not Save.validate(altered), "Invalid specialization rejected")
	altered = fixture(); altered.weapons.resize(5)
	check(not Save.validate(altered), "Weapon slot overflow rejected")
	altered = fixture(); altered.wave = 2.5
	check(not Save.validate(altered), "Fractional wave rejected")
	altered = fixture(); altered.rng_state = 9223372036854775807
	check(not Save.validate(altered), "Potentially lossy RNG integer rejected")
	var envelope_file := FileAccess.open(PATH, FileAccess.READ)
	var envelope: Dictionary = JSON.parse_string(envelope_file.get_as_text())
	envelope_file.close()
	envelope.payload += " "
	raw(PATH, JSON.stringify(envelope))
	check(Save.load_run(PATH).is_empty(), "Checksum mismatch rejected")
	Save.save_run(fixture(), PATH)
	Save.save_run(fixture(), PATH)
	Save.clear_run(PATH)
	check(not FileAccess.file_exists(PATH) and not FileAccess.file_exists(PATH + ".bak"), "Clear removes primary and backup so abandoned run cannot return")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261028
	for class_id in Save.Build.CLASS_IDS:
		var model: Dictionary = Save.Build.new_run(class_id)
		check(Save.validate(model), "Model new_run schema: " + class_id)
		model.wave = 1
		Save.Build.begin_shop(model, rng)
		check(Save.validate(model), "Model shop schema: " + class_id)
		Save.Build.gain_xp(model, 100)
		Save.Build.roll_level(model, rng)
		check(Save.validate(model), "Model pending level schema: " + class_id)
		check(Save.save_run(model, PATH), "Model choice checkpoint serializes: " + class_id)
		var restored := Save.load_run(PATH)
		check(restored.level_offers == model.level_offers, "Model exact level choices restore: " + class_id)
		Save.clear_run(PATH)
	var pending := fixture()
	pending.weapons[0].branch = ""
	pending.pending_branch = 0
	check(Save.validate(pending) and Save.save_run(pending, PATH), "Pending Lv3 specialization survives interruption")
	check(Save.load_run(PATH).pending_branch == 0, "Pending branch selector restores")
	pending.pending_branch = -1
	check(not Save.validate(pending), "Unclaimed required specialization is invalid")
	var duplicate := fixture()
	duplicate.weapons.append(duplicate.weapons[0].duplicate())
	check(not Save.validate(duplicate), "Duplicate weapon identities rejected")
	duplicate = fixture(); duplicate.items.append("core")
	check(not Save.validate(duplicate), "Duplicate unique trade-off items rejected")
	duplicate = fixture(); duplicate.level_offers[0] = "unknown"
	check(not Save.validate(duplicate), "Unknown level card rejected")
	Save.clear_run(PATH)
	print("SAVE_V2_TEST: ", passed, " passed / ", failed, " failed")
	quit(1 if failed else 0)
