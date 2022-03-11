const std = @import("std");
const clap = @import("clap");
const lib = @import("lib/lib.zig");

const config = lib.config;

const debug = std.debug;
const io = std.io;

pub fn main() anyerror!void {
    var parser = config.ConfigParser.new(std.heap.ArenaAllocator.init(std.heap.page_allocator).allocator());
    parser.get("Vêtements").set("Chaussure", "Sôssure");
    parser.get("Vêtements").set("Haut", "Veston trécher");
    parser.get("Accessoires").set("Sakamain", "Pochette élégante");
    parser.write(std.io.getStdOut().writer());
    _ = parser;
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("commit     Commit all changes") catch unreachable,
    };
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return;
    };
    defer res.deinit();

    for (res.positionals()) |pos|
        debug.print("{s}\n", .{pos});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
