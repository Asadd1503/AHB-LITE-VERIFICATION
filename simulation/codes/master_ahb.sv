import ahb3lite_pkg::*;
class master_ahb #(parameter HADDR_SIZE = 16, HDATA_SIZE = 32);
    virtual if_ahb.master_class master_if;


    function new(virtual if_ahb.master_class vif);
        this.master_if = vif;
    endfunction

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

task drive_transaction(
    trans_ahb req
);

    automatic logic [HADDR_SIZE-1:0] cur_addr;
    cur_addr = req.haddr;

    @(master_if.master_cb);
    master_if.master_cb.HADDR  <= cur_addr;
    master_if.master_cb.HWRITE <= req.hwrite;
    master_if.master_cb.HSIZE  <= req.hsize;
    master_if.master_cb.HBURST <= req.hburst;
    master_if.master_cb.HTRANS <= HTRANS_NONSEQ;

    // Remaining Beats
    for (int i = 0; i <= req.hwdata.size(); i++) begin
        do begin
            @(master_if.master_cb);
        end while (master_if.master_cb.HREADY == 1'b0);

        if (req.hwrite) master_if.master_cb.HWDATA <= req.hwdata[i];

        if (i < req.hwdata.size() - 1) begin
            cur_addr = gen_nxt_adr(.cur_adr(cur_addr), .hsize(req.hsize), .hburst(req.hburst)); 
            master_if.master_cb.HADDR  <= cur_addr;
            master_if.master_cb.HTRANS <= HTRANS_SEQ;

        end else begin

          master_if.master_cb.HTRANS <= HTRANS_IDLE;

        end
    end
endtask

endclass