extends RefCounted
class_name RhythmTokens

const INK := Color("1d1716")
const SKY := Color("fff8ea")
const STAGE_BG := Color("ffdc4a")
const LAVENDER := Color("6a5be2")
const AQUA := Color("2cc9b3")
const CORAL := Color("ff625c")
const YELLOW := Color("ffd447")
const WHITE := Color("ffffff")
const CREAM := Color("fff9ed")
const MUTED := Color("5c534f")
const PERFECT := Color("19b89c")
const GOOD := Color("f0932b")
const MISS := Color("eb4d55")

static func grade_color(grade: String) -> Color:
    match grade:
        "Perfect": return PERFECT
        "Good": return GOOD
        "Miss": return MISS
    return MUTED

static func panel(color: Color = WHITE, roundness: int = 20, border_px: int = 4, border_col: Color = INK, margin: int = 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(roundness)
    style.set_border_width_all(border_px)
    style.border_color = border_col
    style.shadow_color = Color(0.11, 0.09, 0.08, 0.22)
    style.shadow_size = 0
    style.shadow_offset = Vector2(0, 4)
    style.set_content_margin_all(margin)
    return style

static func style_button(button: Button, accent: Color = LAVENDER, min_size: Vector2 = Vector2(140, 48), font_px: int = 19) -> void:
    button.add_theme_stylebox_override("normal", panel(accent, 16, 4, INK, 10))
    button.add_theme_stylebox_override("hover", panel(accent.lightened(0.14), 16, 4, INK, 10))
    var pressed_style := panel(accent.darkened(0.14), 16, 4, INK, 10)
    pressed_style.shadow_offset = Vector2(0, 1)
    button.add_theme_stylebox_override("pressed", pressed_style)
    button.add_theme_stylebox_override("focus", panel(accent.lightened(0.18), 16, 4, YELLOW, 10))
    var text_col := INK if (accent.r * 0.299 + accent.g * 0.587 + accent.b * 0.114) > 0.68 else WHITE
    button.add_theme_color_override("font_color", text_col)
    button.add_theme_color_override("font_hover_color", text_col)
    button.add_theme_color_override("font_pressed_color", text_col)
    button.add_theme_font_size_override("font_size", font_px)
    button.custom_minimum_size = min_size
    button.focus_mode = Control.FOCUS_ALL
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
