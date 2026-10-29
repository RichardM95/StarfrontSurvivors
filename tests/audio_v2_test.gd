extends SceneTree
const Sound = preload("res://scripts/audio.gd")
func _initialize() -> void:
	var s=Sound.new()
	s.setup()
	assert(s._voices.size()==10)
	assert(s.MIN_INTERVALS.rifle==0.08)
	assert(s._select_voice("hurt")==s._voices[0])
	assert(s._select_voice("boss")==s._voices[1])
	for i in range(32):
		var voice=s._select_voice("rifle")
		assert(voice!=s._voices[0] and voice!=s._voices[1])
	s.free()
	print("AUDIO_V2_TESTS 36 passed, 0 failed (routing/interval only; no audio-device playback)")
	quit()
