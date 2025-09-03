# alexcad

**alexcad** is a small, cross-platform Flutter-based structural CAD / beam analysis prototype. It lets you create simple 2D node-and-beam models, apply point/line loads and supports, run a linear (1D) beam-chain analysis, visualize deflections and a simple heatmap, and import/export model data as JSON.

> The project codebase is implemented in Dart / Flutter and performs numerical linear analysis using `scidart` (numdart arrays).

---

## What this project does

* Provides an interactive canvas (desktop & mobile) to build simple structural models made of *nodes* and *beams*.
* Each **Node** has a 2D position, an optional point force (Fx, Fy) and a fixator (support) enum.
* Each **Beam** connects two nodes and stores mechanical properties: cross-sectional area, elasticity (E), axial tension and a concentrated/line load (force) value.
* The app assembles a small linear system for a chain of beams and solves for internal displacements/deltas using `scidart` matrix routines. It computes element internal forces from these deltas and can show a heatmap/visualization of results.
* Project supports saving/loading model JSON files and ships with several example JSON files under `example_data/`.

---

## Demo video

Watch a short demo on YouTube:

[![Watch the demo on YouTube](https://img.youtube.com/vi/-bKlsGRozbw/hqdefault.jpg)](https://www.youtube.com/watch?v=-bKlsGRozbw)

---

## Quick start (run locally)

> Requirements: Flutter SDK installed and configured for your target platforms (desktop/mobile). See [https://flutter.dev](https://flutter.dev) for setup.

1. Clone the repository (or use the provided project folder):

```bash
git clone https://github.com/nukeboy76/alexcad.git
cd alexcad
```

2. Get dependencies:

```bash
flutter pub get
```

3. Run in an available device (desktop is supported if you enabled desktop support):

```bash
# run on Windows, macOS or Linux desktop (if enabled)
flutter run -d windows
# or run on an attached Android device/emulator
flutter run -d android
```

4. Use the UI to create/load a model (see "Example usage" below).

---

## Features (observed in code)

* Interactive editor/painter with inspector sidebar.
* Create and edit Nodes and Beams; each element has an editor view (`lib/*_editor_view`).
* Apply point forces to nodes and distributed/axial forces on beams.
* Multiple built-in example models in `example_data/*.json`.
* Import/export model JSON via file picker (uses `file_picker` + `file_saver`).
* Numerical solver that builds matrices using `scidart` and solves for deltas (see `lib/editor.dart` functions like `_getMatrixA`, `_getMatrixB`, and `getDeltas`).
* Simple UI elements for toggles, heatmap visualization and calculations overlay.

---

## Project structure (high level)

```
alexcad/
├─ lib/
│  ├─ main.dart          # App bootstrap + app-level UI widgets (FileOperationsBar, EditorBar etc.)
│  ├─ editor.dart        # Core model classes (Node, Beam), editor state and analysis routines
│  ├─ painter.dart       # Canvas rendering and custom painters
│  ├─ input.dart         # Input/controller glue for pointer + keyboard
│  ├─ inspector.dart     # Property inspector UI for selected elements
│  ├─ window.dart        # Lightweight abstraction for viewport/world transforms
│  ├─ cad_colors.dart    # Color definitions used by UI
│  ├─ cad_icons.dart     # Custom icon set used in the UI
│  └─ utils/             # Small helpers (color utilities, math helpers)
├─ example_data/         # Example JSON models (open via File -> Open)
├─ pubspec.yaml          # Flutter package + dependency list
└─ (platform folders)
```

---

## Data / JSON file format

The project imports/exports a compact JSON object with two arrays: `nodes` and `beams`.

* **Node** JSON fields (as produced/consumed by the code):

  * `positionX` (double)
  * `positionY` (double)
  * `forceX` (double) — point load in X
  * `forceY` (double) — point load in Y
  * `fixator` (string) — one of the `NodeFixator` enum names (e.g. `disabled`, `vt`, `vh`, etc. — see `lib/editor.dart`)

* **Beam** JSON fields:

  * `startI` (int) — index of start node (node.index)
  * `endI` (int) — index of end node
  * `forceX` (double) — axial/distributed force component X
  * `forceY` (double) — axial/distributed force component Y
  * `sectionArea` (double)
  * `elasticity` (double)
  * `tension` (double)

**Example minimal JSON** (two nodes, one beam):

```json
{
  "nodes": [
    { "positionX": 0.0, "positionY": 0.0, "forceX": 0.0, "forceY": 0.0, "fixator": "disabled" },
    { "positionX": 100.0, "positionY": 0.0, "forceX": 0.0, "forceY": 0.0, "fixator": "vt" }
  ],
  "beams": [
    { "startI": 0, "endI": 1, "forceX": 0.0, "forceY": 0.0, "sectionArea": 1.0, "elasticity": 1.0, "tension": 1.0 }
  ]
}
```

You can open the provided `example_data/*.json` files from the app's File -> Open dialog to load prebuilt scenes.

---

## Important dependencies

(From `pubspec.yaml`)

* Flutter SDK
* `scidart` — used for array/matrix algebra and linear system solving
* `file_picker`, `file_saver`, `path_provider` — file I/O and save/open dialogs
* `provider`, `universal_html`, `window_manager` and a few UI helpers

---

## How to use (UI tips)

* Use the top/side bars (FileOperationsBar / EditorBar / Inspector) to open, save, and switch editing modes.
* Create nodes and beams with the editor tools (the inspector panel allows you to tweak properties of the selected node/beam).
* Use the calculation overlay / heatmap toggles to run the linear analysis and view element results.
* Save your model with the Save action; the app writes JSON in the same format described above.

> Note: exact input gestures (e.g., left-click vs drag for creating beams) are implemented in the UI code (`lib/input.dart`, `lib/editor.dart`). If you want the exact controls documented in-app, I can extract and add a short gesture reference table.

---

## Development notes & extension points

* The core numerical routines are in `lib/editor.dart`. If you want to extend the solver (e.g., add 2D frame elements, distributed loads, stiffness assembly for general topology), that file is the natural starting point.
* The code currently solves beam chains with a matrix built by `_getMatrixA` / `_getMatrixB` and calls `matrixSolve()` from `scidart`.
* Rendering and user interaction are separated (see `painter.dart` and `input.dart`), making it possible to swap the UI or reuse the solver logic headlessly.

---

## Known limitations

* The current solver is intended for simple beam chains and uses a 1D approach — it is not a full finite-element solver for arbitrary 2D/3D meshes.
* JSON example files in the repository are minimal; some example files in the shipped archive contain `...` placeholders and may need manual editing.
* Platform-specific save/load dialogs require appropriate permissions (desktop vs mobile) and the `file_picker` behavior differs by platform.

---

## Example: load an example model and run analysis

1. Run the app with `flutter run` for your platform.
2. From the app UI, choose **File → Open** and pick `example_data/1.json` (or another file in `example_data/`).
3. The model will load; use the **Calculate** / overlay or heatmap toggles to compute and visualize results.
4. Modify node/beam properties in the Inspector and re-run calculations.
5. Save your model back to disk with **File → Save**.

---
