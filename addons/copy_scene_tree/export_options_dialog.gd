@tool
## ExportOptionsDialog
## A compact, native-looking editor dialog that lets the user choose which
## information to include in the exported scene tree and in what format.
##
## Emits "copy_requested" with the assembled ExportOptions when the user
## clicks Copy. The plugin listens to this signal and handles clipboard logic.
##
## UI is built entirely in code so no .tscn file is required, keeping the
## addon self-contained.

extends ConfirmationDialog

## Emitted when the user confirms the dialog.
## [param options] is a fully populated ExportOptions ready for the formatter.
signal copy_requested(options)

const ExportOptions   = preload("res://addons/copy_scene_tree/export_options.gd")
const SettingsManager = preload("res://addons/copy_scene_tree/settings_manager.gd")

# ── Content checkboxes ─────────────────────────────────────────────────────
var _cb_names:       CheckBox
var _cb_types:       CheckBox
var _cb_scripts:     CheckBox
var _cb_groups:      CheckBox
var _cb_node_paths:  CheckBox
var _cb_owner:       CheckBox
var _cb_scene_file:  CheckBox
var _cb_unique_name: CheckBox

# ── Format radio buttons ───────────────────────────────────────────────────
var _rb_plain:    CheckBox
var _rb_ascii:    CheckBox
var _rb_markdown: CheckBox


func _init() -> void:
	title = "Copy Scene Tree"
	get_ok_button().text = "Copy"

	# ── Root layout ──────────────────────────────────────────────────────
	# Give the vbox a fixed minimum width. This is the reliable way to
	# control dialog width when building UI procedurally — the Window sizes
	# itself to fit its content, so forcing content width forces dialog width.
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# ── Include section ───────────────────────────────────────────────────
	vbox.add_child(_make_section_label("Include"))

	var content_grid := GridContainer.new()
	content_grid.columns = 2
	content_grid.add_theme_constant_override("h_separation", 16)
	content_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(content_grid)

	_cb_names       = _make_checkbox("Node Names",       true,  content_grid)
	_cb_types       = _make_checkbox("Node Types",       true,  content_grid)
	_cb_scripts     = _make_checkbox("Attached Scripts", true,  content_grid)
	_cb_groups      = _make_checkbox("Groups",           false, content_grid)
	_cb_node_paths  = _make_checkbox("Node Paths",       false, content_grid)
	_cb_owner       = _make_checkbox("Owner",            false, content_grid)
	_cb_scene_file  = _make_checkbox("Scene File",       false, content_grid)
	_cb_unique_name = _make_checkbox("Unique Name (%)",  false, content_grid)

	vbox.add_child(HSeparator.new())

	# ── Output Format section ─────────────────────────────────────────────
	vbox.add_child(_make_section_label("Output Format"))

	var format_vbox := VBoxContainer.new()
	format_vbox.add_theme_constant_override("separation", 2)
	vbox.add_child(format_vbox)

	var btn_group := ButtonGroup.new()
	_rb_plain    = _make_radio("Plain Text", btn_group, format_vbox)
	_rb_ascii    = _make_radio("ASCII Tree", btn_group, format_vbox)
	_rb_markdown = _make_radio("Markdown",   btn_group, format_vbox)
	_rb_ascii.button_pressed = true

	vbox.add_child(HSeparator.new())

	# ── Shortcut tip ──────────────────────────────────────────────────────
	# Kept intentionally short so it fits on one line at the dialog's natural
	# width — no wrapping, no size impact on the layout.
	var tip := Label.new()
	tip.text = "Tip: Use Alt+Shift+C to copy without opening this dialog."
	tip.add_theme_font_size_override("font_size", 10)
	vbox.add_child(tip)

	vbox.add_child(HSeparator.new())

	# ── Footer row ────────────────────────────────────────────────────────
	var footer := HBoxContainer.new()
	vbox.add_child(footer)

	var reset_btn := Button.new()
	reset_btn.text = "Reset Defaults"
	reset_btn.pressed.connect(_on_reset_defaults)
	footer.add_child(reset_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var info_lbl := Label.new()
	info_lbl.text = "Settings are automatically remembered."
	info_lbl.add_theme_font_size_override("font_size", 10)
	info_lbl.modulate = Color(1, 1, 1, 0.45)
	footer.add_child(info_lbl)

	confirmed.connect(_on_confirmed)


# ── Public API ────────────────────────────────────────────────────────────

## Called by the plugin right before popup_centered().
## Loads persisted settings and refreshes every control.
func load_settings() -> void:
	var opts = SettingsManager.load_options()
	_apply_options_to_ui(opts)


# ── Signal handlers ───────────────────────────────────────────────────────

func _on_confirmed() -> void:
	var opts = _read_options_from_ui()
	SettingsManager.save_options(opts)
	copy_requested.emit(opts)


func _on_reset_defaults() -> void:
	var defaults = ExportOptions.new()
	_apply_options_to_ui(defaults)
	SettingsManager.save_options(defaults)


# ── UI helpers ────────────────────────────────────────────────────────────

func _apply_options_to_ui(opts) -> void:
	_cb_names.button_pressed       = opts.include_names
	_cb_types.button_pressed       = opts.include_types
	_cb_scripts.button_pressed     = opts.include_scripts
	_cb_groups.button_pressed      = opts.include_groups
	_cb_node_paths.button_pressed  = opts.include_node_paths
	_cb_owner.button_pressed       = opts.include_owner
	_cb_scene_file.button_pressed  = opts.include_scene_file
	_cb_unique_name.button_pressed = opts.include_unique_name

	match opts.format:
		ExportOptions.Format.PLAIN_TEXT:
			_rb_plain.button_pressed = true
		ExportOptions.Format.MARKDOWN:
			_rb_markdown.button_pressed = true
		ExportOptions.Format.ASCII_TREE, _:
			_rb_ascii.button_pressed = true


func _read_options_from_ui():
	var opts := ExportOptions.new()

	opts.include_names       = _cb_names.button_pressed
	opts.include_types       = _cb_types.button_pressed
	opts.include_scripts     = _cb_scripts.button_pressed
	opts.include_groups      = _cb_groups.button_pressed
	opts.include_node_paths  = _cb_node_paths.button_pressed
	opts.include_owner       = _cb_owner.button_pressed
	opts.include_scene_file  = _cb_scene_file.button_pressed
	opts.include_unique_name = _cb_unique_name.button_pressed

	if _rb_plain.button_pressed:
		opts.format = ExportOptions.Format.PLAIN_TEXT
	elif _rb_markdown.button_pressed:
		opts.format = ExportOptions.Format.MARKDOWN
	else:
		opts.format = ExportOptions.Format.ASCII_TREE

	return opts


static func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.theme_type_variation = "HeaderSmall"
	return lbl


static func _make_checkbox(label: String, default_checked: bool, parent: Control) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label
	cb.button_pressed = default_checked
	parent.add_child(cb)
	return cb


static func _make_radio(label: String, group: ButtonGroup, parent: Control) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label
	cb.toggle_mode = true
	cb.button_group = group
	parent.add_child(cb)
	return cb
