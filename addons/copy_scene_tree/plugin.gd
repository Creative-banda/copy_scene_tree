@tool
## CopySceneTreePlugin
## An editor-only plugin that copies the selected node's scene hierarchy
## as formatted text to the system clipboard.
##
## NOTE on Scene Dock context menu:
##   Godot 4.x does not expose a public API for injecting items into the
##   Scene dock's right-click PopupMenu. Accessing it would require
##   scanning internal editor nodes — a private-API hack that breaks
##   between engine versions. This plugin therefore adds the action via
##   the stable Project > Tools menu.
extends EditorPlugin

const MENU_ITEM_NAME := "Copy Scene Tree"
const FORMATTER := preload("res://addons/copy_scene_tree/scene_tree_formatter.gd")


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _on_copy_scene_tree)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)


## Called when the user clicks Project > Tools > Copy Scene Tree.
func _on_copy_scene_tree() -> void:
	var selected := _get_selected_node()

	if selected == null:
		push_warning("[CopySceneTree] No node selected. Select a node in the Scene dock first.")
		return

	var text := FORMATTER.build(selected, FORMATTER.Format.NAMES_AND_TYPES)
	DisplayServer.clipboard_set(text)
	print("[CopySceneTree] ✓ Copied '%s' tree to clipboard." % selected.name)


# ── Helpers ──────────────────────────────────────────────────────────────────

## Returns the first currently selected node in the edited scene, or null.
func _get_selected_node() -> Node:
	var selection: EditorSelection = EditorInterface.get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	return nodes[0]
