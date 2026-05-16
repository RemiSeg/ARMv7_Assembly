# Project 1: CPU Design

## Overview
This project involves designing and simulating a basic CPU architecture using Logisim-evolution. The design demonstrates fundamental CPU concepts including instruction decoding, data flow, and the integration of key computational components.

## Purpose
The primary goal of this project is to understand the hardware architecture of a Central Processing Unit from the ground up. By implementing a CPU in a circuit simulation environment, this project provides hands-on experience with how computer systems execute instructions at the hardware level.

## Key Components
- **Instruction Memory (InsMem)**: Stores the program instructions to be executed
- **Register File**: Holds temporary data and CPU state during program execution
- **Arithmetic Logic Unit (ALU)**: Performs arithmetic and logical operations
- **Data Memory (RAM)**: Stores program data that persists across instruction cycles
- **Control Path**: Directs instruction flow and operation sequences

## Files
- `cpu.circ`: Logisim circuit file containing the complete CPU design with all integrated components

## Learning Outcomes - CPU Organization & Foundation

### Instruction Execution Pipeline
- Understanding how instructions flow through the CPU from memory to execution
- Recognizing the critical path in CPU design that determines clock frequency
- Observing how different instruction types (arithmetic, memory access, control flow) follow different paths through the CPU

### Register Architecture
- Learning the role of registers as the CPU's fastest storage mechanism
- Understanding register addressing modes and how registers are accessed during instruction execution
- Appreciating the trade-off between number of registers and chip complexity

### Data Path Design
- Understanding how data flows from memory → registers → ALU → back to memory/registers
- Recognizing control signals that determine which components participate in each cycle
- Learning how multiplexers select between different data sources

### Memory Hierarchy Integration
- Seeing how instruction memory and data memory are physically separate but logically connected
- Understanding address decoding for memory operations
- Learning timing constraints when accessing memory

### Fundamental CPU Concepts
- **Fetch**: Retrieving instructions from memory
- **Decode**: Interpreting what instruction to execute
- **Execute**: Performing the actual operation
- **Memory Access**: Reading/writing data as needed
- **Write-back**: Storing results back to registers

## Significance in Computer Architecture
This project forms the foundation for understanding all subsequent projects. It demonstrates that a CPU is fundamentally a state machine that:
1. Reads instructions
2. Accesses operands from registers/memory
3. Performs operations
4. Stores results
5. Advances to the next instruction

All subsequent projects build upon this understanding by using the ARMv7 instruction set to program such a machine.
