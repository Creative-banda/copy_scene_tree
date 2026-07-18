@tool
## CopySceneTreePlugin  v1.2.0
## An editor-only plugin that:
##   • Adds Tools → Copy Scene Tree (opens the export-options dialog).
##   • Registers a keyboard shortcut (default: Alt+Shift+C) that skips the
##     dialog and copies using the user's last-saved settings instantly.
##   • Shows a native editor toast notification on success.
##
## Architecture overview:
##   plugin.gd                – EditorPlugin entry point, menu wiring,
##                              shortcut handling, dialog lifecycle, toast.
##   export_options_dialog.gd – Dialog UI; emits copy_requested(options).
##   export_options.gd        – Plain data class carrying all options.
##   scene_tree_formatter.gd  – Pure formatter: format_tree(root, options).
##   settings_manager.gd      – Loads/saves options via EditorSettings.
##
## Shortcut design:
##   Godot 4's EditorSettings.get_shortcut() is not exposed to GDScript,
##   but a Shortcut resource stored via EditorSettings.set_setting() under
##   the "shortcuts" dictionary IS persisted and appears in
##   Editor → Editor Settings → Shortcuts, allowing the user to remap it.
##   On every key event we re-read the setting so user remaps are honoured
##   without restarting the plugin.

extends EditorPlugin

# ── Constants ──────────────────────────────────────────────────────────────

const MENU_ITEM_NAME  := "Copy Scene Tree"

## EditorSettings key used to store the remappable shortcut resource.
## Appears under Editor → Editor Settings → Shortcuts → copy_scene_tree.
const SHORTCUT_SETTING_KEY := "shortcuts/copy_scene_tree/copy_tree"

## Default shortcut: Alt + Shift + C.
## Chosen to avoid conflicts with built-in Godot editor bindings.
const DEFAULT_KEY      := KEY_C
const DEFAULT_MODIFIERS := KEY_MASK_ALT | KEY_MASK_SHIFT

const ExportOptionsDialog = preload("res://addons/copy_scene_tree/export_options_dialog.gd")
const SceneTreeFormatter  = preload("res://addons/copy_scene_tree/scene_tree_formatter.gd")
const SettingsManager     = preload("res://addons/copy_scene_tree/settings_manager.gd")

# ── State ──────────────────────────────────────────────────────────────────

## The dialog instance. Created once on first use and reused.
var _dialog: ConfirmationDialog = null


# ── Lifecycle ─────────────────────────────────────────────────────────────

func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _on_menu_item_pressed)
	_register_shortcut()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)
	_destroy_dialog()


# ── Shortcut registration ─────────────────────────────────────────────────

## Registers the default shortcut in EditorSettings if it has not been set
## yet. Once registered it appears in Editor → Editor Settings → Shortcuts
## and the user can remap it freely.
func _register_shortcut() -> void:
	var es := EditorInterface.get_editor_settings()
	if es.has_setting(SHORTCUT_SETTING_KEY):
		return  # User already has a (possibly customised) shortcut — leave it.

	var shortcut := _make_default_shortcut()
	es.set_setting(SHORTCUT_SETTING_KEY, shortcut)

	# Mark it as a "basic" shortcut so it shows up in the Shortcuts list.
	es.set_initial_value(SHORTCUT_SETTING_KEY, shortcut, false)


## Builds a Shortcut resource with the default Alt+Shift+C binding.
static func _make_default_shortcut() -> Shortcut:
	var ev := InputEventKey.new()
	ev.keycode    = DEFAULT_KEY
	ev.alt_pressed   = true
	ev.shift_pressed = true

	var sc := Shortcut.new()
	sc.events = [ev]
	return sc


## Returns the current shortcut, reading from EditorSettings so that any
## user remap is honoured immediately without restarting.
func _get_shortcut() -> Shortcut:
	var es := EditorInterface.get_editor_settings()
	if es.has_setting(SHORTCUT_SETTING_KEY):
		var value = es.get_setting(SHORTCUT_SETTING_KEY)
		if value is Shortcut:
			return value as Shortcut
	# Fallback: return the built-in default.
	return _make_default_shortcut()


# ── Input handling ────────────────────────────────────────────────────────

## _shortcut_input fires at shortcut priority, before GUI controls consume
## the event. This is the correct hook for editor plugin keyboard actions.
func _shortcut_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_echo():
		return

	var shortcut := _get_shortcut()
	if not shortcut.matches_event(event):
		return

	# Consume the event so nothing else reacts to it.
	get_viewport().set_input_as_handled()
	_copy_with_saved_settings()


# ── Menu callback ─────────────────────────────────────────────────────────

## Called when the user clicks Tools → Copy Scene Tree.
## Opens the export-options dialog so the user can adjust settings first.
func _on_menu_item_pressed() -> void:
	var selected := _get_selected_node()
	if selected == null:
		push_warning("[CopySceneTree] No node selected. Select a node in the Scene dock first.")
		return

	_ensure_dialog()
	_dialog.load_settings()
	_dialog.popup_centered()


# ── Shortcut copy (no dialog) ─────────────────────────────────────────────

## Copies immediately using the current saved settings — no dialog shown.
## This is what the keyboard shortcut triggers.
func _copy_with_saved_settings() -> void:
	var selected := _get_selected_node()
	if selected == null:
		push_warning("[CopySceneTree] No node selected. Select a node in the Scene dock first.")
		return

	var options = SettingsManager.load_options()
	_perform_copy(selected, options)


# ── Dialog lifecycle ──────────────────────────────────────────────────────

## Creates the dialog on first use and connects its signal.
func _ensure_dialog() -> void:
	if _dialog != null:
		return

	_dialog = ExportOptionsDialog.new()
	# Parent to the editor base control so the dialog inherits the editor theme.
	EditorInterface.get_base_control().add_child(_dialog)
	_dialog.copy_requested.connect(_on_copy_requested)


## Frees the dialog when the plugin is disabled or the editor exits.
func _destroy_dialog() -> void:
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null


# ── Copy handler (shared by dialog and shortcut) ──────────────────────────

## Called when the dialog emits copy_requested.
func _on_copy_requested(options) -> void:
	var selected := _get_selected_node()
	if selected == null:
		push_warning("[CopySceneTree] Selection lost before copy was performed.")
		return
	_perform_copy(selected, options)


## Core copy routine. Formats the tree, sets the clipboard, and shows a
## native editor toast notification. Called by both the dialog and the
## keyboard shortcut path so the behaviour is always identical.
func _perform_copy(root: Node, options) -> void:
	var text: String = SceneTreeFormatter.format_tree(root, options)
	DisplayServer.clipboard_set(text)

	# Native editor toast — disappears automatically, feels built-in.
	EditorInterface.get_editor_toaster().push_toast(
		"✓ Scene tree copied to clipboard.",
		EditorToaster.SEVERITY_INFO
	)

	# Keep the Output panel message as a secondary log.
	print("[CopySceneTree] ✓ Copied '%s' tree to clipboard." % root.name)


# ── Helpers ───────────────────────────────────────────────────────────────

## Returns the first currently selected node in the edited scene, or null.
func _get_selected_node() -> Node:
	var selection: EditorSelection = EditorInterface.get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	return nodes[0]
