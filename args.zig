const std = @import("std");

pub fn get(allocator: std.mem.Allocator) ![][]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var argsList = std.ArrayList([]const u8).init(allocator);
    defer argsList.deinit();

    var arg = args.next();
    while (arg != null) {
        try argsList.append(arg.?);
        arg = args.next();
    }

    return try argsList.toOwnedSlice();
}
