# Project 3: I/O Interactions & Interrupt-Driven Programming Analysis

## Overview
This project implements and analyzes I/O operations on an embedded ARM system, including handling interrupts from hardware devices such as pushbuttons, timers, and switches. The project demonstrates both polling-based and interrupt-driven programming paradigms.

## Purpose
The goal is to understand how embedded systems interact with external hardware devices and manage concurrent events. This project explores interrupt handling mechanisms, device driver implementation, and the fundamental principles of real-time system design on a CPU level.

## Key Concepts Implemented

### Hardware Devices
- **Pushbuttons (PB)**: Digital input from user via interrupt or polling
- **Slider Switches**: Configuration input for program behavior
- **LED Outputs**: Visual feedback system
- **HEX Displays (HEX0-HEX5)**: 7-segment displays for data visualization
- **ARM A9 Private Timer**: Precision timing and periodic interrupts

### Device Addressing
Devices are memory-mapped at specific addresses:
- LED control: `0xFF200000`
- Slider switches: `0xFF200040`
- Pushbuttons: `0xFF200050`
- HEX displays: `0xFF200020` / `0xFF200030`
- ARM Timer: `0xFFFEC600`

## Files
- `part1.s`: Basic I/O driver implementations for polling-based device access
- `part2.s`: Interrupt-driven event handling with GIC (Generic Interrupt Controller) configuration

## Driver Implementations

### Part 1: Polling-Based I/O
**Approach**: Continuously check device status
- `read_slider_switches_ASM`: Reads current switch positions
- `write_LEDs_ASM`: Writes LED state
- `read_PB_data_ASM`: Checks current pushbutton state
- `HEX_write_ASM`: Writes hexadecimal digits to displays
- `HEX_clear_ASM`: Clears display segments
- `HEX_flood_ASM`: Fills all segments (for testing)

**Characteristics:**
- Simple implementation
- CPU continually loops checking device status
- High CPU overhead (busy-waiting)
- Predictable latency
- Cannot efficiently handle multiple devices

### Part 2: Interrupt-Driven I/O
**Approach**: Devices signal CPU only when state changes
- `CONFIG_GIC`: Initialize Generic Interrupt Controller
- `CONFIG_INTERRUPT`: Configure specific interrupt routing
- `SERVICE_IRQ`: Interrupt service routine dispatcher
- `KEY_ISR`: Pushbutton interrupt handler
- `ARM_TIM_ISR`: Timer interrupt handler
- `enable_PB_INT_ASM`: Enable pushbutton interrupts

**Characteristics:**
- Efficient CPU usage (CPU sleeps until interrupt)
- Automatic event detection
- Lower latency-per-event
- More complex implementation
- Handles concurrent events via priority

## Learning Outcomes - CPU Organization & Foundation

### I/O & Memory-Mapped Devices
- **Memory-Mapped I/O**: Devices accessed via memory addresses just like RAM
- **Device Registers**: Each device has control/status registers at specific addresses
- **Atomic Operations**: Understanding STRB/LDRB for atomic device access
- **Hardware Handshaking**: Recognizing status bits (RVALID, RDATA) for device communication

### Interrupt Architecture
- **Interrupt Vector Table**: Predefined addresses where interrupt handlers are stored
  ```
  0x00: Reset vector
  0x04: Undefined instruction
  0x08: Software interrupt (SVC)
  0x0C: Prefetch abort
  0x10: Data abort
  0x14: Unused
  0x18: IRQ (External interrupts)
  0x1C: FIQ (Fast interrupt)
  ```

### Generic Interrupt Controller (GIC)
- **Interrupt Routing**: GIC distributes interrupts to appropriate CPU cores
- **Priority Levels**: Different devices have different priorities
- **Interrupt Acknowledgment**: CPU reads interrupt ID from GIC
- **End-of-Interrupt (EOI)**: Signal completion to re-enable interrupts

### Context Switching & Register Preservation
- **Automatic State Save**: CPU hardware preserves program counter and processor state
- **Manual Save/Restore**: ISR must preserve any registers it modifies
- **PUSH/POP Usage**: Stack used for temporary register storage during interrupts
- **Return from Interrupt**: Special instruction (RFE or BX LR with mode change) restores state

### Register Usage in ISRs
- Caller-saved registers (R0-R3, R12): ISR can freely use
- Callee-saved registers (R4-R11): ISR must preserve if used
- Special registers (SPSR, LR_IRQ): Automatically saved/restored

### Device Synchronization
**Polling-Based Synchronization:**
- CPU waits for status bit to change
- Simple but CPU-intensive
- Predictable timing

**Interrupt-Based Synchronization:**
- Device signals CPU via hardware interrupt
- Efficient use of CPU cycles
- Non-deterministic timing from software perspective

### Timer Interrupt Handling
- **ARM A9 Private Timer**: 32-bit downcounter with interrupt capability
- **Timer Configuration**: Load value, enable, interrupt enable
- **Periodic Interrupts**: Used for time-based tasks
- **Interrupt Status**: Reading and clearing timer interrupt flag

### Concurrent Event Handling
- **Priority-Based**: Higher priority interrupts can preempt lower ones
- **Re-entrancy**: ISRs may call other ISRs if properly prioritized
- **Event Queuing**: Multiple events may be pending simultaneously
- **Race Conditions**: Critical section protection needed for shared resources

### Edge-Capture Registers
- Detects when button is pressed AND released (rising edge capture)
- Different from current status (which only shows instantaneous state)
- Useful for event-based triggers rather than level-based
- Shows edge detection in hardware

## Significance in Computer Architecture

### CPU Efficiency
Modern CPUs achieve high performance through:
- **Power Management**: Sleeping when idle (interrupt-driven code is more power-efficient)
- **Pipeline Efficiency**: Not constantly flushing pipeline with branch instructions
- **Cache Utilization**: CPU can perform other work during I/O wait

### Real-Time Systems
- **Latency**: Interrupt-driven approach minimizes response time to events
- **Determinism**: Harder to guarantee worst-case latency with polling
- **Fairness**: Interrupt priorities ensure important events don't miss deadlines

### System Architecture Decisions
- **Microcontroller Design**: Why embedded systems favor interrupt-driven architectures
- **Performance Trade-offs**: Complexity vs. efficiency
- **Hardware Support**: CPU features (interrupt vector, GIC) enable efficient I/O

### Modern CPU Features
- **Wake-on-Event**: CPUs can sleep and wake only on specific interrupts
- **Interrupt Controllers**: Sophisticated GICs handle complex event hierarchies
- **Device DMA**: Direct memory access for bulk I/O (not shown, but related concept)
- **Vectored Interrupts**: Different interrupt types go to different handlers

## Practical Applications
This project demonstrates principles used in:
- **Embedded Systems**: Microcontrollers in IoT devices, industrial control
- **Real-Time OS**: Kernel interrupt handling for task scheduling
- **Device Drivers**: How OS communicates with hardware
- **Responsive UI**: Event-driven architecture for user interfaces
