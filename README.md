# FPGA-Based Event-Driven Reflex Core (Prototype)

![Status](https://img.shields.io/badge/Status-Prototype_Verified-blue)
![Architecture](https://img.shields.io/badge/Architecture-Neuromorphic_SNN-purple)
![Hardware](https://img.shields.io/badge/Hardware-Artix--7_Compatible-green)

An educational FPGA architecture exploring **neuromorphic event processing** for robotic safety. This core implements a hardware-accelerated **Spiking Neural Network (SNN)** to detect geometric anomalies (slip/drift) in synthetic sensor streams with deterministic latency.

> **Note:** This project is a hardware feasibility study. It uses Hardware-in-the-Loop (HIL) simulation to validate the RTL logic path and is not a production-ready safety system.

## 📐 System Architecture

The design pipeline mimics a "Spinal Cord" reflex, processing sensor data without OS intervention.

1.  **Synthetic Event Source:** Python/PyBullet simulation generates pixel streams representing a slipping object.
2.  **Symmetry Monitor (RTL):** Calculates 1D geometric moments (Centroid Drift, Spread) in real-time.
3.  **Spike Encoder (RTL):** Converts error magnitude into temporal spike trains (Rate Coding).
4.  **LIF Neuron (RTL):** A Leaky Integrate-and-Fire core that triggers a veto signal if error density exceeds a dynamic threshold.

## 📊 Key Results (Simulation)

* **Processing Latency:** < 1 µs (FPGA Logic Path)
* **Resource Usage:** ~6,900 Logic Cells (<11% SNN Core Utilization)
* **Validation:** Verified against synthetic slip traces generated via PyBullet.

| Module | Function | Logic Cells (Est.) |
| :--- | :--- | :--- |
| `symmetry_monitor` | 1st/2nd Moment Calculation | ~4,100 |
| `spike_encoder` | Rate-based Spike Generation | ~1,800 |
| `snn_reflex_core` | LIF Neuron & Thresholding | ~750 |
| **Total** | **Full Reflex Layer** | **~6,900** |

## 🚀 Quick Start

### Prerequisites
* Icarus Verilog (`iverilog`)
* GTKWave
* Python 3 + PyBullet

### Running the HIL Verification
1.  **Generate Synthetic Trace:**
    ```bash
    cd python_model
    python3 generate_grasp_trace.py
    ```
    *Creates `grasp_trace.hex` (simulated sensor stream).*

2.  **Run RTL Simulation:**
    ```bash
    cd ..
    iverilog -o reflex_sim tb/tb_pybullet_replay.v rtl/*.v
    vvp reflex_sim
    ```

3.  **View Waveforms:**
    ```bash
    gtkwave pybullet_wave.vcd
    ```

## ⚠️ Scope & Limitations
* **Input Data:** The system currently ingests frame-based pixel data converted to a stream. Future iterations would target true AER (Address Event Representation) protocols for Dynamic Vision Sensors (DVS).
* **Safety Logic:** The current slip detection relies on geometric symmetry, which assumes structured lighting and symmetric payloads.
* **Platform:** Validated via behavioral synthesis and simulation. Static Timing Analysis (STA) target is 100 MHz on Artix-7 fabric.

## 📜 License
MIT License - Open for educational and research use.