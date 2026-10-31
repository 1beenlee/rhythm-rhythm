extends RefCounted
class_name RhythmSynth

# Original 44.1kHz 16-bit stereo soundtracks, BGM loops, and world/UI SFX live in res://assets/audio/*.wav.
# Procedural 44.1kHz stereo synthesis remains as a deterministic fallback for newly scaffolded games.
const SAMPLE_RATE := 44100
const TAU_VALUE := PI * 2.0
static var _wav_cache: Dictionary = {}

static func load_wav_asset(res_path: String, looped: bool = false) -> AudioStreamWAV:
	var cache_key := "%s:%d" % [res_path, 1 if looped else 0]
	if _wav_cache.has(cache_key):
		return _wav_cache[cache_key]
	if FileAccess.file_exists(res_path):
		var raw := FileAccess.get_file_as_bytes(res_path)
		if raw.size() > 44 and raw.slice(0, 4).get_string_from_ascii() == "RIFF":
			var channels := raw.decode_u16(22)
			var rate := raw.decode_u32(24)
			var bits := raw.decode_u16(34)
			var offset := 12
			var data_offset := 44
			var data_size := raw.size() - 44
			while offset + 8 <= raw.size():
				var chunk_id := raw.slice(offset, offset + 4).get_string_from_ascii()
				var chunk_len := raw.decode_u32(offset + 4)
				if chunk_id == "data":
					data_offset = offset + 8
					data_size = mini(chunk_len, raw.size() - data_offset)
					break
				offset += 8 + chunk_len
			if bits == 16 and data_offset < raw.size():
				var stream := AudioStreamWAV.new()
				stream.format = AudioStreamWAV.FORMAT_16_BITS
				stream.mix_rate = int(rate)
				stream.stereo = (channels >= 2)
				stream.data = raw.slice(data_offset, data_offset + data_size)
				if looped:
					var bytes_per_frame := 4 if stream.stereo else 2
					stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
					stream.loop_begin = 0
					stream.loop_end = int(data_size / bytes_per_frame)
				_wav_cache[cache_key] = stream
				return stream
	if ResourceLoader.exists(res_path):
		var loaded := ResourceLoader.load(res_path)
		if loaded is AudioStreamWAV:
			var stream_copy := (loaded as AudioStreamWAV).duplicate() as AudioStreamWAV
			if looped:
				var bytes_per_frame := 4 if stream_copy.stereo else 2
				stream_copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream_copy.loop_begin = 0
				stream_copy.loop_end = int(stream_copy.data.size() / bytes_per_frame)
			_wav_cache[cache_key] = stream_copy
			return stream_copy
	return null

static func make_song(game_id: String, bpm: float, duration: float, calls: Array) -> AudioStreamWAV:
	var asset_path := "res://assets/audio/%s_song.wav" % game_id
	var prebuilt := load_wav_asset(asset_path, false)
	if prebuilt != null:
		return prebuilt
	var count := int(ceilf(duration * SAMPLE_RATE))
	var pcm := PackedByteArray()
	pcm.resize(count * 4)
	var call_index := 0
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var phase := fposmod(t * bpm / 60.0, 1.0)
		var bass := sin(TAU_VALUE * 98.0 * t) * exp(-phase * 18.0) * 0.28
		var pad_l := sin(TAU_VALUE * 220.0 * t) * 0.06
		var pad_r := sin(TAU_VALUE * 277.18 * t) * 0.06
		while call_index < calls.size() - 1 and t >= float(calls[call_index + 1].get("beat", 0.0)) * 60.0 / bpm:
			call_index += 1
		var melody := 0.0
		if calls.size() > 0:
			var pulse_time := t - float(calls[call_index].get("beat", 0.0)) * 60.0 / bpm
			if pulse_time >= 0.0 and pulse_time < 0.18:
				var note := 440.0 + float(calls[call_index].get("tone", 0)) * 110.0
				melody = sin(TAU_VALUE * note * pulse_time) * exp(-pulse_time * 16.0) * 0.34
		var left := clampf(bass + pad_l + melody * 0.9, -0.95, 0.95)
		var right := clampf(bass + pad_r + melody * 1.05, -0.95, 0.95)
		pcm.encode_s16(i * 4, int(left * 32767.0))
		pcm.encode_s16(i * 4 + 2, int(right * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = pcm
	return stream

static func make_bgm(kind: String) -> AudioStreamWAV:
	# kind: "title", "select", "results_superb", "results_ok", "results_try_again"
	var path := "res://assets/audio/bgm_%s.wav" % kind
	var bgm := load_wav_asset(path, true)
	if bgm != null:
		return bgm
	# Fallback procedural loop if asset missing
	var count := int(SAMPLE_RATE * 4.0)
	var pcm := PackedByteArray()
	pcm.resize(count * 4)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var w := sin(TAU_VALUE * 261.63 * t) * 0.12 + sin(TAU_VALUE * 329.63 * t) * 0.10
		var s := int(clampf(w, -0.9, 0.9) * 32767.0)
		pcm.encode_s16(i * 4, s)
		pcm.encode_s16(i * 4 + 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

static func make_ui_sfx(kind: String) -> AudioStreamWAV:
	# kind: "focus", "click", "eval"
	var path := "res://assets/audio/ui_%s.wav" % kind
	var sfx := load_wav_asset(path, false)
	if sfx != null:
		return sfx
	var dur := 0.08 if kind == "focus" else 0.14
	var count := int(SAMPLE_RATE * dur)
	var pcm := PackedByteArray()
	pcm.resize(count * 4)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var f := 880.0 if kind == "focus" else (1046.5 if t < 0.05 else 1318.5)
		var w := sin(TAU_VALUE * f * t) * exp(-t * 32.0) * 0.25
		var s := int(clampf(w, -0.95, 0.95) * 32767.0)
		pcm.encode_s16(i * 4, s)
		pcm.encode_s16(i * 4 + 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = pcm
	return stream

static func make_world_hit(game_id: String, kind: String, lane: String = "") -> AudioStreamWAV:
	var kind_lower := kind.to_lower()
	if game_id == "rhythm_kitchen" and kind_lower == "perfect":
		var side := "right" if lane == "right" else "left"
		var kitchen_sfx := load_wav_asset("res://assets/audio/rhythm_kitchen_perfect_%s.wav" % side)
		if kitchen_sfx != null:
			return kitchen_sfx
	var world_sfx := load_wav_asset("res://assets/audio/%s_%s.wav" % [game_id, kind_lower])
	if world_sfx != null:
		return world_sfx
	return make_hit(kind)

static func make_fanfare(superb: bool) -> AudioStreamWAV:
	var path := "res://assets/audio/fanfare_superb.wav" if superb else "res://assets/audio/fanfare_ok.wav"
	var sfx := load_wav_asset(path)
	if sfx != null:
		return sfx
	return make_hit("Perfect" if superb else "Good")

static func make_hit(kind: String) -> AudioStreamWAV:
	var fallback_world := load_wav_asset("res://assets/audio/beat_factory_%s.wav" % kind.to_lower())
	if fallback_world != null:
		return fallback_world
	var count := int(SAMPLE_RATE * 0.16)
	var pcm := PackedByteArray()
	pcm.resize(count * 4)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var freq := 740.0 if kind == "Perfect" else (530.0 if kind == "Good" else 160.0)
		var wave := sin(TAU_VALUE * freq * t) * exp(-t * 24.0) * 0.28
		var s := int(clampf(wave, -0.95, 0.95) * 32767.0)
		pcm.encode_s16(i * 4, s)
		pcm.encode_s16(i * 4 + 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = pcm
	return stream
