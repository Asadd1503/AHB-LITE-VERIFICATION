// Scoreboard Class Definition
import ahb3lite_pkg::*;
class scoreboard #(parameter HADDR_SIZE = 16, parameter HDATA_SIZE = 32);

    // 1. Virtual Interface (The software pointer to the hardware bus)
    virtual if_ahb.scoreboard scrbd_if;
    //localparam HADDR_SIZE = 16;
    //localparam HDATA_SIZE = 32;
    localparam BE_SIZE = 4;
    
    
    logic                  pending_tx;
    logic                  pending_write;
    logic [HADDR_SIZE-1:0] pending_addr;
    logic [ 2:0]           pending_size;
    logic [HDATA_SIZE-1:0] expected_data;
    logic [HDATA_SIZE-1:0] temp_data;
    logic [BE_SIZE-1:0] be;
 
    logic [HDATA_SIZE-1:0] mem [logic [HADDR_SIZE-1:0]];

    // 3. The Constructor
    // This is how we pass the physical interface into the class
    function new(virtual if_ahb.scoreboard vif);
        this.scrbd_if = vif;
        this.pending_tx = 0;
    endfunction

    function automatic logic [6:0] address_offset;
    //returns a mask for the lesser bits of the address
    //meaning bits [  0] for 16bit data
    //             [1:0] for 32bit data
    //             [2:0] for 64bit data
    //etc

    //default value, prevent warnings
    address_offset = 0;
	 
    //What are the lesser bits in if_ahb_dut.HADDR?
    case (HDATA_SIZE)
          1024: address_offset = 7'b111_1111; 
           512: address_offset = 7'b011_1111;
           256: address_offset = 7'b001_1111;
           128: address_offset = 7'b000_1111;
            64: address_offset = 7'b000_0111;
            32: address_offset = 7'b000_0011;
            16: address_offset = 7'b000_0001;
       default: address_offset = 7'b000_0000;
    endcase
  endfunction : address_offset

    function automatic logic [BE_SIZE-1:0] gen_be(input [2:0] hsize, input [HADDR_SIZE-1:0] haddr);
       logic [127:0] full_be;
       logic [  6:0] haddr_masked;

       case (hsize)
           3'b111: full_be = {128{1'b1}};  // HSIZE_B1024
           3'b110: full_be = { 64{1'b1}};  // HSIZE_B512
           3'b101: full_be = { 32{1'b1}};  // HSIZE_B256
           3'b100: full_be = { 16{1'b1}};  // HSIZE_B128
           3'b011: full_be = {  8{1'b1}};  // HSIZE_DWORD
           3'b010: full_be = {  4{1'b1}};  // HSIZE_WORD
           3'b001: full_be = {  2{1'b1}};  // HSIZE_HWORD
           default: full_be = {  1{1'b1}}; // HSIZE_BYTE
       endcase

       // Assuming address_offset() returns the correct mask
       haddr_masked = haddr & address_offset(); 
       gen_be = full_be[BE_SIZE-1:0] << haddr_masked;
    endfunction



    task run();
        forever begin
            @(scrbd_if.monitor_cb);

            if (scrbd_if.monitor_cb.HREADY && pending_tx) begin
                
                be = gen_be(pending_size, pending_addr);
                
                if (pending_write) begin
                    temp_data = mem.exists(pending_addr) ? mem[pending_addr] : 32'h0;
                    for (int i=0; i<BE_SIZE; i++) begin
                        if (be[i]) begin 
                            temp_data[i*8+:8] = scrbd_if.monitor_cb.HWDATA[i*8+:8];
                        end
                    end
                    mem[pending_addr] = temp_data;
                    $display("[Time : %0t] [INFO]: Write transaction at address %h with data %h and byte enable %b", 
                            $time, pending_addr, temp_data, be);
                end 
                else begin
                    expected_data = mem[pending_addr];
                    $display("[Time : %0t] [INFO]: Read transaction at address %h with expected data %h and received data %h and byte enable %b", 
                            $time, pending_addr, expected_data, scrbd_if.monitor_cb.HRDATA, be);
                    for (int i=0; i<BE_SIZE; i++) begin
                        if (be[i]) begin 
                            if (expected_data[i*8+:8] !== scrbd_if.monitor_cb.HRDATA[i*8+:8]) begin
                                $warning("Data mismatch at address %h: expected %h, got %h", 
                                        pending_addr, expected_data[i*8+:8], scrbd_if.monitor_cb.HRDATA[i*8+:8]);
                            end
                            else begin
                                $display("[PASS]: Data match at address %h: expected %h, got %h", 
                                        pending_addr, expected_data[i*8+:8], scrbd_if.monitor_cb.HRDATA[i*8+:8]);
                            end
                        end
                    end
                end
            end

            if (scrbd_if.monitor_cb.HREADY) begin
                if (scrbd_if.monitor_cb.HTRANS == 2'b10 || scrbd_if.monitor_cb.HTRANS == 2'b11) begin
                    pending_addr  <= scrbd_if.monitor_cb.HADDR;
                    pending_write <= scrbd_if.monitor_cb.HWRITE;
                    pending_size  <= scrbd_if.monitor_cb.HSIZE;
                    pending_tx    <= 1'b1;
                end 
                else begin
                    // IDLE or BUSY
                    pending_tx <= 1'b0;
                end
            end 
        
             
        end // end forever
    endtask
    task dissplay();
        forever begin
            @(scrbd_if.monitor_cb);
            #1ns;
            $display("[Time: %0t], pending_tx: %b, pending_write: %b, pending_addr: %0h, pending_size: %b, expected_data: %0h", 
                    $time, pending_tx, pending_write, pending_addr, pending_size, expected_data);

        end // end forever
    endtask


endclass