extends Control

var games: Array[Dictionary] = []
var profile: Dictionary = {}
var selected: Dictionary = {}
var selected_idx := 0
var session: RhythmSession
var visual: RhythmVisual
var page: Control
var body: VBoxContainer
var hud: Label
var status: Label
var countdown_text: Label
var debug_label: Label
var pause_modal: Control
var rehearsal_art: StageUIArt
var card_arts: Array[StageUIArt] = []
var bgm_player: AudioStreamPlayer
var preview_sfx: AudioStreamPlayer
var ui_sfx: AudioStreamPlayer
var debug_open := false
var page_name := "home"
var current_bgm_kind := ""
var latest_summary: Dictionary = {}
var eval_seq_id := 0

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.finished.connect(func():
		if current_bgm_kind != "" and is_instance_valid(bgm_player):
			bgm_player.play()
	)
	preview_sfx = AudioStreamPlayer.new()
	add_child(preview_sfx)
	ui_sfx = AudioStreamPlayer.new()
	add_child(ui_sfx)
	get_window().size_changed.connect(_adapt_viewport)
	_adapt_viewport()
	games = GameRegistry.discover()
	profile = RhythmSave.settings()
	_home()

func _play_bgm(kind: String) -> void:
	current_bgm_kind = kind
	if not is_instance_valid(bgm_player):
		return
	if kind == "":
		bgm_player.stop()
		return
	var stream := RhythmSynth.make_bgm(kind)
	if bgm_player.stream != stream or not bgm_player.playing:
		bgm_player.stream = stream
		bgm_player.volume_linear = float(profile.get("volume", 0.85)) * 0.72
		bgm_player.play()

func _play_ui_sfx(kind: String) -> void:
	if not is_instance_valid(ui_sfx):
		return
	ui_sfx.volume_linear = float(profile.get("volume", 0.85))
	ui_sfx.stream = RhythmSynth.make_ui_sfx(kind)
	ui_sfx.play()

func _wire_button_sfx(btn: Button, click_fn: Callable) -> void:
	btn.mouse_entered.connect(func(): _play_ui_sfx("focus"))
	btn.focus_entered.connect(func(): _play_ui_sfx("focus"))
	btn.pressed.connect(func():
		_play_ui_sfx("click")
		click_fn.call()
	)

func _adapt_viewport() -> void:
	var screen := get_window().size
	var base := Vector2i(420, 800) if screen.x < screen.y else Vector2i(960, 640)
	if get_window().content_scale_size != base:
		get_window().content_scale_size = base

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(session):
		if page_name == "play":
			session.pause_session()
			_update_pause_hint()

func _input(event: InputEvent) -> void:
	if page_name == "home" and event is InputEventKey and event.pressed and not event.echo:
		var hkey: int = (event as InputEventKey).keycode
		if hkey in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_play_ui_sfx("click")
			_select_games()
			get_viewport().set_input_as_handled()
		return
	if page_name == "select" and event is InputEventKey and event.pressed and not event.echo:
		var skey: int = (event as InputEventKey).keycode
		if skey in [KEY_LEFT, KEY_A] and not games.is_empty():
			_focus_card((selected_idx - 1 + games.size()) % games.size())
			get_viewport().set_input_as_handled()
		elif skey in [KEY_RIGHT, KEY_D, KEY_L] and not games.is_empty():
			_focus_card((selected_idx + 1) % games.size())
			get_viewport().set_input_as_handled()
		elif skey in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not games.is_empty():
			_play_ui_sfx("click")
			_guide(games[selected_idx])
			get_viewport().set_input_as_handled()
		elif skey in [KEY_ESCAPE, KEY_B, KEY_BACKSPACE]:
			_play_ui_sfx("click")
			_home()
			get_viewport().set_input_as_handled()
		return
	if page_name == "guide" and event is InputEventKey and event.pressed and not event.echo:
		var gkey: int = (event as InputEventKey).keycode
		if gkey in [KEY_SPACE, KEY_F, KEY_J, KEY_A, KEY_L, KEY_LEFT, KEY_RIGHT]:
			_rehearsal_tap()
			get_viewport().set_input_as_handled()
		elif gkey in [KEY_ENTER, KEY_KP_ENTER]:
			_play_ui_sfx("click")
			_play()
			get_viewport().set_input_as_handled()
		return
	if page_name == "results" and event is InputEventKey and event.pressed and not event.echo:
		var rkey: int = (event as InputEventKey).keycode
		if rkey in [KEY_A, KEY_SPACE, KEY_ENTER]:
			_play_ui_sfx("click")
			_play()
			get_viewport().set_input_as_handled()
		elif rkey in [KEY_B, KEY_ESCAPE]:
			_play_ui_sfx("click")
			_select_games()
			get_viewport().set_input_as_handled()
		return
	if page_name != "play" or not is_instance_valid(session):
		return
	if event is InputEventKey:
		var key: int = (event as InputEventKey).keycode
		if event.is_echo():
			return
		if event.pressed:
			if key == KEY_F3:
				debug_open = not debug_open
				if is_instance_valid(debug_label):
					debug_label.visible = debug_open
				if is_instance_valid(hud):
					hud.visible = debug_open
			elif key == KEY_ESCAPE or key == KEY_P:
				_play_ui_sfx("click")
				_toggle_pause()
			elif not session.paused:
				if selected["id"] == "rhythm_kitchen":
					if key in [KEY_A, KEY_LEFT]:
						session.submit("left")
					elif key in [KEY_D, KEY_L, KEY_RIGHT]:
						session.submit("right")
				else:
					if key in [KEY_SPACE, KEY_F, KEY_J, KEY_ENTER, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
						session.submit_press("tap")
			get_viewport().set_input_as_handled()
		else:
			# Key Release (Press-Hold-Release mechanics for Beat Factory!)
			if not session.paused:
				if selected["id"] == "beat_factory":
					if key in [KEY_SPACE, KEY_F, KEY_J, KEY_ENTER, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
						session.submit_release("tap")
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if page_name != "play" or not is_instance_valid(session):
		return
	if is_instance_valid(pause_modal) and pause_modal.visible != session.paused:
		_update_pause_hint()
	if is_instance_valid(debug_label) and debug_open:
		debug_label.text = "DEBUG | audio %.3fs | mix %.3fs | latency %.3fs | input %dms | output %dms" % [session.audio.get_playback_position(), AudioServer.get_time_since_last_mix(), AudioServer.get_output_latency(), int(profile["input_ms"]), int(profile["output_ms"])]
	if is_instance_valid(hud):
		var beat := session.song_time * float(session.chart["bpm"]) / 60.0
		hud.text = "SCORE %06d   COMBO %d   BEAT %.1f" % [session.score, session.combo, beat]

func _reset_page(name: String, margin_px: int = 12, bg_col: Color = RhythmTokens.SKY) -> void:
	eval_seq_id += 1
	page_name = name
	card_arts.clear()
	if is_instance_valid(page):
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var background := ColorRect.new()
	background.color = bg_col
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(background)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", margin_px)
	margins.add_theme_constant_override("margin_right", margin_px)
	margins.add_theme_constant_override("margin_top", margin_px)
	margins.add_theme_constant_override("margin_bottom", margin_px)
	page.add_child(margins)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margins.add_child(body)

func _text(value: String, size_px: int = 20, color: Color = RhythmTokens.INK) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", size_px)
	item.add_theme_color_override("font_color", color)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(item)
	return item

func _button(value: String, fn: Callable, accent: Color = RhythmTokens.LAVENDER) -> Button:
	var button := Button.new()
	button.text = value
	RhythmTokens.style_button(button, accent)
	_wire_button_sfx(button, fn)
	body.add_child(button)
	return button

func _spacer() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

func _heading(title: String, subtitle: String) -> void:
	_text(title, 28, RhythmTokens.INK)
	_text(subtitle, 15, RhythmTokens.MUTED)

# =============================================================================
# PANEL 01: TITLE SCREEN (_home)
# =============================================================================
func _home() -> void:
	_dispose_session()
	_reset_page("home", 0, Color("ffe359"))
	_play_bgm("title")

	var banner := StageUIArt.new().setup("home_banner", "beat_factory", "SUPERB", bool(profile.get("reduced_motion", false)))
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(banner)

	# Bottom-Center Cream Pill Button: "PRESS START" with crisp vector play triangle (Zero Unicode Tofu!)
	var start_btn := Button.new()
	start_btn.text = "   PRESS START"
	RhythmTokens.style_button(start_btn, Color("fffdf5"), Vector2(280, 56), 24)
	CartoonDraw.attach_button_icon(start_btn, "play", CartoonDraw.INK)
	_wire_button_sfx(start_btn, _select_games)
	start_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	start_btn.offset_left = -150
	start_btn.offset_right = 150
	start_btn.offset_top = -74
	start_btn.offset_bottom = -14
	page.add_child(start_btn)

	# Discreet top-right utility buttons for Timing & Offline with vector icons
	var util_row := HBoxContainer.new()
	util_row.add_theme_constant_override("separation", 8)
	util_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	util_row.offset_left = -260
	util_row.offset_right = -12
	util_row.offset_top = 10
	util_row.offset_bottom = 46
	page.add_child(util_row)

	var set_btn := Button.new()
	set_btn.text = "    TIMING"
	RhythmTokens.style_button(set_btn, Color("fffdf5"), Vector2(115, 34), 14)
	CartoonDraw.attach_button_icon(set_btn, "gear", CartoonDraw.INK)
	_wire_button_sfx(set_btn, _settings_page)
	util_row.add_child(set_btn)

	var off_btn := Button.new()
	off_btn.text = "    OFFLINE"
	RhythmTokens.style_button(off_btn, Color("fffdf5"), Vector2(115, 34), 14)
	CartoonDraw.attach_button_icon(off_btn, "plane", CartoonDraw.INK)
	_wire_button_sfx(off_btn, _offline_page)
	util_row.add_child(off_btn)

# =============================================================================
# PANEL 02: STAGE SELECT SCREEN (_select_games)
# =============================================================================
func _select_games() -> void:
	_dispose_session()
	var is_portrait := get_window().size.x < get_window().size.y
	_reset_page("select", 10 if is_portrait else 16, Color("98d8ff"))
	_play_bgm("select")

	var header_art := StageUIArt.new().setup("select_header", "beat_factory", "SUPERB", bool(profile.get("reduced_motion", false)))
	header_art.custom_minimum_size = Vector2(0, 56 if is_portrait else 78)
	body.add_child(header_art)

	if games.is_empty():
		_text("No valid game packs found. Run the manifest validator.")
		return

	var grid: BoxContainer
	if is_portrait:
		grid = VBoxContainer.new()
		grid.add_theme_constant_override("separation", 8)
	else:
		grid = HBoxContainer.new()
		grid.add_theme_constant_override("separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(grid)

	card_arts.clear()
	for idx in range(games.size()):
		var game: Dictionary = games[idx]
		var holder := Control.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		holder.custom_minimum_size = Vector2(0, 145 if is_portrait else 340)
		grid.add_child(holder)

		var poster := StageUIArt.new().setup("poster_card", str(game["id"]), "SUPERB", bool(profile.get("reduced_motion", false)))
		poster.card_selected = (idx == selected_idx)
		poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(poster)
		card_arts.append(poster)

		var hit_btn := Button.new()
		hit_btn.flat = true
		hit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hit_btn.mouse_entered.connect(_focus_card.bind(idx))
		hit_btn.focus_entered.connect(_focus_card.bind(idx))
		hit_btn.pressed.connect(func():
			selected_idx = idx
			_play_ui_sfx("click")
			_guide(game)
		)
		holder.add_child(hit_btn)

	# Bottom Pill Bar: "SELECT    (A) PLAY    (B) BACK" with vector arrows (Panel 02!)
	var bot_row := HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 12)
	body.add_child(bot_row)

	var prev_btn := Button.new()
	prev_btn.text = "     SELECT"
	RhythmTokens.style_button(prev_btn, Color("fffdf5"), Vector2(130 if is_portrait else 160, 42 if is_portrait else 48), 15 if is_portrait else 18)
	CartoonDraw.attach_button_icon(prev_btn, "arrows_lr", CartoonDraw.INK)
	_wire_button_sfx(prev_btn, func(): _focus_card((selected_idx + 1) % games.size()))
	bot_row.add_child(prev_btn)

	var play_sel_btn := Button.new()
	play_sel_btn.text = "(A) PLAY"
	RhythmTokens.style_button(play_sel_btn, Color("ff5d8f"), Vector2(120 if is_portrait else 160, 42 if is_portrait else 48), 16 if is_portrait else 19)
	_wire_button_sfx(play_sel_btn, func(): _guide(games[selected_idx]))
	bot_row.add_child(play_sel_btn)

	var back_btn := Button.new()
	back_btn.text = "(B) BACK"
	RhythmTokens.style_button(back_btn, Color("fffdf5"), Vector2(110 if is_portrait else 150, 42 if is_portrait else 48), 15 if is_portrait else 18)
	_wire_button_sfx(back_btn, _home)
	bot_row.add_child(back_btn)

func _focus_card(idx: int) -> void:
	if idx < 0 or idx >= games.size():
		return
	if selected_idx != idx:
		selected_idx = idx
		_play_ui_sfx("focus")
	for i in range(card_arts.size()):
		if is_instance_valid(card_arts[i]):
			card_arts[i].card_selected = (i == selected_idx)
			card_arts[i].queue_redraw()

# =============================================================================
# REHEARSAL & CHARACTER SHEET SCREEN (_guide — Panels 10, 11, 12)
# =============================================================================
func _guide(game: Dictionary) -> void:
	selected = game
	_reset_page("guide", 14, Color("f7ecd0"))
	_play_bgm("select")
	_heading(str(game["name"]) + " - CHARACTER & RHYTHM GUIDE", str(game["description"]))

	rehearsal_art = StageUIArt.new().setup("rehearsal_stage", str(game["id"]), "SUPERB", bool(profile.get("reduced_motion", false)))
	rehearsal_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rehearsal_art.custom_minimum_size = Vector2(0, 220)
	body.add_child(rehearsal_art)

	var instruction := "Press SPACE / F / J or Click the stage on the beat when each box reaches the Stamp Press!"
	if str(game["id"]) == "echo_planet":
		instruction = "1. LISTEN to the Alien's Call in the top row  ->  2. ECHO those exact beats in the bottom Star row!"
	elif str(game["id"]) == "rhythm_kitchen":
		instruction = "Press A (Left) to catch flying Green Lettuce, and L (Right) to catch flying Red Tomatoes!"
	_text(instruction, 16, RhythmTokens.INK)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	body.add_child(action_row)

	var prac_btn := Button.new()
	prac_btn.text = "   TEST SOUND & POSE"
	RhythmTokens.style_button(prac_btn, RhythmTokens.YELLOW, Vector2(150, 48), 17)
	CartoonDraw.attach_button_icon(prac_btn, "music", CartoonDraw.INK)
	prac_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_button_sfx(prac_btn, _rehearsal_tap)
	action_row.add_child(prac_btn)

	var start_btn := Button.new()
	start_btn.text = "   START STAGE!"
	RhythmTokens.style_button(start_btn, RhythmTokens.CORAL, Vector2(170, 48), 19)
	CartoonDraw.attach_button_icon(start_btn, "star", CartoonDraw.GOLD)
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_button_sfx(start_btn, _play)
	action_row.add_child(start_btn)

	var back_sel_btn := Button.new()
	back_sel_btn.text = "   CHOOSE ANOTHER GAME"
	RhythmTokens.style_button(back_sel_btn, Color("fffdf5"), Vector2(160, 42), 16)
	CartoonDraw.attach_button_icon(back_sel_btn, "back", CartoonDraw.INK)
	_wire_button_sfx(back_sel_btn, _select_games)
	body.add_child(back_sel_btn)

func _rehearsal_tap() -> void:
	if is_instance_valid(preview_sfx) and not selected.is_empty():
		preview_sfx.volume_linear = float(profile.get("volume", 0.85))
		preview_sfx.stream = RhythmSynth.make_world_hit(str(selected["id"]), "Perfect", "left")
		preview_sfx.play()
	if is_instance_valid(rehearsal_art):
		rehearsal_art.trigger_rehearsal_hit("Perfect")

# =============================================================================
# GAMEPLAY STAGE (_play — Panels 03, 04, 05, 06, 07, 08)
# =============================================================================
func _play() -> void:
	_dispose_session()
	_play_bgm("")
	var is_portrait := get_window().size.x < get_window().size.y
	_reset_page("play", 4 if is_portrait else 6, Color("191622"))
	session = RhythmSession.new()
	add_child(session)
	session.configure(selected, profile)
	session.finished.connect(_results)
	session.countdown.connect(_on_countdown)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", RhythmTokens.panel(RhythmTokens.WHITE, 16, 4, RhythmTokens.INK, 2))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(frame)

	var stage_holder := Control.new()
	stage_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(stage_holder)

	var visual_scene := load(str(selected["scene"])) as PackedScene
	if visual_scene == null:
		_text("Scene unavailable", 18, RhythmTokens.WHITE)
		return
	visual = visual_scene.instantiate() as RhythmVisual
	stage_holder.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.configure(selected["_chart"], session, bool(profile["reduced_motion"]))

	var pause_btn := Button.new()
	pause_btn.text = "II" if is_portrait else "II PAUSE"
	RhythmTokens.style_button(pause_btn, RhythmTokens.YELLOW, Vector2(42 if is_portrait else 84, 34 if is_portrait else 40), 13 if is_portrait else 15)
	_wire_button_sfx(pause_btn, _toggle_pause)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -54 if is_portrait else -96
	pause_btn.offset_right = -12
	pause_btn.offset_top = 12
	pause_btn.offset_bottom = 46 if is_portrait else 52
	stage_holder.add_child(pause_btn)

	status = Label.new()
	status.text = "READY?"
	status.visible = false
	stage_holder.add_child(status)

	countdown_text = Label.new()
	countdown_text.text = "3"
	countdown_text.visible = false
	stage_holder.add_child(countdown_text)

	hud = Label.new()
	hud.text = "SCORE 000000   COMBO 0   BEAT 0.0"
	hud.visible = debug_open
	stage_holder.add_child(hud)

	pause_modal = _build_pause_modal()
	pause_modal.visible = false
	page.add_child(pause_modal)
	pause_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	debug_label = _text("", 12, RhythmTokens.YELLOW)
	debug_label.visible = debug_open

func _build_pause_modal() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.08, 0.06, 0.12, 0.76)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(320, 240)
	card.add_theme_stylebox_override("panel", RhythmTokens.panel(RhythmTokens.CREAM, 20, 4, RhythmTokens.INK, 18))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var p_title := Label.new()
	p_title.text = "SHOW PAUSED"
	p_title.add_theme_font_size_override("font_size", 24)
	p_title.add_theme_color_override("font_color", RhythmTokens.INK)
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(p_title)

	var res_btn := Button.new()
	res_btn.text = "   RESUME SHOW"
	RhythmTokens.style_button(res_btn, RhythmTokens.CORAL, Vector2(220, 46), 18)
	CartoonDraw.attach_button_icon(res_btn, "play", Color.WHITE)
	_wire_button_sfx(res_btn, _toggle_pause)
	vbox.add_child(res_btn)

	var rest_btn := Button.new()
	rest_btn.text = "   RESTART TRACK"
	RhythmTokens.style_button(rest_btn, RhythmTokens.AQUA, Vector2(220, 44), 17)
	CartoonDraw.attach_button_icon(rest_btn, "restart", CartoonDraw.INK)
	_wire_button_sfx(rest_btn, _play)
	vbox.add_child(rest_btn)

	var exit_btn := Button.new()
	exit_btn.text = "   STAGE SELECT"
	RhythmTokens.style_button(exit_btn, RhythmTokens.INK, Vector2(220, 44), 17)
	CartoonDraw.attach_button_icon(exit_btn, "back", Color.WHITE)
	_wire_button_sfx(exit_btn, _exit_play)
	vbox.add_child(exit_btn)

	return overlay

func _on_countdown(number: int) -> void:
	if is_instance_valid(session) and session.paused:
		return
	if is_instance_valid(countdown_text):
		countdown_text.text = "PLAY" if number < 0 else ("GO!" if number == 0 else str(number))
	if number < 0 and is_instance_valid(status):
		status.text = "FOLLOW THE SOUND"

func _submit_touch(lane: String) -> void:
	if is_instance_valid(session):
		session.submit(lane)

func _toggle_pause() -> void:
	if not is_instance_valid(session):
		return
	if session.paused:
		session.resume_session()
	else:
		session.pause_session()
	_update_pause_hint()

func _update_pause_hint() -> void:
	if is_instance_valid(pause_modal) and is_instance_valid(session):
		pause_modal.visible = session.paused
	if is_instance_valid(status) and is_instance_valid(session):
		status.text = "PAUSED - TAP RESUME OR PRESS P" if session.paused else ("FOLLOW THE SOUND" if session.active else "GET READY")
	if is_instance_valid(countdown_text) and is_instance_valid(session):
		if session.paused:
			countdown_text.text = "PAUSED"
		elif session.active:
			countdown_text.text = "PLAY"
		else:
			var elapsed := float(Time.get_ticks_usec() - session.countdown_start_usec) / 1000000.0
			countdown_text.text = str(maxi(0, 3 - int(elapsed / clampf(60.0 / float(session.chart.get("bpm", 100.0)), 0.40, 1.00))))

func _exit_play() -> void:
	_dispose_session()
	_select_games()

# =============================================================================
# POST-STAGE FLOW: 검정화면 (Black Curtain) > 평가 (Evaluation) > 시상 (Award Screen, Panel 09)
# =============================================================================
func _compute_tier(summary: Dictionary) -> String:
	var c: Dictionary = summary.get("counts", {"Perfect": 0, "Good": 0, "Miss": 0})
	var total_ev := maxi(1, int(summary.get("total", 1)))
	var hit_ratio := float(int(c.get("Perfect", 0)) + int(c.get("Good", 0))) / float(total_ev)
	var perf_ratio := float(int(c.get("Perfect", 0))) / float(total_ev)
	if hit_ratio >= 0.75 and perf_ratio >= 0.45:
		return "SUPERB"
	elif hit_ratio >= 0.45:
		return "OK"
	return "TRY AGAIN"

func _results(summary: Dictionary) -> void:
	latest_summary = summary.duplicate(true)
	latest_summary["stage_name"] = str(selected.get("name", "Rhythm Kitchen"))
	var tier := _compute_tier(latest_summary)
	_dispose_session()
	_play_bgm("")
	_run_post_stage_sequence(latest_summary, tier)

func _run_post_stage_sequence(summary: Dictionary, tier: String) -> void:
	_reset_page("eval_black", 24, Color("0a0810"))
	var my_seq := eval_seq_id
	_play_ui_sfx("eval")
	_spacer()
	_text("STAGE COMPLETE", 34, RhythmTokens.YELLOW)
	_text(str(summary.get("stage_name", "Stage")) + " - Evaluating your groove...", 18, RhythmTokens.WHITE)
	_spacer()

	await get_tree().create_timer(1.35).timeout
	if my_seq != eval_seq_id or not is_inside_tree():
		return

	_reset_page("eval_reveal", 16, Color("0d0b14"))
	my_seq = eval_seq_id
	if is_instance_valid(preview_sfx):
		preview_sfx.volume_linear = float(profile.get("volume", 0.85))
		if tier == "SUPERB":
			preview_sfx.stream = RhythmSynth.make_fanfare(true)
		elif tier == "OK":
			preview_sfx.stream = RhythmSynth.make_fanfare(false)
		else:
			preview_sfx.stream = RhythmSynth.make_hit("Miss")
		preview_sfx.play()

	var eval_comment := "Chief's Note: Rhythm perfection! Every beat landed right on the groove!" if tier == "SUPERB" else ("Chief's Note: Solid rhythm! Keep riding the beat!" if tier == "OK" else "Chief's Note: Listen closely to the musical cues and try again!")
	_text("EVALUATION", 22, RhythmTokens.MUTED)
	_text(eval_comment, 20, RhythmTokens.WHITE)
	var eval_art := StageUIArt.new().setup("eval_screen", str(selected.get("id", "beat_factory")), tier, bool(profile.get("reduced_motion", false)))
	eval_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	eval_art.custom_minimum_size = Vector2(0, 220)
	body.add_child(eval_art)
	var tier_col := RhythmTokens.YELLOW if tier == "SUPERB" else (RhythmTokens.AQUA if tier == "OK" else RhythmTokens.CORAL)
	_text("***  " + tier + "!  ***", 42, tier_col)

	await get_tree().create_timer(2.40).timeout
	if my_seq != eval_seq_id or not is_inside_tree():
		return

	_show_award_screen(summary, tier)

func _show_award_screen(summary: Dictionary, tier: String = "") -> void:
	if tier == "":
		tier = _compute_tier(summary)
	latest_summary = summary.duplicate(true)
	if not latest_summary.has("stage_name"):
		latest_summary["stage_name"] = str(selected.get("name", "Rhythm Kitchen"))
	_dispose_session()
	var is_portrait := get_window().size.x < get_window().size.y
	_reset_page("results", 0, Color("ffa3bf"))

	var bgm_key := "results_superb" if tier == "SUPERB" else ("results_ok" if tier == "OK" else "results_try_again")
	_play_bgm(bgm_key)

	var award_art := StageUIArt.new().setup("result_vignette", str(selected.get("id", "rhythm_kitchen")), tier, bool(profile.get("reduced_motion", false)))
	award_art.summary_data = latest_summary
	award_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(award_art)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_row.offset_left = 16 if is_portrait else 28
	btn_row.offset_right = -16 if is_portrait else -28
	btn_row.offset_top = -62 if is_portrait else -72
	btn_row.offset_bottom = -10 if is_portrait else -14
	page.add_child(btn_row)

	var retry_btn := Button.new()
	retry_btn.text = "(A)  PLAY AGAIN"
	RhythmTokens.style_button(retry_btn, Color("ff5d8f"), Vector2(150, 48 if is_portrait else 56), 18 if is_portrait else 22)
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_button_sfx(retry_btn, _play)
	btn_row.add_child(retry_btn)

	var stages_btn := Button.new()
	stages_btn.text = "(B)  STAGE SELECT"
	RhythmTokens.style_button(stages_btn, Color("fffdf5"), Vector2(150, 48 if is_portrait else 56), 18 if is_portrait else 22)
	stages_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_button_sfx(stages_btn, _select_games)
	btn_row.add_child(stages_btn)

func _settings_page() -> void:
	_reset_page("settings", 18)
	_play_bgm("select")
	_heading("TIMING & AUDIO CALIBRATION", "Offsets are stored locally on this device")
	_spacer()
	_slider("Input offset (ms)  - later tap = positive", "input_ms", -250, 250, 5)
	_slider("Extra output offset (ms)", "output_ms", -250, 250, 5)
	_slider("Music & SFX volume", "volume", 0, 100, 5)
	var toggle := CheckButton.new()
	toggle.text = "Reduced motion (calm stage effects)"
	toggle.button_pressed = bool(profile["reduced_motion"])
	toggle.toggled.connect(func(checked: bool):
		_play_ui_sfx("click")
		profile["reduced_motion"] = checked
	)
	body.add_child(toggle)
	_spacer()
	_text("Tip: Bluetooth headphones may need +40 to +90 ms input offset.", 14, RhythmTokens.MUTED)
	_button("SAVE & RETURN TO TITLE", _save_settings, RhythmTokens.AQUA)

func _slider(label_text: String, key: String, lo: float, hi: float, step: float) -> void:
	var value := int(round(float(profile[key]) * (100.0 if key == "volume" else 1.0)))
	var label := _text(label_text + ": " + str(value), 17)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.y = 40
	body.add_child(slider)
	slider.value_changed.connect(func(v: float):
		profile[key] = v / 100.0 if key == "volume" else int(v)
		label.text = label_text + ": " + str(int(v))
		if key == "volume" and is_instance_valid(bgm_player):
			bgm_player.volume_linear = float(profile["volume"]) * 0.72
	)

func _save_settings() -> void:
	var err := RhythmSave.write_settings(profile)
	if err != OK:
		push_warning("Could not write user settings: " + str(err))
	_home()

func _offline_page() -> void:
	_reset_page("offline", 18)
	_play_bgm("select")
	_spacer()
	_heading("PLAY ANYWHERE OFFLINE", "100% self-contained cartoon art & 44.1kHz stereo audio")
	_spacer()
	_text("WEB / PWA: Use your browser's Install App / Add to Home Screen command. Complete the first online load so the Service Worker caches the full game and 44.1kHz stereo soundtracks.", 18)
	_text("WINDOWS DESKTOP: Launch RhythmRhythm.exe alongside RhythmRhythm.pck for zero-network native play.", 18)
	_text("All highscores and timing offsets are saved locally on your device.", 15, RhythmTokens.MUTED)
	_spacer()
	var back_btn := _button("   BACK TO TITLE", _home, RhythmTokens.INK)
	CartoonDraw.attach_button_icon(back_btn, "back", Color.WHITE)

func _dispose_session() -> void:
	if is_instance_valid(session):
		session.stop_session()
		session.queue_free()
	session = null
	visual = null
	pause_modal = null
