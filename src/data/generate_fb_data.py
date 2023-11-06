FRAMEBUFFER_SIZE = 800 * 480
FRAMEBUFFER_WIDTH = 800
FRAMEBUFFER_HEIGHT = 480

with open("fb_data.data", "w+") as f:
    for i in range(int(FRAMEBUFFER_SIZE / 2)):
        f.write(bin(0)[2:].zfill(4) + "\n")
    for i in range(int(FRAMEBUFFER_SIZE / 2)):
        f.write(bin(1)[2:].zfill(4) + "\n")
