extends SceneTree
const Main=preload("res://scripts/main_v5.gd")
func _initialize():call_deferred("capture")
func capture():
 var game=Main.new();root.add_child(game)
 root.size=Vector2i(1200,675)
 await process_frame
 var cases=[{"name":"boss-mobile-left","page":"boss","mobile":true,"left":true}]
 for c in cases:
  if c.get("wide",false):root.size=Vector2i(1200,540)
  elif c.get("mobile",false):root.size=Vector2i(1200,675)
  game.debug_density_scale=2.0 if c.get("mobile",false) else 1.0
  game.settings.large_font=c.get("mobile",false)
  game.settings.left_handed=c.get("left",false)
  game.debug_preview(c.page)
  await process_frame
  await process_frame
  await create_timer(0.25).timeout
  if c.has("scroll"):
   for sc in game.page.find_children("*","ScrollContainer",true,false):sc.scroll_vertical=int(c.scroll)
   await process_frame
   await process_frame
  await RenderingServer.frame_post_draw
  var path="/workspace/scratch/ee0b12867f8b/starfront-survivors/exports/v5-preview/"+c.name+".png"
  var code=root.get_texture().get_image().save_png(path)
  print("V5_CAPTURE ",c.name," code=",code," viewport=",root.size," window=",DisplayServer.window_get_size())
 game.debug_density_scale=1.0;game.settings.large_font=false;game.debug_preview("boss");game.pause_game()
 print("V5_CAPTURE_DONE")
