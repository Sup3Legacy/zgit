const std = @import("std");
const clap = @import("clap");
const lib = @import("lib.zig");

pub const Flags = struct {
    bare: bool,
    all: bool,
};

pub const OptionsType = union(enum) {
    clone: []const u8,
    init: []const u8,
    fetch,
    pull,
    push,
    add,
    branch,
    commit,
};

pub const Options = struct {
    option_type: OptionsType,
    flags: Flags,
    loc: ?[]const u8,
};

pub fn collectArgs(args: anytype) ?Options {
    var options: Options = undefined;
    if (args.flag("--bare"))
        options.flags.bare = true;
    if (args.flag("--all"))
        options.flags.all = true;

    var positionals = args.positionals();

    if (positionals.len == 0)
        return null;

    if (std.mem.eql(u8, positionals[0], "init")) {
        std.debug.print("Resolved Git init\n", .{});
        if (positionals.len == 2) {
            options.option_type = .{ .init = positionals[1] };
        } else {
            @panic("Two arguments needed in `git init`.");
        }
    }

    return options;
}

pub fn performGitAction(options: Options, allocator: std.mem.Allocator) !void {
    switch (options.option_type) {
        OptionsType.init => |path| {
            var paths = [_][]const u8 {path};
            var resolved_path = try std.fs.path.resolvePosix(allocator, paths[0..]);
            std.debug.print("Resolved path: {s}\n", .{ resolved_path });
            _ = try lib.git.Repository.new(resolved_path, allocator);
        },
        else => {
            @panic("Unknown Git command.");
        },
    }
}
