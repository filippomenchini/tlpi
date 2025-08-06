const std = @import("std");

const BUFFER_SIZE = 4096;

pub fn main() !void {
    var buffer: [BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = std.os.linux.read(
            std.os.linux.STDIN_FILENO,
            &buffer,
            BUFFER_SIZE,
        );

        if (bytes_read == 0) break; // EOF

        if (bytes_read > BUFFER_SIZE) {
            std.process.exit(1);
        }

        var total_written: usize = 0;
        while (total_written < bytes_read) {
            const bytes_written = std.os.linux.write(
                std.os.linux.STDOUT_FILENO,
                buffer[total_written..].ptr,
                bytes_read - total_written,
            );

            if (bytes_written > (bytes_read - total_written)) {
                std.process.exit(1);
            }

            total_written += bytes_written;
        }
    }
}
