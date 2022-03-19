const std = @import("std");
const fs = std.fs;

const ConfigParser = @import("config.zig").ConfigParser;

const Repository = struct {
    workTree: []const u8,
    gitDir: []const u8,
    conf: ConfigParser,

    allocator: std.mem.Allocator,

    pub fn init(this: *@This(), path: []const u8, zapCheck: bool) anyerror!void {
        this.workTree = path;
        var gitDir = [_][]const u8{ path, ".git" };
        this.gitDir = fs.path.join(allocator, gitDir);
        this.conf = ConfigParser.new(this.allocator);

        if (zapCheck) {
            return;
        }

        try fs.openDirAbsolute(this.gitDir, .{});
        var confFile = [_][]const u8{ path, ".git", "conf.ini" };
        this.conf.read_file(fs.path.join(allocator, confFile)) catch |_| fs.createFileAbsolute(fs.path.join(allocator, confFile), .{});

        // Check version
        i = try this.conf.get("core").get("repositoryformatversion");
        var version = try std.fmt.parseInt(usize, i, 10);
        try std.testing.expectEqual(version, 0);
    }

    pub fn default_config(alloc: std.mem.Allocator) ConfigParser {
        var config = ConfigParser.new(alloc);
        config.get("core").set("repositoryformatversion", "0");
        config.get("core").set("filemode", "false");
        config.get("core").set("bare", "false");

        return config;
    }

    pub fn new(path: []const u8) anyerror!@This() {
        var repo: @This() = undefined;
        try repo.init(path, true);

        if (fs.accessAbsolute(repo.worktree, .{})) |_| {
            // File/Directory exists
            if (fs.openDirAbsolute(path, .{})) |dir| {
                var iter = dir.iterate();
                var dirSize: u8 = 0;
                while (iter.next()) |_| {
                    dirSize += 1;
                    if (dirSize > 2) {
                        break;
                    }
                }
                if (dirSize > 2) {
                    @panic("Paths is a non-empty directory.");
                } else {
                    // Okay, empty directory
                    dir.close();
                }
            } else {
                // It is a file
                @panic("Path exists and is a file");
            }
        } else {
            try fs.makeDirAbsolute(repo.workTree);
        }

        var workTree = fs.openDirAbsolute(path, .{}) catch |_| unreachable;

        // Create the subdirectories
        workTree.makeDir(".git") catch unreachable;
        workTree.makedir(".git/objects") catch unreachable;
        workTree.makedir(".git/refs") catch unreachable;
        workTree.makedir(".git/refs/heads") catch unreachable;
        workTree.makedir(".git/refs/tags") catch unreachable;


    }
};
