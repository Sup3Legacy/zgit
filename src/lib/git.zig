const std = @import("std");
const fs = std.fs;

const ConfigParser = @import("config.zig").ConfigParser;

pub const Repository = struct {
    workTree: []const u8,
    gitDir: []const u8,
    conf: ConfigParser,

    allocator: std.mem.Allocator,

    pub fn init(this: *@This(), path: []const u8, zapCheck: bool) anyerror!void {
        this.workTree = path;
        var gitDir = [_][]const u8{ path, ".git" };
        this.gitDir = try fs.path.join(this.allocator, gitDir[0..]);
        this.conf = ConfigParser.new(this.allocator);

        if (zapCheck) {
            return;
        }

        //try fs.openDirAbsolute(this.gitDir, .{});
        var confFile = [_][]const u8{ path, ".git", "conf.ini" };
        if (this.conf.read_file(try fs.path.join(this.allocator, confFile[0..]))) {} else |_| {
            _ = try fs.createFileAbsolute(try fs.path.join(this.allocator, confFile[0..]), .{});
        }

        // Check version
        var i = this.conf.get("core").get("repositoryformatversion") orelse @panic("...");
        var version = try std.fmt.parseInt(usize, i, 10);
        try std.testing.expectEqual(version, 0);
    }

    fn defaultConfig(alloc: std.mem.Allocator) ConfigParser {
        var config = ConfigParser.new(alloc);
        config.get("core").set("repositoryformatversion", "0");
        config.get("core").set("filemode", "false");
        config.get("core").set("bare", "false");

        return config;
    }

    fn openGitFile(this: *@This(), path: []const u8) !fs.File {
        var paths = [_][]const u8{ this.gitDir, path };
        var absolute_path = try fs.path.join(this.allocator, paths[0..]);
        _ = fs.createFileAbsolute(absolute_path, .{}) catch {};
        return fs.openFileAbsolute(absolute_path, .{
            .read = true,
            .write = true,
        });
    }

    pub fn new(path: []const u8, allocator: std.mem.Allocator) anyerror!@This() {
        var repo: @This() = undefined;
        repo.allocator = allocator;
        try repo.init(path, true);

        if (fs.accessAbsolute(repo.workTree, .{})) |_| {
            // File/Directory exists
            if (fs.openDirAbsolute(path, .{ .iterate = true })) |*dir| {
                var iter = dir.iterate();
                var dirSize: u8 = 0;
                while (iter.next() catch null) |_| {
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
            } else |_| {
                // It is a file
                @panic("Path exists and is a file");
            }
        } else |_| {
            try fs.makeDirAbsolute(repo.workTree);
        }

        var workTree = fs.openDirAbsolute(path, .{}) catch unreachable;

        // Create the subdirectories
        try workTree.makeDir(".git");
        try workTree.makeDir(".git/objects");
        try workTree.makeDir(".git/refs");
        try workTree.makeDir(".git/refs/heads");
        try workTree.makeDir(".git/refs/tags");

        var description = try repo.openGitFile("description");
        _ = try description.write("Unnamed repository; edit this file 'description' to name the repository.\n");
        description.close();

        var head = try repo.openGitFile("HEAD");
        _ = try head.write("ref: refs/heads/master\n");
        head.close();

        var config_parser = Repository.defaultConfig(allocator);
        var config = try repo.openGitFile("config");
        config_parser.write(config.writer());
        config.close();

        return repo;
    }
};
