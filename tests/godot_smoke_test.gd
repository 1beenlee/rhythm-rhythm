extends SceneTree

# CI smoke gate loads the real app and each game script; a pure judge test alone
# would not detect parse errors in the main scene or game-specific visuals.
func _initialize() -> void:
    var required_scripts := [
        "res://scenes/app.gd",
        "res://core/judge.gd",
        "res://core/session.gd",
        "res://core/synth.gd",
        "res://core/game_registry.gd",
        "res://core/game_visual.gd",
        "res://core/save_data.gd",
        "res://core/tokens.gd"
    ]
    for path in required_scripts:
        if ResourceLoader.load(path) == null:
            push_error("Cannot load script: " + path)
            quit(1)
            return
    var scene := ResourceLoader.load("res://scenes/main.tscn") as PackedScene
    if scene == null:
        push_error("Cannot load main scene")
        quit(1)
        return
    var app := scene.instantiate()
    if app == null or app.get_script() == null:
        push_error("Main scene script could not be instantiated")
        quit(1)
        return
    root.add_child(app)
    var packs := GameRegistry.discover()
    if packs.size() != 3:
        push_error("Expected 3 registered games, got " + str(packs.size()))
        quit(1)
        return
    for pack in packs:
        var game_scene := ResourceLoader.load(str(pack["scene"])) as PackedScene
        if game_scene == null:
            push_error("Game scene unavailable: " + str(pack["id"]))
            quit(1)
            return
        var visual := game_scene.instantiate()
        if visual == null or visual.get_script() == null:
            push_error("Missing game scene script: " + str(pack["id"]))
            quit(1)
            return
        visual.free()
    print("RhythmAppSmoke: PASS, 3 registered game scenes")
    quit(0)
