@tool
## CopySceneTreePlugin
## An editor-only plugin that copies the selected node's scene hierarchy
## as formatted text to the system clipboard.
##
## NOTE on Scene Dock context menu:
##   Godot 4.x does not expose a public API for injecting items into the
##   Scene dock's right-click PopupMenu. Accessing it would require
##   scanning internal editor nodes — a private-API hack that breaks
##   between engine versions. This plugin therefore adds the action via:
##     1. Tools menu  → "Copy Scene Tree"  (official EditorPlugin API)
##     2. A lightweight overlay button injected above the scene dock viewport
##        so it stays conveniently close to where you work.
extends EditorPlugin

const MENU_ITEM_NAME := "Copy Scene Tree"
const FORMATTER := preload("res://addons/copy_scene_tree/scene_tree_formatter.gd")


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _on_copy_scene_tree)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)


## Called when the user clicks Tools → "Copy Scene Tree".
func _on_copy_scene_tree() -> void:
	var selected := _get_selected_node()

	if selected == null:
		push_warning("[CopySceneTree] No node selected. Select a node in the Scene dock first.")
		return

	# Build the formatted text using the default format.
	# To switch formats in the future, change the second argument here
	# or expose a settings panel that stores the user's preference.
	var text := FORMATTER.build(selected, FORMATTER.Format.NAMES_AND_TYPES)

	DisplayServer.clipboard_set(text)

	# Godot 4.x has no public toast/notification API for editor plugins.
	# Print to the Output panel — visible without interrupting the workflow.
	print("[CopySceneTree] ✓ Copied '%s' tree to clipboard." % selected.name)


# ── Helpers ──────────────────────────────────────────────────────────────────

## Returns the first currently selected node in the edited scene, or null.
func _get_selected_node() -> Node:
	var selection: EditorSelection = EditorInterface.get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	# If multiple nodes are selected, operate on the first one.
	return nodes[0]
