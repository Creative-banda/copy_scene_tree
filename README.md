# Copy Scene Tree

Ever tried to describe your Godot scene structure in a GitHub issue, a bug report, or an AI chat — and ended up typing it out by hand? This plugin fixes that.

**Copy Scene Tree** is a Godot 4.x editor plugin that copies any selected node's full hierarchy as clean, readable text directly to your clipboard. One menu click, zero friction.

It's especially useful when asking AI assistants like **ChatGPT**, **Claude**, or **Gemini** for help with your Godot project. Instead of describing your scene in prose, you paste the exact structure and get answers grounded in your actual setup.

---

## Features

- One-click copy of any node and its entire subtree
- Clean tree-drawing characters (`├──`, `└──`, `│`) at any nesting depth
- Shows node name and class name by default
- Displays attached script filenames when present (e.g. `[player.gd]`)
- Shows `[Built-in Script]` for scripts embedded directly in the scene file
- Copies directly to the system clipboard — no intermediate steps
- Non-blocking feedback via the Output panel — no popup dialogs
- Editor-only — zero footprint in exported games
- Extensible format system, ready for new output styles

---

## Perfect For

- **AI assistants** — paste your scene into ChatGPT, Claude, or Gemini and get precise, context-aware answers
- **Bug reports** — show exactly what your scene looks like without screenshots
- **GitHub discussions** — share hierarchy in issues or pull request descriptions
- **Team collaboration** — communicate scene structure clearly across your team
- **Project documentation** — drop accurate scene snapshots into wikis or design docs

---

## Installation

### From the Godot Asset Library (recommended)
Search for **"Copy Scene Tree"** and click Install.

### Manual
1. Copy the `addons/copy_scene_tree/` folder into your project's `addons/` directory.
2. Open your project in Godot.
3. Go to **Project → Project Settings → Plugins**.
4. Find **Copy Scene Tree** and set its status to **Enabled**.

---

## Usage

1. Open a scene and click any node in the **Scene dock**.
2. Go to **Tools → Copy Scene Tree**.
3. The hierarchy rooted at the selected node is now on your clipboard.
4. Paste it anywhere — an AI chat, a GitHub issue, a doc, a message to a teammate.

A confirmation message appears in the **Output** panel so you know it worked.

> **Why not the right-click context menu?**
> Godot 4.x does not expose a public API for injecting items into the Scene dock's
> right-click `PopupMenu`. Doing so requires scanning internal editor nodes —
> a fragile approach that breaks between engine versions. The **Tools menu** is the
> stable, officially supported location for editor plugin actions.

---

## Output Format

Default: **Names + Types + Scripts**

```
Player (CharacterBody2D) [player.gd]
├── CollisionShape2D (CollisionShape2D)
├── AnimatedSprite2D (AnimatedSprite2D)
├── AnimationPlayer (AnimationPlayer)
└── Camera2D (Camera2D) [camera_controller.gd]
```

Deeper nesting is handled correctly at any level:

```
Root (Node2D) [main.gd]
├── HUD (CanvasLayer)
│   ├── HealthBar (ProgressBar)
│   └── ScoreLabel (Label)
└── World (Node2D)
    ├── Player (CharacterBody2D) [player.gd]
    └── Enemies (Node2D) [enemy_manager.gd]
```

Script filenames are shown only when a script is attached. Nodes without scripts are displayed as normal. Scripts embedded directly in the scene (not saved as `.gd` files) show `[Built-in Script]`.

The formatter lives in `scene_tree_formatter.gd`. The `Format` enum there is the single place to register new output styles.

---

## Adding New Formats

1. Add a new entry to `SceneTreeFormatter.Format`.
2. Add a `match` branch in `SceneTreeFormatter._format_node()`.
3. (Optional) Expose a settings UI in `plugin.gd` that persists the user's preference.

No other files need to change.

---

## Compatibility

| Godot version | Status |
|---------------|--------|
| 4.x (≥ 4.0)  | ✅ Supported |
| 3.x           | ❌ Not supported |

---

## License

MIT — see [LICENSE](LICENSE).
