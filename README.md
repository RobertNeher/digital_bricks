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

## 🛠️ Python Generators

We provide Python scripts to automate the creation of complex Integrated Circuits. These scripts are located in the `python_generators/` directory.

### 🏁 Intel 4004 Command Decoder
Generates an IC that decodes 8-bit Intel 4004 opcodes into individual control signals.
```bash
py python_generators/gen_i4004_decoder.py
```

### ✍️ Intel 4004 Assembler
Translates Intel 4004 mnemonics into a hex file.

#### Supported Instructions

| Group | Instructions |
| :--- | :--- |
| **Control** | `NOP`, `KBP` |
| **Data Transfer** | `FIM`, `SRC`, `LD`, `XCH`, `LDM` |
| **Memory** | `RDM`, `WRM`, `ADM`, `SBM`, `WMP`, `WRR`, `WPM`, `RDR` |
| **Status** | `RD0-RD3`, `WR0-WR3` |

- **External Resource**: [Intel 4004 Instruction Set (szyc.org)](http://e4004.szyc.org/iset.html)

```bash
py python_generators/asm_4004.py my_program.asm -o my_program.hex
```

### 💾 Generic ROM Generator
Generates a Read-Only Memory IC from either a list of values or an external hex file.

**Example: Generate from data list**
```bash
py python_generators/gen_rom.py --addr 4 --word 4 --data 0,1,2,4,8,7,15,0... --out assets/my_rom.json
```

**Example: Generate from hex file**
```bash
py python_generators/gen_rom.py --addr 4 --word 8 --file sample_program.hex --out assets/sample_program_rom.json
```

### 🧠 Generic RAM Generator (Random Access Memory)
Generates a RAM IC with configurable address and word sizes.
```bash
py python_generators/gen_ram.py --addr 5 --word 8 --out assets/my_ram.json
```

### ⏱️ Timing Generator (4-Phase)
Generates a timing IC that provides four sequential phases (T0, T1, T2, T3) for CPU coordination.
```bash
py python_generators/gen_timing_generator.py
```

---

## 🚀 Programming Your Memory (Workflow)

Follow these steps to create and run custom programs in your Intel 4004 circuit:

1.  **Write Assembly**: Create a `.asm` file using the supported mnemonics (e.g., `LDM`, `XCH`, `WRM`).
2.  **Compile to Hex**: Use the assembler to translate your mnemonics into raw hex values.
    ```bash
    py python_generators/asm_4004.py my_program.asm -o my_program.hex
    ```
3.  **Generate ROM IC**: Use the ROM generator to create a logic circuit asset from your hex file.
    ```bash
    py python_generators/gen_rom.py --addr 4 --word 8 --file my_program.hex --out assets/my_rom.json
    ```
4.  **Load into Simulator**:
    - Open the Digital Bricks simulator.
    - Load your `my_rom.json` as an **Integrated Circuit**.

---

*Built with ❤️ using Flutter for cross-platform precision.*
