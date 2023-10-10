const std = @import("std");
const orca_build = @import("orca");

pub fn build(b: *std.build.Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const orca_dep = b.dependency("orca", .{});

    const app = orca_build.addApp(b, orca_dep, .{
        .name = "UIZ",
        .resource_dir = .{ .path = "data" },
        .optimize = optimize,
        .root_source_file = .{ .path = "src/main.zig" },
    });

    b.installDirectory(.{
        .source_dir = app,
        .install_dir = .prefix,
        .install_subdir = "",
    });
}
