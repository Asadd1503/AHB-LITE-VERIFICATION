//=========================================================================
// AHB-Lite Slave Checker Assumptions Module for Formal Verification 
// Includes Assumptions for JasperGold (JS) with Default Clocking and Reset 
// CREATED BY:                          DATE: 
//=========================================================================

//------------------------- Package Import -------------------------------//
import ahb3lite_pkg::*;

module ahb_assumptions (
   input logic         HCLK,
   input logic         HRESETn,
   input logic [31:0]  HADDR,
   input logic [2:0]   HSIZE,
   input logic [1:0]   HTRANS,  
   input logic [2:0]   HBURST,
   input logic         HWRITE,
   input logic         HSEL,
   input logic         HREADY,
   input logic [3:0]   HPROT  
);



   asm_reset_idle: assume property (@(posedge HCLK) !HRESETn |-> HTRANS == IDLE);


  //--------------------- Default Clocking and Reset -------------------------//
  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  
  //------------------------------- Local Parameters -------------------------//
  localparam IDLE = 2'b00, BUSY = 2'b01, NONSEQ = 2'b10, SEQ = 2'b11;


  //-------------------------------------------------------------------------
  // ASMP-1 (Section 3.6): Master Stability
  //-------------------------------------------------------------------------
  asm_wait_stability: assume property (
      (!HREADY && HTRANS != IDLE) |-> ##1 ($stable(HADDR) && $stable(HWRITE))
  );


  //-------------------------------------------------------------------------
  // ASMP-2 (Section 3.4 & 3.5): Alignment & Boundary
  //-------------------------------------------------------------------------
  asm_addr_alignment: assume property (
      (HTRANS != IDLE) |-> (
         (HSIZE == 3'b001 -> HADDR[0] == 1'b0) &&
         (HSIZE == 3'b010 -> HADDR[1:0] == 2'b00)
      )
  );


  //-------------------------------------------------------------------------
  // ASMP-3: 1KB Boundary
  //-------------------------------------------------------------------------
  asm_1kb_boundary: assume property (
      (HTRANS == SEQ) |-> (HADDR[31:10] == $past(HADDR[31:10]))
  );


  //-------------------------------------------------------------------------
  // ASMP-4 (Section 3.2): Protocol Integrity 
  //-------------------------------------------------------------------------
  asm_htrans_seq_rule: assume property (
      (HTRANS == SEQ) |-> ($past(HTRANS) inside {NONSEQ, SEQ})
  );


  //-------------------------------------------------------------------------
  // ASMP-5: Single Transfer
  //-------------------------------------------------------------------------
  asm_single_no_seq: assume property (
      HBURST == 3'b000 |-> HTRANS != SEQ
  );


  //-------------------------------------------------------------------------
  // ASMP-6: INCR4 Finish
  //-------------------------------------------------------------------------
  asm_finish_incr4: assume property (@(posedge HCLK) 
      (HTRANS == HTRANS_NONSEQ && HBURST == HBURST_INCR4 && HREADY) |=> (HTRANS == HTRANS_SEQ)[*3]
  );


  //-------------------------------------------------------------------------
  // ASMP-7: 
  //-------------------------------------------------------------------------
   asm_master_seq_addr: assume property (@(posedge HCLK)
       (HREADY && HTRANS == HTRANS_SEQ) |-> 
       (HADDR == $past(HADDR) + (1 << $past(HSIZE)))
   );


  //-------------------------------------------------------------------------
  // ASMP-8: 
  //-------------------------------------------------------------------------
  asm_legal_hsize: assume property (@(posedge HCLK) 
      (HTRANS != HTRANS_IDLE) |-> (HSIZE <= HSIZE_WORD)
  );


  //-------------------------------------------------------------------------
  // ASMP-9: 
  //-------------------------------------------------------------------------
  asm_wait_stable: assume property (@(posedge HCLK) 
      (!HREADY && $past(HRESETn)) |=> ($stable(HADDR) && $stable(HWRITE) && $stable(HTRANS) && $stable(HSIZE) && $stable(HBURST))
  );

    
  //-------------------------------------------------------------------------
  // ASMP-10: 
  //-------------------------------------------------------------------------
  asm_wrap4_math: assume property (@(posedge HCLK)
      (HREADY && HTRANS == HTRANS_SEQ && HBURST == HBURST_WRAP4) |-> 
      (HADDR[3:0] == ($past(HADDR[3:0]) + (1 << $past(HSIZE))) % 16)
  );


  //-------------------------------------------------------------------------
  // ASMP-11: 
  //-------------------------------------------------------------------------
  asm_single_no_busy: assume property (@(posedge HCLK)
     (HBURST == HBURST_SINGLE) |-> (HTRANS != HTRANS_BUSY)
  );


  //-------------------------------------------------------------------------
  // ASMP-12: Liveness
  //-------------------------------------------------------------------------
  asm_master_wrap_align: assume property (@(posedge HCLK)
      (HREADY && HTRANS == HTRANS_SEQ && HBURST == HBURST_WRAP4) |-> 
      (HADDR[3:0] == ($past(HADDR[3:0]) + (1 << $past(HSIZE))) % 16)
   );


  //-------------------------------------------------------------------------
  // ASMP-13: Liveness
  //-------------------------------------------------------------------------
  asm_hsel_liveness: assume property (
      HSEL == 1'b1
  );



  //-------------------------------------------------------------------------
  // ASMP-14: HREADY Eventually be HIGH
  //-------------------------------------------------------------------------
  asm_hready_loop: assume property (
      s_eventually HREADY == 1'b1
  );


endmodule





