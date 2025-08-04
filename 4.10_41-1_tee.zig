const std = @import("std");
const args = @import("args.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const arguments = try args.getArgs(allocator);
    defer allocator.free(arguments);
}
