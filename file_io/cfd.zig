// Write a program to verify that duplicated file descriptors share a file offset value
// and open file status flags.

const std = @import("std");
const linux = std.os.linux;

const DUPED_FD = 100;

pub fn main() !void {
    var file_path: ?[*:0]const u8 = null;

    for (std.os.argv, 0..) |arg, i| {
        if (i == 0) continue;

        if (file_path == null) {
            file_path = arg;
            continue;
        }
    }

    const fd = linux.open(
        file_path.?,
        .{
            .ACCMODE = .RDWR,
        },
        linux.S.IRUSR,
    );
    if (linux.E.init(fd) != .SUCCESS)
        std.process.exit(1);
    defer {
        const closed_fd = linux.close(@intCast(fd));
        if (linux.E.init(closed_fd) != .SUCCESS)
            std.process.exit(1);
    }

    const duped_fd = linux.dup2(@intCast(fd), DUPED_FD);
    if (linux.E.init(duped_fd) != .SUCCESS)
        std.process.exit(1);
    defer {
        const closed_fd = linux.close(@intCast(duped_fd));
        if (linux.E.init(closed_fd) != .SUCCESS)
            std.process.exit(1);
    }

    const fd_flags = linux.fcntl(@intCast(fd), linux.F.GETFL, 0);
    const duped_fd_flags = linux.fcntl(@intCast(duped_fd), linux.F.GETFL, 0);
    if (linux.E.init(fd_flags) != .SUCCESS or
        linux.E.init(duped_fd_flags) != .SUCCESS)
        std.process.exit(1);

    std.debug.print("fd: {d} flags -> {b}\n", .{ fd, fd_flags });
    std.debug.print("duped_fd: {d} flags -> {b}\n", .{ duped_fd, duped_fd_flags });

    const fd_offset = linux.lseek(@intCast(fd), 2, linux.SEEK.SET);
    if (linux.E.init(fd_offset) != .SUCCESS)
        std.process.exit(1);

    const duped_fd_offset = linux.lseek(@intCast(duped_fd), 0, linux.SEEK.CUR);
    if (linux.E.init(duped_fd_offset) != .SUCCESS)
        std.process.exit(1);

    std.debug.print("fd: {d} offset -> {d}\n", .{ fd, fd_offset });
    std.debug.print("duped_fd: {d} offset -> {d}\n", .{ duped_fd, duped_fd_offset });
}
