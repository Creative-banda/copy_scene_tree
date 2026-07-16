@tool
## SettingsManager
## Loads and saves export options to Godot's EditorSettings so preferences
## persist across restarts, project switches, and plugin enable/disable cycles.
##
## All setting keys live under the "copy_scene_tree/" namespace to avoid
## collisions with other plugins or built-in editor settings.


const ExportOptions = preload("res://addons/copy_scene_tree/export_options.gd")

# ── Setting key constants ──────────────────────────────────────────────────

const KEY_INCLUDE_NAMES       := "copy_scene_tree/include_names"
const KEY_INCLUDE_TYPES       := "copy_scene_tree/include_types"
const KEY_INCLUDE_SCRIPTS     := "copy_scene_tree/include_scripts"
const KEY_INCLUDE_GROUPS      := "copy_scene_tree/include_groups"
const KEY_INCLUDE_NODE_PATHS  := "copy_scene_tree/include_node_paths"
const KEY_INCLUDE_OWNER       := "copy_scene_tree/include_owner"
const KEY_INCLUDE_SCENE_FILE  := "copy_scene_tree/include_scene_file"
const KEY_INCLUDE_UNIQUE_NAME := "copy_scene_tree/include_unique_name"
const KEY_FORMAT              := "copy_scene_tree/format"


# ── Public API ─────────────────────────────────────────────────────────────

## Loads previously saved settings from EditorSettings and returns a populated
## ExportOptions. Falls back to ExportOptions defaults if a key is missing.
static func load_options():
	var opts := ExportOptions.new()
	var es := EditorInterface.get_editor_settings()

	opts.include_names       = _get_bool(es, KEY_INCLUDE_NAMES,       opts.include_names)
	opts.include_types       = _get_bool(es, KEY_INCLUDE_TYPES,       opts.include_types)
	opts.include_scripts     = _get_bool(es, KEY_INCLUDE_SCRIPTS,     opts.include_scripts)
	opts.include_groups      = _get_bool(es, KEY_INCLUDE_GROUPS,      opts.include_groups)
	opts.include_node_paths  = _get_bool(es, KEY_INCLUDE_NODE_PATHS,  opts.include_node_paths)
	opts.include_owner       = _get_bool(es, KEY_INCLUDE_OWNER,       opts.include_owner)
	opts.include_scene_file  = _get_bool(es, KEY_INCLUDE_SCENE_FILE,  opts.include_scene_file)
	opts.include_unique_name = _get_bool(es, KEY_INCLUDE_UNIQUE_NAME, opts.include_unique_name)
	opts.format              = _get_int(es,  KEY_FORMAT,              opts.format) as ExportOptions.Format

	return opts


## Persists the current ExportOptions values into EditorSettings.
static func save_options(opts) -> void:
	var es := EditorInterface.get_editor_settings()

	es.set_setting(KEY_INCLUDE_NAMES,       opts.include_names)
	es.set_setting(KEY_INCLUDE_TYPES,       opts.include_types)
	es.set_setting(KEY_INCLUDE_SCRIPTS,     opts.include_scripts)
	es.set_setting(KEY_INCLUDE_GROUPS,      opts.include_groups)
	es.set_setting(KEY_INCLUDE_NODE_PATHS,  opts.include_node_paths)
	es.set_setting(KEY_INCLUDE_OWNER,       opts.include_owner)
	es.set_setting(KEY_INCLUDE_SCENE_FILE,  opts.include_scene_file)
	es.set_setting(KEY_INCLUDE_UNIQUE_NAME, opts.include_unique_name)
	es.set_setting(KEY_FORMAT,              opts.format)


# ── Private helpers ────────────────────────────────────────────────────────

## Returns the bool value for [param key] from EditorSettings,
## or [param default_val] when the key does not exist yet.
static func _get_bool(es: EditorSettings, key: String, default_val: bool) -> bool:
	if es.has_setting(key):
		return bool(es.get_setting(key))
	return default_val


## Returns the int value for [param key] from EditorSettings,
## or [param default_val] when the key does not exist yet.
static func _get_int(es: EditorSettings, key: String, default_val: int) -> int:
	if es.has_setting(key):
		return int(es.get_setting(key))
	return default_val
