@tool
## SceneTreeFormatter
## Responsible solely for converting a Node subtree into formatted text.
## Receives an ExportOptions object — never reads UI state directly.
## Adding a new output format only requires:
##   1. Adding a value to ExportOptions.Format
##   2. Adding a branch in format_tree() and a new _build_* function.
##
## Note: ExportOptions is referenced via preload() so its members are accessible,
## but it cannot be used as a type annotation (no class_name). Parameters that
## carry an ExportOptions are therefore left untyped.


const ExportOptions = preload("res://addons/copy_scene_tree/export_options.gd")


# ── Public API ────────────────────────────────────────────────────────────

## Entry point. Returns the complete formatted string for [param root].
## [param options] is an ExportOptions instance that controls every aspect of
## the output. Passing a default ExportOptions produces identical output to v1.0.0.
static func format_tree(root: Node, options) -> String:
	if root == null:
		return ""

	match options.format:
		ExportOptions.Format.PLAIN_TEXT:
			return _build_plain(root, options)
		ExportOptions.Format.MARKDOWN:
			return _build_markdown(root, options)
		ExportOptions.Format.ASCII_TREE, _:
			return _build_ascii(root, options)


# ── ASCII tree (default — matches v1.0.0 output exactly with default options) ─

static func _build_ascii(root: Node, options) -> String:
	var lines: PackedStringArray = []
	lines.append(_format_node(root, options, root))

	var children := root.get_children()
	for i in children.size():
		_collect_ascii(children[i], "", i == children.size() - 1, lines, options, root)

	return "\n".join(lines)


static func _collect_ascii(
		node: Node,
		prefix: String,
		is_last: bool,
		lines: PackedStringArray,
		options,
		export_root: Node
) -> void:
	var branch: String = prefix + ("└── " if is_last else "├── ")
	var child_prefix: String = prefix + ("    " if is_last else "│   ")

	lines.append(branch + _format_node(node, options, export_root))

	var children := node.get_children()
	for i in children.size():
		_collect_ascii(
				children[i],
				child_prefix,
				i == children.size() - 1,
				lines,
				options,
				export_root
		)


# ── Plain text (indented, no branch characters) ───────────────────────────

static func _build_plain(root: Node, options) -> String:
	var lines: PackedStringArray = []
	lines.append(_format_node(root, options, root))
	_collect_plain(root, root, 0, lines, options)
	return "\n".join(lines)


static func _collect_plain(
		node: Node,
		export_root: Node,
		depth: int,
		lines: PackedStringArray,
		options
) -> void:
	var indent := "  ".repeat(depth + 1)
	for child in node.get_children():
		lines.append(indent + _format_node(child, options, export_root))
		_collect_plain(child, export_root, depth + 1, lines, options)


# ── Markdown ──────────────────────────────────────────────────────────────

static func _build_markdown(root: Node, options) -> String:
	var lines: PackedStringArray = []
	lines.append("```")
	lines.append(_format_node(root, options, root))
	_collect_markdown(root, root, 0, lines, options)
	lines.append("```")
	return "\n".join(lines)


static func _collect_markdown(
		node: Node,
		export_root: Node,
		depth: int,
		lines: PackedStringArray,
		options
) -> void:
	var indent := "  ".repeat(depth + 1)
	for child in node.get_children():
		lines.append(indent + "- " + _format_node(child, options, export_root))
		_collect_markdown(child, export_root, depth + 1, lines, options)


# ── Per-node label builder ────────────────────────────────────────────────

## Assembles the display label for a single node.
## All content options are evaluated here; the format-specific collectors only
## deal with tree structure (indentation, branch characters).
static func _format_node(node: Node, options, export_root: Node) -> String:
	# ── Base name / unique-name prefix ───────────────────────────────────
	var display_name: String
	if options.include_unique_name and node.unique_name_in_owner:
		display_name = "%" + node.name
	else:
		display_name = node.name if options.include_names else ""

	# ── Assemble base label ───────────────────────────────────────────────
	# When both names and types are on, produce "Name (Type)" — identical to v1.0.0.
	var label: String
	if options.include_names and options.include_types:
		label = "%s (%s)" % [display_name, node.get_class()]
	elif options.include_names or options.include_unique_name:
		label = display_name
	elif options.include_types:
		label = "(%s)" % node.get_class()
	else:
		label = node.name  # Safety fallback: always show something.

	# ── Attached script ──────────────────────────────────────────────────
	if options.include_scripts:
		label += _script_suffix(node)

	# ── Instanced scene file ─────────────────────────────────────────────
	if options.include_scene_file:
		var scene_path := _scene_file_path(node)
		if not scene_path.is_empty():
			label += " {scene:%s}" % scene_path

	# ── Groups ───────────────────────────────────────────────────────────
	if options.include_groups:
		var groups := node.get_groups()
		if not groups.is_empty():
			label += " [groups:%s]" % ", ".join(groups)

	# ── Node path relative to the export root ────────────────────────────
	if options.include_node_paths and node != export_root:
		var rel_path: String = str(export_root.get_path_to(node))
		label += " [path:%s]" % rel_path

	# ── Owner ────────────────────────────────────────────────────────────
	if options.include_owner:
		var owner := node.owner
		if owner != null:
			label += " [owner:%s]" % owner.name

	return label


# ── Helpers ───────────────────────────────────────────────────────────────

## Returns a script suffix like " [player.gd]", or "" if none is attached.
## Output is identical to v1.0.0.
static func _script_suffix(node: Node) -> String:
	var script := node.get_script()
	if not script is Script:
		return ""
	var path: String = (script as Script).resource_path
	if path.is_empty():
		return " [Built-in Script]"
	return " [%s]" % path.get_file()


## Returns the filename of the instanced .tscn if [param node] is an instanced
## scene root, otherwise returns an empty string.
static func _scene_file_path(node: Node) -> String:
	var scene_file: String = node.scene_file_path
	if scene_file.is_empty():
		return ""
	return scene_file.get_file()
