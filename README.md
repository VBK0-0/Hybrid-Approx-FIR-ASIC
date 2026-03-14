<div align="center">

# Hybrid-Approx-FIR-ASIC: RTL to GDSII

</div>

<div align="center">

![OpenLane](https://img.shields.io/badge/OpenLane%20-v1.0.0-blue?style=for-the-badge)
![VLSI](https://img.shields.io/badge/VLSI-System%20Design-blue?style=for-the-badge)
![Technology](https://img.shields.io/badge/Tech-SkyWater%20130nm-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-ASIC%20%26%20FPGA-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

*Hardware Implementation and VLSI Analysis of Approximate Compressors for FIR Filters*

[Overview](#-overview) • [Architecture](#-architecture) • [Results](#-results) • [Getting Started](#-getting-started) • [Documentation](#-documentation)

---

</div>

## 🎯 Overview

This project presents a **complete hardware implementation** of Approximate 4:2 Compressors based on sorting networks. Designed for Finite Impulse Response (FIR) filters and Multiplier-Accumulator (MAC) units, this repository explores the critical intersection between **architectural theory and physical silicon reality**. 

While approximate computing theoretically reduces area and power by minimizing logic gates, this project proves that physical hardware constraints—specifically CMOS routing overhead and complex gate penalties—can completely upend those theoretical models.

### ✨ Key Highlights

- 🚀 **Dual-Domain Validation**: Proven on both FPGA (Utilization/Power) and ASIC architectures.
- 🎨 **Open-Source Flow**: Complete RTL-to-GDSII implementation using SkyWater 130nm PDK and OpenLane.
- 🔬 **The "XOR Trap" Discovery**: Identified and resolved a critical CMOS standard-cell bottleneck.
- 📊 **Pareto Optimization**: Established a definitive trade-off frontier between Area, Speed, and Power.
- ⚙️ **High-Speed Logic**: Utilized AOI (AND-OR-Invert) standard cell mapping to achieve a 5.54 ns critical path.

---

## 🏗 Architecture

### Design Hierarchy 

## 🎛️ Top-Level Architecture: 4-Tap FIR Filter

While the core focus of this project is the approximate 4:2 compressors, they are practically implemented and evaluated within the context of a **4-Tap Direct-Form Finite Impulse Response (FIR) Filter**. 

The FIR filter acts as the top-level testing ground for the approximate multipliers. It consists of three main stages:

1. **Delay Line (Shift Registers):** The 8-bit input signal (`x_in`) is passed through a chain of three D-flip-flop delay registers (`x1`, `x2`, `x3`) on each positive clock edge.
2. **Approximate Multiplier Array:** Four 8x8 multipliers operate in parallel. Each multiplier takes one delayed input signal and multiplies it by a fixed, positive stress-test coefficient (`h0`, `h1`, `h2`, `h3`). **This is where the Exact, 1-Error, or 2-Error compressor logic is instantiated.**
3. **Accumulation (Adder Tree):** The 16-bit outputs from the four multipliers (`m0`, `m1`, `m2`, `m3`) are summed together to produce the final filtered output (`y_out`).

```text
       x_in ──┬────────►[ Z⁻¹ ]──┬────────►[ Z⁻¹ ]──┬────────►[ Z⁻¹ ]──┐
              │                  │                  │                  │
              ▼                  ▼                  ▼                  ▼
            ( M0 )             ( M1 )             ( M2 )             ( M3 )  ◄── Approximate Multipliers
              ▲                  ▲                  ▲                  ▲
              │                  │                  │                  │
              h0                 h1                 h2                 h3
              │                  │                  │                  │
              └────────┬─────────┴────────┬─────────┴────────┬─────────┘
                       │                  │                  │
                       ▼                  ▼                  ▼
                     [ + ] ◄────────────[ + ] ◄────────────[ + ]  ◄── Adder Tree
                       │
                     y_out
```
The approximate compressors are built upon 4-way sorting networks. By selectively removing sorting elements, 
we trade mathematical precision for physical hardware efficiency.
```text
┌─────────────────────────────────────────────────────────┐
│                    INPUT SIGNALS                        │
│                 x1, x2, x3, x4, Cin                     │
└─────────────────┬───────────────────────────────────────┘
                  │
         ┌────────▼────────┐
         │ 4-WAY SORTING   │ ◄── Exact: Full sorting
         │    NETWORK      │ ◄── 1-Error: 5 Sorters
         │                 │ ◄── 2-Error: 4 Sorters
         └────────┬────────┘
                  │
         ┌────────▼────────┐
         │  OUTPUT LOGIC   │ ◄── Reconstructs Sum & Carry
         │ (AND / OR / XOR)│     The "XOR Trap" occurs here
         └─────────────────┘
                  │
           Sum ◄──┴──► Carry
```

### ⚙️ Compressor Variants

1. **Exact 4:2 Compressor:** Fully accurate mathematical compression using standard sorting structures.
2. **1-Error Compressor:** Utilizes 5 sorters. The `Sum` and `Carry` are calculated using highly efficient `AND`/`OR` logic.
3. **2-Error Compressor:** Utilizes 4 sorters (achieving a theoretical reduction of 1 `AND` and 1 `OR` gate). However, to maintain the correct logic truth table, the output `Sum` relies on an `XOR` operation, and the `Carry` requires an additional `AND` gate. 

---

## 🔄 Complete ASIC Design Flow (OpenROAD

<div align="center">

<img src="./images/Openlane_flow.webp" width="400">

</div>

## ⚠️ The "XOR Trap" and CMOS Standard Cells

During initial ASIC synthesis, the 2-error design yielded a counter-intuitive result: despite having *fewer* structural sorters than the 1-error design, it consumed **more silicon area** and exhibited a **longer critical path**. 

**The Root Cause:** In physical CMOS layouts, primitive `AND`/`OR` gates require ~4–6 transistors. `XOR` gates, however, require 10–12 transistors and complex internal wiring. 

### 🔧 The AOI Optimization Fix
To overcome this, the 2-error Boolean equation was manually expanded at the RTL level. This forced the synthesis tool to abandon discrete, bulky `XOR` cells and map the logic into ultra-fast **AOI (AND-OR-Invert)** compound standard cells:

```verilog
// Unoptimized (Forces bulky XOR standard cells)
assign Sum = (A ^ h1) | h2; 

// Optimized (Maps to high-speed, low-power AOI compound cells)
assign Sum = (A & ~h1) | (~A & h1) | h2; 
```

---

## 📊 6. Final ASIC Physical Synthesis Results (SkyWater 130nm)

Following the AOI standard-cell optimization, the physical data established a distinct **Pareto optimization frontier**. To accurately measure the efficiency trade-offs, the **Area-Delay Product (ADP)** and **Power-Delay Product (PDP)** were calculated.

<div align="center">

| Metric | Exact Filter | 1-Error Filter | 2-Error Filter (Optimized) | 🏆 Optimal Arch |
|:---|:---:|:---:|:---:|:---:|
| **Logic Gates** | 814 | 773 | **771** | **2-Error** |
| **Silicon Area (μm²)** | 18,086 | **16,583** | 17,116 | **1-Error** |
| **Critical Path (ns)** | 6.03 | 5.83 | **5.54** | **2-Error** |
| **Dynamic Power (μW)**| 0.001573 | 0.001412 | **0.001286** | **2-Error** |
| **ADP (μm²·ns)** | 109,058 | 96,678 | **94,822** | **2-Error** |
| **PDP / Energy (fJ)** | 0.00948 | 0.00823 | **0.00712** | **2-Error** |

*(Note: Dynamic power is calculated as `internal_power` + `switching_power`. PDP yields femtoJoules ($fJ$))*
</div>

### 🔑 Key Engineering Conclusions

1. **Absolute Area vs. Architecture:** The **1-error architecture** is the undisputed champion for strict area reduction. The physical footprint of its one extra sorting element is actually smaller than the complex XOR output routing penalty of the 2-error design. 
2. **Speed & Absolute Power:** The **2-error architecture**, when mapped to AOI cells, provides the ultimate optimization for execution speed (5.54 ns) and dynamic power (0.001286 μW).
3. **Overall Efficiency (Figures of Merit):** While the 1-error design is physically smaller, the **2-error design wins both the ADP and PDP metrics**. This proves that the speed and power benefits of the 2-error architecture vastly outweigh its slight area penalty, making it the most energy-efficient and well-rounded hardware accelerator of the three.

`![ASIC Layout](docs/asic_layout.png)`
### 🔋 FPGA Implementation Results

Prior to ASIC synthesis, the multipliers were validated on an FPGA platform. Integrating the compressors into an 8x8 MAC unit demonstrated that for high-value computations, the controlled deviation of the approximate designs significantly reduces overall power consumption and LUT utilization compared to exact multiplication.

---

## 🖼 Visual Gallery

#### 🗺️ 1-Error & 2-Error Schematics
<div align="center">

<img src="./images/Compressor_1error.png" width="400">
<img src="./images/Compressor_2error.png" width="400">

</div>

<p><i>Comparison between 1-Error and 2-Error approximate compressor architectures*</i></p>
---

<div align="center">

<img src="./images/Approx_multiplier_dot_diagram.png" width="400">

</div>

<div align="center">

<img src="./images/Approx_multiplier_decoded_dot_diagram.png" width="400">

</div>

<p><i>Dot diagram and decoded dot diagrams for the approximate multipliers used in FIR Filter</i></p>
---

#### 🧱 ASIC Physical Layout (GDSII)
<div align="center">

<img src="./images/fir_exact_gds.png" width="400">
<img src="./images/fir_1error_gds.png" width="400">
<img src="./images/fir_2error_gds.png" width="400">

</div>

<p><i>SkyWater 130nm — 2D layout view showing complete routed standard cells and power delivery network.</i></p>
---
#### 🔋 FPGA Implementation
<div align="center">

<img src="./images/Approx_mult_impl_using_compressor_1error.png" width="400">
<img src="./images/Approx_mult_impl_using_compressor_2error.png" width="400">

</div>
---
## ⚙️ Compressor Architecture & Variants

The core of this FIR filter design relies on **4:2 Compressors** generated via **Sorting Networks**. Unlike traditional compressors that use a carry-propagation or XOR-sum tree, these designs first reorder the input bits. By strategically "pruning" (removing) sorting elements from the network, we trade mathematical precision for significant gains in silicon area and power efficiency.

### 1. Exact 4:2 Compressor (The Baseline)
* **Architecture:** Implements a full 4-way sorting network utilizing **6 sorting elements**.
* **Precision:** Guaranteed **zero mathematical error** across all $2^5$ input combinations.
* **Role:** Acts as the "Gold Standard" baseline to measure the area-savings and power-reduction of the approximate variants. It utilizes standard `XOR`/`MUX` logic to reconstruct the Sum and Carry from a fully sorted input sequence.

### 2. 1-Error Approximate Compressor
* **Architecture:** Pruned to **5 sorting elements** (1 node removed).
* **Accuracy:** Introduces a maximum error magnitude of 1 in specific, rare input combinations.
* **Efficiency:** By removing one sorter, it significantly reduces the combinatorial depth. The output logic is simplified to use high-efficiency `AND`/`OR` gates, making it the **most area-efficient variant** in the Sky130 PDK.

### 3. 2-Error Approximate Compressor
* **Architecture:** Aggressively pruned to **4 sorting elements** (2 nodes removed).
* **Accuracy:** Introduces a higher error rate but achieves the lowest transistor count within the sorting core.
* **Optimization:** Utilizes **AOI (AND-OR-Invert) optimization** to bypass physical CMOS routing penalties. It achieves the **lowest Power-Delay Product (PDP)** and the fastest timing (5.54 ns).

---

## 🔍 Error Characterization & Corner Cases

<div align="center">

<img src="./images/fir_error_comparision_plot.png" width="600">

</div>

<p><i>FIR Error Comparision Plot</i></p>

In approximate computing, understanding the worst-case scenarios is just as important as the average error. The "pruning" of sorting elements causes the network to fail under specific high-density input patterns. 

### 🟢 The "Zero-Error" Zone (Low Density)
Both the 1-Error and 2-Error compressors maintain **100% exact precision** when the number of active input bits is low (0 or 1).
* **Why it happens:** The remaining sorters are sufficient to correctly identify and route a single `1` to the LSB (Sum) without requiring the missing sorting elements.
* **System Impact:** For sparse signals or quiet periods in DSP data, the filter behaves exactly like an Exact FIR filter.

### 🟡 The 1-Error Corner Case (Maximum Capacity)
The **1-Error Compressor** (5 Sorters) fails only when **all 4 primary inputs are high (`1111`)** and $C_{in}$ is low.
* **Exact Result:** Sum = 0, Carry = 2
* **Approximate Result:** Sum = 1, Carry = 1
* **Deviation:** A magnitude error of $|-1|$.
* **Architectural Logic:** By removing the 6th sorter, the hardware "misses" the final carry-out bit when the pipeline is at absolute maximum capacity.

### 🔴 The 2-Error "Collision" Trap (High Density)
The **2-Error Compressor** (4 Sorters) begins to deviate when **3 or more inputs are high**. 
* **Key Corner Case:** Input pattern (`1110`).
* **Exact Result:** Sum = 1, Carry = 1
* **Approximate Result:** Sum = 0, Carry = 1
* **Deviation:** A magnitude error of $|-1|$.
* **Architectural Logic:** The removal of two sorting elements creates "collisions" in the internal routing, where two high bits are forced into the same logic path and one is effectively "dropped" before reaching the output logic.

---

## 📈 Error Statistics Summary

| Metric | Exact | 1-Error | 2-Error |
| :--- | :---: | :---: | :---: |
| **Pass Rate (Exactness)** | 100% | 93.75% | 75.0% |
| **Max Error Magnitude** | 0 | 1 | 1 |
| **Mean Error Distance (MED)** | 0 | 0.0625 | 0.25 |

> **💡 Engineering Takeaway:**
> *"While the 2-Error design has a 25% error rate, the **Max Error Magnitude never exceeds 1**. This makes it an ideal candidate for error-tolerant applications like Lossy Image Compression (where a pixel change of 1/255 is invisible to the human eye) but unsuitable for high-precision scientific computing."*
> 

---
<!--
#### 📊 FPGA Power Reports
`![FPGA Power](./docs/fpga_power.png)`
*Hardware utilization and dynamic power estimates from the FPGA validation phase.*
-->


## 🚀 Getting Started

### Prerequisites

```bash
# Required Open-Source EDA Tools
- Icarus Verilog & GTKWave (Simulation)
- OpenLane / OpenROAD (ASIC physical design flow)
- Magic / KLayout (GDSII Layout viewing)
- SkyWater 130nm PDK (`sky130_fd_sc_hd`)
```

### Installation and Execution

**1. Clone the Repository**
```bash
git clone [https://github.com/yourusername/Hybrid-Approx-FIR-ASIC.git](https://github.com/yourusername/Hybrid-Approx-FIR-ASIC.git)
cd Hybrid-Approx-FIR-ASIC
```

**2. Run the OpenLane ASIC Flow**
```bash
# Ensure OpenLane is mounted, then run the physical design flow
./flow.tcl -design fir_1error
./flow.tcl -design fir_2error
```

**3. View the Layouts**
Navigate to the generated `runs/` directory and open the `.gds` files using KLayout to view the physical silicon routing.

---

## ❓ Frequently Asked Questions

<details>
<summary><b>Q: Why did the 2-error design consume MORE area than the 1-error design?</b></summary>

**Answer**: This is the "XOR Trap." While the 2-error design saves one AND and one OR gate *inside* the sorting network, its output logic requires an XOR gate to reconstruct the Sum. In physical CMOS, an XOR standard cell requires 10-12 transistors and complex wiring, negating the area saved by removing the 4-transistor sorter gates.
</details>

<details>
<summary><b>Q: How did you fix the timing delay on the 2-error compressor?</b></summary>

**Answer**: We expanded the `(A ^ h1)` XOR logic into its primitive components `(A & ~h1) | (~A & h1)`. This prevented the Yosys synthesizer from using bulky XOR standard cells, allowing it to map the logic directly into high-speed, single-stage **AOI (AND-OR-Invert)** compound logic cells, dropping the delay from 5.98ns to 5.54ns.
</details>

<details>
<summary><b>Q: Which compressor should I use for my project?</b></summary>

**Answer**: If your primary constraint is **Silicon Area** (e.g., IoT edge endpoints), use the **1-Error** design. If your primary constraints are **Speed and Power** (e.g., high-throughput DSP pipelines), use the **2-Error** design optimized with AOI logic.
</details>

<details>
<summary><b>Q: Why did you use a Direct Form FIR filter architecture instead of Transposed Form?</b></summary>

**Answer**: Direct Form was intentionally chosen to isolate the metrics of the approximate multipliers. Transposed Form requires wider pipeline registers (to store the 16-bit accumulated sums), which would have artificially inflated the total silicon area with D-Flip-Flops and obscured the area savings of the approximate compressors. Furthermore, the unpipelined adder tree in the Direct Form architecture allowed us to accurately expose and measure the combinatorial delay penalties (the "XOR Trap") introduced by the 2-error approximation logic.
</details>

---

## 🔮 Future Scope

- [ ] **Tapeout:** Submit the optimized macros to the Google/SkyWater Open MPW shuttle for physical fabrication.
- [ ] **Advanced Nodes:** Port the RTL to predictive sub-nanometer nodes (e.g., ASAP7 / FreePDK45) to observe how the "XOR Trap" scales with FinFET technology.
- [ ] **System Integration:** Integrate these optimized MAC units into a complete systolic array for AI/ML image classification accelerators.

---

## 📝 License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for complete terms.

---

### ⭐ Star this repository if you found this VLSI analysis helpful!

</div>
