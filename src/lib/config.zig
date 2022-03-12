const std = @import("std");

pub const ConfigParser = struct {
    const children_type = std.StringArrayHashMap(Title);
    children: children_type,
    alloc: std.mem.Allocator,

    pub fn new(alloc: std.mem.Allocator) @This() {
        return .{
            .children = children_type.init(alloc),
            .alloc = alloc,
        };
    }
    pub fn get_strict(this: *@This(), key: []const u8) ?*Title {
        return this.children.getPtr(key);
    }
    pub fn add(this: *@This(), key: []const u8) ?*Title {
        if (this.children.contains(key)) {
            return null;
        } else {
            var title = Title.new(this.alloc);
            this.children.put(key, title) catch {};
            return this.children.getPtr(key);
        }
    }
    pub fn get(this: *@This(), key: []const u8) *Title {
        if (this.children.contains(key)) {
            return this.get_strict(key).?;
        } else {
            return this.add(key).?;
        }
    }

    pub fn write(this: *@This(), writer: anytype) void {
        for (this.children.keys()) |t| {
            writer.print("[{s}]\n", .{ t }) catch {};
            this.children.getPtr(t).?.write(writer);
        }
    }

    pub fn write_file(this: *@This(), path: []const u8) void {
        var file = std.fs.openFileAbsolute(path, .{ .write = true }) catch unreachable;
        this.write(file.writer());
    }

    pub fn read(this: *@This(), reader: anytype) void {
        _ = this;
        _ = reader;
    }
};

pub const Title = struct {
    const children_type = std.StringArrayHashMap([]const u8);
    children: children_type,

    pub fn new(alloc: std.mem.Allocator) @This() {
        return .{
            .children = children_type.init(alloc),
        };
    }
    pub fn get(this: *@This(), key: []const u8) ?[]const u8 {
        return this.children.get(key);
    }
    pub fn set(this: *@This(), key: []const u8, val: []const u8) void {
        this.children.put(key, val) catch {};
    }
    pub fn write(this: *@This(), writer: anytype) void {
        for (this.children.keys()) |t| {
            writer.print("{s} = \"{s}\" \n", .{ t, this.get(t).? }) catch {};
        }
        writer.writeByte('\n') catch {};
    }
};
