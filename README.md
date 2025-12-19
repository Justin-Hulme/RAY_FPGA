Raycasting program written for Basys 3 FPGA boards.

Developed by Cole Francis, Justin Hulme, and Maggie Michelsen.

Uses DDA (Digital Differential Analysis) Raycasting to output via VGA.

# Project Architecture
This project uses a MicroBlaze CPU to place information into BRAM. The
graphics processing control unit takes this information from BRAM and 
sends it to to different process elements. These elements send the processed
information back to the control unit, which stores it into a FIFO buffer.
The column buffer reads from this, processes it, and sends it to to the
VGA components.
