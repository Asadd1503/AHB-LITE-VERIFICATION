import ahb3lite_pkg::*;
interface if_ahb #(
    parameter HADDR_SIZE        = 16,
    parameter HDATA_SIZE        = 32
)(
    input logic HCLK,
    input logic HREADY
);
    timeunit 1ns;
    timeprecision 1ns;
    //logic HCLK;
    logic HRESETn;
    logic HSEL;
    logic HWRITE;
    logic [HADDR_SIZE-1:0]  HADDR;
    logic [HSIZE_SIZE-1:0]  HSIZE;
    logic [HBURST_SIZE-1:0] HBURST;
    logic [HTRANS_SIZE-1:0] HTRANS;
    logic [HDATA_SIZE-1:0]  HWDATA;
    logic [HDATA_SIZE-1:0]  HRDATA;

modport ahb_dut (
    input HADDR, HSIZE, HBURST, HTRANS, HWDATA, HSEL, HWRITE, HRESETn,
    output HRDATA
);
modport ahb_tb (
    output HRESETn,
    clocking master_cb,
    import simple_write, simple_read , write_burst, read_burst, b2b_write_read  
);
modport master_class (
  clocking master_cb
);

modport scoreboard (
    clocking monitor_cb
    
);
//------------- Master clocking block ----------------
clocking master_cb @(posedge HCLK);
    default input #1step output #2ns;
    output HADDR, HSIZE, HBURST, HTRANS, HWRITE, HWDATA, HSEL;
    input  HRDATA, HREADY;
endclocking
//----------------------------------------------------
//------------- Slave clocking block ----------------
clocking monitor_cb @(posedge HCLK);
    default input #1step;
    
    // Everything is an input to a monitor! It just watches.
    input HADDR, HSIZE, HBURST, HTRANS, HWRITE, HWDATA;
    input HRDATA, HREADY;
endclocking
// ---------------------------------------------------
// -------------- FUNCTIONS TO DETERMINE NEXT ADDRESS -----------------------
  function automatic logic [HADDR_SIZE-1:0] gen_nxt_adr_incr;
    //Returns the next address for an incrementing burst
    input [HADDR_SIZE-1:0] cur_adr;
    input [HSIZE_SIZE-1:0] hsize;

    case (hsize)
       HSIZE_B1024: gen_nxt_adr_incr = cur_adr + 'h128;
       HSIZE_B512 : gen_nxt_adr_incr = cur_adr + 'h 64;
       HSIZE_B256 : gen_nxt_adr_incr = cur_adr + 'h 32;
       HSIZE_B128 : gen_nxt_adr_incr = cur_adr + 'h 16;
       HSIZE_DWORD: gen_nxt_adr_incr = cur_adr + 'h 8;
       HSIZE_WORD : gen_nxt_adr_incr = cur_adr + 'h 4;
       HSIZE_HWORD: gen_nxt_adr_incr = cur_adr + 'h 2;
       default    : gen_nxt_adr_incr = cur_adr + 'h 1;
    endcase
  endfunction : gen_nxt_adr_incr


  function automatic logic [HADDR_SIZE-1:0] gen_nxt_adr_wrap;
    //Returns the next address for a wrapping burst
    input [HADDR_SIZE -1:0] cur_adr;
    input [HSIZE_SIZE -1:0] hsize;
    input [HBURST_SIZE-1:0] hburst;

    logic [HADDR_SIZE-1:0] mask;

    //mask cur_adr
    case (hburst)
      HBURST_WRAP16: mask = { {HADDR_SIZE-4{1'b1}}, 4'h0};
      HBURST_WRAP8 : mask = { {HADDR_SIZE-3{1'b1}}, 3'h0};
      default      : mask = { {HADDR_SIZE-2{1'b1}}, 2'h0};
    endcase

    //mask depends on transfer size
    case (hsize)
       HSIZE_B1024: mask = mask << 64;
       HSIZE_B512 : mask = mask << 32;
       HSIZE_B256 : mask = mask << 16;
       HSIZE_B128 : mask = mask <<  8;
       HSIZE_DWORD: mask = mask <<  4;
       HSIZE_WORD : mask = mask <<  2;
       HSIZE_HWORD: mask = mask <<  1;
       default    : mask = mask <<  0;
    endcase

    //nxt wrapped address
    gen_nxt_adr_wrap = (cur_adr & mask) | (gen_nxt_adr_incr(cur_adr,hsize) & ~mask);
  endfunction : gen_nxt_adr_wrap


  function automatic logic [HADDR_SIZE-1:0] gen_nxt_adr;
    //returns next expected address
    input [HADDR_SIZE -1:0] cur_adr;
    input [HSIZE_SIZE -1:0] hsize;
    input [HBURST_SIZE-1:0] hburst;

    case (hburst)
      HBURST_WRAP16: gen_nxt_adr = gen_nxt_adr_wrap(cur_adr, hsize, hburst);
      HBURST_WRAP8 : gen_nxt_adr = gen_nxt_adr_wrap(cur_adr, hsize, hburst);
      HBURST_WRAP4 : gen_nxt_adr = gen_nxt_adr_wrap(cur_adr, hsize, hburst);
      default      : gen_nxt_adr = gen_nxt_adr_incr(cur_adr, hsize);
    endcase

  endfunction : gen_nxt_adr
//-------------------------------------------------------------------------------

task simple_write (
    input logic [HADDR_SIZE-1:0] h_addr_i,
    input logic [HSIZE_SIZE-1:0] h_size_i,
    input logic [HDATA_SIZE-1:0] h_data_i
);
    @(master_cb);
    // ADDR PHASE
    master_cb.HADDR <= h_addr_i; 
    master_cb.HSIZE <= h_size_i;
    master_cb.HBURST <= HBURST_SINGLE;
    master_cb.HTRANS <= HTRANS_NONSEQ;
    master_cb.HWRITE <= 1'b1;
    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0);
    // DATA PHASE
    master_cb.HWDATA <= h_data_i;
    master_cb.HTRANS <= HTRANS_IDLE;

    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0); 

    // DATA PHASE ENDS 
endtask : simple_write

task simple_read(
    input logic [HADDR_SIZE-1:0] h_addr_i,
    input logic [HSIZE_SIZE-1:0] h_size_i,
    output logic [HDATA_SIZE-1:0] h_data_o
);
    @(master_cb);
    // ADDR PHASE
    master_cb.HADDR <= h_addr_i;
    master_cb.HSIZE <= h_size_i;
    master_cb.HBURST <= HBURST_SINGLE;
    master_cb.HTRANS <= HTRANS_NONSEQ;
    master_cb.HWRITE <= 1'b0;
    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0);
    // DATA PHASE
    master_cb.HTRANS <= HTRANS_IDLE;
    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0); 
    h_data_o = master_cb.HRDATA;

    // DATA PHASE ENDS 
endtask : simple_read

// Task to perform INCR4, INCR8, or INCR16 writes
  task write_burst(
    input logic [HADDR_SIZE-1:0] start_addr_i, 
    input logic [HBURST_SIZE-1:0] burst_type_i, 
    input logic [HSIZE_SIZE-1:0] size_i,       
    input logic [HDATA_SIZE-1:0] data_i[]   
  );
    
    automatic int                    num_beats = data_i.size();
    automatic logic [HADDR_SIZE-1:0] current_addr = start_addr_i;

    @(master_cb);
    master_cb.HADDR  <= current_addr;
    master_cb.HWRITE <= 1'b1;         
    master_cb.HSIZE  <= size_i;
    master_cb.HBURST <= burst_type_i;
    master_cb.HTRANS <= HTRANS_NONSEQ;        // NONSEQ for the first beat


    for (int i = 0; i <= num_beats; i++) begin
        do begin
          @(master_cb);
        end while (master_cb.HREADY == 1'b0);  
        master_cb.HWDATA <= data_i[i];

        if (i < num_beats - 1) begin
          current_addr = gen_nxt_adr(.cur_adr(current_addr), .hsize(size_i), .hburst(burst_type_i)); // Increment address
          master_cb.HADDR  <= current_addr;
          master_cb.HTRANS <= HTRANS_SEQ;                
        end else begin
            master_cb.HTRANS <= HTRANS_IDLE;

        end
    end
    
  endtask : write_burst

  // Task to perform INCR4, INCR8, or INCR16 reads
  task read_burst(
    input  logic [HADDR_SIZE-1:0] start_addr_i, 
    input  logic [HBURST_SIZE-1:0] burst_type_i, 
    input  logic [HSIZE_SIZE-1:0] size_i,
    input  int                    num_beats,       
    output logic [HDATA_SIZE-1:0] data_o[] 
  );
    
    automatic logic [HADDR_SIZE-1:0] current_addr = start_addr_i;
    automatic logic flag = 0;
    data_o = new[num_beats];

    @(master_cb);
    master_cb.HADDR  <= current_addr;
    master_cb.HWRITE <= 1'b0;        
    master_cb.HSIZE  <= size_i;
    master_cb.HBURST <= burst_type_i;
    master_cb.HTRANS <= HTRANS_NONSEQ;       

    for (int i = 0; i <= num_beats; i++) begin
      
        do begin
          @(master_cb);
        end while (master_cb.HREADY == 1'b0); 
        if (flag) begin
            data_o[i] = master_cb.HRDATA; // Capture read data
        end
        flag = 1;
        if (i < num_beats - 1) begin
          current_addr = gen_nxt_adr(.cur_adr(current_addr), .hsize(size_i), .hburst(burst_type_i)); 
          master_cb.HADDR  <= current_addr;
          master_cb.HTRANS <= HTRANS_SEQ;
        end else begin
          master_cb.HTRANS <= HTRANS_IDLE;
        end
         
    end
    
  endtask : read_burst

  task b2b_write_read (
    input logic  [HADDR_SIZE-1:0] write_addr_i,
    input logic  [HSIZE_SIZE-1:0] h_size_i,
    input logic  [HDATA_SIZE-1:0] write_data_i,
    input logic  [HADDR_SIZE-1:0] read_addr_i,
    output logic [HDATA_SIZE-1:0] read_data_o
  );
    @(master_cb);
    // 1st transfer address phase
    master_cb.HADDR <= write_addr_i;
    master_cb.HSIZE <= h_size_i;
    master_cb.HBURST <= HBURST_SINGLE;
    master_cb.HTRANS <= HTRANS_NONSEQ;
    master_cb.HWRITE <= 1'b1;
    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0);
    // 1st transfer data phase and 2nd transfer address phase
    master_cb.HWDATA <= write_data_i;
    master_cb.HWRITE <= 1'b0;
    master_cb.HTRANS <= HTRANS_NONSEQ;
    master_cb.HADDR  <= read_addr_i;
    master_cb.HBURST <= HBURST_SINGLE;
    do begin
        @(master_cb);
    end while(master_cb.HREADY == 1'b0);
    // 2nd transfer data phase
    master_cb.HTRANS <= HTRANS_IDLE;
    do begin
        @(master_cb);
    end while (master_cb.HREADY == 1'b0);
    read_data_o = master_cb.HRDATA;
    

  endtask : b2b_write_read




   
endinterface