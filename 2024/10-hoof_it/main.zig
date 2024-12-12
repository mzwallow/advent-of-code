const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // const file = try std.fs.cwd().openFile("example.txt", .{});
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var map = ArrayList([]u8).init(allocator);
    defer {
        for (map.items) |item| allocator.free(item);
        map.deinit();
    }

    var buf: [64]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const new_line = try allocator.alloc(u8, line.len);
        for (line, 0..) |char, i| {
            new_line[i] = char - '0';
        }

        try map.append(new_line);
    }

    // for (map.items) |row| {
    //     print("{any}\n", .{row});
    // }

    var score_1: usize = 0;
    var score_2: usize = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |col, x| {
            if (col == 0) {
                const start_node = Pos{ .x = x, .y = y };

                var visited_1 = HashMap(Pos, u1).init(allocator);
                defer visited_1.deinit();
                var s_1: usize = 0;
                try partOne(map.items, start_node, &s_1, &visited_1);
                score_1 += s_1;

                var visited_2 = HashMap(Pos, u1).init(allocator);
                defer visited_2.deinit();
                var s_2: usize = 0;
                try partTwo(map.items, start_node, &s_2);
                score_2 += s_2;
            }
        }
    }

    print("Part 1: {d}\n", .{score_1});
    print("Part 2: {d}\n", .{score_2});
}

fn partOne(map: [][]u8, start: Pos, score: *usize, visited: *HashMap(Pos, u1)) !void {
    return dfs(true, map, start, score, visited);
}

fn partTwo(map: [][]u8, start: Pos, score: *usize) !void {
    return dfs(false, map, start, score, null);
}

fn dfs(isPartOne: bool, map: [][]u8, start: Pos, score: *usize, visited: ?*HashMap(Pos, u1)) !void {
    // print("node: ({d},{d}) = {d}\n", .{ start.x, start.y, map[start.y][start.x] });

    if (map[start.y][start.x] == 9) {
        if (isPartOne) {
            if (visited.?.getKey(start) == null) {
                try visited.?.put(start, 1);
                score.* += 1;
            }
        } else {
            score.* += 1;
        }

        // print("\n", .{});
        return;
    }

    const next_value: u8 = map[start.y][start.x] + 1;

    // Up
    if (start.y > 0 and map[start.y - 1][start.x] == next_value) {
        const next_node = Pos{ .x = start.x, .y = start.y - 1 };
        try dfs(isPartOne, map, next_node, score, visited);
    }

    // Down
    if (start.y < map.len - 1 and map[start.y + 1][start.x] == next_value) {
        const next_node = Pos{ .x = start.x, .y = start.y + 1 };
        try dfs(isPartOne, map, next_node, score, visited);
    }

    // Left
    if (start.x > 0 and map[start.y][start.x - 1] == next_value) {
        const next_node = Pos{ .x = start.x - 1, .y = start.y };
        try dfs(isPartOne, map, next_node, score, visited);
    }

    // Right
    if (start.x < map[start.y].len - 1 and map[start.y][start.x + 1] == next_value) {
        const next_node = Pos{ .x = start.x + 1, .y = start.y };
        try dfs(isPartOne, map, next_node, score, visited);
    }
}

const Pos = struct {
    x: usize,
    y: usize,
};
