# 🧱 Digital Bricks

**Digital Bricks** is a powerful, high-performance digital circuit simulator built with Flutter. It provides an intuitive, high-precision environment for designing, testing, and modularizing complex logic systems.

---

## ⚡ Key Features

### 🔌 Logic Gates
* **Flexible Inputs**: Standard gates (AND, NAND, OR, NOR, XOR, NXOR) support 2, 3, 4, or 8 inputs, configurable via context menu.
* **Precision Inversion**: High-speed inverter (NOT) gate.

### ⏱️ Timing
* **Oscillator**: Configurable Oscillator for precise clock signal generation.

### 🖼️ Visualization & I/O
* **Interactive Indicators**: Customizable LEDs with labels and adjustable High/Low colors. Multi-segment displays (7 and 16 segments) with independent decimal point control.
* **User Input**: Interactive Buttons with labels and toggleable Constant Sources.
* **Markdown Support**: Embed documentation directly into your circuit using Markdown components.

### 🔌 Display Pin Layouts

#### 7-Segment Display (Raw Control)
The 7-segment display uses 8 input pins for direct segment control:

| Pin | Segment |
| :-- | :--- |
| `a`-`g` | Corresponding segments A-G |
| `dp` | Decimal Point |

```
       a
     f   b
       g
     e   c
       d   (dp)
```

#### 16-Segment Display (ASCII Decoder + DP)
The 16-segment display uses 8 input pins to decode ASCII characters and control the decimal point:

| Pin Index | Function |
| :--- | :--- |
| 1-7 (Top) | ASCII bits 6 down to 0 (Standard character set 0-127) |
| 8 (Bottom) | Decimal Point (`dp`) |

*   **Logic**: Bit 0 (LSB) of the ASCII value is pin 7, bit 1 is pin 6, etc. Pin 8 is an independent decimal point control.

---

## 🏗️ Integrated Circuits (Modular Design)

Modularize your designs by creating custom **Integrated Circuits (ICs)**.

### 🔓 Unpack & Repack
* **Live Inspection**: Right-click an IC and select **Unpack** to expand it into its constituent components on the main canvas.
* **Unpack Limit**: To maintain canvas performance and clarity, **only one circuit can be unpacked at a time**.
* **Smart Repack**: Quickly collapse an expanded circuit back into its IC form. You can trigger a **Repack Parent** action by right-clicking *any* child component of an unpacked circuit, or by using the selection toolbar.

---

## 🖱️ Interaction & Tools

* **Infinite Canvas**: A massive 10,000 x 10,000 area with a high-precision grid.
* **Smart Connections**: Bezier-curved wires with automatic pin-to-pin snapping.
* **Batch Actions**: Multi-select components to move, align, delete, or repack them as a group.
* **Contextual Control**: Right-click any component to access advanced parameters and settings.

---

## ⌨️ Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Ctrl + A` | Select All |
| `Ctrl + S` | Save Circuit |
| `Ctrl + O` | Open Circuit |
| `Esc` | Clear Selection |
| `Arrows` | Move Selected Items (20px steps) |
| `Del / Backspace` | Delete Selected Items |

---

## 📂 File Management

* **Save / Save As**: Store your designs as JSON files.
* **Open**: Load existing `.json` circuit files.
* **Clear**: Wipe the canvas for a fresh start.

---

*Built with ❤️ using Flutter for cross-platform precision.*
