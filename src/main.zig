const std = @import("std");
const zuri = @import("zuri");
const iguanatls = @import("iguanatls");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = &gpa.allocator;

    const url = try zuri.Uri.parse("https://zpm.random-projects.net:443/api/packages", true);

    const sock = try std.net.tcpConnectToHost(alloc, url.host.name, url.port.?);
    defer sock.close();

    var client = try iguanatls.client_connect(.{
        .reader = sock.reader(),
        .writer = sock.writer(),
        .cert_verifier = .none,
        .temp_allocator = alloc,
        .ciphersuites = iguanatls.ciphersuites.all,
    }, url.host.name);
    defer client.close_notify() catch {};

    const w = client.writer();
    try w.print("GET {s} HTTP/1.1\r\n", .{url.path});
    try w.print("Host: {s}:{}\r\n", .{url.host.name, url.port.?});
    try w.writeAll("Accept: application/json; charset=UTF-8\r\n");
    try w.writeAll("Connection: Close\r\n");
    try w.writeAll("\r\n");

    const r = client.reader();

    const data = try r.readAllAlloc(alloc, std.math.maxInt(usize));

    std.debug.print("{}\n", .{data});
}
