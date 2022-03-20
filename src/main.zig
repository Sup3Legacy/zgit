const std = @import("std");
const clap = @import("clap");
const lib = @import("lib/lib.zig");

const config = lib.config;

const debug = std.debug;
const io = std.io;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("--bare   Bare repository") catch unreachable,
        clap.parseParam("--all   All") catch unreachable,
        clap.parseParam("<POS>...") catch unreachable,
    };
    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer args.deinit();

    if (lib.cli.collectArgs(args)) |options|
        lib.cli.performGitAction(options, alloc) catch |err| {
            debug.print("Error encountered: {}\n", .{err});
            try clap.help(std.io.getStdErr().writer(), params[0..]);
        };
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
