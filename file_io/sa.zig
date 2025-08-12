// Write a program that opens an existing file for writing with the O_APPEND flag, and
// then seeks to the beginning of the file before writing some data. Where does the
// data appear in the file? Why?
//
// ANSWER: when opening with append mode on, writes are ALWAYS appended at the end of the file
// without considering the offset.

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

    if (file_path == null)
        std.process.exit(1);

    const file_fd = linux.open(
        file_path.?,
        .{
            .ACCMODE = .WRONLY,
            .CREAT = true,
            .APPEND = true,
        },
        linux.S.IRUSR | linux.S.IWUSR,
    );

    if (linux.E.init(file_fd) != .SUCCESS)
        std.process.exit(1);
    defer {
        const close_status = linux.close(@intCast(file_fd));
        if (linux.E.init(close_status) != .SUCCESS)
            std.process.exit(1);
    }

    const offset = linux.lseek(@intCast(file_fd), 0, linux.SEEK.SET);
    if (linux.E.init(offset) != .SUCCESS)
        std.process.exit(1);

    const buffer = "test\n";
    const bytes_written = linux.write(@intCast(file_fd), buffer, 5);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);
}
