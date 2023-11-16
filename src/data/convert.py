lines = []

with open("sprite.mem", "r") as f:
    lines = f.readlines()

with open("sprite.coe", "w+") as f:
    f.write("memory_initialization_radix=2;\n")
    f.write("memory_initialization_vector=\n")
    for line in lines:
        l = line.strip().split(" ")
        f.write(",\n".join([j+i for i,j in zip(l[::2], l[1::2])]) + ",\n")
