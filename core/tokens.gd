extends RefCounted
class_name RhythmTokens

const INK := Color("1a2139")
const SKY := Color("f5f9ff")
const LAVENDER := Color("7568e9")
const AQUA := Color("34c9b9")
const CORAL := Color("ff786f")
const YELLOW := Color("ffd866")
const WHITE := Color("ffffff")
const MUTED := Color("67738f")
const PERFECT := Color("1db7aa")
const GOOD := Color("e49a2b")
const MISS := Color("e56268")

static func grade_color(grade: String) -> Color:
    match grade:
        "Perfect": return PERFECT
        "Good": return GOOD
        "Miss": return MISS
    return MUTED

static func panel(color: Color = WHITE, roundness: int = 22) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(roundness)
    style.set_content_margin_all(16)
    return style

static func style_button(button: Button, accent: Color = LAVENDER) -> void:
    button.add_theme_stylebox_override("normal", panel(accent, 16))
    button.add_theme_stylebox_override("hover", panel(accent.lightened(0.12), 16))
    button.add_theme_stylebox_override("pressed", panel(accent.darkened(0.15), 16))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_color_override("font_color", WHITE)
    button.add_theme_color_override("font_hover_color", WHITE)
    button.add_theme_color_override("font_pressed_color", WHITE)
    button.add_theme_font_size_override("font_size", 20)
    button.custom_minimum_size = Vector2(150, 54)
    button.focus_mode = Control.FOCUS_ALL
