package decompose

import "core:os"
import "core:fmt"
import "core:strings"
import "core:c"
import path "core:path/filepath"
import "vendor:stb/image"

copy_channel :: proc(dst: []byte, src: [^]byte, x, y, c: int)
{
    for i := 0; i < x*y; i += 1
    {
        dst[i] = src[4*i + c]
    }
}

main :: proc()
{
    args := os.args

    if len(args) != 2
    {
        fmt.eprintf("invalid arguments\n")
    }

    file := args[1]

    x_, y_, c_: c.int
    img := image.load(strings.clone_to_cstring(file), &x_, &y_, &c_, c.int(4))

    x, y, c := int(x_), int(y_), int(c_)

    img_r := make([]byte, x*y)
    copy_channel(img_r, img, x, y, 0)

    img_g := make([]byte, x*y)
    copy_channel(img_g, img, x, y, 1)

    img_b := make([]byte, x*y)
    copy_channel(img_b, img, x, y, 2)

    img_a := make([]byte, x*y)
    copy_channel(img_a, img, x, y, 3)

    stem := path.stem(file)
    image.write_png(strings.clone_to_cstring(fmt.tprintf("%s_r.png", stem)), x_, y_, 1, raw_data(img_r), x_)
    image.write_png(strings.clone_to_cstring(fmt.tprintf("%s_g.png", stem)), x_, y_, 1, raw_data(img_g), x_)
    image.write_png(strings.clone_to_cstring(fmt.tprintf("%s_b.png", stem)), x_, y_, 1, raw_data(img_b), x_)
    image.write_png(strings.clone_to_cstring(fmt.tprintf("%s_a.png", stem)), x_, y_, 1, raw_data(img_a), x_)

    fmt.eprintf("successfully decomposed %v\n", file)
}
