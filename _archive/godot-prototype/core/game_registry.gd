extends RefCounted
class_name GameRegistry

# Read-only discovery: adding games/<id>/game.json automatically fills the menu.
static func discover() -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    var dir := DirAccess.open("res://games")
    if dir == null:
        push_error("Missing games directory")
        return found
    var dirs := dir.get_directories()
    dirs.sort()
    for id in dirs:
        var path := "res://games/%s/game.json" % id
        if not FileAccess.file_exists(path):
            continue
        var data := read_json(path)
        if data.is_empty() or str(data.get("id", "")) != id:
            push_warning("Invalid game manifest: " + path)
            continue
        if not ResourceLoader.exists(str(data.get("scene", ""))):
            push_warning("Missing game scene: " + path)
            continue
        var chart := read_json(str(data.get("chart", "")))
        if chart.is_empty():
            push_warning("Missing chart: " + path)
            continue
        data["_chart"] = chart
        found.append(data)
    return found

static func read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed
