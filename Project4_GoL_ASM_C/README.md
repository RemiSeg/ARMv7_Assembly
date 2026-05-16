# Project 4: Game of Life with Assembly-C Integration

## Overview
This project implements Conway's Game of Life on an embedded system using a combination of ARMv7 assembly and C. The implementation provides VGA graphics display, PS/2 keyboard input, and interactive grid manipulation for the cellular automaton simulation.

## Purpose
The goal is to understand how high-level algorithms are efficiently implemented through hardware-software co-design, combining the performance benefits of assembly language drivers with the productivity of C for application logic. This project demonstrates practical embedded systems programming where different languages are chosen based on their strengths.

## Game of Life Rules
- **Alive Cell**: Dies if fewer than 2 or more than 3 neighbors (underpopulation/overpopulation)
- **Dead Cell**: Becomes alive with exactly 3 neighbors (reproduction)
- **Stable Cell**: Lives if exactly 2-3 neighbors (survival)

## Architecture Overview

### Hardware Components
- **VGA Display**: 320×240 pixel graphics output
  - Pixel buffer: `0xC8000000` (16-bit RGB color)
  - Character buffer: `0xC9000000` (8-bit ASCII display overlay)
- **PS/2 Keyboard**: User input via serial protocol
  - Data register: `0xFF200100` (with RVALID bit at position 15)
- **Grid Display**: 16×12 Game of Life cells (20×20 pixels each)

## Implementation Files

### Assembly Drivers (`part2.s`, `vga.s`, `ps2.s`)

#### VGA Display Functions (`part2.s`)
- `VGA_draw_point_ASM`: Draw single pixel with bounds checking
- `VGA_clear_pixelbuff_ASM`: Clear entire pixel buffer to black
- `VGA_write_char_ASM`: Write ASCII character to character display
- `VGA_clear_charbuff_ASM`: Clear character buffer
- `VGA_draw_line`: Draw horizontal/vertical lines efficiently
- `VGA_draw_rect`: Draw filled rectangles for grid cells

#### PS/2 Keyboard Functions (`ps2.s`)
- `read_PS2_data_ASM`: Read keyboard data with validity checking
  - Checks RVALID bit to detect new data
  - Extracts 8-bit ASCII value
  - Returns 1 if data valid, 0 otherwise

#### Supporting Functions (`part2.s`)
- `write_hex_digit`: Format and display hexadecimal values (for debugging)
- `write_byte`: Display two-digit hex values
- `input_loop`: Main input polling loop for keyboard

### Application Logic (`part3.c`)

#### Game State Management
- `GoLBoard[12][16]`: Current generation state
- `NextBoard[12][16]`: Computed next generation
- `CursorX`, `CursorY`: User's edit position

#### Graphics Functions
- `GoL_draw_grid`: Draw 16×12 grid overlay
- `GoL_fill_gridxy`: Fill individual grid cell (20×20 pixels)
- `GoL_draw_board`: Render all alive cells
- `GoL_draw_cursor`: Highlight current cell
- `GoL_redraw`: Refresh entire display

#### Computation Functions
- `GoL_count_neighbors`: Count alive cells around position (x,y)
- `GoL_next_generation`: Compute one generation step

#### User Interface
- `main`: Event loop handling keyboard input
  - **W/A/S/D**: Move cursor
  - **Space**: Toggle current cell alive/dead
  - **N**: Advance one generation

## Learning Outcomes - CPU Organization & Foundation

### Hardware-Software Interface
- **Memory-Mapped I/O**: Direct hardware access via memory addresses
- **Device Registers**: Understanding register semantics (RVALID bit, address format)
- **Bit Manipulation**: Extracting fields using shifts and masks (LSR, AND operations)
- **Timing Considerations**: Polling PS/2 status; understanding device response times

### Graphics Pipeline on Embedded Systems
- **Address Computation**: Converting (x,y) coordinates to linear frame buffer address
  - Pixel address: `0xC8000000 | (y << 10) | (x << 1)`
  - Character address: `0xC9000000 | (y << 7) | x`
- **Data Types**: 16-bit RGB565 for graphics, 8-bit ASCII for text
- **Bounds Checking**: Software checking before hardware access (efficiency + safety)
- **Loop Optimization**: Clearing large buffers requires efficient loop structure

### Input Handling & Event Processing
- **Polling Loop**: Continuously checking device status
- **Status Bit Monitoring**: Reading RVALID bit to detect new data
- **Input Validation**: Ensuring data is valid before processing
- **Non-Blocking I/O**: Program remains responsive even without input

### Assembly Performance Optimization
- **Critical Path Identification**: Graphics functions called frequently; optimized in assembly
- **Register Allocation**: Choosing which variables stay in registers
- **Branch Minimization**: Tight inner loops in graphics functions
- **Data Type Selection**: 16-bit colors reduce memory bandwidth vs. 32-bit

### Function Call & Parameter Passing
- **Register Arguments**: First 4 parameters in R0-R3 (A1-A4 in assembly)
- **Return Values**: R0 holds single return value (int functions)
- **Callee-Saved Registers**: Assembly functions must preserve V1-V8 (R4-R11)
- **Inline Assembly**: C functions with embedded assembly blocks

### Algorithm Efficiency in Hardware
- **Neighbor Counting**: Eight-neighbor checking requires predictable memory access
- **Generation Computation**: Cell update logic maps directly to conditional branches
- **Buffer Copying**: Efficient block memory operations (loop unrolling could improve)
- **Display Updates**: Only redraw changed cells for efficiency

## Significance in Computer Architecture

### Heterogeneous System Design
Modern embedded systems benefit from:
- **Performance-Critical Drivers**: Assembly for low-level hardware access
- **Maintainability**: High-level C for application logic
- **Development Productivity**: Using appropriate language for each layer
- **Optimization Opportunities**: Profiling to identify hot-spots worth assembly optimization

### Graphics Rendering at Hardware Level
- **Frame Buffering**: Continuous memory update to display hardware
- **Pixel Timing**: Understanding display refresh rates and timing
- **Memory Bandwidth**: Graphics operations are memory-intensive
- **Pipeline Hazards**: Memory writes to display hardware may cause stalls

### Input/Output Synchronization Patterns
- **Polling vs. Interrupts**: This project uses polling; shows trade-off with responsiveness
- **Debouncing**: Real keyboards require electrical debouncing (not shown)
- **Protocol Handling**: PS/2 is serial protocol; driver abstracts complexity
- **Buffer Management**: Keyboard events can queue; need to handle all presses

### Multitasking Simulation
- **Event Loop**: Single-threaded polling loop simulates concurrent events
- **Responsiveness**: Dividing computation into small steps
- **State Machines**: Game state (playing, editing) can be managed explicitly
- **Fairness**: Round-robin through different event types

### Real-World Embedded Systems
This project demonstrates patterns found in:
- **Retro Game Systems**: Graphics via frame buffers, input polling
- **Industrial Control**: Real-time grid computations with user interaction
- **Graphical Displays**: Any system combining graphics + keyboard input
- **IoT Devices**: Simple embedded systems with multiple I/O sources

## Performance Considerations

### Bottlenecks
1. **Graphics Rendering**: Clearing/drawing 320×240 pixels is expensive
2. **Neighbor Counting**: Computing next generation requires checking 8 neighbors per cell
3. **Display Refresh**: Limited by display hardware (typically 60Hz)
4. **Input Polling**: PS/2 reading in main loop could block on slow data

### Optimization Opportunities
- **Double Buffering**: Avoid visual tearing (not shown)
- **Dirty Rectangles**: Only redraw changed cells
- **Cache Optimization**: Improve memory access patterns
- **Vectorization**: Using NEON SIMD instructions for batch operations
- **Interrupt-Driven Input**: Use PS/2 interrupt instead of polling

## Extension Ideas
1. **Variable Game Speed**: Configurable generation rate
2. **Multiple Patterns**: Load classic patterns (gliders, oscillators)
3. **Save/Load**: Persist patterns to storage
4. **Statistics**: Display population count, generation number
5. **Full Interrupt-Driven I/O**: Reduce CPU usage with event-driven architecture
