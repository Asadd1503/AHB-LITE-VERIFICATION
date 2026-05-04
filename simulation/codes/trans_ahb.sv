import ahb3lite_pkg::*;

class trans_ahb #(parameter HADDR_SIZE = 16, parameter HDATA_SIZE = 32);
    rand logic [HADDR_SIZE-1:0]  haddr;
    rand logic [HSIZE_SIZE-1:0]  hsize;
    rand logic [HBURST_SIZE-1:0] hburst;
    rand logic                   hwrite;
    rand logic [HDATA_SIZE-1:0]  hwdata[];

constraint c_supported_types {
    hsize  inside {HSIZE_BYTE, HSIZE_HWORD, HSIZE_WORD};         // Only allow Byte, Halfword, Word
    hburst inside {HBURST_SINGLE, HBURST_WRAP4, HBURST_INCR4, HBURST_WRAP8, HBURST_INCR8, HBURST_WRAP16, HBURST_INCR16}; 
}

constraint c_alignment {
    if (hsize == HSIZE_HWORD) haddr[0] == 1'b0;      // Halfword -> Even addresses only
    if (hsize == HSIZE_WORD) haddr[1:0] == 2'b00;   // Word -> Divisible by 4
}
constraint c_data_size {
    if (hburst == HBURST_SINGLE) hwdata.size() == 1;   // SINGLE
    if (hburst == HBURST_INCR4 || hburst == HBURST_WRAP4)  hwdata.size() == 4;  
    if (hburst == HBURST_INCR8 || hburst == HBURST_WRAP8)  hwdata.size() == 8;   // INCR8
    if (hburst == HBURST_INCR16 || hburst == HBURST_WRAP16) hwdata.size() == 16;  // INCR16
}
constraint c_boundary {
    (haddr % 1024) + (hwdata.size() * (1 << hsize)) <= 1024;
}

endclass