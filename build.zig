const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const optimize = b.standardOptimizeOption(.{});
    const orca_dep = b.dependency("orca", .{});

    const app = b.addSharedLibrary(.{
        .name = "module",
        .target = .{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .cpu_features_add = std.Target.wasm.featureSet(&.{.bulk_memory}),
        },
        .optimize = optimize,
        .root_source_file = .{ .path = "src/main.zig" },
    });
    app.rdynamic = true;
    app.disable_sanitize_c = true;
    app.defineCMacro("__ORCA__", null);
    app.addSystemIncludePath(orca_dep.path("src/libc-shim/include"));
    app.addIncludePath(orca_dep.path("src"));
    app.addIncludePath(orca_dep.path("src/ext"));

    const cflags: []const []const u8 = &.{
        "-O2", // works around undefined symbol on __fpclassifyl
    };
    app.addCSourceFile(.{
        .file = orca_dep.path("src/orca.c"),
        .flags = cflags,
    });
    for (libc_shim_files) |libc_shim_file| {
        app.addCSourceFile(.{
            .file = orca_dep.path(libc_shim_file),
            .flags = cflags,
        });
    }

    const orca_exe = b.addExecutable(.{
        .name = "orca",
        .target = .{},
        .optimize = .ReleaseFast,
    });
    // TODO: add the build.zig logic for building the orca tool itself
    // if orca upstream used build.zig then we could just grab the exe from there
    const run_orca = b.addRunArtifact(orca_exe);
    run_orca.addArgs(&.{ "bundle", "--orca-dir" });
    run_orca.addFileArg(orca_dep.path("."));
    run_orca.addArgs(&.{ "--name", "UI", "--resource-dir", "data" });
    run_orca.addFileArg(app.getEmittedBin());

    // TODO what is the output of orca command? for now we will just
    // run it in the source dir and let it poop something out
    b.getInstallStep().dependOn(&run_orca.step);
}

const libc_shim_files: []const []const u8 = &.{
    "src/libc-shim/src/__cos.c",
    "src/libc-shim/src/__cosdf.c",
    "src/libc-shim/src/__errno_location.c",
    "src/libc-shim/src/__math_divzero.c",
    "src/libc-shim/src/__math_divzerof.c",
    "src/libc-shim/src/__math_invalid.c",
    "src/libc-shim/src/__math_invalidf.c",
    "src/libc-shim/src/__math_oflow.c",
    "src/libc-shim/src/__math_oflowf.c",
    "src/libc-shim/src/__math_uflow.c",
    "src/libc-shim/src/__math_uflowf.c",
    "src/libc-shim/src/__math_xflow.c",
    "src/libc-shim/src/__math_xflowf.c",
    "src/libc-shim/src/__rem_pio2.c",
    "src/libc-shim/src/__rem_pio2_large.c",
    "src/libc-shim/src/__rem_pio2f.c",
    "src/libc-shim/src/__sin.c",
    "src/libc-shim/src/__sindf.c",
    "src/libc-shim/src/__tan.c",
    "src/libc-shim/src/__tandf.c",
    "src/libc-shim/src/abs.c",
    "src/libc-shim/src/acos.c",
    "src/libc-shim/src/acosf.c",
    "src/libc-shim/src/asin.c",
    "src/libc-shim/src/asinf.c",
    "src/libc-shim/src/atan.c",
    "src/libc-shim/src/atan2.c",
    "src/libc-shim/src/atan2f.c",
    "src/libc-shim/src/atanf.c",
    "src/libc-shim/src/cbrt.c",
    "src/libc-shim/src/cbrtf.c",
    "src/libc-shim/src/ceil.c",
    "src/libc-shim/src/cos.c",
    "src/libc-shim/src/cosf.c",
    "src/libc-shim/src/exp.c",
    "src/libc-shim/src/exp2f_data.c",
    "src/libc-shim/src/exp2f_data.h",
    "src/libc-shim/src/exp_data.c",
    "src/libc-shim/src/exp_data.h",
    "src/libc-shim/src/expf.c",
    "src/libc-shim/src/fabs.c",
    "src/libc-shim/src/fabsf.c",
    "src/libc-shim/src/floor.c",
    "src/libc-shim/src/fmod.c",
    "src/libc-shim/src/libm.h",
    "src/libc-shim/src/log.c",
    "src/libc-shim/src/log2.c",
    "src/libc-shim/src/log2_data.c",
    "src/libc-shim/src/log2_data.h",
    "src/libc-shim/src/log2f.c",
    "src/libc-shim/src/log2f_data.c",
    "src/libc-shim/src/log2f_data.h",
    "src/libc-shim/src/log_data.c",
    "src/libc-shim/src/log_data.h",
    "src/libc-shim/src/logf.c",
    "src/libc-shim/src/logf_data.c",
    "src/libc-shim/src/logf_data.h",
    "src/libc-shim/src/pow.c",
    "src/libc-shim/src/pow_data.h",
    "src/libc-shim/src/powf.c",
    "src/libc-shim/src/powf_data.c",
    "src/libc-shim/src/powf_data.h",
    "src/libc-shim/src/scalbn.c",
    "src/libc-shim/src/sin.c",
    "src/libc-shim/src/sinf.c",
    "src/libc-shim/src/sqrt.c",
    "src/libc-shim/src/sqrt_data.c",
    "src/libc-shim/src/sqrt_data.h",
    "src/libc-shim/src/sqrtf.c",
    "src/libc-shim/src/string.c",
    "src/libc-shim/src/tan.c",
    "src/libc-shim/src/tanf.c",
};
