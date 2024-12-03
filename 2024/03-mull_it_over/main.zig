// Zig does not have regular expressions 🤯
// You can also use Posix's regex.h,
// more on https://www.openmymind.net/Regular-Expressions-in-Zig/
//
// But I'm not too familiar with C and headers so I'm not gonna use it.

const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const ParseIntError = std.fmt.ParseIntError;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try partOne();
    try partTwo(allocator);
}

fn partOne() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    var sum: u32 = 0;

    var buf: [4096]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sum += mulInstruction(line);
    }

    print("Part 1: {d}\n", .{sum});
}

fn partTwo(allocator: Allocator) !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buf_reader = buffered.reader();

    // Forgot to think in long sequence and STUCK here for too long 😭
    //
    // Concat in a single line
    var long_line = ArrayList(u8).init(allocator);
    defer long_line.deinit();
    var buf: [4096]u8 = undefined;
    while (try buf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try long_line.appendSlice(line);
    }

    var sum: u32 = 0;

    var do_i: usize = 0;
    var do_iter = std.mem.splitSequence(u8, long_line.items, "do()");
    while (do_iter.next()) |do_ins| {
        // print("[{d}]do(): '{s}'\n", .{ do_i, do_ins });
        // print("|\n", .{});

        var dont_iter = std.mem.splitSequence(u8, do_ins, "don't()");
        const doable_section = if (dont_iter.next()) |_| do_ins[0 .. dont_iter.index orelse do_ins.len] else do_ins;

        const mutable_do_ins = try allocator.alloc(u8, doable_section.len);
        defer allocator.free(mutable_do_ins);

        @memcpy(mutable_do_ins, doable_section);

        // print("-----\n", .{});
        // print("{s}\n", .{mutable_do_ins});
        // print("-----\n", .{});

        sum += mulInstruction(mutable_do_ins);

        // print("\n\n", .{});
        do_i += 1;
    }

    print("Part 2: {d}\n", .{sum});

    // 117549707: too high
    // 108830766
}

fn mulInstruction(line: []u8) u32 {
    var sum: u32 = 0;

    var i: usize = 0;
    outer: while (i < line.len) {
        const char = line[i];

        if (char == 'm') {
            var cand: []u8 = undefined;
            for (line[i + 1 ..], i + 1..) |m, j| {
                if (m == 'm') {
                    i = j;
                    continue;
                }

                if (m == ')') {
                    cand = line[i .. j + 1];

                    // Check mul(X,Y)
                    var count: usize = 0;

                    var iter = std.mem.splitAny(u8, cand, "(,)");
                    while (iter.next()) |_| count += 1;
                    iter.reset();

                    if (count == 4) {
                        if (!std.mem.eql(u8, iter.next().?, "mul")) {
                            i = j;
                            continue;
                        }
                        const a = std.fmt.parseInt(u32, iter.next().?, 10) catch {
                            i = j;
                            continue;
                        };
                        const b = std.fmt.parseInt(u32, iter.next().?, 10) catch {
                            i = j;
                            continue;
                        };

                        // print("{s}\n", .{cand});

                        sum += a * b;
                    } else {
                        i = j;
                        continue;
                    }

                    i = j + 1;
                    continue :outer;
                }
            }
        }

        i += 1;
    }

    return sum;
}
