# COMP-ARC-MP4

A multicycle, 32-bit RISC-V-style processor implemented in SystemVerilog for the
iceBlinkPico board, which uses an iCE40 UP5K FPGA. The design combines a
processor datapath and controller with byte-addressable memory, memory-mapped
timers, and PWM-controlled LEDs.

## Features

- 32-bit datapath and 32-entry integer register file (`x0` is hardwired to zero).
- Multicycle control FSM for instruction fetch, decode, execution, memory access,
  and register writeback.
- Instruction decoding for R-type and I-type ALU operations, loads, stores,
  conditional branches, `JAL`, `JALR`, `LUI`, and `AUIPC`.
- ALU operations include arithmetic, logic, shifts, signed and unsigned
  comparisons, and multiply/divide operations.
- 4 KiB instruction memory and 4 KiB data memory, each organized as four byte
  lanes.
- Byte, half-word, and word data transfers, with signed and unsigned reads.
- Memory-mapped LED brightness and millisecond/microsecond timer registers.
- Simulation testbench with register checks, execution logging, and VCD waveform
