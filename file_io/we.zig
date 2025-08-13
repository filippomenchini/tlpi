// After each of the calls to write() in the following code, explain what the content of
// the output file would be, and why:
// ```c
// fd1 = open(file, O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
// fd2 = dup(fd1);
// fd3 = open(file, O_RDWR);
// write(fd1, "Hello,", 6);
// write(fd2, "world", 6);
// lseek(fd2, 0, SEEK_SET);
// write(fd1, "HELLO,", 6);
// write(fd3, "Gidday", 6);
// ```
//
// ANSWER: The output file will cycle between different states even if it is referenced
// with three different file descriptors (fd1, fd2,fd3).
//
// Here is what every instruction after the opening of the three file descriptors will do
// to the file:
// - write(fd1, "Hello,", 6); -> Hello,
// - write(fd2, "world", 6);  -> Hello,world
// - lseek(fd2, 0, SEEK_SET); -> (sets the offset to the start of the file, no content change)
// - write(fd1, "HELLO,", 6); -> HELLO,world (overwrites the first write)
// - write(fd3, "Gidday", 6); -> Giddayworld (overwrites the third write, open called indipendently)

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
    const file = file_path.?;

    const fd1 = linux.open(
        file,
        .{
            .ACCMODE = .RDWR,
            .CREAT = true,
            .TRUNC = true,
        },
        linux.S.IRUSR | linux.S.IWUSR,
    );
    if (linux.E.init(fd1) != .SUCCESS)
        std.process.exit(1);

    const fd2 = linux.dup(@intCast(fd1));
    if (linux.E.init(fd2) != .SUCCESS)
        std.process.exit(1);

    const fd3 = linux.open(file, .{ .ACCMODE = .RDWR }, 0);
    if (linux.E.init(fd3) != .SUCCESS)
        std.process.exit(1);

    defer {
        const fds = [_]usize{ fd1, fd2, fd3 };
        for (fds) |fd| {
            const closed_fd = linux.close(@intCast(fd));
            if (linux.E.init(closed_fd) != .SUCCESS)
                std.process.exit(1);
        }
    }

    var bytes_written: usize = 0;

    bytes_written = linux.write(@intCast(fd1), "Hello,", 6);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);

    bytes_written = linux.write(@intCast(fd2), "world", 5);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);

    const offset = linux.lseek(@intCast(fd2), 0, linux.SEEK.SET);
    if (linux.E.init(offset) != .SUCCESS)
        std.process.exit(1);

    bytes_written = linux.write(@intCast(fd1), "HELLO,", 6);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);

    bytes_written = linux.write(@intCast(fd3), "Gidday", 6);
    if (linux.E.init(bytes_written) != .SUCCESS)
        std.process.exit(1);
}
