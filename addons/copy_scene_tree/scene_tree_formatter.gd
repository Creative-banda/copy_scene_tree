@tool
## SceneTreeFormatter
## Responsible solely for converting a Node subtree into formatted text.
## Adding new output formats in the future only requires extending this script.


## Available copy formats. Add new entries here to support future formats.
enum Format {
	NAMES_AND_TYPES,  ## "NodeName (ClassName)" — the default
	NAMES_ONLY,       ## "NodeName"
}


## Entry point. Returns the formatted string for [param root] using [param format].
static func build(root: Node, format: Format = Format.NAMES_AND_TYPES) -> String:
	if root == null:
		return ""

	var lines: PackedStringArray = []
	lines.append(_format_node(root, format))

	var children := root.get_children()
	for i in children.size():
		_collect_lines(children[i], "", i == children.size() - 1, lines, format)

	return "\n".join(lines)


## Recursively walks the tree and appends one line per node.
static func _collect_lines(
		node: Node,
		prefix: String,
		is_last: bool,
		lines: PackedStringArray,
		format: Format
) -> void:
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
	if not script is Script:
		return ""

	var path: String = (script as Script).resource_path
	if path.is_empty():
		return " [Built-in Script]"

	return " [%s]" % path.get_file()
