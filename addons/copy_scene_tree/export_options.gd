@tool
## ExportOptions
## A plain data class that carries every user-configurable export option.
## The formatter reads from this object exclusively — no UI state leaks into
## formatting logic, making future additions straightforward.
##
## All other scripts reference this via preload(), so no class_name is needed.


# ── Content toggles ────────────────────────────────────────────────────────

## Include the node's name in the output (always enabled by default).
var include_names: bool = true

## Include the node's built-in class name, e.g. "Node2D".
var include_types: bool = true

## Include the filename of any attached GDScript / script resource.
var include_scripts: bool = true

## Include the list of groups the node belongs to.
var include_groups: bool = false

## Include the node's path relative to the exported root.
var include_node_paths: bool = false

## Include the node's owner name (useful for instanced sub-scenes).
var include_owner: bool = false

## Include the source .tscn path when the node is the root of an instanced scene.
var include_scene_file: bool = false

## Include the node's unique name (% prefix) when one is assigned.
var include_unique_name: bool = false


# ── Output format ──────────────────────────────────────────────────────────

## Available output formats. Extend this enum to add future formats.
enum Format {
	PLAIN_TEXT,  ## Simple indented text, no branch characters.
	ASCII_TREE,  ## Unicode box-drawing branch characters (default).
	MARKDOWN,    ## Markdown fenced block with indented list items.
}

## The output format to use when building the text.
var format: Format = Format.ASCII_TREE
