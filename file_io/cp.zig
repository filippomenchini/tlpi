// Write a program like cp that, when used to copy a regular file that contains holes
// (sequences of null bytes), also creates corresponding holes in the target file.

const std = @import("std");
const linux = std.os.linux;

const BUFFER_SIZE = 4096;

pub fn main() !void {
    var source_file_path: ?[*:0]const u8 = null;
    var destination_file_path: ?[*:0]const u8 = null;

    for (std.os.argv, 0..) |arg, i| {
        if (i == 0) continue;

        if (source_file_path == null) {
            source_file_path = arg;
            continue;
        }

        if (destination_file_path == null) {
            destination_file_path = arg;
            continue;
        }
    }

    if (source_file_path == null or destination_file_path == null)
        std.process.exit(1);

    const source_fd = linux.open(
        source_file_path.?,
        .{ .ACCMODE = .RDONLY },
        linux.S.IRUSR,
    );

    if (linux.E.init(source_fd) != .SUCCESS)
        std.process.exit(1);

    const destination_fd = linux.open(
        destination_file_path.?,
        .{
            .ACCMODE = .WRONLY,
            .CREAT = true,
        },
        linux.S.IRUSR | linux.S.IWUSR,
    );

    if (linux.E.init(destination_fd) != .SUCCESS)
        std.process.exit(1);

    defer {
        const closed_source = linux.close(@intCast(source_fd));
        const closed_destination = linux.close(@intCast(destination_fd));

        if (linux.E.init(closed_source) != .SUCCESS or linux.E.init(closed_destination) != .SUCCESS)
            std.process.exit(1);
    }

    var buffer: [BUFFER_SIZE]u8 = undefined;
    while (true) {
        const bytes_read = linux.read(
            @intCast(source_fd),
            &buffer,
            BUFFER_SIZE,
        );

        if (bytes_read == 0) break; //EOF
        if (linux.E.init(bytes_read) != .SUCCESS or bytes_read > BUFFER_SIZE)
            std.process.exit(1);

        var is_hole: bool = false;
        for (buffer[0..bytes_read]) |byte| {
            if (byte != 0) break;
            is_hole = true;
        }

        if (is_hole) {
            const offset = linux.lseek(@intCast(destination_fd), @intCast(bytes_read), linux.SEEK.CUR);
            if (linux.E.init(offset) != .SUCCESS)
                std.process.exit(1);
            continue;
        }

        var total_written: usize = 0;
        while (total_written < bytes_read) {
            const bytes_written = linux.write(
                @intCast(destination_fd),
                &buffer,
                bytes_read - total_written,
            );

            if (linux.E.init(bytes_written) != .SUCCESS or bytes_written > (bytes_read - total_written))
                std.process.exit(1);

            total_written += bytes_written;
        }
    }
}
