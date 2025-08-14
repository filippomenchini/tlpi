# The Linux Programming Interface

This repo contains exercises from "The Linux Programming Interface" book
by Micheal Kerrisk.
Exercises are written in the Zig language and use the `std.os.linux`
namespace to make syscalls to the kernel. Some exercises highly depend
on specific C language features or C preprocessor/compiler features and 
legacy features, so I won't implement every exercise.

## Programs structure
Every program is structured to be self-contained and easy to understand.
I'm not focusing on code quality or architecture, I'm aiming for simple
and hackable programs to better understand the ins and outs of the Linux
kernel.
Any suggestion on how to make these programs better are well accepted!
Answers to exercises can be found at the top of every program.

## Exercises list

### File I/O
- **4.10** 
    - 4-1 [tee](file_io/tee.zig)
    - 4-2 [cp](file_io/cp.zig)
- **5.14** 
    - 5-2 [seek append](file_io/sa.zig)
    - 5-3 [atomic append](file_io/aa.zig)
    - 5-4 [dup](file_io/dup.zig)
    - 5-5 [compare file descriptors](file_io/cfd.zig)
    - 5-6 [write explanation](file_io/we.zig)
    - 5-7 [scatter gather io](file_io/sgio.zig)

### Processes
- **6.10**
    - 6-1 [mem segments](processes/mem_segments.zig) ([C impl](processes/mem_segments.c))
