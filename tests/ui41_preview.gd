extends SceneTree
var game
func _initialize(): call_deferred("run")
func shot(name):
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/ui/"+name+".png")
func run():
	game=load("res://main.tscn").instantiate(); root.add_child(game)
	game.test_mode=true; game.touch_mode=true
	game.radio.clear_queue()
	await shot("01-menu")
	game.start_run(); game.paused=false; game.radio.clear_queue()
	game.radio.play([{"speaker":"泰隆","text":"指挥部，前线已就位。通讯测试：保持移动，注意危险预警。"}])
	game.radio.advance()
	await create_timer(0.4).timeout
	game.hurt_timer=0; game.queue_redraw()
	await shot("02-battle-radio")
	game.radio.clear_queue(); game.cash=500; game.finish_wave(); game._show_shop()
	await shot("03-shop")
	game.build.pending_levels=1; game.Build.roll_level(game.build,game.rng); game._show_level()
	await shot("04-upgrade")
	game.weapons[0].level=3; game._show_branch(0)
	await shot("05-branch")
	game._show_bridge()
	await shot("06-bridge")
	game.radio.show_history()
	await shot("07-history")
	game.radio.close_history(); game._show_shop()
	for size in [Vector2i(960,540),Vector2i(960,432)]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		root.min_size=Vector2i.ZERO
		root.size=size
		DisplayServer.window_set_size(size)
		await create_timer(1.0).timeout
		print("RATIO requested=",size," actual=",DisplayServer.window_get_size()," viewport=",root.size)
		await shot("shop-"+str(size.x)+"x"+str(size.y))
	game._shop_portrait("collins"); await shot("08-collins")
	game._shop_portrait("ella"); await shot("09-ella")
	game._shop_portrait("adjutant"); await shot("10-adjutant")
	game._shop_portrait("hank")
	print("UI41_SCREENSHOTS_DONE")
