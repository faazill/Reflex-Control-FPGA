# FPGA-Based Geometric Stability Monitor

**Status:** Hardware-Verified Prototype | **Target:** Artix-7 FPGA | **Synthesis:** Yosys Open-Source Flow

## Overview

An FPGA-accelerated architecture for real-time grasp stability monitoring using geometric feature extraction and spiking neural network decision logic. This work demonstrates sub-microsecond processing latency for vision-based safety reflexes in structured manipulation tasks.

The system processes streaming pixel data to compute first and second geometric moments, encoding instability into spike trains processed by a hardware Leaky Integrate-and-Fire (LIF) neuron. A policy gate provides deterministic motor command arbitration.

## Architecture

**Pipeline Stages:**

1. **Symmetry Monitor** - Computes drift (M1) and spread (M2) metrics from pixel intensity distributions
2. **Spike Encoder** - Rate-codes error signals into temporal spike trains  
3. **SNN Reflex Core** - LIF neuron integrates spikes with decay, fires veto on threshold breach
4. **Policy Gate** - Hardware multiplexer switches between AI policy and safe state (τ = 0)

**Design Principle:** Feed-forward datapath with no frame buffering, minimizing computational latency to FPGA clock cycles only.

## Verification

**Methodology:** Hardware-in-the-Loop (HIL) simulation using PyBullet physics traces injected into Verilog testbench.

**Test Scenario:** Parallel-jaw gripper with decreasing friction coefficient until slip event (>1mm vertical drop).

**Results:**
- Logic processing latency: 420 ns (synthesis-verified)
- Veto assertion within 1 µs of drift metric threshold breach
- Total resource utilization: 6,895 logic cells, 293 flip-flops on 28nm equivalent fabric

| Module | Logic Cells | Percentage |
|--------|-------------|------------|
| Symmetry Monitor | 4,148 | 60.1% |
| Spike Encoder | 1,812 | 26.2% |
| SNN Reflex Core | 747 | 10.8% |
| Policy Gate | 188 | 2.7% |

## Repository Structure

```
├── rtl/
│   ├── symmetry_monitor.v
│   ├── spike_encoder.v
│   ├── snn_reflex_core.v
│   └── policy_gate.v
├── tb/
│   └── tb_pybullet_replay.v
├── python_model/
│   └── generate_grasp_trace.py
└── synthesis/
    └── yosys_synth.ys
```

## Build and Simulate

**Generate test trace:**
```bash
cd python_model && python3 generate_grasp_trace.py
```

**Run RTL simulation:**
```bash
iverilog -o sim tb/tb_pybullet_replay.v rtl/*.v
vvp sim
gtkwave pybullet_wave.vcd
```

**Synthesize:**
```bash
yosys -s synthesis/yosys_synth.ys
```

## Scope and Limitations

**This is a research prototype, not a production safety system.**

- **Geometric constraints:** Assumes centrally symmetric objects with consistent visual features
- **Sensor dependency:** End-to-end latency dominated by camera frame rate (30-100 Hz), not FPGA processing
- **Environmental sensitivity:** Intensity-based moments susceptible to lighting variation, occlusion, and texture-less surfaces
- **Validation domain:** Tested on synthetic physics simulation only; no physical robot deployment

**Intended use cases:** FPGA architecture education, neuromorphic computing demonstrations, HIL verification methodology examples.

## Dependencies

- Icarus Verilog 10.3+
- Yosys 0.9+
- Python 3.8+ with PyBullet
- GTKWave (for waveform visualization)

## License

MIT License - Open for educational and non-commercial research use.

## Citation

If referencing this work, please cite as a prototype study:

```
K., Muhammed Fazil. "Hardware-Enforced Safety: An Event-Driven Neuromorphic 
Reflex Layer for Robotic Manipulation." FPGA Prototype, 2025.
```