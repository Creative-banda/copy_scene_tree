@tool
## CopySceneTreePlugin  v1.1.0
## An editor-only plugin that opens an export-options dialog and then copies
## the selected node's scene hierarchy as formatted text to the system clipboard.
##
## Architecture overview:
##   plugin.gd                – EditorPlugin entry point, menu wiring, dialog lifecycle.
##   export_options_dialog.gd – Dialog UI; emits copy_requested(ExportOptions).
##   export_options.gd        – Plain data class carrying all configurable options.
##   scene_tree_formatter.gd  – Pure formatter; format_tree(root, options) -> String.
##   settings_manager.gd      – Loads/saves options via EditorSettings.
##
## NOTE on Scene Dock context menu:
##   Godot 4.x does not expose a public API for injecting items into the
##   Scene dock's right-click PopupMenu. Accessing it would require scanning
##   internal editor nodes — a private-API hack that breaks between engine
##   versions. This plugin therefore adds the action via the stable Tools menu.

extends EditorPlugin

const MENU_ITEM_NAME := "Copy Scene Tree"

const ExportOptionsDialog = preload("res://addons/copy_scene_tree/export_options_dialog.gd")
const SceneTreeFormatter  = preload("res://addons/copy_scene_tree/scene_tree_formatter.gd")

## The dialog instance. Created once and reused.
var _dialog: ConfirmationDialog = null


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _on_menu_item_pressed)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)
	_destroy_dialog()


# ── Menu callback ─────────────────────────────────────────────────────────

## Called when the user clicks Tools → Copy Scene Tree.
func _on_menu_item_pressed() -> void:
	var selected := _get_selected_node()

	if selected == null:
		push_warning("[CopySceneTree] No node selected. Select a node in the Scene dock first.")
		return

	_ensure_dialog()
	_dialog.load_settings()
	_dialog.popup_centered()


# ── Dialog lifecycle ──────────────────────────────────────────────────────

## Creates the dialog on first use and connects its signal.
func _ensure_dialog() -> void:
	if _dialog != null:
		return

	_dialog = ExportOptionsDialog.new()
	# Add as child of the editor base control so it inherits the editor theme.
	EditorInterface.get_base_control().add_child(_dialog)
	_dialog.copy_requested.connect(_on_copy_requested)


## Frees the dialog when the plugin is disabled / editor exits.
func _destroy_dialog() -> void:
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null


# ── Copy handler ──────────────────────────────────────────────────────────

## Receives the confirmed ExportOptions from the dialog, formats the tree,
## and writes the result to the system clipboard.
func _on_copy_requested(options) -> void:
	var selected := _get_selected_node()

	if selected == null:
		push_warning("[CopySceneTree] Selection lost before copy was performed.")
		return

	var text: String = SceneTreeFormatter.format_tree(selected, options)
	DisplayServer.clipboard_set(text)
	print("[CopySceneTree] ✓ Copied '%s' tree to clipboard." % selected.name)


# ── Helpers ───────────────────────────────────────────────────────────────

## Returns the first currently selected node in the edited scene, or null.
func _get_selected_node() -> Node:
	var selection: EditorSelection = EditorInterface.get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	return nodes[0]
