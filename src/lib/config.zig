const std = @import("std");

const debug = std.debug;

pub const ConfigError = error{ IllFormedValue, OrphanValue };

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
            writer.print("[{s}]\n", .{t}) catch {};
            this.children.getPtr(t).?.write(writer);
        }
    }

    pub fn write_file(this: *@This(), path: []const u8) void {
        var file = std.fs.openFileAbsolute(path, .{ .write = true }) catch unreachable;
        this.write(file.writer());
    }

    pub fn read(this: *@This(), reader: anytype) ConfigError!void {
        const to_trim = [_]u8{ '\t', '\n', ' ' };
        const to_trimm_header = [_]u8{ '[', ']', '\t', '\n', ' ' };

        const to_trim_key = [_]u8{ '\t', ' ' };
        const to_trim_value = [_]u8{ '\t', '\n', ' ', '=', '\"' };
        const to_trim_quote = [_]u8{'\"'};

        //var under_slices = std.ArrayList([]const u8).init(this.alloc);
        var last_header: ?*Title = null;

        while (true) {
            if (reader.readUntilDelimiterAlloc(this.alloc, '\n', 256)) |line| {
                var trimmed = std.mem.trim(u8, line[0..line.len], to_trim[0..]);
                if (trimmed.len > 0 and trimmed[0] == '[') {
                    var title = std.mem.trim(u8, line[0..line.len], to_trimm_header[0..]);
                    last_header = this.get(title);
                } else if (trimmed.len > 0) {
                    // Try and see if an allocation is possible
                    var equals_pos = std.mem.indexOfScalar(u8, trimmed, '=');
                    if (equals_pos) |p| {
                        var key = std.mem.trim(u8, trimmed[0..p], to_trim_key[0..]);
                        var val_with_quote = std.mem.trim(u8, trimmed[p..], to_trim_value[0..]);
                        var val = std.mem.trim(u8, val_with_quote, to_trim_quote[0..]);
                        if (last_header) |header| {
                            header.set(key, val);
                        } else {
                            return ConfigError.OrphanValue;
                        }
                    } else {
                        return ConfigError.IllFormedValue;
                    }
                }
            } else |_| {
                break;
            }
        }
    }

    pub fn read_file(this: *@This(), path: []const u8) anyerror!void {
        var file = try std.fs.openFileAbsolute(path, .{
            .read = true,
        });
        return this.read(file.reader());
    }

    pub fn free(this: *@This()) void {
        for (this.children.keys()) |k| {
            this.children.getPtr(k).?.children.deinit();
        }
        this.children.deinit();
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
