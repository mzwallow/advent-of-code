const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

const ALPHANUMERIC = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

const Pos = struct {
    x: i16,
    y: i16,
};

const Info = struct {
    const Self = @This();

    freq: u8 = undefined,
    positions: ArrayList(Pos),
    allocator: Allocator,

    fn init(allocator: Allocator, freq: u8) Self {
        return Self{
            .freq = freq,
            .positions = ArrayList(Pos).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        self.positions.deinit();
    }

    fn addPos(self: *Self, vec: Pos) !void {
        try self.positions.append(vec);
    }
};

const FreqMap = struct {
    const Self = @This();

    map_1: ArrayList([]u8),
    map_2: ArrayList([]u8),
    allocator: Allocator,

    fn init(allocator: Allocator) Self {
        return Self{
            .map_1 = ArrayList([]u8).init(allocator),
            .map_2 = ArrayList([]u8).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Self) void {
        for (self.map_1.items) |line| self.allocator.free(line);
        self.map_1.deinit();

        for (self.map_2.items) |line| self.allocator.free(line);
        self.map_2.deinit();
    }

    fn setAntinodes1(self: *Self, freq_pair: [2]Pos) void {
        const dist = Pos{
            .x = freq_pair[1].x - freq_pair[0].x,
            .y = freq_pair[1].y - freq_pair[0].y,
        };

        if (dist.x >= 0) {
            // First antinode
            const first_antinode_x = freq_pair[0].x - i16Abs(dist.x);
            const first_antinode_y = freq_pair[0].y - i16Abs(dist.y);
            if (first_antinode_x >= 0 and
                first_antinode_y >= 0)
            {
                // if (self.map.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] == '.')
                self.map_1.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] = '#';
            }

            // Second antinode
            const second_antinode_x = freq_pair[1].x + i16Abs(dist.x);
            const second_antinode_y = freq_pair[1].y + i16Abs(dist.y);
            if (second_antinode_y < self.map_1.items.len and
                second_antinode_x < self.map_1.items[@intCast(second_antinode_y)].len)
            {
                // if (self.map.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] == '.')
                self.map_1.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] = '#';
            }
        } else {
            // First antinode
            const first_antinode_x = freq_pair[0].x + i16Abs(dist.x);
            const first_antinode_y = freq_pair[0].y - i16Abs(dist.y);

            if (first_antinode_y >= 0 and
                first_antinode_x < self.map_1.items[@intCast(first_antinode_y)].len)
            {
                // if (self.map.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] == '.')
                self.map_1.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] = '#';
            }

            // Second antinode
            const second_antinode_x = freq_pair[1].x - i16Abs(dist.x);
            const second_antinode_y = freq_pair[1].y + i16Abs(dist.y);
            if (second_antinode_x >= 0 and
                second_antinode_y < self.map_1.items.len)
            {
                // if (self.map.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] == '.')
                self.map_1.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] = '#';
            }
        }
    }

    fn setAntinodes2(self: *Self, freq_pair: [2]Pos) void {
        const dist = Pos{
            .x = freq_pair[1].x - freq_pair[0].x,
            .y = freq_pair[1].y - freq_pair[0].y,
        };

        for (1..self.map_2.items.len + 1) |i| {
            if (dist.x >= 0) {
                // First antinode
                const first_antinode_x = freq_pair[0].x - i16Abs(dist.x * @as(i16, @intCast(i)));
                const first_antinode_y = freq_pair[0].y - i16Abs(dist.y * @as(i16, @intCast(i)));
                if (first_antinode_x >= 0 and
                    first_antinode_y >= 0)
                {
                    self.map_2.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] = '#';
                }

                // Second antinode
                const second_antinode_x = freq_pair[1].x + i16Abs(dist.x * @as(i16, @intCast(i)));
                const second_antinode_y = freq_pair[1].y + i16Abs(dist.y * @as(i16, @intCast(i)));
                if (second_antinode_y < self.map_2.items.len and
                    second_antinode_x < self.map_2.items[@intCast(second_antinode_y)].len)
                {
                    self.map_2.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] = '#';
                }
            } else {
                // First antinode
                const first_antinode_x = freq_pair[0].x + i16Abs(dist.x * @as(i16, @intCast(i)));
                const first_antinode_y = freq_pair[0].y - i16Abs(dist.y * @as(i16, @intCast(i)));

                if (first_antinode_y >= 0 and
                    first_antinode_x < self.map_2.items[@intCast(first_antinode_y)].len)
                {
                    self.map_2.items[@intCast(first_antinode_y)][@intCast(first_antinode_x)] = '#';
                }

                // Second antinode
                const second_antinode_x = freq_pair[1].x - i16Abs(dist.x * @as(i16, @intCast(i)));
                const second_antinode_y = freq_pair[1].y + i16Abs(dist.y * @as(i16, @intCast(i)));
                if (second_antinode_x >= 0 and
                    second_antinode_y < self.map_2.items.len)
                {
                    self.map_2.items[@intCast(second_antinode_y)][@intCast(second_antinode_x)] = '#';
                }
            }
        }
    }

    fn antinodes1(self: *Self) usize {
        var count: usize = 0;
        for (self.map_1.items) |line| {
            for (line) |char| {
                if (char == '#') count += 1;
            }
        }
        return count;
    }

    fn antinodes2(self: *Self) usize {
        var count: usize = 0;
        for (self.map_2.items) |line| {
            var has_antinode = false;
            if (std.mem.indexOfScalar(u8, line, '#')) |_| has_antinode = true;
            for (line) |char| {
                if (has_antinode) {
                    if (char != '.') count += 1;
                } else {
                    if (char == '#') count += 1;
                }
            }
        }
        return count;
    }

    fn printMap1(self: *Self) void {
        print("PART 1------------------------\n", .{});
        for (self.map_1.items) |line| {
            print("{s}\n", .{line});
        }
        print("------------------------------\n", .{});
    }

    fn printMap2(self: *Self) void {
        print("PART 2------------------------\n", .{});
        for (self.map_2.items) |line| {
            print("{s}\n", .{line});
        }
        print("------------------------------\n", .{});
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var freq_set = HashMap(u8, Info).init(allocator);
    defer {
        var iter = freq_set.valueIterator();
        while (iter.next()) |v| v.deinit();
        freq_set.deinit();
    }

    var freq_map = FreqMap.init(allocator);
    defer freq_map.deinit();

    {
        var y: usize = 0;

        var buf: [1024]u8 = undefined;
        while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (y += 1) {
            const line_1 = try allocator.alloc(u8, line.len);
            std.mem.copyForwards(u8, line_1, line);
            try freq_map.map_1.append(line_1);

            const line_2 = try allocator.alloc(u8, line.len);
            std.mem.copyForwards(u8, line_2, line);
            try freq_map.map_2.append(line_2);

            for (line, 0..) |char, x| {
                if (isAlphanumeric(char)) {
                    const vec = Pos{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    };

                    if (freq_set.getPtr(char)) |entry| {
                        try entry.addPos(vec);
                    } else {
                        var info = Info.init(allocator, char);
                        try info.addPos(vec);
                        try freq_set.put(char, info);
                    }
                }
            }
        }
    }

    var iter = freq_set.iterator();
    while (iter.next()) |entry| {
        var freq_pairs = ArrayList([2]Pos).init(allocator);
        defer freq_pairs.deinit();

        for (entry.value_ptr.positions.items, 0..) |pos_1, i| {
            for (entry.value_ptr.positions.items, 0..) |pos_2, j| {
                if (i >= j) continue;
                try freq_pairs.append([2]Pos{ pos_1, pos_2 });
            }
        }

        print("{c}: [ ", .{entry.key_ptr.*});
        for (freq_pairs.items) |pair| {
            print("[({d},{d}),({d},{d})], ", .{ pair[0].x, pair[0].y, pair[1].x, pair[1].y });
            freq_map.setAntinodes1(pair);
            freq_map.setAntinodes2(pair);
        }
        print("]\n", .{});
    }

    freq_map.printMap1();
    freq_map.printMap2();

    print("Part 1: {d}\n", .{freq_map.antinodes1()});
    // 341: PASSED
    print("Part 2: {d}\n", .{freq_map.antinodes2()});
    // 1129: FAILED
    // 1134: PASSED
}

fn isAlphanumeric(char: u8) bool {
    if (std.mem.indexOfScalar(u8, ALPHANUMERIC, char)) |_| return true;
    return false;
}

fn i16Abs(value: i16) i16 {
    if (value < 0) return value * -1;
    return value;
}
