extends Control

var games: Array[Dictionary] = []
var profile: Dictionary = {}
var selected: Dictionary = {}
var session: RhythmSession
var visual: RhythmVisual
var page: Control
var body: VBoxContainer
var hud: Label
var status: Label
var countdown_text: Label
var debug_label: Label
var debug_open := false
var page_name := "home"
var latest_summary: Dictionary = {}

func _ready() -> void:
    games = GameRegistry.discover()
    profile = RhythmSave.settings()
    _home()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(session):
        if page_name == "play":
            session.pause_session()
            _update_pause_hint()

func _input(event: InputEvent) -> void:
    if page_name != "play" or not is_instance_valid(session):
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var key: int = (event as InputEventKey).keycode
        if key == KEY_F3:
            debug_open = not debug_open
            if is_instance_valid(debug_label):
                debug_label.visible = debug_open
        elif key == KEY_ESCAPE or key == KEY_P:
            _toggle_pause()
        elif not session.paused:
            if selected["id"] == "rhythm_kitchen":
                if key == KEY_A or key == KEY_LEFT:
                    session.submit("left")
                elif key == KEY_L or key == KEY_RIGHT:
                    session.submit("right")
            elif key == KEY_SPACE or key == KEY_F or key == KEY_J:
                session.submit("tap")
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if page_name != "play" or not is_instance_valid(session):
        return
    if is_instance_valid(debug_label) and debug_open:
        debug_label.text = "DEBUG | audio %.3fs | mix %.3fs | latency %.3fs | input %dms | output %dms" % [session.audio.get_playback_position(), AudioServer.get_time_since_last_mix(), AudioServer.get_output_latency(), int(profile["input_ms"]), int(profile["output_ms"])]
    if is_instance_valid(hud):
        hud.text = "SCORE %06d     COMBO %d     BEAT %.1f" % [session.score, session.combo, session.song_time * float(session.chart["bpm"]) / 60.0]

func _reset_page(name: String) -> void:
    page_name = name
    if is_instance_valid(page):
        page.queue_free()
    page = Control.new()
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(page)
    var background := ColorRect.new()
    background.color = RhythmTokens.SKY
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    page.add_child(background)
    var margins := MarginContainer.new()
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margins.add_theme_constant_override("margin_left", 18)
    margins.add_theme_constant_override("margin_right", 18)
    margins.add_theme_constant_override("margin_top", 18)
    margins.add_theme_constant_override("margin_bottom", 18)
    page.add_child(margins)
    body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 12)
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
    button.pressed.connect(fn)
    body.add_child(button)
    return button

func _spacer() -> void:
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(spacer)

func _heading(title: String, subtitle: String) -> void:
    _text("●  RHYTHM RHYTHM", 15, RhythmTokens.LAVENDER)
    _text(title, 37)
    _text(subtitle, 17, RhythmTokens.MUTED)

func _home() -> void:
    _dispose_session()
    _reset_page("home")
    _spacer()
    _heading("RHYTHM²", "Tiny games. Big grooves.")
    _spacer()
    _button("PLAY THE COLLECTION", _select_games)
    _button("SETTINGS & LATENCY", _settings_page, RhythmTokens.AQUA)
    _button("INSTALL & OFFLINE GUIDE", _offline_page, RhythmTokens.INK)
    _spacer()
    _text("Three original music-driven mini worlds · v0.1", 14, RhythmTokens.MUTED)

func _select_games() -> void:
    _reset_page("select")
    _heading("CHOOSE YOUR GROOVE", "Play one complete mini-game at a time")
    _spacer()
    if games.is_empty():
        _text("No valid game packs found. Run the manifest validator.")
    for game in games:
        _button(str(game["name"]) + "  •  BEST %d" % RhythmSave.best(str(game["id"])), _guide.bind(game), Color(str(game["color"])))
        _text(str(game["description"]), 15, RhythmTokens.MUTED)
    _spacer()
    _button("← BACK", _home, RhythmTokens.INK)

func _guide(game: Dictionary) -> void:
    selected = game
    _reset_page("guide")
    _spacer()
    _heading(str(game["name"]), str(game["description"]))
    _spacer()
    var instruction := "Press SPACE or tap the button to the beat."
    if str(game["id"]) == "echo_planet":
        instruction = "LISTEN for four beats, then COPY the pattern for four beats."
    elif str(game["id"]) == "rhythm_kitchen":
        instruction = "Press A / L or tap LEFT / RIGHT to catch the correct ingredient."
    _text(instruction, 21)
    _text("Perfect ±75ms   Good ±160ms   Miss after ±210ms", 15, RhythmTokens.MUTED)
    _spacer()
    _button("LET'S PLAY", _play)
    _button("← GAMES", _select_games, RhythmTokens.INK)

func _play() -> void:
    _dispose_session()
    _reset_page("play")
    session = RhythmSession.new()
    add_child(session)
    session.configure(selected, profile)
    session.finished.connect(_results)
    session.countdown.connect(_on_countdown)
    hud = _text("SCORE 000000     COMBO 0     BEAT 0.0", 21)
    status = _text("READY?", 17, RhythmTokens.LAVENDER)
    var frame := PanelContainer.new()
    frame.add_theme_stylebox_override("panel", RhythmTokens.panel(RhythmTokens.WHITE))
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(frame)
    var visual_scene := load(str(selected["scene"])) as PackedScene
    if visual_scene == null:
        _text("Scene unavailable", 18)
        return
    visual = visual_scene.instantiate() as RhythmVisual
    frame.add_child(visual)
    visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
    visual.configure(selected["_chart"], session, bool(profile["reduced_motion"]))
    countdown_text = _text("3", 27, RhythmTokens.CORAL)
    debug_label = _text("", 12, RhythmTokens.MUTED)
    debug_label.visible = debug_open
    if str(selected["id"]) == "rhythm_kitchen":
        var lane_row := HBoxContainer.new()
        lane_row.add_theme_constant_override("separation", 12)
        body.add_child(lane_row)
        for lane in ["left", "right"]:
            var key := Button.new()
            key.text = "◀ LEFT (A)" if lane == "left" else "RIGHT (L) ▶"
            RhythmTokens.style_button(key, RhythmTokens.CORAL if lane == "left" else RhythmTokens.AQUA)
            key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            key.pressed.connect(_submit_touch.bind(lane))
            lane_row.add_child(key)
    else:
        _button("●  TAP THE BEAT  (SPACE)", _submit_touch.bind("tap"), RhythmTokens.CORAL)
    _button("Ⅱ  PAUSE / RESUME", _toggle_pause, RhythmTokens.INK)
    _button("↻  RESTART TRACK", _play, RhythmTokens.MUTED)
    _button("×  EXIT TO GAMES", _exit_play, RhythmTokens.MUTED)

func _on_countdown(number: int) -> void:
    if is_instance_valid(countdown_text):
        countdown_text.text = "GO!" if number == 0 else str(number)

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
    if is_instance_valid(status) and is_instance_valid(session):
        status.text = "PAUSED — press resume" if session.paused else "FOLLOW THE SOUND"
    if is_instance_valid(countdown_text) and is_instance_valid(session):
        if session.paused:
            countdown_text.text = "PAUSED"
        elif session.active:
            countdown_text.text = "♪"

func _exit_play() -> void:
    _dispose_session()
    _select_games()

func _results(summary: Dictionary) -> void:
    latest_summary = summary
    _dispose_session()
    _reset_page("results")
    _spacer()
    _heading("TRACK COMPLETE!", str(selected["name"]))
    _spacer()
    _text("%06d" % int(summary["score"]), 52, RhythmTokens.LAVENDER)
    _text("BEST %06d    MAX COMBO %d" % [summary["best"], summary["max_combo"]], 20)
    var c: Dictionary = summary["counts"]
    _text("PERFECT %d  •  GOOD %d  •  MISS %d" % [c["Perfect"], c["Good"], c["Miss"]], 18)
    _spacer()
    _button("↻  RETRY", _play, RhythmTokens.AQUA)
    _button("ALL GAMES", _select_games, RhythmTokens.INK)

func _settings_page() -> void:
    _reset_page("settings")
    _heading("FIND YOUR GROOVE", "Offsets are stored only on this device")
    _spacer()
    _slider("Input offset (ms)  — later tap = positive", "input_ms", -250, 250, 5)
    _slider("Extra output offset (ms)", "output_ms", -250, 250, 5)
    _slider("Music & SFX volume", "volume", 0, 100, 5)
    var toggle := CheckButton.new()
    toggle.text = "Reduced motion"
    toggle.button_pressed = bool(profile["reduced_motion"])
    toggle.toggled.connect(func(checked: bool): profile["reduced_motion"] = checked)
    body.add_child(toggle)
    _spacer()
    _text("Hint: try a few taps, then adjust by 10–20 ms. Headphones may help.", 15, RhythmTokens.MUTED)
    _button("SAVE & RETURN", _save_settings, RhythmTokens.AQUA)

func _slider(label_text: String, key: String, lo: float, hi: float, step: float) -> void:
    var value := int(round(float(profile[key]) * (100.0 if key == "volume" else 1.0)))
    var label := _text(label_text + ": " + str(value), 17)
    var slider := HSlider.new()
    slider.min_value = lo
    slider.max_value = hi
    slider.step = step
    slider.value = value
    slider.custom_minimum_size.y = 44
    body.add_child(slider)
    slider.value_changed.connect(func(v: float):
        profile[key] = v / 100.0 if key == "volume" else int(v)
        label.text = label_text + ": " + str(int(v))
    )

func _save_settings() -> void:
    var err := RhythmSave.write_settings(profile)
    if err != OK:
        push_warning("Could not write user settings: " + str(err))
    _home()

func _offline_page() -> void:
    _reset_page("offline")
    _spacer()
    _heading("PLAY ANYWHERE", "No account. No external services.")
    _spacer()
    _text("WEB: Use your browser's Install App / Add to Home Screen command. Complete the first online load to cache the Godot game and audio assets. Then test airplane mode.", 19)
    _text("WINDOWS: Use the standalone exported EXE offline. Browser caches can be cleared or evicted by the OS.", 19)
    _text("If the web app fails offline, reconnect once to refresh its cache. Your local save may also be cleared when site data is removed.", 16, RhythmTokens.MUTED)
    _spacer()
    _button("← HOME", _home, RhythmTokens.INK)

func _dispose_session() -> void:
    if is_instance_valid(session):
        session.stop_session()
        session.queue_free()
    session = null
    visual = null
