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
    // const file = try std.fs.cwd().openFile("example.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var disk_map = ArrayList([]u8).init(allocator);
    defer {
        for (disk_map.items) |item| allocator.free(item);
        disk_map.deinit();
    }

    var input = ArrayList(u8).init(allocator);
    defer input.deinit();

    var files = ArrayList(u8).init(allocator);
    defer files.deinit();

    var spaces = ArrayList(u8).init(allocator);
    defer spaces.deinit();

    var buf: [20480]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var block_id: usize = 0;
        for (line, 0..) |char, i| {
            const block = try std.fmt.parseInt(u8, &[_]u8{char}, 10);

            try input.append(block);

            if (try isEven(i)) {
                try files.append(block);

                var repeat: u8 = 0;
                while (repeat < block) : (repeat += 1) {
                    const block_id_str = try std.fmt.allocPrint(allocator, "{d}", .{block_id});
                    try disk_map.append(block_id_str);
                }

                block_id += 1;
            } else {
                try spaces.append(block);

                var repeat: u8 = 0;
                while (repeat < block) : (repeat += 1) {
                    const dot = try std.fmt.allocPrint(allocator, ".", .{});
                    try disk_map.append(dot);
                }
            }
        }

        break;
    }

    var disk_map_1 = try allocator.alloc([]u8, disk_map.items.len);
    defer {
        for (disk_map_1) |item| allocator.free(item);
        allocator.free(disk_map_1);
    }
    {
        for (disk_map.items, 0..) |item, i| {
            const new_item = try allocator.alloc(u8, item.len);
            std.mem.copyForwards(u8, new_item, item);
            disk_map_1[i] = new_item;
        }
    }

    var disk_map_2 = try allocator.alloc([]u8, disk_map.items.len);
    defer {
        for (disk_map_2) |item| allocator.free(item);
        allocator.free(disk_map_2);
    }
    {
        for (disk_map.items, 0..) |item, i| {
            const new_item = try allocator.alloc(u8, item.len);
            std.mem.copyForwards(u8, new_item, item);
            disk_map_2[i] = new_item;
        }
    }

    const checksum_1 = try partOne(&disk_map_1);
    const checksum_2 = try partTwo(input.items, disk_map_2, files.items, spaces.items);

    print("Part 1: {d}\n", .{checksum_1});
    // 88934811716: FAILED - Too low
    // 88935968966: FAILED - Too low
    // 6225730762521: PASSED

    print("Part 2: {d}\n", .{checksum_2});
    // 12838265093415: FAILED - Too high
    // 12745090777388: FAILED - Too high
    // 12719358014229: FAILED - Too high
    // 6250605700557: PASSED
}

fn partOne(disk_map: *[][]u8) !u128 {
    // print("=====================================\n", .{});
    // for (disk_map.*) |char| {
    //     print("{s}", .{char});
    // }
    // print("\n=====================================\n", .{});

    {
        var i: usize = 0;
        var j: usize = disk_map.len - 1;
        while (i < disk_map.len) {
            if (std.mem.eql(u8, disk_map.*[i], ".")) {
                while (j > 0) : (j -= 1) {
                    if (!std.mem.eql(u8, disk_map.*[j], ".")) break;
                }

                const tmp = disk_map.*[i];
                disk_map.*[i] = disk_map.*[j];
                disk_map.*[j] = tmp;
            }

            if (i + 1 == j) break;

            i += 1;
        }

        // print("=====================================\n", .{});
        // for (disk_map.*) |char| {
        //     print("{s}", .{char});
        // }
        // print("\n=====================================\n", .{});
    }

    var last_block_idx: usize = undefined;
    {
        var i = disk_map.len - 1;
        while (true) : (i -= 1) {
            if (!std.mem.eql(u8, disk_map.*[i], ".")) {
                last_block_idx = i;
                break;
            }
        }
    }

    var checksum: u128 = 0;
    for (disk_map.*, 0..) |char, i| {
        const block: u128 = try std.fmt.parseInt(u128, char, 10);

        checksum += i * @as(@TypeOf(checksum), @intCast(block));

        if (i == last_block_idx) break;
    }

    return checksum;
}

fn partTwo(disk_map: []u8, blocks: [][]u8, files: []u8, spaces: []u8) !u128 {
    // print("blocks: {s}\n", .{blocks});
    // print("disk_map: {any}\n", .{disk_map});
    // print("files: {any}\n", .{files});
    // print("spaces: {any}\n", .{spaces});

    var file_id: usize = files.len - 1;
    while (file_id > 0) : (file_id -= 1) {
        for (spaces, 0..) |space, space_idx| {
            // print("files:{d} file_id:{d}\t", .{ files[file_id], file_id });
            // print("space:{d} space_idx:{d}\n", .{ space, space_idx });
            if (space >= files[file_id]) {
                const first_file_idx = sum(disk_map[0 .. file_id * 2]);
                const first_space_idx = sum(disk_map[0 .. space_idx * 2 + 1]);
                if (first_space_idx >= first_file_idx) break;

                // print("\tfirst_file_idx: {d}\n", .{first_file_idx});
                // print("\tfirst_space_idx: {d}\n", .{first_space_idx});

                // Swap
                for (0..files[file_id]) |i| {
                    const tmp = blocks[first_space_idx + i];
                    blocks[first_space_idx + i] = blocks[first_file_idx + i];
                    blocks[first_file_idx + i] = tmp;
                }

                disk_map[space_idx * 2 + 1] -= files[file_id];
                disk_map[space_idx * 2] += files[file_id];
                disk_map[file_id * 2] = 0;

                spaces[space_idx] -= files[file_id];
                break;
            }
        }
    }

    var checksum: u128 = 0;
    for (blocks, 0..) |char, i| {
        if (std.mem.eql(u8, char, ".")) continue;

        const block: u128 = try std.fmt.parseInt(u128, char, 10);

        checksum += i * @as(@TypeOf(checksum), @intCast(block));
    }

    return checksum;
}

fn isEven(value: usize) !bool {
    if (value == 0) return true;

    if (try std.math.mod(@TypeOf(value), value, 2) == 0) return true;
    return false;
}

fn sum(xs: []u8) usize {
    var result: usize = 0;
    for (xs) |x| result += @intCast(x);
    return result;
}
