// The tee command reads its standard input until end-of-file, writing a copy of the input
// to standard output and to the file named in its command-line argument.
// Implement tee using I/O system calls. By default, tee overwrites any existing file with
// the given name. Implement the –a command-line option (tee –a file), which causes tee
// to append text to the end of a file if it already exists.

const std = @import("std");
const linux = std.os.linux;

const BUFFER_SIZE = 4096;

pub fn main() !void {
    var file_path: ?[*:0]const u8 = null;
    var append_mode = false;

    for (std.os.argv, 0..) |arg, i| {
        if (i == 0) continue;

        if (std.mem.eql(u8, std.mem.span(arg), "-a")) {
            append_mode = true;
            continue;
        }

        if (file_path == null) {
            file_path = arg;
            continue;
        }
    }

    const file_fd = linux.open(
        file_path.?,
        .{
            .ACCMODE = .WRONLY,
            .CREAT = true,
            .APPEND = append_mode,
        },
        linux.S.IRUSR | linux.S.IWUSR,
    );
    if (linux.E.init(file_fd) != linux.E.SUCCESS)
        std.process.exit(1);
    defer {
        const close_status = linux.close(@intCast(file_fd));
        if (linux.E.init(close_status) != linux.E.SUCCESS)
            std.process.exit(1);
    }

    const fds: [2]linux.fd_t = [2]linux.fd_t{
        linux.STDOUT_FILENO,
        @intCast(file_fd),
    };

    var buffer: [BUFFER_SIZE]u8 = undefined;
    while (true) {
        const bytes_read = linux.read(
            linux.STDIN_FILENO,
            &buffer,
            BUFFER_SIZE,
        );

        if (bytes_read == 0) break; // EOF
        if (linux.E.init(bytes_read) != linux.E.SUCCESS)
            std.process.exit(1);

        if (bytes_read > BUFFER_SIZE) {
            std.process.exit(1);
        }

        var total_written: usize = 0;
        for (fds) |fd| {
            total_written = try writeToFd(
                fd,
                &buffer,
                bytes_read,
            );
        }
    }
}

pub fn writeToFd(
    fd: linux.fd_t,
    buf: []u8,
    count: usize,
) error{WriteError}!usize {
    var total_written: usize = 0;
    while (total_written < count) {
        const bytes_written = linux.write(
            fd,
            buf[total_written..].ptr,
            count - total_written,
        );
        if (linux.E.init(bytes_written) != linux.E.SUCCESS)
            std.process.exit(1);

        if (bytes_written > (count - total_written)) {
            return error.WriteError;
        }

        total_written += bytes_written;
    }

    return total_written;
}
