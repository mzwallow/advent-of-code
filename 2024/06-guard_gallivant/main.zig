const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

const Pos = struct {
    x: usize,
    y: usize,
};
const Direction = enum { up, down, left, right };
const Guard = struct {
    x: usize,
    y: usize,
    facing_direction: Direction,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var map_1 = ArrayList([]u8).init(allocator);
    defer {
        for (map_1.items) |item| allocator.free(item);
        map_1.deinit();
    }

    const starting_guard = try allocator.create(Guard);
    defer allocator.destroy(starting_guard);

    var guard = try allocator.create(Guard);
    defer allocator.destroy(guard);

    var visited_pos = ArrayList(*Pos).init(allocator);
    defer {
        for (visited_pos.items) |item| allocator.destroy(item);
        visited_pos.deinit();
    }

    var buf: [1024]u8 = undefined;
    var i: usize = 0;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (i += 1) {
        // print("{s}\n", .{line});

        for (line, 0..) |pos, j| {
            guard.facing_direction = switch (pos) {
                '^' => .up,
                'v' => .down,
                '<' => .left,
                '>' => .right,
                else => continue,
            };
            guard.x = j;
            guard.y = i;

            starting_guard.* = guard.*;
            break;
        }

        const new_line = try allocator.alloc(u8, line.len);
        @memcpy(new_line, line);
        try map_1.append(new_line);
    }

    const original_map = try allocator.alloc([]u8, map_1.items.len);
    defer allocator.free(original_map);
    for (map_1.items, 0..) |line, map_idx| {
        original_map[map_idx] = try std.mem.Allocator.dupe(allocator, u8, line);
    }
    defer for (original_map) |line| allocator.free(line);

    // Part 1
    try part_one(allocator, &map_1, &visited_pos, guard);

    var looped: usize = 0;

    for (visited_pos.items, 1..) |pos, c| {
        // NOTE: The new obstruction can't be placed at the guard's starting position -
        // the guard is there right now and would notice.
        //
        // 😭
        if (pos.x == starting_guard.x and pos.y == starting_guard.y) continue;

        print("[{d}]Pos: {any}\n", .{ c, pos });

        const map = try allocator.alloc([]u8, original_map.len);
        defer allocator.free(map);
        for (original_map, 0..) |line, map_idx| {
            map[map_idx] = try std.mem.Allocator.dupe(allocator, u8, line);
        }
        defer for (map) |line| allocator.free(line);

        map[starting_guard.y][starting_guard.x] = '.';
        map[pos.y][pos.x] = 'O';

        guard.* = starting_guard.*;

        var obs = std.StringHashMap(usize).init(allocator);
        defer {
            var iter = obs.keyIterator();
            while (iter.next()) |k| allocator.free(k.*);
            obs.deinit();
        }

        outer: while (true) {
            // print("LOOP! {any}\n", .{guard});

            switch (guard.facing_direction) {
                .up => {
                    if (guard.y == 0) break :outer;

                    switch (map[guard.y - 1][guard.x]) {
                        '#', 'O' => {
                            const ob = try std.fmt.allocPrint(allocator, "({d},{d},^)", .{ guard.x, guard.y - 1 });
                            if (obs.fetchRemove(ob)) |old_entry| {
                                try obs.put(ob, old_entry.value + 1);
                                allocator.free(old_entry.key);
                            } else {
                                try obs.put(ob, 0);
                            }

                            turn_right(&guard.facing_direction);
                            map[guard.y][guard.x] = '+';
                        },
                        '.', '|', '-', '+' => {
                            guard.y -= 1;
                            map[guard.y][guard.x] = '|';
                        },
                        else => unreachable,
                    }
                },
                .down => {
                    if (guard.y == map.len - 1) break :outer;

                    switch (map[guard.y + 1][guard.x]) {
                        '#', 'O' => {
                            const ob = try std.fmt.allocPrint(allocator, "({d},{d},v)", .{ guard.x, guard.y + 1 });
                            if (obs.fetchRemove(ob)) |old_entry| {
                                try obs.put(ob, old_entry.value + 1);
                                allocator.free(old_entry.key);
                            } else {
                                try obs.put(ob, 0);
                            }

                            turn_right(&guard.facing_direction);
                            map[guard.y][guard.x] = '+';
                        },
                        '.', '|', '-', '+' => {
                            guard.y += 1;
                            map[guard.y][guard.x] = '|';
                        },
                        else => unreachable,
                    }
                },
                .left => {
                    if (guard.x == 0) break :outer;

                    switch (map[guard.y][guard.x - 1]) {
                        '#', 'O' => {
                            const ob = try std.fmt.allocPrint(allocator, "({d},{d},<)", .{ guard.x - 1, guard.y });
                            if (obs.fetchRemove(ob)) |old_entry| {
                                try obs.put(ob, old_entry.value + 1);
                                allocator.free(old_entry.key);
                            } else {
                                try obs.put(ob, 0);
                            }

                            turn_right(&guard.facing_direction);
                            map[guard.y][guard.x] = '+';
                        },
                        '.', '|', '-', '+' => {
                            guard.x -= 1;
                            map[guard.y][guard.x] = '-';
                        },
                        else => unreachable,
                    }
                },
                .right => {
                    if (guard.x == map[guard.y].len - 1) break :outer;

                    switch (map[guard.y][guard.x + 1]) {
                        '#', 'O' => {
                            const ob = try std.fmt.allocPrint(allocator, "({d},{d},>)", .{ guard.x + 1, guard.y });
                            if (obs.fetchRemove(ob)) |old_entry| {
                                try obs.put(ob, old_entry.value + 1);
                                allocator.free(old_entry.key);
                            } else {
                                try obs.put(ob, 0);
                            }

                            turn_right(&guard.facing_direction);
                            map[guard.y][guard.x] = '+';
                        },
                        '.', '|', '-', '+' => {
                            guard.x += 1;
                            map[guard.y][guard.x] = '-';
                        },
                        else => unreachable,
                    }
                },
            }

            var iter = obs.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* > 1) {
                    print("k:{s} v:{d}!\n", .{ entry.key_ptr.*, entry.value_ptr.* });
                    looped += 1;

                    map[starting_guard.y][starting_guard.x] = switch (starting_guard.facing_direction) {
                        .up => '^',
                        .down => 'v',
                        .left => '<',
                        .right => '>',
                    };
                    for (map) |line| {
                        print("{s}\n", .{line});
                    }
                    break :outer;
                }
            }
        }

        // map[starting_guard.y][starting_guard.x] = switch (starting_guard.facing_direction) {
        //     .up => '^',
        //     .down => 'v',
        //     .left => '<',
        //     .right => '>',
        // };
        //
        // for (map) |line| {
        //     print("{s}\n", .{line});
        // }
        print("==========================\n", .{});
    }

    print("Part 1: {d}\n", .{visited_pos.items.len});
    print("Part 2: {d}\n", .{looped});
    // FAILED: 1656
}

fn turn_right(guard_facing: *Direction) void {
    guard_facing.* = switch (guard_facing.*) {
        .up => .right,
        .down => .left,
        .left => .up,
        .right => .down,
    };
}

fn part_one(allocator: Allocator, map: *ArrayList([]u8), visited_pos: *ArrayList(*Pos), guard: *Guard) !void {
    outer: while (true) {
        map.items[guard.y][guard.x] = 'X';

        switch (guard.facing_direction) {
            .up => {
                if (guard.y == 0) {
                    break :outer;
                }

                switch (map.items[guard.y - 1][guard.x]) {
                    '#' => turn_right(&guard.facing_direction),
                    '.', 'X' => guard.y -= 1,
                    else => unreachable,
                }
            },
            .down => {
                if (guard.y == map.items.len - 1) {
                    break :outer;
                }

                switch (map.items[guard.y + 1][guard.x]) {
                    '#' => turn_right(&guard.facing_direction),
                    '.', 'X' => guard.y += 1,
                    else => unreachable,
                }
            },
            .left => {
                if (guard.x == 0) {
                    break :outer;
                }

                switch (map.items[guard.y][guard.x - 1]) {
                    '#' => turn_right(&guard.facing_direction),
                    '.', 'X' => guard.x -= 1,
                    else => unreachable,
                }
            },
            .right => {
                if (guard.x == map.items[guard.y].len - 1) {
                    break :outer;
                }

                switch (map.items[guard.y][guard.x + 1]) {
                    '#' => turn_right(&guard.facing_direction),
                    '.', 'X' => guard.x += 1,
                    else => unreachable,
                }
            },
        }
    }

    var pos_count: usize = 0;

    for (map.items, 0..) |line, i| {
        print("{s}\n", .{line});

        for (line, 0..) |pos, j| {
            if (pos == 'X') {
                pos_count += 1;

                const p = try allocator.create(Pos);
                p.* = .{
                    .x = j,
                    .y = i,
                };

                try visited_pos.append(p);
            }
        }
    }
}
