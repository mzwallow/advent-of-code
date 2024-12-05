const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap(u8, ArrayList(u8));

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var updates = ArrayList([]u8).init(allocator);
    defer {
        for (updates.items) |item| allocator.free(item);
        updates.deinit();
    }

    var ordering_rule_set = AutoHashMap.init(allocator);
    defer {
        var iter = ordering_rule_set.iterator();
        while (iter.next()) |entry| entry.value_ptr.*.deinit();
        ordering_rule_set.deinit();
    }

    var update_sec = false;

    var buf: [256]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // print("{s}\n", .{line});

        if (std.mem.eql(u8, line, "")) {
            update_sec = true;
            continue;
        }

        if (!update_sec) {
            var iter = std.mem.tokenizeScalar(u8, line, '|');
            const x = try std.fmt.parseInt(u8, iter.next().?, 10);
            const y = try std.fmt.parseInt(u8, iter.next().?, 10);

            if (ordering_rule_set.getPtr(x)) |list| {
                try list.append(y);
            } else {
                var new_list = ArrayList(u8).init(allocator);
                try new_list.append(y);
                try ordering_rule_set.put(x, new_list);
            }
        } else {
            var tmp_updates = ArrayList(u8).init(allocator);
            defer tmp_updates.deinit();

            var iter = std.mem.tokenizeScalar(u8, line, ',');
            while (iter.next()) |update| try tmp_updates.append(try std.fmt.parseInt(u8, update, 10));

            const update = try allocator.alloc(u8, tmp_updates.items.len);
            @memcpy(update, tmp_updates.items);

            try updates.append(update);
        }
    }

    var sum_part_1: usize = 0;

    var incorrect_updates = ArrayList([]u8).init(allocator);
    defer _ = incorrect_updates.deinit();

    outer: for (updates.items) |update| {
        // print("{any}\n", .{update});

        for (update, 0..) |page_number, i| {
            var f: usize = i + 1;
            while (f < update.len) : (f += 1) {
                const set = ordering_rule_set.get(update[f]);
                if (set) |_| {
                    if (std.mem.indexOfScalar(u8, set.?.items, page_number) != null) {
                        // print("bad_f: {any}\n", .{update});
                        try incorrect_updates.append(update); // Collect for part 2
                        continue :outer;
                    }
                }
            }

            if (i > 0) {
                var b: usize = i - 1;
                while (b >= 0) : (b -= 1) {
                    const set = ordering_rule_set.get(page_number);
                    if (set) |_| {
                        if (std.mem.indexOfScalar(u8, set.?.items, update[b]) != null) {
                            // print("bad_b: {any}\n", .{update});
                            try incorrect_updates.append(update); // Collect for part 2
                            continue :outer;
                        }
                    }

                    if (b == 0) break;
                }
            }
        }

        sum_part_1 += update[update.len / 2];
    }

    print("Part 1: {d}\n", .{sum_part_1});

    var sum_part_2: usize = 0;

    for (incorrect_updates.items) |update| {
        // print("{any}\n", .{update});

        var j: usize = 0;
        mid: while (j < update.len) {
            const page_number: u8 = update[j];

            var f: usize = j + 1;
            while (f < update.len) : (f += 1) {
                const set = ordering_rule_set.get(update[f]);
                if (set) |_| {
                    if (std.mem.indexOfScalar(u8, set.?.items, page_number) != null) {
                        std.mem.swap(u8, &update[j], &update[f]);
                        // print("bad_f: {any}\n", .{update});
                        continue :mid;
                    }
                }
            }

            j += 1;
        }

        sum_part_2 += update[update.len / 2];
    }

    print("Part 2: {d}\n", .{sum_part_2});
}
