import ahb3lite_pkg::*;
// ADDING CLASSES DEFINATION
`include "scoreboard.sv"
`include "trans_ahb.sv"
`include "master_ahb.sv"

module tb_top;
    timeunit 1ns;
    timeprecision 1ns;
    logic clk = 0;
    always #5 clk = ~clk;
    logic HREADY;

    if_ahb if_ahb_inst (.HCLK(clk), .HREADY(HREADY));

    ahb3lite_slave dut (.HCLK(clk), .HREADYOUT(HREADY), .HREADY(HREADY), .if_ahb_dut(if_ahb_inst));

    ahb_lite_tb ahb_lite_tb_inst (.HCLK(clk), .if_ahb_tb(if_ahb_inst));

    scoreboard #(.HADDR_SIZE(16), .HDATA_SIZE(32)) scrbd_inst;

    trans_ahb #(.HADDR_SIZE(16), .HDATA_SIZE(32)) random_req;

    master_ahb #(.HADDR_SIZE(16), .HDATA_SIZE(32)) master_inst;

    initial begin
        scrbd_inst      = new(if_ahb_inst);
        master_inst     = new(if_ahb_inst);
        random_req      = new();
        fork
            scrbd_inst.run();
            `ifndef random_data 
                scrbd_inst.dissplay();
            `endif
        join_none

        @reset_done;

        for (int i=0; i<1000; i++) begin
            if(!random_req.randomize()) $fatal("Randomization Failed");
            // force write
            random_req.hwrite = 1;
            master_inst.drive_transaction(random_req);
            // force read
            random_req.hwrite = 0;
            master_inst.drive_transaction(random_req);


        end
        $display(" TEST FINISHED !");
        $stop;

    end

endmodule