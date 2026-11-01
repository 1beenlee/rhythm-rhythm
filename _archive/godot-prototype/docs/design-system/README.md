# Rhythm Rhythm Design System · v0.1

## Visual direction
**Playroom instrumentation:** warm, toy-like geometry rather than literal skeuomorphism; each game has unique silhouettes but all navigation uses shared cards/buttons. Source-of-truth colors and component styles are in `core/tokens.gd`. No company design system or third-party game assets.

## Design tokens
| Token | Value | Use |
|---|---|---|
| ink | `#1a2139` | headings and key controls |
| sky | `#f5f9ff` | common background |
| lavender | `#7568e9` | brand and primary buttons |
| aqua | `#34c9b9` | success and secondary action |
| coral | `#ff786f` | key input and gameplay targets |
| yellow | `#ffd866` | beat/event accents |
| muted | `#67738f` | secondary text |
| perfect | `#1db7aa` | perfect feedback |
| good | `#e49a2b` | good feedback |
| miss | `#e56268` | miss feedback |

System font for broad character coverage, fallback for handwritten canvas labels. Primary title 37px, heading 20–23px, body 17–21px, small notes 14–15px. Spacing rhythm: 4px unit, default container gap 12px, outer margin 18px. Rounded controls radius 16px, panels radius 22px. All large touch actions are at least 54px high.

## Components and state
- Shell: Splash (engine load), home, choose game, pre-play help, play, results, settings, offline guidance.
- HUD: score, combo, beat. Game-specific scene owns only playfield visuals; global controls and results never diverge.
- Perfect / Good / Miss: text plus teal/amber/red flash and positive/neutral/low pitch sound respectively. Text makes outcomes accessible independent of color.
- Countdown: 3–2–1–GO before audio starts. Pause and resume must preserve song position; restart resets all notes.
- Motion: key hits respond for 300ms, score/feedback immediately; reduced-motion mode eliminates decorative pulsing, not timing cues.
- Audio identity: distinct synthesized bass + bright pulses, no imported samples. On input, short procedural tones. Never rely on particles alone.
- Accessibility: contrast-focused ink on pale backgrounds; keyboard and touch affordances; two-lane buttons labeled with directions, no color-only meaning; settings for audio offsets and reduced motion. Requires actual contrast and device-level QA.

## Variability contract
A mini-game may own its sky/color, creature/prop geometry, cue shapes, lane positions and pulse motion. It must not duplicate menu, HUD, judgement, score, settings, pause or results. New games extend `RhythmVisual` and add manifest/chart only. 3 implementations use `RhythmTokens` directly.

## Limitations
Illustrations are deterministic vector primitives in GDScript, not polished character sheets. Screenreader labels are not validated. Haptics and localization are future improvements. All real-device visual tests remain required.
