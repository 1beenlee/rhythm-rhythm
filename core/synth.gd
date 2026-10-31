extends RefCounted
class_name RhythmSynth

# All PCM audio is generated deterministically locally; no CDN, licensed music or network.
const SAMPLE_RATE := 11025
const TAU_VALUE := PI * 2.0

static func make_song(game_id: String, bpm: float, duration: float, calls: Array) -> AudioStreamWAV:
    var count := int(ceilf(duration * SAMPLE_RATE))
    var pcm := PackedByteArray()
    pcm.resize(count * 2)
    var call_index := 0
    for i in count:
        var t := float(i) / SAMPLE_RATE
        var phase := fposmod(t * bpm / 60.0, 1.0)
        var bass := sin(TAU_VALUE * (75.0 if game_id == "beat_factory" else 92.0) * t) * exp(-phase * 22.0) * 0.28
        var bright := sin(TAU_VALUE * 630.0 * t) * exp(-phase * 50.0) * 0.07
        var pad := sin(TAU_VALUE * (165.0 if game_id == "echo_planet" else 220.0) * t) * 0.035
        while call_index < calls.size() - 1 and t >= float(calls[call_index + 1].get("beat", 0.0)) * 60.0 / bpm:
            call_index += 1
        var melody := 0.0
        if calls.size() > 0:
            var pulse_time := t - float(calls[call_index].get("beat", 0.0)) * 60.0 / bpm
            if pulse_time >= 0.0 and pulse_time < 0.16:
                var note := 380.0 + float(calls[call_index].get("tone", 0)) * 110.0
                melody = sin(TAU_VALUE * note * pulse_time) * exp(-pulse_time * 17.0) * 0.36
        var wave := clampf(bass + bright + pad + melody, -0.95, 0.95)
        pcm.encode_s16(i * 2, int(wave * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = pcm
    return stream

static func make_hit(kind: String) -> AudioStreamWAV:
    var count := int(SAMPLE_RATE * 0.14)
    var pcm := PackedByteArray()
    pcm.resize(count * 2)
    for i in count:
        var t := float(i) / SAMPLE_RATE
        var freq := 740.0 if kind == "Perfect" else (530.0 if kind == "Good" else 160.0)
        var wave := sin(TAU_VALUE * freq * t) * exp(-t * 26.0) * 0.26
        pcm.encode_s16(i * 2, int(wave * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = pcm
    return stream
