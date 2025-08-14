// Compile the program in Listing 6-1 (mem_segments.c), and list its size using ls –l.
// Although the program contains an array (mbuf) that is around 10 MB in size, the
// executable file is much smaller than this. Why is this?
//
// ANSWER: The program occupies less space on disk due to the fact that globBuff and
// mbuf are initialzied global arrays, so they end up in the bss section of the process.
//
// DISCLAIMER: I've included the C version of this program to compare the result of Zig
// and C, because Zig doesn't have static variable like C.
//
// To compile the C program use `zig cc process/mem_segments.c -O2`
// To compile the Zig program use `zig build-exe process/mem_segments.zig -O ReleaseSmall`
//
// After compiling you should see pretty similar sizes, they will not be the same, cause
// the zig compiler behavies differently than the C compiler.
//
// Open to better ways to show this behaviour!

const std = @import("std");

var globBuf: [65536]u8 = undefined;
const primes: []i32 = [_]i32{ 2, 3, 5, 7 };
const key: i32 = 9973;
var mbuf: [10240000]u8 = undefined;

pub fn main() !void {
    const p = try std.heap.page_allocator.alloc(u8, 100);
    defer std.heap.page_allocator.free(p);

    doCalc(key);
}

fn square(x: i32) i32 {
    return x * x;
}

fn doCalc(val: i32) void {
    std.debug.print("The square of {d} is {d}\n", .{ val, square(val) });

    if (val < 1000) {
        const t = val * val * val;

        std.debug.print("The cube of {d} is {d}\n", .{ val, t });
    }
}
