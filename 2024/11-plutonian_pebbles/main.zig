const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const L = std.DoublyLinkedList(usize);
const HashMap = std.AutoHashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // const file = try std.fs.cwd().openFile("example.txt", .{});
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var stones = ArrayList(usize).init(allocator);
    defer stones.deinit();

    var list = L{};

    {
        var buf: [64]u8 = undefined;
        while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var iter = std.mem.tokenizeScalar(u8, line, ' ');
            while (iter.next()) |stone| {
                const number = try std.fmt.parseInt(usize, stone, 10);
                try stones.append(number);
                const node = try aa.create(L.Node);
                node.data = number;
                list.append(node);
            }
        }
    }

    print("Initial:\n", .{});
    {
        print("[ ", .{});
        var it = list.first;
        while (it) |node| : (it = node.next) {
            print("{d} ", .{node.data});
        }
        print("] {d}\n\n", .{list.len});
    }

    try partOne(aa, &list);
    try partTwo(allocator, &stones);
}

fn partOne(aa: Allocator, list: *L) !void {
    const times: u8 = 25;

    var buf: [20]u8 = undefined;
    for (0..times) |t| {
        var it = list.first;
        while (it) |node| : (it = node.next) {
            const number_str = try std.fmt.bufPrint(&buf, "{d}", .{node.data});

            if (node.data == 0) {
                node.data = 1;
            } else if (try std.math.mod(usize, number_str.len, 2) == 0) {
                const left = try std.fmt.parseInt(usize, number_str[0 .. number_str.len / 2], 10);
                const right = try std.fmt.parseInt(usize, number_str[number_str.len / 2 ..], 10);

                node.data = right;
                const left_node = try aa.create(L.Node);
                left_node.data = left;
                list.insertBefore(node, left_node);
            } else {
                const result: usize = node.data * 2024;
                node.data = result;
            }
        }

        // print("After {d} blink(s):\n", .{t + 1});
        // {
        //     print("[ ", .{});
        //     var d_it = list.first;
        //     while (d_it) |node| : (d_it = node.next) {
        //         print("{d} ", .{node.data});
        //     }
        //     print("] {d}\n\n", .{list.len});
        // }
        print("\r{d} blink(s)", .{t + 1});
        // _ = t;
    }

    print("\nPart 1: {d}\n\n", .{list.len}); // 204022: PASSED
}

fn partTwo(allocator: Allocator, stones: *ArrayList(usize)) !void {
    var cache = HashMap(usize, usize).init(allocator);
    defer cache.deinit();

    for (stones.items) |stone| {
        const count = cache.getPtr(stone);
        if (count) |c| {
            c.* += 1;
        } else {
            try cache.put(stone, 1);
        }
    }

    const times: u8 = 75;

    var buf: [20]u8 = undefined;
    for (0..times) |t| {
        var tmp_cache = HashMap(usize, usize).init(allocator);
        defer tmp_cache.deinit();

        var iter = cache.iterator();
        while (iter.next()) |entity| {
            const cur = entity.key_ptr.*;

            const number_str = try std.fmt.bufPrint(&buf, "{d}", .{cur});

            if (cur == 0) {
                if (tmp_cache.getPtr(1)) |tmp| {
                    tmp.* += entity.value_ptr.*;
                } else {
                    try tmp_cache.put(1, entity.value_ptr.*);
                }
            } else if (try std.math.mod(usize, number_str.len, 2) == 0) {
                const left = try std.fmt.parseInt(usize, number_str[0 .. number_str.len / 2], 10);
                const right = try std.fmt.parseInt(usize, number_str[number_str.len / 2 ..], 10);

                if (tmp_cache.getPtr(left)) |tmp| {
                    tmp.* += entity.value_ptr.*;
                } else {
                    try tmp_cache.put(left, entity.value_ptr.*);
                }

                if (tmp_cache.getPtr(right)) |tmp| {
                    tmp.* += entity.value_ptr.*;
                } else {
                    try tmp_cache.put(right, entity.value_ptr.*);
                }
            } else {
                const res = cur * 2024;

                if (tmp_cache.getPtr(res)) |tmp| {
                    tmp.* += entity.value_ptr.*;
                } else {
                    try tmp_cache.put(res, entity.value_ptr.*);
                }
            }
        }

        cache.deinit();
        cache = try tmp_cache.clone();

        print("\r{d} blink(s)", .{t + 1});
        // {
        //     print("[ ", .{});
        //     var d_it = cache.iterator();
        //     while (d_it.next()) |entry| print("{d}:{d} ", .{ entry.key_ptr.*, entry.value_ptr.* });
        //     print("]", .{});
        // }
        // print("\n\n", .{});
    }

    var sum: usize = 0;
    var it = cache.iterator();
    while (it.next()) |entry| sum += entry.value_ptr.*;

    print("\nPart 2: {d}\n", .{sum});
}
