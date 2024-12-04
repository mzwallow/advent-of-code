const std = @import("std");
const print = std.debug.print;

const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var rows = ArrayList([]u8).init(allocator);
    defer {
        for (rows.items) |line| allocator.free(line);
        rows.deinit();
    }

    var buf: [256]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const new_line = try allocator.alloc(u8, line.len);
        @memcpy(new_line, line);
        try rows.append(new_line);
    }

    try partOne(&rows);
    try partTwo(&rows);
}

fn partOne(rows: *ArrayList([]u8)) !void {
    var count: usize = 0;

    var i: usize = 0;
    while (i < rows.items.len) : (i += 1) {
        var tmp_i: isize = @intCast(i);
        _ = &tmp_i;

        // print("i: {d}\n", .{tmp_i});

        var j: usize = 0;
        while (j < rows.items[i].len) : (j += 1) {
            var tmp_j: isize = @intCast(j);
            _ = &tmp_j;

            // print("j: {d}\n", .{tmp_j});

            if (rows.items[i][j] == 'X') {
                // Right
                if (tmp_j + 3 < rows.items[i].len) {
                    if (rows.items[i][j + 1] == 'M' and
                        rows.items[i][j + 2] == 'A' and
                        rows.items[i][j + 3] == 'S')
                        count += 1;
                }

                // Left
                if (tmp_j - 3 >= 0) {
                    if (rows.items[i][j - 1] == 'M' and
                        rows.items[i][j - 2] == 'A' and
                        rows.items[i][j - 3] == 'S')
                        count += 1;
                }

                // Top
                if (tmp_i - 3 >= 0) {
                    if (rows.items[i - 1][j] == 'M' and
                        rows.items[i - 2][j] == 'A' and
                        rows.items[i - 3][j] == 'S')
                        count += 1;
                }

                // Bottom
                if (tmp_i + 3 < rows.items.len) {
                    if (rows.items[i + 1][j] == 'M' and
                        rows.items[i + 2][j] == 'A' and
                        rows.items[i + 3][j] == 'S')
                        count += 1;
                }

                // Top-right
                if (tmp_i - 3 >= 0 and tmp_j + 3 < rows.items[i].len) {
                    if (rows.items[i - 1][j + 1] == 'M' and
                        rows.items[i - 2][j + 2] == 'A' and
                        rows.items[i - 3][j + 3] == 'S')
                        count += 1;
                }

                // Top-left
                if (tmp_i - 3 >= 0 and tmp_j - 3 >= 0) {
                    if (rows.items[i - 1][j - 1] == 'M' and
                        rows.items[i - 2][j - 2] == 'A' and
                        rows.items[i - 3][j - 3] == 'S')
                        count += 1;
                }

                // Bottom-right
                if (tmp_i + 3 < rows.items.len and tmp_j + 3 < rows.items[i].len) {
                    if (rows.items[i + 1][j + 1] == 'M' and
                        rows.items[i + 2][j + 2] == 'A' and
                        rows.items[i + 3][j + 3] == 'S')
                        count += 1;
                }

                // Bottom-left
                if (tmp_i + 3 < rows.items.len and tmp_j - 3 >= 0) {
                    if (rows.items[i + 1][j - 1] == 'M' and
                        rows.items[i + 2][j - 2] == 'A' and
                        rows.items[i + 3][j - 3] == 'S')
                        count += 1;
                }
            }
        }
    }

    print("Part 1: {d}\n", .{count});
}

fn partTwo(rows: *ArrayList([]u8)) !void {
    var count: usize = 0;

    var i: usize = 0;
    while (i < rows.items.len) : (i += 1) {
        var tmp_i: isize = @intCast(i);
        _ = &tmp_i;

        var j: usize = 0;
        while (j < rows.items[i].len) : (j += 1) {
            var tmp_j: isize = @intCast(j);
            _ = &tmp_j;

            if (rows.items[i][j] == 'A') {
                // Top-left and Bottom-right
                // and
                // Top-right and Bottom-left
                if ((tmp_i - 1 >= 0 and tmp_j - 1 >= 0) and (tmp_i + 1 < rows.items.len and tmp_j + 1 < rows.items[i].len) and
                    (tmp_i - 1 >= 0 and tmp_j + 1 < rows.items[i].len) and (tmp_i + 1 < rows.items.len and tmp_j - 1 >= 0))
                {
                    // Top-left and Bottom-right
                    // and
                    // Top-right and Bottom-left
                    if (((rows.items[i - 1][j - 1] == 'M' and rows.items[i + 1][j + 1] == 'S') or
                        (rows.items[i - 1][j - 1] == 'S' and rows.items[i + 1][j + 1] == 'M')) and
                        ((rows.items[i - 1][j + 1] == 'M' and rows.items[i + 1][j - 1] == 'S') or
                        (rows.items[i - 1][j + 1] == 'S' and rows.items[i + 1][j - 1] == 'M')))
                        count += 1;
                }
            }
        }
    }

    print("Part 2: {d}\n", .{count});
}
