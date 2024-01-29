package decompose

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:c"
import path "core:path/filepath"
import "vendor:stb/image"

copy_channel :: proc(dst: []byte, src: [^]byte, x, y: int, c: Channel)
{
    for i := 0; i < x*y; i += 1
    {
        dst[4*i + int(c)] = src[i]
    }
}

set_channel :: proc(dst: []byte, x, y: int, c: Channel, value: byte)
{
    for i := 0; i < x*y; i += 1
    {
        dst[4*i + int(c)] = value
    }
}

Channel :: enum
{
    R = 0,
    G = 1,
    B = 2,
    A = 3,
}

Channels :: bit_set[Channel]

main :: proc()
{
    args := os.args

    context.allocator = context.temp_allocator

    if len(args) < 2
    {
        fmt.eprintf("needs at least one image\n")
    }

    dst: []byte
    dst_x := -1
    dst_y := -1

    channels: Channels

    @(thread_local)
    buf: [1024]byte

    for file_index := 1; file_index < len(args); file_index += 1
    {
        file := args[file_index]

        x_, y_, c_: c.int
        img := image.load(strings.clone_to_cstring(file), &x_, &y_, &c_, c.int(1))

        if (c_ != 1)
        {
            fmt.eprintf("image has to be single channel\n")
            os.exit(-1)
        }

        x, y, c := int(x_), int(y_), int(c_)

        if dst == nil
        {
            dst = make([]byte, x*y*4)
            dst_x = x
            dst_y = y
        }

        fmt.printf("processing %v:\nwhat channel should this go in?\nr: red, g: green, b: blue, a: alpha\n", file);

        total_read, _ := os.read(os.stdin, buf[:])
        str := transmute(string)buf[:total_read]
        str = strings.to_lower(strings.trim_space(str))

        channel: Channel

        switch str
        {
            case "r": copy_channel(dst, img, x, y, .R); channel = .R
            case "g": copy_channel(dst, img, x, y, .G); channel = .G
            case "b": copy_channel(dst, img, x, y, .B); channel = .B
            case "a": copy_channel(dst, img, x, y, .A); channel = .A
        }

        channels += {channel}

        fmt.printf("ok, going in %v\n", channel)
    }

    missing_channels := ~channels
    for channel in Channel
    {
        if channel not_in missing_channels do continue

        fmt.printf("what value should go in %v?\n", channel)

        total_read, _ := os.read(os.stdin, buf[:])
        str := transmute(string)buf[:total_read]
        str = strings.to_lower(strings.trim_space(str))

        for 
        {
            value, ok := strconv.parse_i64(str);

            if ok
            {
                if value >= 0 && value < 256
                {
                    set_channel(dst, dst_x, dst_y, channel, byte(value))
                    fmt.printf("ok, putting %v in %v\n", value, channel)
                    break
                }
                else
                {
                    fmt.eprintf("value out of range\n")
                }
            }
            else
            {
                fmt.eprintf("invalid value\n")
            }
        }
    }

    assert(dst_x != -1)
    assert(dst_y != -1)

    first_file := args[1]
    stem := path.stem(first_file)

    dst_file := strings.clone_to_cstring(fmt.tprintf("%s_merged.png", stem))
    image.write_png(dst_file, c.int(dst_x), c.int(dst_y), 4, raw_data(dst), c.int(dst_x*4))

    fmt.eprintf("successfully recomposed %v\n", dst_file)
}
