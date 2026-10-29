class_name SFAudio
extends Node
## Original, sample-free synthesised game audio. All sounds are created in RAM.
## Add as a child, then call play_sfx("rifle"), etc. Safe with Godot's Dummy audio driver.

const SAMPLE_RATE: int = 22050
const VOICE_COUNT: int = 10
const DURATIONS: Dictionary = {
	"rifle": 0.105, "shotgun": 0.23, "flame": 0.27,
	"hurt": 0.20, "kill": 0.12, "pickup": 0.12,
	"dash": 0.25, "level": 0.60, "buy": 0.30,
	"wave": 0.65, "boss": 1.0, "victory": 1.40, "defeat": 1.10,
}
const GAINS: Dictionary = {
	"rifle": -19.0, "shotgun": -16.5, "flame": -22.0,
	"hurt": -13.0, "kill": -23.0, "pickup": -22.0,
	"dash": -17.0, "level": -15.0, "buy": -17.0,
	"wave": -16.0, "boss": -15.0, "victory": -14.0, "defeat": -16.0,
}
const MIN_INTERVALS: Dictionary = {
	"rifle": 0.08, "shotgun": 0.07, "flame": 0.15,
	"hurt": 0.12, "kill": 0.055, "pickup": 0.07,
}

var muted: bool = false
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _last_played: Dictionary = {}
var _cursor: int = 0
var _pitch_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	setup()


func setup() -> void:
	if not _streams.is_empty():
		return
	_pitch_rng.randomize()
	for kind: String in DURATIONS.keys():
		_streams[kind] = _make_sound(kind, float(DURATIONS[kind]))
	for i: int in range(VOICE_COUNT):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "SynthVoice%d" % i
		voice.max_polyphony = 1
		add_child(voice)
		_voices.append(voice)


func play_sfx(kind: String, volume_db: float = 0.0) -> void:
	# The dedicated/headless path needs no playback (and no audio-device warnings).
	if muted or not is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	if _streams.is_empty():
		setup()
	if not _streams.has(kind):
		return
	var now: float = Time.get_ticks_usec() / 1000000.0
	var min_interval: float = float(MIN_INTERVALS.get(kind, 0.0))
	if now - float(_last_played.get(kind, -100.0)) < min_interval:
		return
	_last_played[kind] = now
	var voice: AudioStreamPlayer = _select_voice(kind)
	# Merge a repeated critical cue rather than interrupt the cue already playing.
	if kind in ["hurt", "boss"] and voice.playing: return
	voice.stop()
	voice.stream = _streams[kind]
	voice.volume_db = float(GAINS.get(kind, -18.0)) + clampf(volume_db, -30.0, 6.0)
	voice.pitch_scale = _pitch_rng.randf_range(0.94, 1.06) if MIN_INTERVALS.has(kind) else 1.0
	voice.play()


func _select_voice(kind: String) -> AudioStreamPlayer:
	# Independent critical voices cannot be stolen by ordinary fire/pickup sounds.
	if kind == "hurt": return _voices[0]
	if kind == "boss": return _voices[1]
	var ordinary_count := VOICE_COUNT - 2
	var voice: AudioStreamPlayer = _voices[2 + _cursor]
	for offset in range(ordinary_count):
		var candidate: AudioStreamPlayer = _voices[2 + (_cursor + offset) % ordinary_count]
		if not candidate.playing:
			voice = candidate
			break
	_cursor = (_cursor + 1) % ordinary_count
	return voice


func toggle_muted() -> bool:
	muted = not muted
	if muted:
		for voice: AudioStreamPlayer in _voices:
			voice.stop()
	return muted


func _make_sound(kind: String, duration: float) -> AudioStreamWAV:
	var count: int = int(duration * SAMPLE_RATE)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 781237 + kind.hash()
	var filtered_noise: float = 0.0
	for i: int in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var u: float = t / duration
		var noise: float = rng.randf_range(-1.0, 1.0)
		filtered_noise = filtered_noise * 0.73 + noise * 0.27
		var s: float = _sample(kind, t, u, noise, filtered_noise)
		# A 3 ms edge ramp prevents clicks; tanh gently limits stacked harmonics.
		var edge: float = minf(t / 0.003, (duration - t) / 0.008)
		s = tanh(s) * clampf(edge, 0.0, 1.0)
		var value: int = int(clampf(s, -1.0, 1.0) * 32760.0)
		bytes[i * 2] = value & 255
		bytes[i * 2 + 1] = (value >> 8) & 255
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _sample(kind: String, t: float, u: float, noise: float, low_noise: float) -> float:
	match kind:
		"rifle":
			return (noise * exp(-u * 22.0) * 1.35 + low_noise * exp(-u * 6.5) * 0.9 + sin(TAU * (175.0 * t - 510.0 * t * t)) * exp(-u * 8.0) * 0.7)
		"shotgun":
			return noise * exp(-u * 15.0) * 1.5 + low_noise * exp(-u * 4.2) * 1.9 + sin(TAU * (93.0 * t - 110.0 * t * t)) * exp(-u * 6.0)
		"flame":
			return (low_noise * 2.3 + noise * 0.23 + sin(TAU * 48.0 * t) * 0.14) * pow(1.0 - u, 1.2)
		"hurt":
			return (sin(TAU * (205.0 * t - 360.0 * t * t)) * 0.65 + noise * 0.32) * exp(-u * 4.0)
		"kill":
			return (low_noise * 1.3 + sin(TAU * (160.0 * t - 480.0 * t * t)) * 0.3) * exp(-u * 4.0)
		"pickup":
			return sin(TAU * (1100.0 * t + 2300.0 * t * t)) * sin(PI * u) * 0.50
		"dash":
			return (low_noise * 1.7 + sin(TAU * (180.0 * t + 1250.0 * t * t)) * 0.19) * sin(PI * u) * (1.0 - u * 0.6)
		"level":
			var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
			var index: int = mini(int(u * 4.0), 3)
			var note_phase: float = fmod(t, 0.15)
			return _bell(notes[index], note_phase) * minf((1.0 - u) * 5.0, 1.0)
		"buy":
			var f: float = 659.25 if u < 0.45 else 987.77
			return _bell(f, fmod(t, 0.135)) * pow(1.0 - u, 0.7)
		"wave":
			var f: float = 220.0 if u < 0.3 else (330.0 if u < 0.6 else 440.0)
			return (sin(TAU * f * t) * 0.45 + sin(TAU * f * 2.0 * t) * 0.16) * sin(PI * u)
		"boss":
			return (sin(TAU * (65.0 * t + 35.0 * t * t)) * 0.55 + sin(TAU * (98.0 * t + 50.0 * t * t)) * 0.25 + low_noise * 0.5) * sin(PI * u)
		"victory":
			var melody: Array[float] = [523.25, 659.25, 783.99, 1046.50, 1046.50]
			var index: int = mini(int(u * 5.0), 4)
			var phase: float = fmod(t, 0.28)
			return (_bell(melody[index], phase) + _bell(261.63, t) * 0.35 + _bell(392.0, t) * 0.20) * minf((1.0 - u) * 7.0, 1.0)
		"defeat":
			var f: float = 293.66 if u < 0.33 else (233.08 if u < 0.66 else 146.83)
			return (sin(TAU * f * t) * 0.5 + sin(TAU * f * 1.5 * t) * 0.18) * pow(1.0 - u, 0.8)
	return 0.0


func _bell(frequency: float, t: float) -> float:
	return (sin(TAU * frequency * t) * 0.55 + sin(TAU * frequency * 2.0 * t) * 0.14 + sin(TAU * frequency * 3.0 * t) * 0.05) * exp(-t * 6.0)
