FRAMEBUFFER_SIZE = 800 * 480
FRAMEBUFFER_WIDTH = 800
FRAMEBUFFER_HEIGHT = 480

with open("fb_data.coe", "w+") as f:
    f.write("memory_initialization_radix=2;\n")
    f.write("memory_initialization_vector=\n")
    for i in range(int(FRAMEBUFFER_SIZE / 2)):
        f.write(bin(0)[2:].zfill(4) + ",\n")
    for i in range(int(FRAMEBUFFER_SIZE / 2)):
        if (i == FRAMEBUFFER_SIZE / 2 - 1):
            f.write(bin(1)[2:].zfill(4) + ";")
        else:
            f.write(bin(1)[2:].zfill(4) + ",\n")
