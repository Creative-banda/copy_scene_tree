# Copy Scene Tree

Ever tried to describe your Godot scene structure in a GitHub issue, a bug report, or an AI chat — and ended up typing it out by hand? This plugin fixes that.

**Copy Scene Tree** is a Godot 4.x editor plugin that lets you export any selected node's hierarchy as clean, readable text directly to your clipboard. Use the keyboard shortcut for instant copying, or open the export dialog to fine-tune exactly what gets included.

It is especially useful when asking AI assistants like **ChatGPT**, **Claude**, or **Gemini** for help with your Godot project. Instead of describing your scene in prose, you can paste the exact structure and get answers grounded in your actual setup.

---

## Features

- **Keyboard shortcut** — copy instantly with `Alt+Shift+C`, no dialog needed
- **Configurable export dialog** — choose exactly what gets included before copying
- **Export options:** Node Names, Node Types, Attached Scripts, Groups, Node Paths, Owner, Scene File, Unique Name
- **Output formats:** ASCII Tree (default), Plain Text, Markdown
- **Native toast notification** — a built-in editor notification confirms every successful copy
- Settings are automatically remembered across restarts and project switches
- Reset Defaults button to restore the original configuration in one click
- Copies directly to the system clipboard
- Editor-only addon with no runtime footprint in exported games

---

## Perfect For

- **AI assistants** — paste your scene into ChatGPT, Claude, or Gemini and get precise, context-aware answers
- **Bug reports** — show exactly what your scene looks like without screenshots
- **GitHub discussions** — share hierarchy in issues or pull request descriptions
- **Team collaboration** — communicate scene structure clearly across your team
- **Project documentation** — drop accurate scene snapshots into wikis or design docs

---

## Demo

See the demo GIF in the repository root on GitHub. Asset Library downloads include only the addon folder.

---

## Repository Layout

```text
addons/
└── copy_scene_tree/
    ├── plugin.cfg
    ├── plugin.gd
    ├── export_options.gd
    ├── export_options_dialog.gd
    ├── scene_tree_formatter.gd
    ├── settings_manager.gd
    ├── icon.svg
    ├── icon.png
    ├── README.md
    └── LICENSE
```

Only the `addons/` folder is included in Asset Library downloads. The repository root contains project metadata, documentation, and the demo GIF.

---

## Installation

### From the Godot Asset Library

Search for **Copy Scene Tree** in the Godot Asset Library and click **Install**.

### Manual Installation

1. Copy the `addons/copy_scene_tree/` folder into your project's `addons/` directory.
2. Open your project in Godot 4.x.
3. Go to **Project → Project Settings → Plugins**.
4. Find **Copy Scene Tree** and set its status to **Enabled**.

---

## Usage

There are two ways to copy your scene tree:

### Quick copy (keyboard shortcut)

1. Select any node in the **Scene** dock.
2. Press **Alt+Shift+C**.
3. The hierarchy is copied to your clipboard using your last saved settings.
4. A native editor notification confirms the copy.

### With export options (menu)

1. Select any node in the **Scene** dock.
2. Go to **Project → Tools → Copy Scene Tree**.
3. The export dialog opens. Choose which information to include and the output format.
4. Click **Copy**.

Your selections are saved automatically. Use **Reset Defaults** to restore the original configuration at any time.

### Changing the shortcut

Go to **Editor → Editor Settings → Shortcuts** and search for **copy_scene_tree**. Double-click the entry to assign a different key combination.

> **Why not the right-click context menu?**
> Godot 4.x does not expose a public API for injecting items into the Scene dock's
> right-click `PopupMenu`. Doing so requires scanning internal editor nodes,
> which is fragile across engine versions. The **Project → Tools** menu is the
> stable, officially supported location for editor plugin actions.

---

## Output Examples

### ASCII Tree (default)

```text
Player (CharacterBody2D) [player.gd]
├── CollisionShape2D (CollisionShape2D)
├── AnimatedSprite2D (AnimatedSprite2D)
├── AnimationPlayer (AnimationPlayer)
└── Camera2D (Camera2D) [camera_controller.gd]
```

Deeper nesting is handled correctly at any level:

```text
Root (Node2D) [main.gd]
├── HUD (CanvasLayer)
│   ├── HealthBar (ProgressBar)
│   └── ScoreLabel (Label)
└── World (Node2D)
    ├── Player (CharacterBody2D) [player.gd]
    └── Enemies (Node2D) [enemy_manager.gd]
```

### Plain Text

```text
Root (Node2D) [main.gd]
  HUD (CanvasLayer)
    HealthBar (ProgressBar)
    ScoreLabel (Label)
  World (Node2D)
    Player (CharacterBody2D) [player.gd]
    Enemies (Node2D) [enemy_manager.gd]
```

### Markdown

````text
```
Root (Node2D) [main.gd]
  - HUD (CanvasLayer)
    - HealthBar (ProgressBar)
    - ScoreLabel (Label)
  - World (Node2D)
    - Player (CharacterBody2D) [player.gd]
    - Enemies (Node2D) [enemy_manager.gd]
```
````

Script filenames are shown only when a script is attached. Scripts embedded directly in the scene rather than saved as `.gd` files show `[Built-in Script]`.

---

## Export Options Reference

| Option | Default | Description |
|---|---|---|
| Node Names | ✓ | The name of each node as shown in the Scene dock |
| Node Types | ✓ | The built-in Godot class name, e.g. `CharacterBody2D` |
| Attached Scripts | ✓ | Filename of any attached script, e.g. `[player.gd]` |
| Groups | ✗ | All groups the node belongs to |
| Node Paths | ✗ | Path relative to the exported root |
| Owner | ✗ | The node's owner name |
| Scene File | ✗ | Source `.tscn` filename for instanced scene roots |
| Unique Name | ✗ | Prefixes the name with `%` when a unique name is assigned |

---

## Architecture

The addon is split into focused, single-responsibility scripts:

| File | Responsibility |
|---|---|
| `plugin.gd` | EditorPlugin entry point, menu registration, shortcut handling, dialog lifecycle |
| `export_options_dialog.gd` | Dialog UI, reads/writes controls, emits `copy_requested` |
| `export_options.gd` | Plain data class carrying all selected options |
| `scene_tree_formatter.gd` | Pure formatter — `format_tree(root, options) → String` |
| `settings_manager.gd` | Loads and saves options via `EditorSettings` |

### Adding a New Output Format

1. Add an entry to the `Format` enum in `export_options.gd`.
2. Add a radio button for it in `export_options_dialog.gd` (`_init`).
3. Add a `_build_*` function and a `match` branch in `scene_tree_formatter.gd`.

### Adding a New Export Option

1. Add a `bool` property to `export_options.gd`.
2. Add a checkbox in `export_options_dialog.gd` (`_init`, `_apply_options_to_ui`, `_read_options_from_ui`).
3. Add a setting key and load/save lines in `settings_manager.gd`.
4. Handle the option in `_format_node()` in `scene_tree_formatter.gd`.

---

## Compatibility

| Godot version | Status |
|---|---|
| 4.x (4.0 and newer) | Supported |
| 3.x | Not supported |

---

## Author

Created by [Creative-banda](https://github.com/Creative-banda).

---

## License

MIT — see [LICENSE](LICENSE).
