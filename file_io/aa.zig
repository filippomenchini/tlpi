// This exercise is designed to demonstrate why the atomicity guaranteed by opening
// a file with the O_APPEND flag is necessary. Write a program that takes up to three
// command-line arguments:
//
// $ atomic_append filename num-bytes [x]
//
// This file should open the specified filename (creating it if necessary) and append
// num-bytes bytes to the file by using write() to write a byte at a time. By default, the
// program should open the file with the O_APPEND flag, but if a third command-line
// argument (x) is supplied, then the O_APPEND flag should be omitted, and instead the
// program should perform an lseek(fd, 0, SEEK_END) call before each write(). Run
// two instances of this program at the same time without the x argument to write
// 1 million bytes to the same file:
//
// $ atomic_append f1 1000000 & atomic_append f1 1000000
//
// Repeat the same steps, writing to a different file, but this time specifying the x
// argument:
//
// $ atomic_append f2 1000000 x & atomic_append f2 1000000 x
//
// List the sizes of the files f1 and f2 using ls –l and explain the difference.
//
// ANSWER: The O_APPEND version makes every write atomic, so all 2,000,000 bytes are written
// successfully. Without O_APPEND the program could access the same position of the file
// and overwrite its content, so data could be lost forever.

const std = @import("std");
const linux = std.os.linux;

pub fn main() !void {
    var file_path: ?[*:0]const u8 = null;
    var append_mode: bool = true;
    var bytes_to_write: ?i32 = null;

    for (std.os.argv, 0..) |arg, i| {
        if (i == 0) continue;

        if (file_path == null) {
            file_path = arg;
            continue;
        }

        if (bytes_to_write == null) {
            bytes_to_write = try std.fmt.parseInt(
                i32,
                std.mem.span(arg),
                10,
            );
        }

        if (std.mem.eql(u8, std.mem.span(arg), "x")) {
            append_mode = false;
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
            .APPEND = append_mode,
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

    var i: i32 = 0;
    while (i < bytes_to_write.?) : (i += 1) {
        if (!append_mode) {
            const offset = linux.lseek(
                @intCast(file_fd),
                0,
                linux.SEEK.END,
            );
            if (linux.E.init(offset) != .SUCCESS)
                std.process.exit(1);
        }

        const bytes_written = linux.write(
            @intCast(file_fd),
            "X",
            1,
        );
        if (linux.E.init(bytes_written) != .SUCCESS or
            bytes_written > 1)
            std.process.exit(1);
    }
}
