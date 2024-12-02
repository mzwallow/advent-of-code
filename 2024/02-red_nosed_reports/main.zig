const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var safe_reports: u32 = 0;
    var fault_safe_reports: u32 = 0;

    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // print("{s}\n", .{line});

        var levels = ArrayList(i16).init(allocator);
        defer levels.deinit();

        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (iter.next()) |level_str| {
            try levels.append(try std.fmt.parseUnsigned(i16, level_str, 10));
        }

        var is_inc = false;
        var is_safe = false;

        for (levels.items, 0..) |level, i| {
            const diff: i16 = level - levels.items[i + 1];

            if (i == 0 and diff < 0) is_inc = true;

            if ((is_inc and (diff >= 0 or @abs(diff) > 3)) or (!is_inc and (diff <= 0 or diff > 3))) {
                break;
            }

            if (i == levels.items.len - 2) {
                is_safe = true;
                break;
            }
        }

        if (is_safe) {
            safe_reports += 1;
        } else {
            // print("{s}\n", .{line});
            var cur: usize = 0;

            var fault_safe = false;

            outer: while (cur < levels.items.len) : (cur += 1) {
                var tmp_levels = try levels.clone();
                defer tmp_levels.deinit();

                _ = tmp_levels.orderedRemove(cur);

                is_inc = false;

                for (tmp_levels.items, 0..) |level, i| {
                    const diff: i16 = level - tmp_levels.items[i + 1];

                    if (i == 0 and diff < 0) is_inc = true;

                    if ((is_inc and (diff >= 0 or @abs(diff) > 3)) or (!is_inc and (diff <= 0 or diff > 3))) {
                        continue :outer;
                    }

                    if (i == tmp_levels.items.len - 2) {
                        fault_safe = true;
                        break :outer;
                    }
                }
            }

            if (fault_safe) fault_safe_reports += 1;
        }
    }

    print("Safe reports: {d}\n", .{safe_reports});
    print("Fault-torelant safe reports: {d}\n", .{fault_safe_reports});
    print("Total: {d}\n", .{safe_reports + fault_safe_reports});
}
