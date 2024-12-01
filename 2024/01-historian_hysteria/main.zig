const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var buf_reader = buffered.reader();

    var left = ArrayList(i32).init(allocator);
    defer left.deinit();

    var right = ArrayList(i32).init(allocator);
    defer right.deinit();

    var buf: [1024]u8 = undefined;
    var i: usize = 0;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (i += 1) {
        var iter = std.mem.tokenizeAny(u8, line, " ");

        try left.append(try std.fmt.parseInt(i32, iter.next().?, 10));
        try right.append(try std.fmt.parseInt(i32, iter.next().?, 10));
    }

    // try partOne(left, right);
    try partTwo(allocator, left, right);
}

fn partOne(left: ArrayList(i32), right: ArrayList(i32)) !void {
    std.mem.sort(i32, left.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, comptime std.sort.asc(i32));

    var sum: i32 = 0;

    var i = 0;
    while (i < left.items.len) : (i += 1) {
        var d = right.items[i] - left.items[i];

        if (d < 0) d *= -1;

        sum += d;
    }

    print("sum: {d}\n", .{sum});
}

fn partTwo(allocator: Allocator, left: ArrayList(i32), right: ArrayList(i32)) !void {
    const Sim = struct { times: i32 = 1, sim: i32 = undefined };

    var hash = HashMap(i32, Sim).init(allocator);
    defer hash.deinit();

    for (left.items) |l| {
        if (!hash.contains(l)) {
            var dup: i32 = 0;
            for (right.items) |r| {
                if (l == r) dup += 1;
            }

            try hash.put(l, .{ .sim = l * dup });
        } else {
            hash.getPtr(l).?.*.times += 1;
        }
    }

    var sum: i32 = 0;
    var iter = hash.iterator();
    while (iter.next()) |h| {
        sum += h.value_ptr.sim * h.value_ptr.times;
    }

    print("sum: {d}\n", .{sum});
}
