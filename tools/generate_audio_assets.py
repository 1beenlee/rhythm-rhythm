#!/usr/bin/env python3
"""
Rhythm Rhythm v0.2 — Deterministic 44.1kHz Stereo Original Soundtrack & SFX Generator
Generates all production WAV assets under assets/audio/ and writes assets/audio/PROVENANCE.json.
Every track's lead melody and rhythmic cues are 100% locked to its chart.json events and calls.
"""
import array
import json
import math
import wave
from pathlib import Path

SAMPLE_RATE = 44100
TAU = math.pi * 2.0

ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "assets" / "audio"


def midi_to_hz(midi: float) -> float:
    return 440.0 * (2.0 ** ((midi - 69.0) / 12.0))


def soft_clip(x: float) -> float:
    return math.tanh(x * 1.15) * 0.92


def write_wav_stereo(path: Path, left: array.array, right: array.array) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    n = min(len(left), len(right))
    interleaved = array.array("h", [0] * (n * 2))
    # Ultra-short 2ms fade-in so beat 0.0 transients stay razor-sharp, 100ms fade-out at end
    fade_in = int(0.002 * SAMPLE_RATE)
    fade_out = int(0.10 * SAMPLE_RATE)
    for i in range(n):
        env = 1.0
        if i < fade_in:
            env = i / float(max(1, fade_in))
        elif i > n - fade_out:
            env = max(0.0, (n - i) / float(fade_out))
        interleaved[i * 2] = int(soft_clip(left[i] * env) * 32767.0)
        interleaved[i * 2 + 1] = int(soft_clip(right[i] * env) * 32767.0)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(interleaved.tobytes())


def add_note_stereo(
    left: array.array,
    right: array.array,
    start_sec: float,
    dur_sec: float,
    fn,
    pan: float = 0.0,
) -> None:
    i0 = max(0, int(round(start_sec * SAMPLE_RATE)))
    i1 = min(len(left), int(round((start_sec + dur_sec) * SAMPLE_RATE)))
    angle = (pan + 1.0) * (math.pi / 4.0)
    gl = math.cos(angle)
    gr = math.sin(angle)
    inv_sr = 1.0 / SAMPLE_RATE
    for i in range(i0, i1):
        t = (i - i0) * inv_sr
        val = fn(t, dur_sec)
        left[i] += val * gl
        right[i] += val * gr


# --- Synthesis primitives (zero-delay attack transients + true phase integration) ---

def prng_noise(idx: int) -> float:
    n = (idx ^ 61) ^ (idx >> 16)
    n = n + (n << 3)
    n = n ^ (n >> 4)
    n = (n * 0x27D4EB2D) & 0xFFFFFFFF
    n = n ^ (n >> 15)
    return (n / 2147483647.5) - 1.0


def kick_drum(t: float, _dur: float) -> float:
    phase = TAU * (48.0 * t + (115.0 / 38.0) * (1.0 - math.exp(-t * 38.0)))
    body = math.sin(phase) * math.exp(-t * 12.5)
    click = math.sin(TAU * 980.0 * t) * math.exp(-t * 140.0) * 0.30
    return (body + click) * 0.56


def snare_drum(t: float, _dur: float, tight: bool = False) -> float:
    idx = int(t * SAMPLE_RATE)
    decay = 28.0 if tight else 19.0
    noise = prng_noise(idx) * math.exp(-t * decay) * 0.34
    tone = math.sin(TAU * 205.0 * t) * math.exp(-t * 32.0) * 0.26
    return noise + tone


def woodblock_tick(freq: float = 820.0, amp: float = 0.20):
    def _fn(t: float, _dur: float) -> float:
        return (
            math.sin(TAU * freq * t) * 0.75
            + math.sin(TAU * freq * 2.42 * t) * math.exp(-t * 95.0) * 0.25
        ) * math.exp(-t * 55.0) * amp
    return _fn


def hihat(t: float, _dur: float, open_hat: bool = False) -> float:
    idx = int(t * SAMPLE_RATE)
    decay = 12.0 if open_hat else 52.0
    n = prng_noise(idx)
    ring = math.sin(TAU * 3840.0 * t) * math.sin(TAU * 5410.0 * t)
    return (n * 0.65 + ring * 0.35) * math.exp(-t * decay) * 0.15


def slap_bass(freq: float, brightness: float = 1.0):
    def _fn(t: float, dur: float) -> float:
        env = min(1.0, t / 0.002) * math.exp(-t * 6.0) * min(1.0, max(0.0, (dur - t) / 0.012))
        mod = math.sin(TAU * freq * 2.0 * t) * math.exp(-t * 20.0) * 1.3 * brightness
        sig = (
            math.sin(TAU * freq * t + mod) * 0.65
            + math.sin(TAU * freq * 0.5 * t) * 0.25
            + math.sin(TAU * freq * 3.0 * t) * math.exp(-t * 16.0) * 0.12
        )
        return sig * env * 0.34
    return _fn


def epiano_chord(freqs: list[float], amp: float = 0.14):
    def _fn(t: float, dur: float) -> float:
        env = min(1.0, t / 0.004) * math.exp(-t * 3.0) * min(1.0, max(0.0, (dur - t) / 0.025))
        total = 0.0
        for f in freqs:
            tine = math.sin(TAU * f * 7.0 * t) * math.exp(-t * 22.0) * 0.08
            total += math.sin(TAU * f * t + tine) + 0.20 * math.sin(TAU * f * 2.0 * t) * math.exp(-t * 5.5)
        return (total / max(1, len(freqs))) * env * amp
    return _fn


def brass_lead(freq: float, amp: float = 0.24):
    def _fn(t: float, dur: float) -> float:
        # Instantaneous 1.5ms attack transient so rhythm onset is locked to t=0
        attack = min(1.0, t / 0.0015)
        release = min(1.0, max(0.0, (dur - t) / 0.020))
        env = attack * math.exp(-t * 2.2) * release
        # True phase modulation (never multiply f(t)*t)
        pm = (0.0 if t < 0.06 else math.sin(TAU * 5.5 * t) * 0.15)
        ph = TAU * freq * t + pm
        transient = math.sin(TAU * freq * 5.0 * t) * math.exp(-t * 75.0) * 0.22
        sig = (
            math.sin(ph) * 0.52
            + math.sin(ph * 2.0) * 0.28
            + math.sin(ph * 3.0) * 0.14
            + math.sin(ph * 4.0) * 0.06
            + transient
        )
        return sig * env * amp
    return _fn


def steam_cue_whistle(freq: float):
    def _fn(t: float, _dur: float) -> float:
        idx = int(t * SAMPLE_RATE)
        env = min(1.0, t / 0.0015) * math.exp(-t * 24.0)
        whistle = math.sin(TAU * freq * t) * 0.22 + math.sin(TAU * freq * 1.5 * t) * 0.10
        chug = prng_noise(idx) * math.exp(-t * 42.0) * 0.14
        return (whistle + chug) * env
    return _fn


def alien_vocal_call(tone_idx: int, is_echo: bool = False):
    # Crisp, zero-latency rhythmic alien synth-choir call ("Ba! / Doo! / La!")
    # Pitches in F major pentatonic: F4, A4, C5, D5, F5, G5, A5
    scale_midi = [65, 69, 72, 74, 77, 79, 81]
    base_idx = max(0, min(len(scale_midi) - 1, tone_idx + (2 if is_echo else 0)))
    f0 = midi_to_hz(scale_midi[base_idx])
    f1 = 720.0 if tone_idx % 2 == 0 else 520.0
    f2 = 1320.0 + tone_idx * 180.0

    def _fn(t: float, dur: float) -> float:
        # 1ms attack + crisp consonant pluck at t=0 so the beat onset is unmistakable
        attack = min(1.0, t / 0.001)
        release = min(1.0, max(0.0, (dur - t) / 0.018))
        env = attack * math.exp(-t * 3.6) * release
        # Exact integrated phase with subtle vibrato
        ph = TAU * f0 * t + math.sin(TAU * 6.0 * t) * 0.12
        pluck = math.sin(TAU * f0 * 4.0 * t) * math.exp(-t * 85.0) * 0.35
        click = math.sin(TAU * 1760.0 * t) * math.exp(-t * 120.0) * 0.22
        fund = math.sin(ph) * 0.56 + math.sin(ph * 2.0) * 0.26
        formant1 = math.sin(TAU * f1 * t) * (0.5 + 0.5 * math.sin(ph)) * 0.20
        formant2 = math.sin(TAU * f2 * t) * (0.5 + 0.5 * math.cos(ph)) * 0.12
        amp = 0.36 if is_echo else 0.50
        return (fund + formant1 + formant2 + pluck + click) * env * amp
    return _fn


def space_bell(freq: float, amp: float = 0.18):
    def _fn(t: float, _dur: float) -> float:
        env = min(1.0, t / 0.001) * math.exp(-t * 6.5)
        return (
            math.sin(TAU * freq * t) * 0.68
            + math.sin(TAU * freq * 2.0 * t) * 0.22
            + math.sin(TAU * freq * 4.0 * t) * math.exp(-t * 25.0) * 0.18
        ) * env * amp
    return _fn


def kitchen_marimba(freq: float, amp: float = 0.24):
    def _fn(t: float, _dur: float) -> float:
        env = min(1.0, t / 0.001) * math.exp(-t * 11.0)
        return (
            math.sin(TAU * freq * t) * 0.72
            + math.sin(TAU * freq * 4.0 * t) * math.exp(-t * 35.0) * 0.28
        ) * env * amp
    return _fn


def kitchen_prep_cue(is_left: bool):
    def _fn(t: float, _dur: float) -> float:
        idx = int(t * SAMPLE_RATE)
        if is_left:
            f = 440.0  # Crisp left woodblock
            return (math.sin(TAU * f * t) + 0.4 * math.sin(TAU * f * 2.4 * t)) * math.exp(-t * 42.0) * 0.22
        else:
            f = 880.0  # Crisp right triangle/rim
            sizzle = prng_noise(idx) * math.exp(-t * 48.0) * 0.08
            return (math.sin(TAU * f * t) * math.exp(-t * 36.0) * 0.20) + sizzle
    return _fn


# ============================================================================
# 1. BEAT FACTORY — 104 BPM, 42.0s, Funky Industrial Pop (Melody Locked to Chart)
# ============================================================================
def build_beat_factory_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    chord_prog = [
        [midi_to_hz(60), midi_to_hz(63), midi_to_hz(67), midi_to_hz(70)],  # Cm7
        [midi_to_hz(53), midi_to_hz(57), midi_to_hz(63), midi_to_hz(67)],  # F9
        [midi_to_hz(56), midi_to_hz(60), midi_to_hz(63), midi_to_hz(67)],  # Abmaj7
        [midi_to_hz(55), midi_to_hz(59), midi_to_hz(65), midi_to_hz(68)],  # G7b9
    ]
    bass_roots = [36, 41, 44, 43]
    riff_scale = [72, 75, 77, 79, 82, 79, 77, 75]

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        chord_idx = bar % 4

        # Tight 4-on-the-floor factory groove
        if beat_in_bar in (0, 2):
            add_note_stereo(left, right, t0, 0.24, kick_drum, pan=0.0)
        else:
            add_note_stereo(left, right, t0, 0.20, snare_drum, pan=0.04)

        add_note_stereo(left, right, t0, 0.08, lambda t, d: hihat(t, d, False), pan=-0.22)
        add_note_stereo(left, right, t0 + 0.5 * spb, 0.09, lambda t, d: hihat(t, d, False), pan=0.22)

        root_midi = bass_roots[chord_idx]
        add_note_stereo(left, right, t0, 0.45 * spb, slap_bass(midi_to_hz(root_midi), 1.0), pan=-0.08)

        if beat_in_bar == 0:
            add_note_stereo(left, right, t0, 1.8 * spb, epiano_chord(chord_prog[chord_idx], 0.14), pan=-0.25)

    # Lock the brass lead 100% to chart["events"] (zero off-beat steam whistle lead!)
    for idx, ev in enumerate(chart.get("events", [])):
        ev_beat = float(ev["beat"])
        ev_time = ev_beat * spb
        is_offbeat = abs((ev_beat % 1.0) - 0.5) < 0.05
        # Brass lead note hits squarely on the exact event beat!
        note_midi = 84 if is_offbeat else riff_scale[idx % len(riff_scale)]
        add_note_stereo(left, right, ev_time, 0.38 * spb, brass_lead(midi_to_hz(note_midi), 0.22), pan=0.18)

    return left, right


# ============================================================================
# 2. ECHO PLANET — 96 BPM, 36.0s, 100% Chart-Locked Call & Response Groove
# ============================================================================
def build_echo_planet_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    chords = [
        [midi_to_hz(53), midi_to_hz(57), midi_to_hz(60), midi_to_hz(64)],  # Fmaj7
        [midi_to_hz(50), midi_to_hz(53), midi_to_hz(57), midi_to_hz(60)],  # Dm7
        [midi_to_hz(46), midi_to_hz(50), midi_to_hz(53), midi_to_hz(58)],  # Bbmaj7
        [midi_to_hz(48), midi_to_hz(52), midi_to_hz(55), midi_to_hz(60)],  # C7
    ]
    bass_notes = [41, 38, 34, 36]

    # Steady, crystal-clear 96 BPM quarter-note pulse (NO random offbeat arpeggio bells!)
    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        c_idx = bar % 4
        cycle_beat = b % 8

        # Kick on 0, 2; Crisp rim/snare on 1, 3; Steady woodblock pulse on all 4 quarter-beats
        if beat_in_bar in (0, 2):
            add_note_stereo(left, right, t0, 0.22, kick_drum, pan=0.0)
        else:
            add_note_stereo(left, right, t0, 0.16, lambda t, d: snare_drum(t, d, tight=True), pan=0.0)

        # Crisp metronomic pulse on every integer beat (higher tick on beat 4 = start of YOUR TURN!)
        tick_freq = 1046.5 if cycle_beat == 4 else (784.0 if beat_in_bar == 0 else 587.33)
        tick_amp = 0.22 if cycle_beat == 4 else 0.12
        add_note_stereo(left, right, t0, 0.06, woodblock_tick(tick_freq, tick_amp), pan=0.0)

        # Warm bass on each quarter beat
        add_note_stereo(left, right, t0, 0.72 * spb, slap_bass(midi_to_hz(bass_notes[c_idx]), 0.65), pan=0.0)

        # Warm low-mid pad on bar downbeat (beats 0 and 4 of the 8-beat phrase)
        if beat_in_bar == 0:
            add_note_stereo(left, right, t0, 3.6 * spb, epiano_chord(chords[c_idx], 0.11), pan=0.0)

    # Map call beats to their tones so response beats play the exact matching melodic contour!
    call_tone_map = {}
    for call in chart.get("calls", []):
        c_beat = float(call["beat"])
        c_sec = c_beat * spb
        tone = int(call.get("tone", 0))
        call_tone_map[round(c_beat * 2.0)] = tone
        scale_midi = [65, 69, 72, 74, 77, 79, 81]
        c_midi = scale_midi[max(0, min(len(scale_midi) - 1, tone))]
        # Alien Lead Singer ("Luma-Lou") + tight rhythmic rimshot/clap & bass punch locked to c_beat!
        add_note_stereo(left, right, c_sec, 0.32, alien_vocal_call(tone, is_echo=False), pan=-0.10)
        add_note_stereo(left, right, c_sec, 0.24, space_bell(midi_to_hz(c_midi + 12), 0.22), pan=-0.10)
        add_note_stereo(left, right, c_sec, 0.14, lambda t, d: snare_drum(t, d, tight=True), pan=-0.08)

    # Player Response Turn: keep rhythm section rock-steady; let player's input produce the melody notes!
    for ev in chart.get("events", []):
        ev_beat = float(ev["beat"])
        ev_sec = ev_beat * spb
        # Crisp rhythmic rimshot punch on response beat so player has a firm metronomic pulse
        add_note_stereo(left, right, ev_sec, 0.14, lambda t, d: snare_drum(t, d, tight=True) * 1.25, pan=0.0)

    return left, right


# ============================================================================
# 3. RHYTHM KITCHEN — 102 BPM, 42.0s, Bossa-Pop (Melody Locked to Chart)
# ============================================================================
def build_rhythm_kitchen_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    chords = [
        [midi_to_hz(55), midi_to_hz(59), midi_to_hz(62), midi_to_hz(66)],  # Gmaj7
        [midi_to_hz(52), midi_to_hz(56), midi_to_hz(59), midi_to_hz(62)],  # E7
        [midi_to_hz(57), midi_to_hz(60), midi_to_hz(64), midi_to_hz(67)],  # Am7
        [midi_to_hz(50), midi_to_hz(54), midi_to_hz(60), midi_to_hz(64)],  # D9
    ]
    walking_bass = [
        [43, 47, 50, 47],
        [40, 44, 47, 44],
        [45, 48, 52, 48],
        [38, 42, 45, 49],
    ]

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        c_idx = bar % 4

        add_note_stereo(left, right, t0, 0.22, kick_drum, pan=0.0)
        if beat_in_bar in (1, 3):
            add_note_stereo(left, right, t0, 0.18, lambda t, d: snare_drum(t, d, tight=True), pan=0.06)

        add_note_stereo(left, right, t0, 0.07, lambda t, d: hihat(t, d, False), pan=-0.2)
        add_note_stereo(left, right, t0 + 0.5 * spb, 0.07, lambda t, d: hihat(t, d, False), pan=0.2)

        b_midi = walking_bass[c_idx][beat_in_bar]
        add_note_stereo(left, right, t0, 0.80 * spb, slap_bass(midi_to_hz(b_midi), 0.8), pan=0.0)

        if beat_in_bar == 0:
            add_note_stereo(left, right, t0, 1.8 * spb, epiano_chord(chords[c_idx], 0.13), pan=0.0)

    # Lock the Marimba & Brass melody 100% to chart["events"] (Left = G major low-mid phrase, Right = D/B high phrase)
    left_scale = [71, 74, 79, 74]
    right_scale = [76, 79, 83, 86]
    for idx, ev in enumerate(chart.get("events", [])):
        ev_beat = float(ev["beat"])
        ev_time = ev_beat * spb
        is_left = str(ev.get("lane", "left")) == "left"
        cue_t = max(0.0, (ev_beat - 1.0) * spb)
        add_note_stereo(left, right, cue_t, 0.10, kitchen_prep_cue(is_left), pan=-0.45 if is_left else 0.45)

        m_note = left_scale[idx % len(left_scale)] if is_left else right_scale[idx % len(right_scale)]
        pan_val = -0.30 if is_left else 0.30
        add_note_stereo(left, right, ev_time, 0.42 * spb, kitchen_marimba(midi_to_hz(m_note), 0.24), pan=pan_val)
        add_note_stereo(left, right, ev_time, 0.35 * spb, brass_lead(midi_to_hz(m_note - 12), 0.13), pan=pan_val * 0.5)

    return left, right


# ============================================================================
# 4. WORLD-SPECIFIC SFX & JINGLES (44.1kHz Stereo)
# ============================================================================
def build_sfx(dur: float, fn, pan: float = 0.0) -> tuple[array.array, array.array]:
    n = int(dur * SAMPLE_RATE)
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)
    add_note_stereo(left, right, 0.0, dur, fn, pan=pan)
    return left, right


def sfx_bf_perfect(t: float, _d: float) -> float:
    thud = math.sin(TAU * (110.0 * t + (180.0 / 45.0) * (1.0 - math.exp(-t * 45.0)))) * math.exp(-t * 18.0) * 0.55
    chime1 = math.sin(TAU * 1046.5 * t) * math.exp(-t * 16.0) * 0.35
    chime2 = math.sin(TAU * 1567.98 * max(0.0, t - 0.035)) * math.exp(-max(0.0, t - 0.035) * 14.0) * (0.38 if t >= 0.035 else 0.0)
    clack = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 65.0) * 0.25
    return thud + chime1 + chime2 + clack


def sfx_bf_good(t: float, _d: float) -> float:
    thud = math.sin(TAU * 130.0 * t) * math.exp(-t * 22.0) * 0.45
    tone = math.sin(TAU * 698.46 * t) * math.exp(-t * 18.0) * 0.32
    return thud + tone


def sfx_bf_miss(t: float, _d: float) -> float:
    ph = TAU * 165.0 * t - 2.5 * math.sin(TAU * 14.0 * t)
    return (math.sin(ph) + 0.4 * math.sin(ph * 2.5)) * math.exp(-t * 9.0) * 0.48


def sfx_ep_perfect(t: float, _d: float) -> float:
    voice = alien_vocal_call(4, is_echo=False)(t, 0.26) * 0.85
    sparkle = (
        math.sin(TAU * 1396.91 * t) * 0.24
        + math.sin(TAU * 1760.0 * t) * 0.20
        + math.sin(TAU * 2093.0 * t) * 0.18
    ) * math.exp(-t * 12.0)
    return voice + sparkle


def sfx_ep_good(t: float, _d: float) -> float:
    return alien_vocal_call(2, is_echo=False)(t, 0.22) * 0.75


def sfx_ep_miss(t: float, _d: float) -> float:
    ph = TAU * (230.0 * t - 150.0 * t * t) + 1.2 * math.sin(TAU * 22.0 * t)
    return (math.sin(ph) + 0.35 * math.sin(ph * 1.9)) * math.exp(-t * 8.5) * 0.45


def sfx_rk_perfect_left(t: float, _d: float) -> float:
    sizzle = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 28.0) * 0.26
    pop1 = math.sin(TAU * 783.99 * t) * math.exp(-t * 20.0) * 0.42
    pop2 = math.sin(TAU * 1174.66 * max(0.0, t - 0.03)) * math.exp(-max(0.0, t - 0.03) * 16.0) * (0.36 if t >= 0.03 else 0.0)
    return sizzle + pop1 + pop2


def sfx_rk_perfect_right(t: float, _d: float) -> float:
    clink = math.sin(TAU * 1567.98 * t) * math.exp(-t * 24.0) * 0.35
    pop2 = math.sin(TAU * 2349.32 * max(0.0, t - 0.03)) * math.exp(-max(0.0, t - 0.03) * 16.0) * (0.35 if t >= 0.03 else 0.0)
    body = math.sin(TAU * 587.33 * t) * math.exp(-t * 18.0) * 0.32
    return clink + pop2 + body


def sfx_rk_good(t: float, _d: float) -> float:
    return (math.sin(TAU * 587.33 * t) + 0.3 * math.sin(TAU * 880.0 * t)) * math.exp(-t * 18.0) * 0.40


def sfx_rk_miss(t: float, _d: float) -> float:
    noise = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 16.0) * 0.28
    thud = math.sin(TAU * (150.0 * t - 30.0 * t * t)) * math.exp(-t * 11.0) * 0.40
    return noise + thud


def sfx_ui_focus(t: float, _d: float) -> float:
    # Crisp tactile marimba/woodblock focus pop (C6 + harmonic overtone)
    return (
        math.sin(TAU * 1046.50 * t) * 0.72
        + math.sin(TAU * 2093.00 * t) * math.exp(-t * 75.0) * 0.28
    ) * math.exp(-t * 42.0) * 0.42


def sfx_ui_click(t: float, _d: float) -> float:
    # Cheerful two-note major-third confirmation chime (C6 -> E6 + bell sparkle)
    if t < 0.045:
        return (
            math.sin(TAU * 1046.50 * t) * 0.65
            + math.sin(TAU * 2093.00 * t) * 0.25
        ) * math.exp(-t * 28.0) * 0.48
    t2 = t - 0.045
    return (
        math.sin(TAU * 1318.51 * t2) * 0.62
        + math.sin(TAU * 1975.53 * t2) * 0.28
        + math.sin(TAU * 2637.02 * t2) * 0.20
    ) * math.exp(-t2 * 22.0) * 0.52


def sfx_ui_eval(t: float, _d: float) -> float:
    # Snare drumroll (0.0..0.42s) + spotlight cymbal/chord hit at 0.42s for Black Screen -> Evaluation reveal!
    if t < 0.42:
        roll_env = 0.45 + 0.55 * (t / 0.42)
        pulse = 0.65 + 0.35 * abs(math.sin(TAU * 18.0 * t))
        return prng_noise(int(t * SAMPLE_RATE)) * roll_env * pulse * 0.28 + math.sin(TAU * 195.0 * t) * 0.12
    t2 = t - 0.42
    cymbal = prng_noise(int(t2 * SAMPLE_RATE)) * math.exp(-t2 * 9.5) * 0.22
    chord = (
        math.sin(TAU * 523.25 * t2) * 0.25
        + math.sin(TAU * 659.25 * t2) * 0.22
        + math.sin(TAU * 783.99 * t2) * 0.20
        + math.sin(TAU * 1046.50 * t2) * 0.18
    ) * math.exp(-t2 * 5.5)
    return cymbal + chord


def build_menu_bgm(kind: str) -> tuple[array.array, array.array, float]:
    # Full-length 64-beat (16-bar, 32.0s to 38.4s) multi-section BGM tracks for Title, Stage Select, and Results screens!
    specs = {
        "title": (
            120.0,
            [60, 65, 67, 60, 60, 62, 64, 67, 65, 64, 62, 60, 57, 62, 67, 60],
            [
                # Section A (Bars 1-4): Main Showtime Fanfare Theme
                72, 76, 79, 84, 81, 79, 76, 74, 72, 76, 79, 81, 84, 79, 76, 72,
                # Section B (Bars 5-8): Upbeat Groove Call & Response
                76, 79, 84, 88, 86, 84, 81, 79, 76, 77, 79, 81, 83, 84, 86, 88,
                # Section C (Bars 9-12): Jazzy Bridge
                89, 88, 86, 84, 83, 81, 79, 76, 77, 79, 81, 84, 83, 79, 76, 74,
                # Section D (Bars 13-16): Big Brass Finale Turnaround
                72, 74, 76, 79, 81, 84, 86, 88, 89, 86, 84, 79, 84, 79, 76, 72,
            ],
        ),
        "select": (
            112.0,
            [53, 57, 58, 60, 53, 55, 57, 60, 58, 57, 55, 53, 50, 55, 58, 60],
            [
                # Section A (Bars 1-4): Bouncy Marimba Menu Theme
                69, 72, 74, 77, 76, 72, 69, 67, 70, 74, 77, 81, 79, 76, 72, 69,
                # Section B (Bars 5-8): playful syncopated climb
                72, 76, 77, 81, 79, 77, 74, 72, 74, 77, 81, 84, 81, 79, 76, 72,
                # Section C (Bars 9-12): Warm Rhodes & Bell interlude
                82, 81, 79, 77, 76, 74, 72, 69, 70, 72, 74, 77, 79, 76, 72, 67,
                # Section D (Bars 13-16): Turnaround back to top
                69, 72, 76, 77, 79, 81, 84, 81, 79, 77, 76, 74, 72, 70, 69, 65,
            ],
        ),
        "results_superb": (
            120.0,
            [60, 64, 65, 67, 60, 67, 69, 64, 65, 60, 62, 67, 65, 67, 72, 60],
            [
                # Section A (Bars 1-4): Triumphant Victory Brass
                76, 79, 84, 88, 86, 84, 79, 76, 77, 81, 84, 86, 84, 79, 81, 84,
                # Section B (Bars 5-8): High Celebration Melody
                88, 91, 88, 84, 86, 89, 86, 81, 84, 88, 91, 93, 91, 88, 86, 84,
                # Section C (Bars 9-12): Confetti Bell Dance
                89, 88, 84, 81, 84, 81, 79, 76, 74, 77, 81, 84, 86, 84, 81, 79,
                # Section D (Bars 13-16): Grand Encore Climax
                76, 79, 84, 88, 89, 91, 93, 96, 91, 88, 84, 79, 84, 88, 84, 76,
            ],
        ),
        "results_ok": (
            108.0,
            [55, 52, 53, 55, 55, 59, 60, 62, 57, 55, 53, 50, 52, 55, 57, 55],
            [
                71, 74, 76, 79, 76, 74, 71, 67, 69, 72, 76, 74, 71, 69, 67, 71,
                74, 76, 79, 83, 81, 79, 76, 74, 72, 76, 79, 81, 79, 76, 74, 71,
                76, 74, 72, 69, 71, 74, 76, 79, 77, 76, 74, 72, 71, 69, 67, 64,
                67, 71, 74, 76, 79, 81, 83, 79, 76, 74, 71, 69, 71, 74, 71, 67,
            ],
        ),
        "results_try_again": (
            100.0,
            [57, 53, 55, 52, 57, 60, 55, 52, 53, 50, 52, 57, 53, 55, 52, 57],
            [
                69, 72, 71, 69, 65, 69, 67, 64, 69, 72, 74, 72, 71, 69, 67, 64,
                72, 76, 74, 72, 69, 72, 71, 67, 65, 69, 72, 74, 71, 69, 67, 64,
                76, 74, 72, 69, 67, 65, 64, 62, 64, 67, 69, 72, 71, 69, 67, 64,
                69, 71, 72, 74, 76, 74, 72, 69, 67, 69, 71, 67, 69, 67, 64, 69,
            ],
        ),
    }
    bpm, bass_roots, melody_notes = specs[kind]
    spb = 60.0 / bpm
    total_beats = 64
    dur = total_beats * spb
    n = int(round(dur * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        section = bar // 4
        beat_in_bar = b % 4
        root = bass_roots[bar % len(bass_roots)]
        mel = melody_notes[b % len(melody_notes)]

        if kind != "results_try_again":
            if beat_in_bar in (0, 2):
                add_note_stereo(left, right, t0, 0.20, kick_drum, pan=0.0)
            else:
                add_note_stereo(left, right, t0, 0.15, lambda t, d: snare_drum(t, d, tight=True), pan=0.04)
            add_note_stereo(left, right, t0 + 0.5 * spb, 0.07, lambda t, d: hihat(t, d, False), pan=0.18)
            if section in (1, 3) and beat_in_bar in (1, 3):
                add_note_stereo(left, right, t0 + 0.5 * spb, 0.06, woodblock_tick(880.0, 0.10), pan=-0.22)
        else:
            if beat_in_bar == 0:
                add_note_stereo(left, right, t0, 0.18, kick_drum, pan=0.0)
            elif beat_in_bar == 2:
                add_note_stereo(left, right, t0, 0.08, woodblock_tick(523.25, 0.08), pan=0.0)

        add_note_stereo(left, right, t0, 0.55 * spb, slap_bass(midi_to_hz(root - 12), 0.52), pan=-0.06)
        if beat_in_bar in (0, 2):
            chord_hz = [midi_to_hz(root), midi_to_hz(root + 4), midi_to_hz(root + 7), midi_to_hz(root + 11)]
            add_note_stereo(left, right, t0, 1.8 * spb, epiano_chord(chord_hz, 0.11), pan=-0.12)

        if kind in ("title", "results_superb"):
            add_note_stereo(left, right, t0, 0.42 * spb, brass_lead(midi_to_hz(mel), 0.14), pan=0.14)
            add_note_stereo(left, right, t0, 0.35 * spb, kitchen_marimba(midi_to_hz(mel + 12), 0.12), pan=-0.14)
            if section in (1, 3) and b % 2 == 1:
                add_note_stereo(left, right, t0 + 0.5 * spb, 0.25 * spb, space_bell(midi_to_hz(mel + 7), 0.10), pan=0.22)
        else:
            add_note_stereo(left, right, t0, 0.45 * spb, kitchen_marimba(midi_to_hz(mel), 0.15), pan=0.12)
            if b % 2 == 0 or section == 1:
                add_note_stereo(left, right, t0, 0.40 * spb, space_bell(midi_to_hz(mel + 12), 0.10), pan=-0.15)

    return left, right, round(dur, 3)


def build_result_fanfare(superb: bool) -> tuple[array.array, array.array]:
    dur = 2.4
    n = int(dur * SAMPLE_RATE)
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)
    if superb:
        notes = [(0.0, 0.16, 72), (0.16, 0.16, 76), (0.32, 0.16, 79), (0.48, 0.22, 81), (0.72, 1.2, 84)]
        for st, d, m in notes:
            add_note_stereo(left, right, st, d, brass_lead(midi_to_hz(m), 0.26), pan=-0.15)
            add_note_stereo(left, right, st, d * 1.2, space_bell(midi_to_hz(m + 12), 0.18), pan=0.2)
        add_note_stereo(left, right, 0.72, 1.4, epiano_chord([midi_to_hz(60), midi_to_hz(64), midi_to_hz(67), midi_to_hz(72)], 0.22), pan=0.0)
    else:
        notes = [(0.0, 0.22, 67), (0.24, 0.22, 72), (0.48, 0.9, 76)]
        for st, d, m in notes:
            add_note_stereo(left, right, st, d, epiano_chord([midi_to_hz(m), midi_to_hz(m - 5)], 0.22), pan=0.0)
    return left, right


def main() -> None:
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    manifest_records = []

    games = ["beat_factory", "echo_planet", "rhythm_kitchen"]
    builders = {
        "beat_factory": build_beat_factory_song,
        "echo_planet": build_echo_planet_song,
        "rhythm_kitchen": build_rhythm_kitchen_song,
    }

    for gid in games:
        chart_path = ROOT / "games" / gid / "chart.json"
        chart = json.loads(chart_path.read_text(encoding="utf-8"))
        print(f"Synthesizing 44.1kHz stereo soundtrack for {gid} ({chart['bpm']} BPM, {chart['duration']}s)...")
        l_ch, r_ch = builders[gid](chart)
        out_wav = AUDIO_DIR / f"{gid}_song.wav"
        write_wav_stereo(out_wav, l_ch, r_ch)
        manifest_records.append({
            "file": f"res://assets/audio/{gid}_song.wav",
            "game_id": gid,
            "sample_rate": SAMPLE_RATE,
            "channels": 2,
            "duration_sec": chart["duration"],
            "bpm": chart["bpm"],
            "license": "CC0-1.0 / Original First-Party Procedural Composition (tools/generate_audio_assets.py)",
        })

    for bgm_kind in ["title", "select", "results_superb", "results_ok", "results_try_again"]:
        l_ch, r_ch, b_dur = build_menu_bgm(bgm_kind)
        fname = f"bgm_{bgm_kind}.wav"
        write_wav_stereo(AUDIO_DIR / fname, l_ch, r_ch)
        manifest_records.append({
            "file": f"res://assets/audio/{fname}",
            "sample_rate": SAMPLE_RATE,
            "channels": 2,
            "duration_sec": b_dur,
            "license": "CC0-1.0 / Original First-Party BGM Loop (tools/generate_audio_assets.py)",
        })

    sfx_specs = [
        ("beat_factory_perfect.wav", 0.26, sfx_bf_perfect, 0.0),
        ("beat_factory_good.wav", 0.22, sfx_bf_good, 0.0),
        ("beat_factory_miss.wav", 0.28, sfx_bf_miss, 0.0),
        ("echo_planet_perfect.wav", 0.28, sfx_ep_perfect, 0.05),
        ("echo_planet_good.wav", 0.22, sfx_ep_good, 0.0),
        ("echo_planet_miss.wav", 0.28, sfx_ep_miss, 0.0),
        ("rhythm_kitchen_perfect_left.wav", 0.24, sfx_rk_perfect_left, -0.25),
        ("rhythm_kitchen_perfect_right.wav", 0.24, sfx_rk_perfect_right, 0.25),
        ("rhythm_kitchen_good.wav", 0.22, sfx_rk_good, 0.0),
        ("rhythm_kitchen_miss.wav", 0.26, sfx_rk_miss, 0.0),
        ("ui_focus.wav", 0.09, sfx_ui_focus, 0.0),
        ("ui_click.wav", 0.16, sfx_ui_click, 0.0),
        ("ui_eval.wav", 0.95, sfx_ui_eval, 0.0),
    ]
    for fname, dur, fn, pan in sfx_specs:
        l_ch, r_ch = build_sfx(dur, fn, pan)
        write_wav_stereo(AUDIO_DIR / fname, l_ch, r_ch)
        manifest_records.append({
            "file": f"res://assets/audio/{fname}",
            "sample_rate": SAMPLE_RATE,
            "channels": 2,
            "duration_sec": dur,
            "license": "CC0-1.0 / Original First-Party SFX (tools/generate_audio_assets.py)",
        })

    for fname, superb in [("fanfare_superb.wav", True), ("fanfare_ok.wav", False)]:
        l_ch, r_ch = build_result_fanfare(superb)
        write_wav_stereo(AUDIO_DIR / fname, l_ch, r_ch)
        manifest_records.append({
            "file": f"res://assets/audio/{fname}",
            "sample_rate": SAMPLE_RATE,
            "channels": 2,
            "duration_sec": 2.4,
            "license": "CC0-1.0 / Original First-Party Jingle (tools/generate_audio_assets.py)",
        })

    prov_path = AUDIO_DIR / "PROVENANCE.json"
    prov_path.write_text(json.dumps({"schema_version": 1, "generator": "tools/generate_audio_assets.py", "assets": manifest_records}, indent=2), encoding="utf-8")
    print(f"Generated {len(manifest_records)} stereo 44.1kHz WAV files and {prov_path.name}.")


if __name__ == "__main__":
    main()
