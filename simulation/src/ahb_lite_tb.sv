import ahb3lite_pkg::*;
module ahb_lite_tb 
#(
    parameter HADDR_SIZE        = 16,
    parameter HDATA_SIZE        = 32
    
)(
    input logic HCLK,
    //input logic HERESTn,
    //output logic [HADDR_SIZE-1:0] HADDR,
    //output logic [HSIZE_SIZE-1:0] HSIZE,
    //output logic [HBURST_SIZE-1:0] HBURST,
    //output logic [HTRANS_SIZE-1:0] HTRANS,
    //output logic [HDATA_SIZE-1:0]  HWDATA,
    //input logic                    HREADY,
    if_ahb.ahb_tb if_ahb_tb
);
//--------- driver ---------------------
initial begin
    logic [HDATA_SIZE-1:0] data_out;
    logic [HDATA_SIZE-1:0] burst_wr_payload[];
    logic [HDATA_SIZE-1:0] burst_rd_payload[];
    int                    num_beats;
    if_ahb_tb.HRESETn = 0; if_ahb_tb.master_cb.HTRANS <= HTRANS_IDLE; if_ahb_tb.master_cb.HSIZE <= HSIZE_WORD; if_ahb_tb.master_cb.HBURST <= HBURST_SINGLE;
    @(if_ahb_tb.master_cb);
    if_ahb_tb.HRESETn = 1; if_ahb_tb.master_cb.HSEL <= 1'b1;
    @(if_ahb_tb.master_cb); 
    -> reset_done;
    // Test_id simple_1.1
   // if_ahb_tb.simple_write(16'h0000, HSIZE_WORD, 32'hDEADBEEF);
   // if_ahb_tb.simple_read(16'h0000, HSIZE_WORD, .h_data_o(data_out));
    // Test_id simple_1.2
   // if_ahb_tb.simple_write(16'h0006, HSIZE_HWORD, 32'hCAFEBABE);
   // if_ahb_tb.simple_read(16'h0006, HSIZE_HWORD, .h_data_o(data_out));
    // Test_id simple_1.3
   // if_ahb_tb.simple_write(16'h0008, HSIZE_BYTE, 32'h12345678);
   // if_ahb_tb.simple_read(16'h0008, HSIZE_BYTE, .h_data_o(data_out));
    
    
    //-------- Test_id burst 2.1 -------------
    /*
    burst_wr_payload = new[4];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    if_ahb_tb.write_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR4), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR4), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    
    //-------------------------------------
    */
    /*
    //-------- Test_id burst 2.2--------
    
    burst_wr_payload = new[8];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    burst_wr_payload[4] = 32'h55556666;
    burst_wr_payload[5] = 32'h77778888;
    burst_wr_payload[6] = 32'h9999AAAA;
    burst_wr_payload[7] = 32'hBBBBCCCC;
    if_ahb_tb.write_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR8), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR8), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    
    //-------------------------------------
    */
    /*
    //---------- Test_id burst 2.3 ------------
    burst_wr_payload = new[16];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    burst_wr_payload[4] = 32'h55556666;
    burst_wr_payload[5] = 32'h77778888;
    burst_wr_payload[6] = 32'h9999AAAA;
    burst_wr_payload[7] = 32'hBBBBCCCC;
    burst_wr_payload[8]  = 32'hDDDDEEEE;
    burst_wr_payload[9]  = 32'hFFFF1111;
    burst_wr_payload[10] = 32'h22225555;
    burst_wr_payload[11] = 32'h66667777;
    burst_wr_payload[12] = 32'h88889999;
    burst_wr_payload[13] = 32'hAAAABBBB;
    burst_wr_payload[14] = 32'hCCCCDDDD;
    burst_wr_payload[15] = 32'hEEEEFFFF;
    if_ahb_tb.write_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR16), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR16), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    //-------------------------------
    */
    /*
    //-------- Test_id wrap_3.1 --------------
    burst_wr_payload = new[4];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    if_ahb_tb.write_burst(.start_addr_i(16'h0014), .burst_type_i(HBURST_WRAP4), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0014), .burst_type_i(HBURST_WRAP4), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    //--------------------------------------
    */
    /*
    //---------- Test_id wrap_3.2 ----------
    burst_wr_payload = new[8];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    burst_wr_payload[4] = 32'h55556666;
    burst_wr_payload[5] = 32'h77778888;
    burst_wr_payload[6] = 32'h9999AAAA;
    burst_wr_payload[7] = 32'hBBBBCCCC;
    if_ahb_tb.write_burst(.start_addr_i(16'h0014), .burst_type_i(HBURST_WRAP8), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0014), .burst_type_i(HBURST_WRAP8), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    //--------------------------------------
    */
    /*
    //-------- Test_id hready_4.1 -------------
    
    burst_wr_payload = new[4];
    burst_wr_payload[0] = 32'hAAAABBBB;
    burst_wr_payload[1] = 32'hCCCCDDDD;
    burst_wr_payload[2] = 32'hEEEEFFFF;
    burst_wr_payload[3] = 32'h11112222;
    if_ahb_tb.write_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR4), .size_i(HSIZE_WORD), .data_i(burst_wr_payload));
    num_beats = burst_wr_payload.size();
    if_ahb_tb.read_burst(.start_addr_i(16'h0010), .burst_type_i(HBURST_INCR4), .size_i(HSIZE_WORD), .data_o(burst_rd_payload), .num_beats(num_beats));
    
    //-------------------------------------
    */
    // --------------Test_id b2b_5.1 -------------
    //if_ahb_tb.b2b_write_read(.write_addr_i(16'h0030), .read_addr_i(16'h0030), .h_size_i(HSIZE_WORD), .write_data_i(32'hDEADBEEF), .read_data_o(data_out));
    //--------------------------------------------
    //$stop;

end
endmodule