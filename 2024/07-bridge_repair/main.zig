const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var equations = ArrayList([]u128).init(allocator);
    defer {
        for (equations.items) |item| allocator.free(item);
        equations.deinit();
    }

    var buf: [1024]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var numbers = ArrayList(u128).init(allocator);
        defer numbers.deinit();

        var iter = std.mem.tokenizeAny(u8, line, " :");
        while (iter.next()) |number| {
            try numbers.append(try std.fmt.parseInt(u128, number, 10));
        }

        const tmp_numbers = try allocator.alloc(u128, numbers.items.len);
        std.mem.copyForwards(u128, tmp_numbers, numbers.items);

        try equations.append(tmp_numbers);
    }

    var first_failed_equations = ArrayList([]u128).init(allocator);
    defer first_failed_equations.deinit();

    var operators_1 = [2]u8{ '+', '*' };
    var sum_1: u128 = 0;
    outer: for (equations.items) |numbers| {
        var tmp_ops = ArrayList(u8).init(allocator);
        defer tmp_ops.deinit();

        var op_list = ArrayList([]u8).init(allocator);
        defer {
            for (op_list.items) |ops| allocator.free(ops);
            op_list.deinit();
        }

        try gen_op(allocator, operators_1[0..], numbers.len - 2, &tmp_ops, &op_list);

        for (op_list.items) |ops| {
            var result: u128 = undefined;
            for (numbers[1..], 0..) |number, i| {
                if (i == 0) {
                    result = number;
                    continue;
                }

                switch (ops[i - 1]) {
                    '+' => result += number,
                    '*' => result *= number,
                    else => unreachable,
                }
            }

            if (numbers[0] == result) {
                sum_1 += result;
                continue :outer;
            }
        }

        try first_failed_equations.append(numbers);
    }

    var operators_2 = [3]u8{ '|', '+', '*' };
    var sum_2: u128 = 0;
    outer: for (first_failed_equations.items) |numbers| {
        var tmp_ops = ArrayList(u8).init(allocator);
        defer tmp_ops.deinit();

        var op_list = ArrayList([]u8).init(allocator);
        defer {
            for (op_list.items) |ops| allocator.free(ops);
            op_list.deinit();
        }

        try gen_op(allocator, operators_2[0..], numbers.len - 2, &tmp_ops, &op_list);

        for (op_list.items) |ops| {
            var result: u128 = undefined;

            for (numbers[1..], 0..) |number, i| {
                if (i == 0) {
                    result = number;
                    continue;
                }

                switch (ops[i - 1]) {
                    '|' => {
                        var digits: u32 = 1;
                        var n = number;
                        while (n >= 10) : (n /= 10) digits += 1;
                        result = (result * std.math.pow(u128, 10, digits)) + number;
                    },
                    '+' => result += number,
                    '*' => result *= number,
                    else => unreachable,
                }
            }

            if (numbers[0] == result) {
                sum_2 += result;
                // print("--------------------------------------------------------\n", .{});
                // print("{d}={d}: {any} {s}\n", .{ numbers[0], result, numbers[1..], ops });
                // print("--------------------------------------------------------\n", .{});
                continue :outer;
            }
        }
    }

    print("Part 1: {d}\n", .{sum_1});
    // 3351424677624: PASSED
    print("Part 2: {d}\n", .{sum_1 + sum_2});
    // 3886921569504: FAILED
    // 204976636995111: PASSED
}

fn gen_op(allocator: Allocator, operators: []u8, num_op: usize, tmp_ops: *ArrayList(u8), op_list: *ArrayList([]u8)) !void {
    if (tmp_ops.items.len == num_op) {
        // for (current.items) |op| {
        //     print("{c} ", .{op});
        // }
        // print("\n", .{});

        const ops = try allocator.alloc(u8, tmp_ops.items.len);
        @memcpy(ops, tmp_ops.items);
        try op_list.append(ops);

        return;
    }

    for (operators) |op| {
        try tmp_ops.append(op);
        try gen_op(allocator, operators, num_op, tmp_ops, op_list);
        _ = tmp_ops.pop();
    }
}
