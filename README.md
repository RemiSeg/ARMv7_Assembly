# ARMv7_Assembly: CPU Organization & Foundation Through Practical Implementation

## Overview
This repository contains a comprehensive collection of ARMv7 assembly language projects designed to teach CPU organization, computer architecture fundamentals, and embedded systems programming. Each project builds upon previous concepts to develop a complete understanding of how modern processors work, from the hardware level up to application development.

## Educational Progression

The four projects follow a logical learning progression that mirrors how computer systems are built and understood:

### **Project 1: CPU Design** - The Foundation
*Understanding Hardware Architecture*

Implements a complete CPU design in Logisim-evolution, demonstrating all fundamental components:
- Instruction fetch and decode mechanisms
- Register file architecture and addressing
- Arithmetic Logic Unit (ALU) operations
- Data path and control path design
- Memory hierarchy integration

**Key Learning**: See exactly how instructions execute at the circuit level—the foundation for everything that follows.

→ [Project 1 Details](./Project1_CPU_design/README.md)

---

### **Project 2: Iterative vs Recursive Assembly** - Algorithm Meets Hardware
*How Different Algorithms Impact CPU Efficiency*

Compares two implementations of the Recamán sequence in pure assembly:
- Iterative approach using loops
- Recursive approach using function calls and the stack

**Key Learning**: Discover that algorithm efficiency isn't just about the algorithm itself—it's intimately tied to how the underlying CPU executes branches, manages the stack, and allocates registers. Understand function call overhead, register pressure, and memory usage patterns.

→ [Project 2 Details](./Project2_Analysis_Iterative_vs_Recusive_assembly/README.md)

---

### **Project 3: Interrupt-Driven I/O** - Real-Time Systems & Event Handling
*How CPUs Manage Concurrent Hardware Events*

Implements device drivers and interrupt handlers for embedded I/O:
- Polling-based device drivers (LEDs, switches, pushbuttons, timers)
- Interrupt Vector Table configuration
- Generic Interrupt Controller (GIC) programming
- Context switching and register preservation
- Interrupt Service Routines (ISRs)

**Key Learning**: Learn how real embedded systems work. Understand interrupt architecture, the cost of context switching, and why interrupt-driven programming is more efficient than polling for CPU utilization and power consumption.

→ [Project 3 Details](./Project3_IO_interations_analysis/README.md)

---

### **Project 4: Game of Life with Assembly-C Integration** - Practical System Design
*Bringing It All Together: Performance, Responsiveness, and User Interaction*

Implements Conway's Game of Life using:
- Assembly-language graphics drivers (VGA frame buffer)
- Assembly keyboard input handler (PS/2 protocol)
- C application logic for game state and computation
- Interactive real-time UI with graphics rendering

**Key Learning**: See how professional embedded systems are built—combining assembly performance optimization with C productivity. Understand frame buffering, graphics pipeline efficiency, event loops, and hardware-software co-design.

→ [Project 4 Details](./Project4_GoL_ASM_C/README.md)

---

## Core Concepts Learned Across All Projects

### Hardware Architecture
- CPU pipeline stages: Fetch → Decode → Execute → Memory Access → Write-back
- Register hierarchy and addressing modes
- Memory hierarchy and address translation
- Control signals and data paths

### Assembly Language & Low-Level Programming
- ARM instruction set fundamentals
- Register conventions and calling procedures
- Stack management and frame pointers
- Direct memory and I/O access

### CPU Performance & Optimization
- Branch prediction impact on pipeline efficiency
- Cache locality and memory access patterns
- Instruction-level parallelism
- Trade-offs between code speed and size

### Embedded Systems & Real-Time Programming
- Memory-mapped I/O and device registers
- Interrupt handling and prioritization
- Context switching and state preservation
- Power-efficient programming patterns

### Hardware-Software Co-Design
- When to use assembly vs. higher-level languages
- Profiling and optimization techniques
- Balancing performance, complexity, and maintainability
- Practical embedded systems engineering

## Project Structure

```
ARMv7_Assembly/
├── Project1_CPU_design/
│   ├── README.md                 # CPU design overview and learning outcomes
│   ├── cpu.circ                  # Logisim circuit file
│   └── testfiles/                # Test vectors and ROM files
│
├── Project2_Analysis_Iterative_vs_Recusive_assembly/
│   ├── README.md                 # Iterative vs recursive analysis
│   ├── part1.s                   # Base implementation
│   ├── part2-iterative.s         # Iterative approach
│   └── part2-recursive.s         # Recursive approach
│
├── Project3_IO_interations_analysis/
│   ├── README.md                 # I/O and interrupt handling guide
│   ├── part1.s                   # Polling-based device drivers
│   └── part2.s                   # Interrupt-driven event handling
│
├── Project4_GoL_ASM_C/
│   ├── README.md                 # Game of Life implementation guide
│   ├── part1.s                   # Test graphics rendering
│   ├── part2.s                   # VGA and keyboard drivers
│   ├── part3.c                   # Game logic in C
│   ├── ps2.s                     # PS/2 keyboard driver
│   └── vga.s                     # VGA display driver
│
└── README.md                      # This file - overview and navigation
```

## How to Use This Repository

### For Learning
1. **Start with Project 1** if you're new to CPU architecture
2. **Progress to Project 2** to understand how algorithms translate to hardware
3. **Study Project 3** to learn interrupt-driven programming
4. **Conclude with Project 4** to see everything working together in a practical application

### For Reference
- Each project README includes detailed explanations of concepts
- Assembly code is commented to explain functionality
- See "Learning Outcomes" sections for CPU organization insights

## Prerequisites

To work with these projects, you'll need:
- **ARMv7 Assembly Knowledge**: Basic instruction set understanding
- **Development Tools**:
  - ARM cross-compiler (arm-none-eabi-gcc)
  - Logisim-evolution (for Project 1)
  - Possibly a simulator or development board (for Projects 2-4)
- **Understanding of**:
  - Number systems (binary, hex, decimal)
  - Boolean logic
  - Basic data structures (arrays, stacks)

## Key Takeaways

### Why CPU Architecture Matters
- **Efficiency**: Understanding your hardware helps write better code
- **Predictability**: Knowing CPU behavior helps with timing-critical code
- **Debugging**: Hardware-level understanding simplifies debugging
- **Career Skills**: These concepts transfer to all systems programming

### The Progression
1. **Hardware Foundation** → Understanding physical constraints
2. **Algorithm Efficiency** → Matching algorithms to hardware capabilities
3. **System Integration** → Managing concurrent events and I/O
4. **Practical Engineering** → Real embedded systems design

### What You Gain
By completing all four projects, you'll understand:
- How every instruction flows through a CPU
- Why some algorithms run faster than others on real hardware
- How operating systems manage hardware and software
- How to write efficient embedded systems code
- The principles behind modern processor design

## Significance in Computer Science Education

These projects bridge the gap between theoretical computer science and practical systems programming:

- **Computer Organization**: See how computers actually work, not just abstraction
- **Systems Programming**: Learn to write efficient low-level code
- **Embedded Systems**: Understand how embedded devices are programmed
- **Performance Engineering**: Learn to identify and optimize bottlenecks
- **Hardware-Software Interaction**: Appreciate the symbiotic relationship

## Further Exploration

After completing these projects, consider:
- **SIMD Instructions**: Vector operations in ARMv7 (NEON)
- **Virtual Memory**: Memory protection and address translation
- **Caching Strategies**: L1/L2 cache behavior and optimization
- **Modern CPU Design**: Out-of-order execution, speculation, branch prediction
- **RTOS Kernels**: Real-time OS concepts and scheduling algorithms
- **High-Performance Computing**: Parallel processing and scalability

## License & Attribution

These educational projects are provided for learning purposes.

---

**Start your journey through computer architecture! Begin with Project 1** →

