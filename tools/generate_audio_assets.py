#!/usr/bin/env python3
"""
Rhythm Rhythm v0.2 — Deterministic 44.1kHz Stereo Original Soundtrack & SFX Generator
Generates all production WAV assets under assets/audio/ and writes assets/audio/PROVENANCE.json.
"""
import array
import json
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
TAU = math.pi * 2.0

ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "assets" / "audio"


def midi_to_hz(midi: float) -> float:
    return 440.0 * (2.0 ** ((midi - 69.0) / 12.0))


def clamp(v: float, lo: float = -1.0, hi: float = 1.0) -> float:
    return lo if v < lo else (hi if v > hi else v)


def soft_clip(x: float) -> float:
    # Smooth tanh-like saturation to prevent harsh digital clipping while keeping punch
    return math.tanh(x * 1.15) * 0.92


def write_wav_stereo(path: Path, left: array.array, right: array.array) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    n = min(len(left), len(right))
    interleaved = array.array("h", [0] * (n * 2))
    # Fade in first 15ms and fade out last 120ms to guarantee zero boundary clicks
    fade_in = int(0.015 * SAMPLE_RATE)
    fade_out = int(0.12 * SAMPLE_RATE)
    for i in range(n):
        env = 1.0
        if i < fade_in:
            env = i / float(fade_in)
        elif i > n - fade_out:
            env = max(0.0, (n - i) / float(fade_out))
        l_val = int(soft_clip(left[i] * env) * 32767.0)
        r_val = int(soft_clip(right[i] * env) * 32767.0)
        interleaved[i * 2] = l_val
        interleaved[i * 2 + 1] = r_val
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
    i0 = max(0, int(start_sec * SAMPLE_RATE))
    i1 = min(len(left), int((start_sec + dur_sec) * SAMPLE_RATE))
    # Constant-power pan (-1.0 left .. +1.0 right)
    angle = (pan + 1.0) * (math.pi / 4.0)
    gl = math.cos(angle)
    gr = math.sin(angle)
    inv_sr = 1.0 / SAMPLE_RATE
    for i in range(i0, i1):
        t = (i - i0) * inv_sr
        val = fn(t, dur_sec)
        left[i] += val * gl
        right[i] += val * gr


# --- Synthesis primitives ---

def prng_noise(idx: int) -> float:
    # Deterministic fast hash noise in [-1, 1]
    n = (idx ^ 61) ^ (idx >> 16)
    n = n + (n << 3)
    n = n ^ (n >> 4)
    n = (n * 0x27D4EB2D) & 0xFFFFFFFF
    n = n ^ (n >> 15)
    return (n / 2147483647.5) - 1.0


def kick_drum(t: float, _dur: float) -> float:
    # Punchy pitch-swept kick (155Hz -> 48Hz) + click transient
    freq = 48.0 + 115.0 * math.exp(-t * 36.0)
    phase = TAU * (48.0 * t + (115.0 / 36.0) * (1.0 - math.exp(-t * 36.0)))
    body = math.sin(phase) * math.exp(-t * 11.5)
    click = math.sin(TAU * 920.0 * t) * math.exp(-t * 120.0) * 0.25
    return (body + click) * 0.55


def snare_drum(t: float, _dur: float, tight: bool = False) -> float:
    idx = int(t * SAMPLE_RATE)
    decay = 26.0 if tight else 18.0
    noise = prng_noise(idx) * math.exp(-t * decay) * 0.34
    tone = math.sin(TAU * 195.0 * t) * math.exp(-t * 28.0) * 0.24
    return noise + tone


def hihat(t: float, _dur: float, open_hat: bool = False) -> float:
    idx = int(t * SAMPLE_RATE)
    decay = 11.0 if open_hat else 48.0
    n = prng_noise(idx)
    # High-frequency metallic ring modulation
    ring = math.sin(TAU * 3840.0 * t) * math.sin(TAU * 5410.0 * t)
    return (n * 0.65 + ring * 0.35) * math.exp(-t * decay) * 0.16


def slap_bass(freq: float, brightness: float = 1.0):
    def _fn(t: float, dur: float) -> float:
        env = min(1.0, t / 0.004) * math.exp(-t * 5.5) * min(1.0, max(0.0, (dur - t) / 0.015))
        # FM slap + warm sub harmonics
        mod = math.sin(TAU * freq * 2.0 * t) * math.exp(-t * 18.0) * 1.4 * brightness
        sig = (
            math.sin(TAU * freq * t + mod) * 0.65
            + math.sin(TAU * freq * 0.5 * t) * 0.25
            + math.sin(TAU * freq * 3.0 * t) * math.exp(-t * 14.0) * 0.12
        )
        return sig * env * 0.34
    return _fn


def epiano_chord(freqs: list[float], amp: float = 0.14):
    def _fn(t: float, dur: float) -> float:
        env = min(1.0, t / 0.008) * math.exp(-t * 2.8) * min(1.0, max(0.0, (dur - t) / 0.03))
        total = 0.0
        for f in freqs:
            tine = math.sin(TAU * f * 7.0 * t) * math.exp(-t * 20.0) * 0.08
            total += math.sin(TAU * f * t + tine) + 0.22 * math.sin(TAU * f * 2.0 * t) * math.exp(-t * 5.0)
        return (total / max(1, len(freqs))) * env * amp
    return _fn


def brass_lead(freq: float, amp: float = 0.22):
    def _fn(t: float, dur: float) -> float:
        attack = min(1.0, t / 0.018)
        release = min(1.0, max(0.0, (dur - t) / 0.025))
        env = attack * math.exp(-t * 1.8) * release
        vib = math.sin(TAU * 5.5 * t) * (0.004 if t > 0.08 else 0.0)
        f = freq * (1.0 + vib)
        # Rich saw-like brass harmonics
        sig = (
            math.sin(TAU * f * t) * 0.50
            + math.sin(TAU * f * 2.0 * t) * 0.30
            + math.sin(TAU * f * 3.0 * t) * 0.16
            + math.sin(TAU * f * 4.0 * t) * 0.08
        )
        return sig * env * amp
    return _fn


def steam_cue_whistle(freq: float):
    # Audible factory anticipation whistle / piston hiss on the half-beat before a package
    def _fn(t: float, _dur: float) -> float:
        idx = int(t * SAMPLE_RATE)
        env = min(1.0, t / 0.005) * math.exp(-t * 22.0)
        whistle = math.sin(TAU * freq * t) * 0.18 + math.sin(TAU * freq * 1.5 * t) * 0.09
        chug = prng_noise(idx) * math.exp(-t * 35.0) * 0.12
        return (whistle + chug) * env
    return _fn


def alien_vocal_call(tone_idx: int):
    # Expressive formant-synthesized "Ba / Doo / La!" alien choir call for Echo Planet
    # Pitches in F major pentatonic: F4, G4, A4, C5, D5, F5, G5
    scale_midi = [65, 67, 69, 72, 74, 77, 79]
    midi = scale_midi[max(0, min(len(scale_midi) - 1, tone_idx))]
    f0 = midi_to_hz(midi)
    # Vowel formants (F1, F2) shifting by tone_idx so high notes sound like "La!", low like "Ba/Doo"
    f1 = 720.0 if tone_idx % 2 == 0 else 480.0
    f2 = 1240.0 + tone_idx * 160.0

    def _fn(t: float, dur: float) -> float:
        attack = min(1.0, t / 0.010)
        release = min(1.0, max(0.0, (dur - t) / 0.03))
        env = attack * math.exp(-t * 3.2) * release
        # Slight upward pitch scoop at start for cute vocal character
        scoop = 1.0 - 0.04 * math.exp(-t * 45.0)
        vib = 1.0 + math.sin(TAU * 6.2 * t) * 0.006
        f = f0 * scoop * vib
        fund = math.sin(TAU * f * t) * 0.55 + math.sin(TAU * f * 2.0 * t) * 0.28
        formant1 = math.sin(TAU * f1 * t) * (0.5 + 0.5 * math.sin(TAU * f * t)) * 0.25
        formant2 = math.sin(TAU * f2 * t) * (0.5 + 0.5 * math.cos(TAU * f * t)) * 0.14
        bell = math.sin(TAU * f * 3.0 * t) * math.exp(-t * 14.0) * 0.18
        return (fund + formant1 + formant2 + bell) * env * 0.44
    return _fn


def space_bell(freq: float, amp: float = 0.16):
    def _fn(t: float, _dur: float) -> float:
        env = min(1.0, t / 0.004) * math.exp(-t * 4.8)
        return (
            math.sin(TAU * freq * t) * 0.65
            + math.sin(TAU * freq * 2.0 * t) * 0.25
            + math.sin(TAU * freq * 4.01 * t) * math.exp(-t * 14.0) * 0.15
        ) * env * amp
    return _fn


def kitchen_marimba(freq: float, amp: float = 0.20):
    def _fn(t: float, _dur: float) -> float:
        env = min(1.0, t / 0.003) * math.exp(-t * 9.5)
        return (
            math.sin(TAU * freq * t) * 0.72
            + math.sin(TAU * freq * 4.0 * t) * math.exp(-t * 28.0) * 0.28
        ) * env * amp
    return _fn


def kitchen_prep_cue(is_left: bool):
    # Distinct audible cue 1 beat before ingredient lands:
    # Left = wooden chopping board "tock" (lower woody pitch), Right = pan sizzle/spoon "ting" (higher metallic pitch)
    def _fn(t: float, _dur: float) -> float:
        idx = int(t * SAMPLE_RATE)
        if is_left:
            f = 392.0 # G4 woody block
            return (math.sin(TAU * f * t) + 0.35 * math.sin(TAU * f * 2.4 * t)) * math.exp(-t * 38.0) * 0.18
        else:
            f = 784.0 # G5 bright rim/ting
            sizzle = prng_noise(idx) * math.exp(-t * 42.0) * 0.08
            return (math.sin(TAU * f * t) * math.exp(-t * 32.0) * 0.16) + sizzle
    return _fn


# ============================================================================
# 1. BEAT FACTORY — 104 BPM, 42.0s, Funky Industrial Pop / Clavinet Groove
# ============================================================================
def build_beat_factory_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    # 4-bar chord loop in C Dorian / Funk (Cm7 - F9 - Abmaj7 - G7alt)
    chord_prog = [
        [midi_to_hz(60), midi_to_hz(63), midi_to_hz(67), midi_to_hz(70)],  # Cm7
        [midi_to_hz(53), midi_to_hz(57), midi_to_hz(63), midi_to_hz(67)],  # F9
        [midi_to_hz(56), midi_to_hz(60), midi_to_hz(63), midi_to_hz(67)],  # Abmaj7
        [midi_to_hz(55), midi_to_hz(59), midi_to_hz(65), midi_to_hz(68)],  # G7b9
    ]
    bass_roots = [36, 41, 44, 43]  # C2, F2, Ab2, G2

    # Melodic hook per 16-beat section (Intro, Verse A, Syncopated B, Climax C)
    melody_a = [
        (0.0, 1.0, 72), (1.0, 0.5, 75), (1.5, 0.5, 77), (2.0, 1.5, 79),
        (4.0, 1.0, 77), (5.0, 0.5, 75), (5.5, 0.5, 72), (6.0, 1.5, 70),
        (8.0, 0.75, 72), (8.75, 0.75, 75), (9.5, 0.5, 79), (10.0, 1.5, 84),
        (12.0, 1.0, 82), (13.0, 1.0, 79), (14.0, 1.5, 74),
    ]
    melody_b = [
        (0.0, 0.5, 79), (0.5, 0.5, 82), (1.0, 1.0, 84), (2.5, 1.0, 79),
        (4.0, 0.5, 77), (4.5, 0.5, 79), (5.0, 1.0, 81), (6.5, 1.0, 77),
        (8.0, 0.5, 75), (8.5, 0.5, 79), (9.0, 1.0, 82), (10.5, 1.0, 84),
        (12.0, 0.75, 86), (12.75, 0.75, 84), (13.5, 0.5, 79), (14.0, 1.5, 83),
    ]

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        chord_idx = bar % 4

        # Drums: Kick on 0, 2 (plus funky 16th pickup in section B/C), Snare on 1, 3
        if beat_in_bar in (0, 2):
            add_note_stereo(left, right, t0, 0.25, kick_drum, pan=0.0)
            if bar >= 5 and beat_in_bar == 2:
                add_note_stereo(left, right, t0 - 0.5 * spb, 0.22, kick_drum, pan=0.0)
        else:
            add_note_stereo(left, right, t0, 0.22, snare_drum, pan=0.05)

        # Eighth-note hi-hats with pan groove
        add_note_stereo(left, right, t0, 0.09, lambda t, d: hihat(t, d, False), pan=-0.25)
        add_note_stereo(left, right, t0 + 0.5 * spb, 0.12, lambda t, d: hihat(t, d, beat_in_bar == 3), pan=0.25)

        # Funky octaver slap bass
        root_midi = bass_roots[chord_idx]
        add_note_stereo(left, right, t0, 0.45 * spb, slap_bass(midi_to_hz(root_midi), 1.0), pan=-0.1)
        if beat_in_bar in (1, 3) or bar >= 5:
            add_note_stereo(left, right, t0 + 0.5 * spb, 0.42 * spb, slap_bass(midi_to_hz(root_midi + 12), 1.25), pan=0.1)

        # Electric piano chord stabs on beat 0 and syncopated 2.5
        if beat_in_bar == 0:
            add_note_stereo(left, right, t0, 1.4 * spb, epiano_chord(chord_prog[chord_idx], 0.15), pan=-0.3)
        elif beat_in_bar == 2:
            add_note_stereo(left, right, t0 + 0.5 * spb, 0.9 * spb, epiano_chord(chord_prog[chord_idx], 0.13), pan=0.3)

    # Layer brass lead hooks across 16-beat phrases
    for phrase_start in range(4, total_beats - 4, 16):
        pattern = melody_a if (phrase_start // 16) % 2 == 0 else melody_b
        for rel_b, dur_b, midi_note in pattern:
            st = (phrase_start + rel_b) * spb
            if st < duration - 0.5:
                add_note_stereo(left, right, st, dur_b * spb * 0.92, brass_lead(midi_to_hz(midi_note), 0.19), pan=0.18)

    # Embed audible conveyor piston / whistle cue 0.5 beat before each stamp event so players can play with eyes closed!
    for ev in chart.get("events", []):
        ev_beat = float(ev["beat"])
        cue_time = max(0.0, (ev_beat - 0.5) * spb)
        is_offbeat = abs((ev_beat % 1.0) - 0.5) < 0.05
        cue_freq = 1174.66 if is_offbeat else 880.0  # D6 high whistle for syncopated offbeat, A5 for straight beat
        add_note_stereo(left, right, cue_time, 0.11, steam_cue_whistle(cue_freq), pan=-0.35)

    return left, right


# ============================================================================
# 2. ECHO PLANET — 96 BPM, 36.0s, Dreamy Space-Pop & Star Choir Call/Response
# ============================================================================
def build_echo_planet_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    # Fmaj9 - Dm9 - Bbmaj7 - C13sus4 dreamy progression
    chords = [
        [midi_to_hz(53), midi_to_hz(60), midi_to_hz(64), midi_to_hz(67), midi_to_hz(74)],  # Fmaj9
        [midi_to_hz(50), midi_to_hz(57), midi_to_hz(60), midi_to_hz(64), midi_to_hz(72)],  # Dm9
        [midi_to_hz(46), midi_to_hz(53), midi_to_hz(57), midi_to_hz(62), midi_to_hz(69)],  # Bbmaj7
        [midi_to_hz(48), midi_to_hz(55), midi_to_hz(58), midi_to_hz(62), midi_to_hz(69)],  # C9sus4
    ]
    arp_notes = [
        [77, 81, 84, 88],
        [74, 77, 81, 84],
        [70, 74, 77, 81],
        [72, 76, 79, 84],
    ]
    bass_notes = [41, 38, 34, 36]

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        c_idx = bar % 4
        # Determine if we are in LISTEN (first 4 beats of 8-beat round) or RESPONSE (second 4 beats)
        is_response = (b % 8) >= 4

        # Soft space-pop kick & rimshot
        if beat_in_bar in (0, 2):
            add_note_stereo(left, right, t0, 0.24, kick_drum, pan=0.0)
        else:
            add_note_stereo(left, right, t0, 0.16, lambda t, d: snare_drum(t, d, tight=True), pan=0.0)

        # Shimmering starlight arpeggio (quieter during LISTEN/RESPONSE so vocal calls shine, fuller on response groove)
        arp_amp = 0.11 if not is_response else 0.15
        arp_seq = arp_notes[c_idx]
        add_note_stereo(left, right, t0, 0.45 * spb, space_bell(midi_to_hz(arp_seq[beat_in_bar]), arp_amp), pan=-0.4 if beat_in_bar % 2 == 0 else 0.4)
        add_note_stereo(left, right, t0 + 0.5 * spb, 0.45 * spb, space_bell(midi_to_hz(arp_seq[(beat_in_bar + 2) % 4]), arp_amp * 0.8), pan=0.35 if beat_in_bar % 2 == 0 else -0.35)

        # Warm synth bass pulse
        add_note_stereo(left, right, t0, 0.85 * spb, slap_bass(midi_to_hz(bass_notes[c_idx]), 0.6), pan=0.0)

        # Lush warm pad on bar downbeat
        if beat_in_bar == 0:
            add_note_stereo(left, right, t0, 3.8 * spb, epiano_chord(chords[c_idx], 0.12), pan=0.0)

        # Subtle turn-handoff chime on beat 3.5 of LISTEN phase ("ding-dong -> your turn!")
        if (b % 8) == 3:
            add_note_stereo(left, right, t0 + 0.5 * spb, 0.25, space_bell(midi_to_hz(84), 0.20), pan=0.0)

    # Render the Alien Singer's melodic calls with expressive formant synthesis
    for call in chart.get("calls", []):
        c_beat = float(call["beat"])
        tone = int(call.get("tone", 0))
        add_note_stereo(left, right, c_beat * spb, 0.34, alien_vocal_call(tone), pan=-0.12)

    return left, right


# ============================================================================
# 3. RHYTHM KITCHEN — 102 BPM, 42.0s, Jaunty Bossa-Ska / Acoustic Marimba Pop
# ============================================================================
def build_rhythm_kitchen_song(chart: dict) -> tuple[array.array, array.array]:
    bpm = float(chart["bpm"])
    duration = float(chart["duration"])
    spb = 60.0 / bpm
    n = int(math.ceil(duration * SAMPLE_RATE))
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)

    total_beats = int(duration / spb)
    # Gmaj7 - E7alt - Am7 - D9 jaunty cooking progression
    chords = [
        [midi_to_hz(55), midi_to_hz(59), midi_to_hz(62), midi_to_hz(66)],  # Gmaj7
        [midi_to_hz(52), midi_to_hz(56), midi_to_hz(59), midi_to_hz(62)],  # E7
        [midi_to_hz(57), midi_to_hz(60), midi_to_hz(64), midi_to_hz(67)],  # Am7
        [midi_to_hz(50), midi_to_hz(54), midi_to_hz(60), midi_to_hz(64)],  # D9
    ]
    walking_bass = [
        [43, 47, 50, 47],  # G - B - D - B
        [40, 44, 47, 44],  # E - G# - B - G#
        [45, 48, 52, 48],  # A - C - E - C
        [38, 42, 45, 49],  # D - F# - A - C#
    ]
    marimba_hook = [
        (0.0, 0.5, 79), (0.5, 0.5, 83), (1.0, 1.0, 86), (2.0, 0.5, 83), (2.5, 1.0, 79),
        (4.0, 0.5, 76), (4.5, 0.5, 80), (5.0, 1.0, 83), (6.0, 1.5, 76),
        (8.0, 0.5, 76), (8.5, 0.5, 79), (9.0, 1.0, 81), (10.0, 0.5, 79), (10.5, 1.0, 76),
        (12.0, 0.5, 74), (12.5, 0.5, 78), (13.0, 0.5, 81), (13.5, 0.5, 84), (14.0, 1.5, 86),
    ]

    for b in range(total_beats):
        t0 = b * spb
        bar = b // 4
        beat_in_bar = b % 4
        c_idx = bar % 4

        # Bossa/Ska drum groove: Kick on all 4, crisp offbeat ska chord chop on the "&" of every beat!
        add_note_stereo(left, right, t0, 0.22, kick_drum, pan=0.0)
        if beat_in_bar in (1, 3):
            add_note_stereo(left, right, t0, 0.18, lambda t, d: snare_drum(t, d, tight=True), pan=0.08)

        # Upbeat ska guitar/epiano chop on "+0.5" beat
        add_note_stereo(left, right, t0 + 0.5 * spb, 0.35 * spb, epiano_chord(chords[c_idx], 0.16), pan=-0.28 if beat_in_bar % 2 == 0 else 0.28)
        # Shaker on 16ths
        add_note_stereo(left, right, t0 + 0.25 * spb, 0.06, lambda t, d: hihat(t, d, False), pan=-0.3)
        add_note_stereo(left, right, t0 + 0.75 * spb, 0.06, lambda t, d: hihat(t, d, False), pan=0.3)

        # Walking acoustic bassline
        b_midi = walking_bass[c_idx][beat_in_bar]
        add_note_stereo(left, right, t0, 0.85 * spb, slap_bass(midi_to_hz(b_midi), 0.8), pan=0.0)

    # Playful Marimba & Brass melody
    for phrase_start in range(0, total_beats - 4, 16):
        for rel_b, dur_b, m_note in marimba_hook:
            st = (phrase_start + rel_b) * spb
            if st < duration - 0.5:
                add_note_stereo(left, right, st, dur_b * spb, kitchen_marimba(midi_to_hz(m_note), 0.21), pan=0.2)
                if phrase_start >= 16:
                    add_note_stereo(left, right, st, dur_b * spb * 0.85, brass_lead(midi_to_hz(m_note - 12), 0.11), pan=-0.2)

    # Audible left/right prep cue 1.0 beat before each ingredient event
    for ev in chart.get("events", []):
        ev_beat = float(ev["beat"])
        is_left = str(ev.get("lane", "left")) == "left"
        cue_t = max(0.0, (ev_beat - 1.0) * spb)
        add_note_stereo(left, right, cue_t, 0.10, kitchen_prep_cue(is_left), pan=-0.45 if is_left else 0.45)

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
    # Heavy mechanical stamp thud + crisp pneumatic release + bright C6-G6 ink chime!
    thud = math.sin(TAU * (110.0 + 180.0 * math.exp(-t * 45.0)) * t) * math.exp(-t * 18.0) * 0.55
    chime1 = math.sin(TAU * 1046.5 * t) * math.exp(-t * 16.0) * 0.35
    chime2 = math.sin(TAU * 1567.98 * max(0.0, t - 0.035)) * math.exp(-max(0.0, t - 0.035) * 14.0) * (0.38 if t >= 0.035 else 0.0)
    clack = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 65.0) * 0.25
    return thud + chime1 + chime2 + clack


def sfx_bf_good(t: float, _d: float) -> float:
    thud = math.sin(TAU * 130.0 * t) * math.exp(-t * 22.0) * 0.45
    tone = math.sin(TAU * 698.46 * t) * math.exp(-t * 18.0) * 0.32
    return thud + tone


def sfx_bf_miss(t: float, _d: float) -> float:
    # Comic spring boing / crooked clank
    freq = 165.0 - 45.0 * math.sin(TAU * 14.0 * t) * math.exp(-t * 6.0)
    boing = (math.sin(TAU * freq * t) + 0.4 * math.sin(TAU * freq * 2.5 * t)) * math.exp(-t * 9.0) * 0.48
    return boing


def sfx_ep_perfect(t: float, _d: float) -> float:
    # Harmonized alien star-choir response ("La-aa!" + shimmering bell chord F5-A5-C6)
    voice = alien_vocal_call(5)(t, 0.26) * 0.85
    sparkle = (
        math.sin(TAU * 1396.91 * t) * 0.22
        + math.sin(TAU * 1760.0 * t) * 0.18
        + math.sin(TAU * 2093.0 * t) * 0.16
    ) * math.exp(-t * 11.0)
    return voice + sparkle


def sfx_ep_good(t: float, _d: float) -> float:
    return alien_vocal_call(2)(t, 0.22) * 0.75


def sfx_ep_miss(t: float, _d: float) -> float:
    # Off-key warbling alien antenna "womp-womp"
    f = 230.0 - 75.0 * (t / 0.25) + 18.0 * math.sin(TAU * 22.0 * t)
    return (math.sin(TAU * f * t) + 0.35 * math.sin(TAU * f * 1.9 * t)) * math.exp(-t * 8.5) * 0.45


def sfx_rk_perfect_left(t: float, _d: float) -> float:
    # Crisp frying pan toss sizzle + cheerful G5-B5 marimba pop!
    sizzle = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 28.0) * 0.26
    pop1 = math.sin(TAU * 783.99 * t) * math.exp(-t * 20.0) * 0.42
    pop2 = math.sin(TAU * 1174.66 * max(0.0, t - 0.03)) * math.exp(-max(0.0, t - 0.03) * 16.0) * (0.36 if t >= 0.03 else 0.0)
    return sizzle + pop1 + pop2


def sfx_rk_perfect_right(t: float, _d: float) -> float:
    # Ceramic mixing bowl whisk chime + cheerful D5-A5-D6 pop!
    clink = math.sin(TAU * 1567.98 * t) * math.exp(-t * 24.0) * 0.35
    pop2 = math.sin(TAU * 2349.32 * max(0.0, t - 0.03)) * math.exp(-max(0.0, t - 0.03) * 16.0) * (0.35 if t >= 0.03 else 0.0)
    body = math.sin(TAU * 587.33 * t) * math.exp(-t * 18.0) * 0.32
    return clink + pop2 + body


def sfx_rk_good(t: float, _d: float) -> float:
    return (math.sin(TAU * 587.33 * t) + 0.3 * math.sin(TAU * 880.0 * t)) * math.exp(-t * 18.0) * 0.40


def sfx_rk_miss(t: float, _d: float) -> float:
    # Comic pot clatter / splat
    noise = prng_noise(int(t * SAMPLE_RATE)) * math.exp(-t * 16.0) * 0.28
    thud = math.sin(TAU * (150.0 - 60.0 * t) * t) * math.exp(-t * 11.0) * 0.40
    return noise + thud


def build_result_fanfare(superb: bool) -> tuple[array.array, array.array]:
    dur = 2.4
    n = int(dur * SAMPLE_RATE)
    left = array.array("f", [0.0] * n)
    right = array.array("f", [0.0] * n)
    if superb:
        # Joyful Rhythm-Heaven-style brass & bell fanfare (C5 - E5 - G5 - A5 - C6!)
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
