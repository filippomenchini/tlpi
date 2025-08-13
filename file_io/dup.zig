// Implement dup() and dup2() using fcntl() and, where necessary, close(). (You may
// ignore the fact that dup2() and fcntl() return different errno values for some error
// cases.) For dup2(), remember to handle the special case where oldfd equals newfd. In
// this case, you should check whether oldfd is valid, which can be done by, for example,
// checking if fcntl(oldfd, F_GETFL) succeeds. If oldfd is not valid, then the function
// should return –1 with errno set to EBADF.

const std = @import("std");
const linux = std.os.linux;

pub fn main() !void {
    var newfd: usize = dup(linux.STDOUT_FILENO);
    if (linux.E.init(newfd) != .SUCCESS)
        std.process.exit(1);

    std.debug.print(
        "dup result: {d} -> {d}\n",
        .{ linux.STDOUT_FILENO, newfd },
    );

    var closed_newfd: usize = linux.close(@intCast(newfd));
    if (linux.E.init(closed_newfd) != .SUCCESS)
        std.process.exit(1);

    newfd = dup2(linux.STDOUT_FILENO, 100);
    if (linux.E.init(newfd) != .SUCCESS)
        std.process.exit(1);

    std.debug.print(
        "dup2 result: {d} -> {d}\n",
        .{ linux.STDOUT_FILENO, newfd },
    );

    closed_newfd = linux.close(@intCast(newfd));
    if (linux.E.init(closed_newfd) != .SUCCESS)
        std.process.exit(1);
}

fn dup(oldfd: linux.fd_t) usize {
    return linux.fcntl(oldfd, linux.F.DUPFD, @intCast(oldfd));
}

fn dup2(oldfd: linux.fd_t, newfd: linux.fd_t) usize {
    const oldfd_check = linux.fcntl(oldfd, linux.F.GETFD, 0);
    if (linux.E.init(oldfd_check) != .SUCCESS)
        return @intFromEnum(linux.E.BADF);

    if (oldfd == newfd) return @intCast(newfd);

    _ = linux.close(newfd);
    return linux.fcntl(oldfd, linux.F.DUPFD, @intCast(newfd));
}
