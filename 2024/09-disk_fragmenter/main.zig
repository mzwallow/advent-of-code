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
    const buf_reader = buffered.reader();

    var disk_map = ArrayList([]u8).init(allocator);
    defer {
        for (disk_map.items) |item| allocator.free(item);
        disk_map.deinit();
    }

    var file_id_map = HashMap(u128, usize).init(allocator);
    defer file_id_map.deinit();

    var buf: [20480]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var block_id: usize = 0;
        for (line, 0..) |char, i| {
            const block = try std.fmt.parseInt(u8, &[_]u8{char}, 10);

            if (try isEven(i)) {
                var repeat: u8 = 0;
                while (repeat < block) : (repeat += 1) {
                    const block_id_str = try std.fmt.allocPrint(allocator, "{d}", .{block_id});
                    try disk_map.append(block_id_str);
                }

                block_id += 1;
            } else {
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
    const checksum_2 = try partTwo(&disk_map_2);

    print("Part 1: {d}\n", .{checksum_1});
    // 88934811716: FAILED - Too low
    // 88935968966: FAILED - Too low
    // 6225730762521: PASSED

    print("Part 2: {d}\n", .{checksum_2});
    // 12838265093415: FAILED - Too high
}

fn partOne(disk_map: *[][]u8) !u128 {
    print("=====================================\n", .{});
    for (disk_map.*) |char| {
        print("{s}", .{char});
    }
    print("\n=====================================\n", .{});

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
                // print("{s} i:{d} j:{d}\n", .{ disk_map.*, i, j });
            }

            if (i + 1 == j) break;

            i += 1;
        }

        print("=====================================\n", .{});
        for (disk_map.*) |char| {
            print("{s}", .{char});
        }
        print("\n=====================================\n", .{});
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
        // print("{d}: ({d} * {d})\n", .{ checksum, i, block });

        if (i == last_block_idx) break;
    }

    return checksum;
}

fn partTwo(disk_map: *[][]u8) !u128 {
    // print("=====================================\n", .{});
    // for (disk_map.*) |char| {
    //     print("{s}", .{char});
    // }
    // print("\n=====================================\n", .{});

    {
        var latest_file_id: usize = undefined;
        var latest_file_id_idx: usize = undefined;
        {
            var idx = disk_map.len - 1;
            while (true) : (idx -= 1) {
                if (!std.mem.eql(u8, disk_map.*[idx], ".")) {
                    latest_file_id_idx = idx;
                    latest_file_id = try std.fmt.parseInt(@TypeOf(latest_file_id), disk_map.*[idx], 10);
                    break;
                }
            }
        }

        var i: usize = 0;
        outer: while (latest_file_id > 0) {
            if (!std.mem.eql(u8, disk_map.*[i], ".")) {
                i += 1;
            } else {
                var cur_space_idx = i;
                var spaces: usize = 0;
                while (std.mem.eql(u8, disk_map.*[cur_space_idx], ".")) : (cur_space_idx += 1) {
                    spaces += 1;
                }

                print("i:{d} spaces:{d}\n", .{ i, spaces });

                while (latest_file_id > 0) : (latest_file_id -= 1) {
                    latest_file_id_idx = try lastIndexOf(disk_map, latest_file_id);

                    var cur_latest_file_id_idx = latest_file_id_idx;
                    const cur_latest_file_id_str = disk_map.*[cur_latest_file_id_idx];
                    var file_id_count: usize = 0;
                    while (std.mem.eql(u8, disk_map.*[cur_latest_file_id_idx], cur_latest_file_id_str)) : (cur_latest_file_id_idx -= 1) {
                        file_id_count += 1;
                    }

                    print("latest_file_id:{d} idx:{d} count:{d}\n", .{ latest_file_id, latest_file_id_idx, file_id_count });

                    if (spaces >= file_id_count) {
                        var iter_j: usize = 0;
                        while (iter_j < file_id_count) : (iter_j += 1) {
                            const tmp = disk_map.*[i + iter_j];
                            disk_map.*[i + iter_j] = disk_map.*[latest_file_id_idx - iter_j];
                            disk_map.*[latest_file_id_idx - iter_j] = tmp;
                        }

                        // for (disk_map.*) |char| {
                        //     print("{s}", .{char});
                        // }
                        // print("\n", .{});

                        i += spaces;
                        latest_file_id -= 1;
                        latest_file_id_idx = try lastIndexOf(disk_map, latest_file_id);

                        if (std.mem.eql(u8, disk_map.*[i], disk_map.*[latest_file_id_idx])) {
                            i = 0;
                        }

                        continue :outer;
                    }
                }
            }
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
        if (std.mem.eql(u8, char, ".")) continue;

        const block: u128 = try std.fmt.parseInt(u128, char, 10);

        checksum += i * @as(@TypeOf(checksum), @intCast(block));

        if (i == last_block_idx) break;
    }

    return checksum;
}

fn isEven(value: usize) !bool {
    if (value == 0) return true;

    if (try std.math.mod(@TypeOf(value), value, 2) == 0) return true;
    return false;
}

fn lastIndexOf(disk: *[][]u8, file_id: usize) !usize {
    var idx: usize = disk.len - 1;
    var buf: [8]u8 = undefined;
    while (true) : (idx -= 1) {
        if (std.mem.eql(u8, disk.*[idx], try std.fmt.bufPrint(&buf, "{d}", .{file_id}))) {
            return idx;
        }
    }
}
