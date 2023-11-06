FRAMEBUFFER_SIZE = 800 * 480
FRAMEBUFFER_WIDTH = 800
FRAMEBUFFER_HEIGHT = 480

with open("fb_data.data", "w+") as f:
    for sy in range(FRAMEBUFFER_HEIGHT):
        for sx in range(FRAMEBUFFER_WIDTH):
            if sx >= 300 and sx < 500 and sy >= 140:
                f.write(bin(0)[2:].zfill(4) + "\n")
            else:
                f.write(bin(1)[2:].zfill(4) + "\n")

    #for i in range(int(FRAMEBUFFER_SIZE / 2)):
    #    f.write(bin(5)[2:].zfill(4) + "\n")
    #for i in range(int(FRAMEBUFFER_SIZE / 2)):
    #    f.write(bin(10)[2:].zfill(4) + "\n")
