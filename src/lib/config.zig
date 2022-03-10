const std = @import("std");

pub const ConfigParser = struct {
    root: ConfigNode,

    pub fn new(alloc: std.mem.Allocator) @This() {
        return .{
            .root = ConfigNode.new(),
        };
    }
};

pub const ConfigNode = struct {
    const children_type = std.AutoArrayHashMap([]const u8, *ConfigNode);
    children: children_type,

    pub fn new(alloc: std.mem.Allocator) @This() {
        return .{
            .children = children_type.init(alloc),
        };
    }
};