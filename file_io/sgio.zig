// Implement readv() and writev() using read(), write(), and suitable functions from the
// malloc package.

const std = @import("std");
const linux = std.os.linux;

pub fn main() !void {
    var file_path: ?[*:0]const u8 = null;

    for (std.os.argv, 0..) |arg, i| {
        if (i == 0) continue;

        if (file_path == null) {
            file_path = arg;
            continue;
        }
    }

    const fd = linux.open(file_path.?, .{ .ACCMODE = .RDONLY }, linux.S.IRUSR);
    if (linux.E.init(fd) != .SUCCESS)
        std.process.exit(1);

    defer {
        const closed_fd = linux.close(@intCast(fd));
        if (linux.E.init(closed_fd) != .SUCCESS)
            std.process.exit(1);
    }

    var buffer_1 = [_]u8{0} ** 10;
    var buffer_2 = [_]u8{0} ** 20;
    var buffer_3 = [_]u8{0} ** 30;
    var buffers = [_][]u8{ &buffer_1, &buffer_2, &buffer_3 };

    const bytes_read = readv(@intCast(fd), &buffers);
    if (linux.E.init(bytes_read) != .SUCCESS)
        std.process.exit(1);

    std.debug.print("BYTES READ: {d}\n", .{bytes_read});
    for (buffers) |buffer| {
        std.debug.print("\t{s}\n", .{buffer});
    }
}

fn readv(fd: linux.fd_t, iovec: [][]u8) usize {
    var total_bytes_read: usize = 0;
    for (iovec) |io| {
        const bytes_read = linux.read(fd, io.ptr, io.len);
        if (linux.E.init(bytes_read) != .SUCCESS) {
            return bytes_read;
        }

        if (bytes_read == 0) break; // EOF
        total_bytes_read += bytes_read;
    }

    return total_bytes_read;
}
