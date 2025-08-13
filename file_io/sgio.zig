// Implement readv() and writev() using read(), write(), and suitable functions from the
// malloc package.

const std = @import("std");
const linux = std.os.linux;

const IoVec = struct {
    buffer: []u8,
    len: usize,

    fn init(buffer: []u8) IoVec {
        return IoVec{
            .buffer = buffer,
            .len = 0,
        };
    }

    fn data(self: *const IoVec) []const u8 {
        return self.buffer[0..self.len];
    }
};

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

    var iovec = [_]IoVec{
        IoVec.init(&buffer_1),
        IoVec.init(&buffer_2),
        IoVec.init(&buffer_3),
    };

    const bytes_read = readv(@intCast(fd), &iovec);
    if (linux.E.init(bytes_read) != .SUCCESS)
        std.process.exit(1);

    std.debug.print("BYTES READ: {d}\n\n", .{bytes_read});
    for (iovec) |io| {
        std.debug.print("{s}\n", .{io.data()});
    }

    std.debug.print("\n\n", .{});

    const bytes_written = writev(linux.STDOUT_FILENO, &iovec);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);

    std.debug.print("BYTES WRITTEN: {d}\n", .{bytes_written});
}

fn readv(fd: linux.fd_t, iovec: []IoVec) usize {
    var total_bytes_read: usize = 0;
    for (iovec) |*io| {
        const bytes_read = linux.read(fd, io.buffer.ptr, io.buffer.len);
        if (linux.E.init(bytes_read) != .SUCCESS) return bytes_read;
        if (bytes_read == 0) break;

        io.len = bytes_read;
        total_bytes_read += bytes_read;
    }
    return total_bytes_read;
}

fn writev(fd: linux.fd_t, iovec: []const IoVec) usize {
    var total_bytes_written: usize = 0;
    for (iovec) |io| {
        if (io.len == 0) continue;

        var written: usize = 0;
        while (written < io.len) {
            const result = linux.write(fd, io.buffer.ptr + written, io.len - written);
            if (linux.E.init(result) != .SUCCESS) return result;
            written += result;
        }
        total_bytes_written += written;
    }
    return total_bytes_written;
}
