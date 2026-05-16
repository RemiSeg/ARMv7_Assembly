# Project 2: Iterative vs Recursive Assembly Implementation Analysis

## Overview
This project provides a comparative analysis of implementing the Recamán sequence algorithm using two different programming paradigms: iterative and recursive approaches in ARMv7 assembly language.

## Purpose
The goal is to explore how different algorithmic approaches translate to assembly code and understand the performance implications, memory usage, and register allocation strategies in each case. This project highlights the trade-offs between code simplicity and computational efficiency at the hardware level.

## Recamán Sequence
The Recamán sequence is defined as:
- `a(0) = 0`
- `a(n) = a(n-1) - n` if positive and not already in sequence
- Otherwise: `a(n) = a(n-1) + n`

## Files
- `part1.s`: Base setup for the Recamán sequence
- `part2-iterative.s`: Iterative implementation using loops and state variables
- `part2-recursive.s`: Recursive implementation using function calls and the call stack

## Implementation Comparison

### Iterative Approach (part2-iterative.s)
**Characteristics:**
- Uses loop constructs (BLE, BGE branch instructions)
- Maintains state in registers (V1-V4 for loop counter, previous value, etc.)
- Direct memory access for sequence storage
- Single stack frame for entire computation

**Advantages:**
- Faster execution (fewer function calls)
- Lower memory overhead
- More predictable performance
- Easier to optimize for specific register constraints

**Disadvantages:**
- Code logic is more explicit and complex
- Harder to understand the algorithm's natural structure
- More state variables to track manually

### Recursive Approach (part2-recursive.s)
**Characteristics:**
- Uses function calls (BL) for recursive decomposition
- Each recursive level creates new stack frame
- Parameters passed via registers (A1, A2)
- Natural alignment with the mathematical definition

**Advantages:**
- Code closely mirrors the mathematical definition
- More intuitive and elegant for naturally recursive problems
- Automatic state preservation via stack
- Easier to verify correctness

**Disadvantages:**
- Function call overhead (PUSH/POP, BL/BX)
- Stack memory grows with recursion depth (potential stack overflow)
- Slower execution for deep recursion
- Cache misses from repeated memory access

## Learning Outcomes - CPU Organization & Foundation

### Function Call Mechanics
- Understanding the ARM calling convention (A1-A4 for parameters, V1-V8 for callee-saved registers)
- Learning how the return address is stored in LR (Link Register)
- Recognizing the overhead of PUSH/POP operations in stack manipulation
- Understanding frame pointers and stack frame layout

### Register Allocation Strategy
- Appreciating how compilers/assemblers decide which variables go in registers
- Understanding register pressure when many variables are in use
- Learning the difference between caller-saved and callee-saved registers
- Recognizing when values must be spilled to memory

### Memory Usage Patterns
- **Iterative**: Flat memory usage (no call stack growth)
- **Recursive**: Linear memory growth with recursion depth (O(n) stack space)
- Understanding the relationship between recursion depth and memory consumption
- Recognizing stack limitations and potential overflow conditions

### Performance Analysis at Hardware Level
- **Branch Prediction**: How different branch patterns affect CPU pipeline efficiency
- **Instruction Cache**: Iterative code stays in tight loops (better cache locality)
- **Function Call Overhead**: Each recursive call requires multiple instructions (PUSH, BL, POP, BX)
- **Load-Store Operations**: Frequency and patterns of memory access in each approach

### Control Flow & Branching
- Understanding conditional branches (CMP, BLE, BGE)
- Learning how loops are implemented via branch-back instructions
- Recognizing branch prediction challenges in recursive calls
- Understanding the CPU's ability to pipeline different branch patterns

### Stack Frame Architecture
- How the stack grows downward in memory (ARM convention)
- Automatic state preservation without explicit coding (in recursion)
- Understanding saved return addresses and parameter passing
- Learning the cost of each recursive level in terms of memory and CPU cycles

## Significance in Computer Architecture
This project demonstrates that algorithm efficiency isn't just about algorithm design—it's fundamentally tied to how the underlying hardware executes the instructions. Key insights:

1. **Architecture-Algorithm Interaction**: Different algorithms perform differently on the same CPU architecture due to how they use branches, memory, and function calls

2. **Pipeline Efficiency**: CPUs are optimized for certain patterns:
   - Tight loops (better branch prediction)
   - Sequential execution (better cache usage)
   - Predictable memory access patterns

3. **Hardware Resource Usage**: Every recursion level consumes physical hardware resources (stack memory, register save/restore operations)

4. **Real-World Implications**: Modern CPUs may optimize recursion through tail-call elimination, but understanding the hardware cost helps write better code

## Practical Implications
- Choose iterative approaches for performance-critical code on CPUs with simple branch prediction
- Consider recursive approaches for readability when performance is less critical
- Understand that compiler optimizations can sometimes automatically convert between these approaches
- Recognize that hardware capabilities (cache size, branch prediction) influence which approach performs better
