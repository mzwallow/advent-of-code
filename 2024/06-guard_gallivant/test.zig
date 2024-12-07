const std = @import("std");
const print = std.debug.print;
const allocator = std.testing.allocator;

test "main" {
    var obs = std.StringHashMap(usize).init(allocator);
    defer {
        var iter = obs.keyIterator();
        while (iter.next()) |k| {
            allocator.free(k.*);
        }
        obs.deinit();
    }

    const k_1 = try std.fmt.allocPrint(allocator, "({d},{d})", .{ 1, 2 });

    if (obs.getPtr(k_1)) |v| {
        v.* += 1;
    } else {
        try obs.put(k_1, 0);
    }

    const k_2 = try std.fmt.allocPrint(allocator, "({d},{d})", .{ 1, 2 });

    print("k1:{*} k2{*}\n", .{ k_1, k_2 });

    if (obs.fetchRemove(k_2)) |entry| {
        print("YAY\n", .{});

        print("YAY k1:{*} k2{*}\n", .{ entry.key, k_2 });
        allocator.free(entry.key);
        try obs.put(k_2, entry.value + 1);
    } else {
        try obs.put(k_2, 0);
    }

    print("{*} {*}\n", .{ k_1, k_2 });

    var iter = obs.iterator();
    while (iter.next()) |entry| {
        print("k:{s} v:{d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}
