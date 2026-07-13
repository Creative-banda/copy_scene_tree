@tool
## SceneTreeFormatter
## Responsible solely for converting a Node subtree into formatted text.
## Adding new output formats in the future only requires adding a new method here.
class_name SceneTreeFormatter


## Available copy formats. Add new entries here to support future formats.
enum Format {
	NAMES_AND_TYPES,  ## "NodeName (ClassName)"  — the default
	NAMES_ONLY,       ## "NodeName"
	# Future formats can be added here, e.g.:
	# AI_PROMPT,
	# MARKDOWN,
}


## Entry point. Returns the formatted string for [param root] using [param format].
static func build(root: Node, format: Format = Format.NAMES_AND_TYPES) -> String:
	if root == null:
		return ""
	var lines: PackedStringArray = []
	# Print the root node label with no branch prefix, then recurse into children.
	lines.append(_format_node(root, format))
	var children := root.get_children()
	for i in children.size():
		_collect_lines(children[i], "", i == children.size() - 1, lines, format)
	return "\n".join(lines)


## Recursively walks the tree and appends one line per node.
## [param prefix]      — the continuation-line indentation inherited from the parent
## [param is_last]     — whether this node is the last child of its parent
static func _collect_lines(
		node: Node,
		prefix: String,
		is_last: bool,
		lines: PackedStringArray,
		format: Format
) -> void:
	# Choose the branch glyph for this node and the prefix its children inherit.
	var branch: String
	var child_prefix: String

	if is_last:
		branch = prefix + "└── "
		child_prefix = prefix + "    "
	else:
		branch = prefix + "├── "
		child_prefix = prefix + "│   "

	lines.append(branch + _format_node(node, format))

	var children := node.get_children()
	for i in children.size():
		_collect_lines(
				children[i],
				child_prefix,
				i == children.size() - 1,
				lines,
				format
		)


## Returns the display label for a single node based on the chosen format.
static func _format_node(node: Node, format: Format) -> String:
	match format:
		Format.NAMES_ONLY:
			return node.name
		Format.NAMES_AND_TYPES, _:
			return "%s (%s)%s" % [node.name, node.get_class(), _script_suffix(node)]


## Returns a script suffix string like " [player.gd]", or "" if no script is attached.
## Shows "[Built-in Script]" when the script exists but has no file path.
static func _script_suffix(node: Node) -> String:
	var script := node.get_script()
	# get_script() returns null when no script is attached, or a Variant
	# that is not a Script when called on a node without one — guard both cases.
	if not script is Script:
		return ""

	var path: String = (script as Script).resource_path
	if path.is_empty():
		return " [Built-in Script]"

	# resource_path is a full res:// path — extract just the filename.
	return " [%s]" % path.get_file()
