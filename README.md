# Automatic Washing Machine Controller

A VHDL-based digital controller for an automatic washing machine, built as a Finite State Machine (FSM) and simulated using Xilinx tools.

**Course:** Digital System Design (CEL-442) — Bahria University, Karachi  

---

## What This Project Does

This controller handles the full washing cycle of an automatic washing machine — from the moment you press Start to when the buzzer sounds at the end. It sequences through every phase automatically: filling water, heating it (if needed), dispensing detergent, washing, rinsing, draining, and spin-drying.

The entire logic is implemented as a **Moore-type FSM** in VHDL with 12 states, where each state corresponds to one phase of the wash cycle. Outputs (motor, valves, heater, etc.) are driven purely by the current state, making the behavior deterministic and predictable.

---

## How It Works

### The Wash Cycle

When started, the controller walks through these steps in order:

1. **Door Check** — Waits until the door sensor confirms the door is closed, then locks it.
2. **Fill Water** — Opens the water inlet valve and waits for the water level sensor to signal full.
3. **Heat Water** — Activates the heater for a fixed duration (skipped in Delicate and Quick modes).
4. **Add Detergent** — Triggers the detergent dispenser for a short timed period.
5. **Wash** — Runs the motor, alternating direction every second to agitate the load.
6. **Rinse Drain** — Opens the drain valve to empty the soapy water.
7. **Rinse Fill** — Refills with fresh water.
8. **Rinse** — Runs the motor again with clean water.
9. **Spin Drain** — Drains the rinse water.
10. **Spin** — Runs the motor at high speed in one direction to spin-dry the load.
11. **Complete** — Sounds the buzzer, signals done, and returns to idle.

### Wash Modes

The `wash_mode` input (2-bit) selects one of four presets that control how long each phase runs and whether heating is enabled:

| Mode | Code | Wash | Rinse | Spin | Heating |
|------|------|------|-------|------|---------|
| Normal | `00` | 10s | 5s | 3s | Yes |
| Heavy Duty | `01` | 15s | 8s | 5s | Yes |
| Delicate | `10` | 6s | 4s | 2s | No |
| Quick Wash | `11` | 4s | 2s | 2s | No |

> Timings are scaled for simulation. On a real 50 MHz FPGA, the timer divider would be adjusted to produce actual minute-scale durations.

### Safety Features

- The door is **locked** for the entire cycle once started and only unlocks after completion.
- If the door is open when Start is pressed, the machine waits at the Door Check state — it won't proceed.
- An **active-low asynchronous reset** (`rst_n`) immediately returns the controller to IDLE from any state, acting as an emergency stop.

---

## Project Files

| File | Description |
|------|-------------|
| `washing_machine_controller.vhd` | Main FSM controller entity |
| `tb_washing_machine.vhd` | Testbench covering all 4 wash modes + safety tests |

---

## Simulation

The testbench runs six test scenarios:

- All four wash modes from start to completion
- Door interlock behavior (machine holds until door closes)
- Emergency reset mid-cycle

Tested and verified in Xilinx. All 12 states transition correctly and all outputs behave as expected across every mode.

---

## Limitations

- No physical FPGA deployment — simulation only.
- Sensors (water level, temperature) are modeled as simple binary signals.
- No fault detection or error recovery logic.
