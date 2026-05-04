import ahb3lite_pkg::*;
class ahb_coverage;
  virtual if_ahb.scoreboard  cvg_if;

  covergroup cg_ahb @(cvg_if.monitor_cb);
    option.per_instance = 1;
    cp_htrans: coverpoint cvg_if.monitor_cb.HTRANS {
      bins idle   = {HTRANS_IDLE};
      bins busy   = {HTRANS_BUSY};
      bins nonseq = {HTRANS_NONSEQ};
      bins seq    = {HTRANS_SEQ};
    }

    cp_hburst: coverpoint cvg_if.monitor_cb.HBURST {
      bins single = {HBURST_SINGLE};
      bins incr   = {HBURST_INCR};
      bins wrap4  = {HBURST_WRAP4};
      bins incr4  = {HBURST_INCR4};
      bins wrap8  = {HBURST_WRAP8};
      bins incr8  = {HBURST_INCR8};
      bins wrap16 = {HBURST_WRAP16};
      bins incr16 = {HBURST_INCR16};
    } 
    cp_hsize:  coverpoint cvg_if.monitor_cb.HSIZE {
      bins byte_size     =  {HSIZE_BYTE};
      bins halfword_size =  {HSIZE_HWORD};
      bins word_size     =  {HSIZE_WORD};
      ignore_bins unsupported_sizes = {[HSIZE_DWORD : HSIZE_B1024]}; 
    }

    cp_hwrite: coverpoint cvg_if.monitor_cb.HWRITE {
      bins read  = {0};
      bins write = {1};
    }

    cp_hready: coverpoint cvg_if.monitor_cb.HREADY {
        bins ready_0 = {0}; 
        bins ready_1 = {1};
    }

    cp_hresp: coverpoint cvg_if.monitor_cb.HRESP {
        bins okay  = {0};
        ignore_bins error = {1};   
    }

    cp_haddr: coverpoint cvg_if.monitor_cb.HADDR {
        bins region_1_outof_4 = {[16'h0000 : 16'h3FFF]};
        bins region_2_outof_4 = {[16'h4000 : 16'h7FFF]};
        bins region_3_outof_4 = {[16'h8000 : 16'hBFFF]};
        bins region_4_outof_4 = {[16'hC000 : 16'hFFFF]};
    }
    // Different write and read bursts
    cx_hburst_hwrite: cross cp_hburst, cp_hwrite {
        bins single_read  = binsof(cp_hburst.single) && binsof(cp_hwrite.read);
        bins single_write = binsof(cp_hburst.single) && binsof(cp_hwrite.write);
        bins incr_read    = binsof(cp_hburst.incr)   && binsof(cp_hwrite.read);
        bins incr_write   = binsof(cp_hburst.incr)   && binsof(cp_hwrite.write);
        bins wrap4_write  = binsof(cp_hburst.wrap4)  && binsof(cp_hwrite.write);
        bins wrap4_read   = binsof(cp_hburst.wrap4)  && binsof(cp_hwrite.read);
        bins incr4_write  = binsof(cp_hburst.incr4)  && binsof(cp_hwrite.write);
        bins incr4_read   = binsof(cp_hburst.incr4)  && binsof(cp_hwrite.read);
        bins wrap8_write  = binsof(cp_hburst.wrap8)  && binsof(cp_hwrite.write);
        bins wrap8_read   = binsof(cp_hburst.wrap8)  && binsof(cp_hwrite.read);
        bins incr8_write  = binsof(cp_hburst.incr8)  && binsof(cp_hwrite.write);
        bins incr8_read   = binsof(cp_hburst.incr8)  && binsof(cp_hwrite.read);
        bins wrap16_write = binsof(cp_hburst.wrap16) && binsof(cp_hwrite.write);
        bins wrap16_read  = binsof(cp_hburst.wrap16) && binsof(cp_hwrite.read);
        bins incr16_write = binsof(cp_hburst.incr16) && binsof(cp_hwrite.write);
        bins incr16_read  = binsof(cp_hburst.incr16) && binsof(cp_hwrite.read);

    }
    // write and read operation of different sizess
    cx_size_write: cross cp_hsize, cp_hwrite {
      bins byte_read      = binsof(cp_hsize.byte_size)     && binsof(cp_hwrite.read);
      bins byte_write     = binsof(cp_hsize.byte_size)     && binsof(cp_hwrite.write);
      bins halfword_read  = binsof(cp_hsize.halfword_size) && binsof(cp_hwrite.read);
      bins halfword_write = binsof(cp_hsize.halfword_size) && binsof(cp_hwrite.write);
      bins word_read      = binsof(cp_hsize.word_size)     && binsof(cp_hwrite.read);
      bins word_write     = binsof(cp_hsize.word_size)     && binsof(cp_hwrite.write);
    }
    cx_htrans_hready: cross cp_htrans, cp_hready {
        option.cross_auto_bin_max = 0;
        bins seq_stalled = binsof(cp_htrans.seq) && binsof(cp_hready.ready_0);
    }
    

  endgroup


  function new(virtual if_ahb.scoreboard vif);
    this.cvg_if = vif;
    cg_ahb = new(); 
  endfunction
  

endclass