const std = @import("std");

const orca = @cImport({
    @cInclude("orca.h");
});

var frameSize: orca.oc_vec2 = .{ .c = .{ 1200, 838 } };

var surface: orca.oc_surface = undefined;
var canvas: orca.oc_canvas = undefined;
var ui: orca.oc_ui_context = undefined;

var fontRegular: orca.oc_font = undefined;
var fontBold: orca.oc_font = undefined;

var textArena = std.mem.zeroes(orca.oc_arena);
var logArena = std.mem.zeroes(orca.oc_arena);

var logLines: orca.oc_str8_list = undefined;

inline fn orca_string(slice: []const u8) orca.oc_str8 {
    return .{
        .ptr = @constCast(slice.ptr),
        .len = slice.len,
    };
}

export fn oc_on_init() callconv(.C) void {
    {
        const src = @src();
        orca.oc_log_ext(
            orca.OC_LOG_LEVEL_ERROR,
            src.file.ptr,
            src.fn_name.ptr,
            @intCast(src.line),
            "Hello World!\n",
        );
    }

    orca.oc_log_ext(0, "", @src().fn_name.ptr, @intCast(@src().line), ":^)\n");

    orca.oc_window_set_title(orca_string("Orca UI Demo"));
    orca.oc_window_set_size(frameSize);

    surface = orca.oc_surface_canvas();
    canvas = orca.oc_canvas_create();
    orca.oc_ui_init(&ui);

    const fonts: [2]*orca.oc_font = .{ &fontRegular, &fontBold };
    const names: [2][]const u8 = .{ "/OpenSans-Regular.ttf", "/OpenSans-Bold.ttf" };
    for (fonts, names) |font, name| {
        var scratch: orca.oc_arena_scope = orca.oc_scratch_begin();
        defer orca.oc_scratch_end(scratch);

        const file: orca.oc_file = orca.oc_file_open(
            orca_string(name),
            orca.OC_FILE_ACCESS_READ,
            0,
        );
        defer orca.oc_file_close(file);

        if (orca.oc_file_last_error(file) != orca.OC_IO_OK) {
            const src = @src();
            orca.oc_log_ext(
                orca.OC_LOG_LEVEL_ERROR,
                src.file.ptr,
                src.fn_name.ptr,
                @intCast(src.line),
                "Couldn't open file %s\n",
                name.ptr,
            );
        }

        const size: u64 = orca.oc_file_size(file);
        const buffer: [*]u8 = @ptrCast(orca.oc_arena_push(scratch.arena, size).?);
        _ = orca.oc_file_read(file, size, buffer); //TODO: error handling?

        const ranges: [5]orca.oc_unicode_range = .{
            orca.OC_UNICODE_BASIC_LATIN,
            orca.OC_UNICODE_C1_CONTROLS_AND_LATIN_1_SUPPLEMENT,
            orca.OC_UNICODE_LATIN_EXTENDED_A,
            orca.OC_UNICODE_LATIN_EXTENDED_B,
            orca.OC_UNICODE_SPECIALS,
        };

        font.* = orca.oc_font_create_from_memory(
            orca.oc_str8_from_buffer(size, buffer),
            5,
            @constCast(&ranges),
        );
    }

    orca.oc_arena_init(&textArena);
    orca.oc_arena_init(&logArena);
    orca.oc_list_init(&logLines.list);
}

export fn oc_on_raw_event(event: *orca.oc_event) void {
    orca.oc_ui_process_event(event);
}

export fn oc_on_resize(width: u32, height: u32) void {
    frameSize.unnamed_0.x = @floatFromInt(width);
    frameSize.unnamed_0.y = @floatFromInt(height);
}

export fn oc_on_frame_refresh() void {
    var scratch: orca.oc_arena_scope = orca.oc_scratch_begin();

    var defaultStyle: orca.oc_ui_style = .{ .font = fontRegular };
    var defaultMask: orca.oc_ui_style_mask = orca.OC_UI_STYLE_FONT;

    {
        orca.oc_ui_begin_frame(frameSize, &defaultStyle, defaultMask);
        defer orca.oc_ui_end_frame();

        // Menu bar
        {
            orca.oc_ui_menu_bar_begin("menu_bar");
            defer orca.oc_ui_menu_bar_end();

            {
                orca.oc_ui_menu_begin("File");
                defer orca.oc_ui_menu_end();

                if (orca.oc_ui_menu_button("Quit").pressed) {
                    orca.oc_request_quit();
                }
            }
        }

        var style = std.mem.zeroes(orca.oc_ui_style);
        style.size.unnamed_0.width = .{ .kind = orca.OC_UI_SIZE_PIXELS, .value = 305 };
        style.size.unnamed_0.height = .{ .kind = orca.OC_UI_SIZE_TEXT };

        orca.oc_ui_style_next(&style, orca.OC_UI_STYLE_SIZE);

        const Static = struct {
            var text = orca_string("Text box");
        };

        var res: orca.oc_ui_text_box_result = orca.oc_ui_text_box("text", scratch.arena, Static.text);

        if (res.changed) {
            orca.oc_arena_clear(&textArena);
            Static.text = orca.oc_str8_push_copy(&textArena, res.text);
        }
        if (res.accepted) {
            const src = @src();
            orca.oc_log_ext(
                orca.OC_LOG_LEVEL_ERROR,
                src.file.ptr,
                src.fn_name.ptr,
                @intCast(src.line),
                \\Entered Text: "%s"
                \\
            ,
                Static.text.ptr,
            );
        }
    }

    _ = orca.oc_canvas_select(canvas);
    orca.oc_surface_select(surface);

    orca.oc_set_color(ui.theme[0].bg0);
    orca.oc_clear();

    orca.oc_ui_draw();
    orca.oc_render(canvas);
    orca.oc_surface_present(surface);
}
