# kule-fpga

## Project setup

Install [vivado-git](https://github.com/barbedo/vivado-git#installation). After cloning the project, open the project by clicking `Tools -> Run Tcl Script...`, and choose `kule-fpga.tcl`.
You have to do this each time you open the project. The tcl file runs a series of commands to set up the project correctly.

To add new files to git, first create the file in the `src` directory. Then, in Vivado, add the new file as a design source. You can just choose the whole `src` directory.

### Target Language

Since Verilog is a bit hard to work with, we use SystemVerilog. It has all the features of Verilog, with some extras. See [this site](https://vlsiverify.com/systemverilog) for some examples and tutorials on SystemVerilog. Also [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page) has some nice tutorials in Verilog.
