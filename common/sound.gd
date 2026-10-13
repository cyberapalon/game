extends Node
## All sounds are synthesized here from original sine/noise recipes.

var muted: bool = false
var _voices: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer
var _clips: Dictionary[StringName, AudioStreamWAV] = {}
var _voice_index: int = 0


func _ready() -> void:
	# The dummy headless audio driver never mixes queued WAV playback resources.
	if DisplayServer.get_name() == "headless":
		return
	for index in range(6):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14.0
		add_child(voice)
		_voices.append(voice)
	var frequencies: Dictionary[StringName, float] = {
		&"jump": 460.0,
		&"land": 110.0,
		&"dash": 680.0,
		&"swing": 350.0,
		&"hit": 155.0,
		&"hurt": 90.0,
		&"death": 65.0,
		&"enemy_death": 240.0,
		&"pickup": 720.0,
		&"beacon": 540.0
	}
	for kind: StringName in frequencies:
		_clips[kind] = _tone(frequencies[kind], 0.24 if kind != &"pickup" else 0.65)
	_ambient = AudioStreamPlayer.new()
	_ambient.volume_db = -22.0
	_ambient.stream = _garden_drone()
	add_child(_ambient)
	_ambient.play()


func play(kind: StringName) -> void:
	if muted or _voices.is_empty() or not _clips.has(kind):
		return
	var voice := _voices[_voice_index]
	_voice_index = (_voice_index + 1) % _voices.size()
	voice.stream = _clips[kind]
	voice.play()


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)


func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null
	if is_instance_valid(_ambient):
		_ambient.stop()
		_ambient.stream = null
	_clips.clear()


func _tone(frequency: float, duration: float) -> AudioStreamWAV:
	var rate: int = 22050
	var count := int(rate * duration)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index in range(count):
		var t := float(index) / rate
		var envelope := minf(t * 150.0, 1.0) * pow(1.0 - t / duration, 2.0)
		var wave := (
			sin(TAU * frequency * t * (1.0 - t * 0.6)) * 0.65 + sin(TAU * frequency * 1.5 * t) * 0.2
		)
		samples.encode_s16(index * 2, int(wave * envelope * 22000.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.data = samples
	return clip


func _garden_drone() -> AudioStreamWAV:
	var rate: int = 22050
	var samples := PackedByteArray()
	samples.resize(rate * 8 * 2)
	for index in range(rate * 8):
		var t := float(index) / rate
		var envelope := 0.65 + 0.35 * cos(TAU * t / 8.0)
		var wave := (
			sin(TAU * 110.0 * t) * 0.34 + sin(TAU * 165.0 * t) * 0.18 + sin(TAU * 220.0 * t) * 0.12
		)
		samples.encode_s16(index * 2, int(wave * envelope * 12000.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
	clip.loop_end = rate * 8
	clip.data = samples
	return clip
