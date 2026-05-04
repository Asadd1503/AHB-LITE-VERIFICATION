//=========================================================================
// AHB-Lite Slave Checker Module
// Includes Properties and Assertions with Default Clocking and Reset 
// CREATED BY: Naqi Ul Hassan          
//=========================================================================

//------------------------- Package Import -------------------------------//
import ahb3lite_pkg::*;

module ahb_checker (
   input logic         HCLK,
   input logic         HRESETn,
   input logic [31:0]  HADDR,
   input logic [2:0]   HSIZE,
   input logic [1:0]   HTRANS,  
   input logic [2:0]   HBURST,
   input logic         HWRITE,
   input logic         HSEL,
   input logic         HREADY,
   input logic         HREADYOUT,   // Output HREADY from Slave (Shows Readiness of Slave) 
   input logic         HRESP,       // 0: OKAY, 1: ERROR
   input logic [31:0]  HWDATA,
   input logic [31:0]  HRDATA     
);

  
  //--------------------- Default Clocking and Reset -------------------------//
  default clocking cb @(posedge HCLK); endclocking
  default disable iff (!HRESETn);

  // Localparams for HTRANS
  localparam IDLE   = 2'b00;
  localparam BUSY   = 2'b01;
  localparam NONSEQ = 2'b10;
  localparam SEQ    = 2'b11;


  //=========================================================================
  // ------------------- 1. PROTOCOL INTERFACE ASSERTIONS -------------------
  //=========================================================================

  
  //-------------------------------------------------------------------------
  // SPEC-1 (Section 3.4): HADDR Alignment
  // Address Must be Aligned to the Size of the Transfer
  //-------------------------------------------------------------------------
  assert_haddr_alignment: assert property (
   (HTRANS != IDLE) |-> (
        (HSIZE == 3'b001 -> HADDR[0]    == 1'b0) &&   // Halfword (16-Bits)
        (HSIZE == 3'b010 -> HADDR[1:0]  == 2'b00)     // Word (32-Bits)
     )  
  ) else $error("ERR: HADDR Alignment Violation for HSIZE: %0d", HSIZE);


  //-------------------------------------------------------------------------
  // SPEC-2 (Section 3.2): HTRANS SEQUENCING
  // SEQ Must Follow NONSEQ or SEQ
  // Cannot Follow IDLE or BUSY at Burst Start 
  //-------------------------------------------------------------------------
  assert_htrans_sequencing: assert property (
      (HTRANS == SEQ) |-> ($past(HTRANS) == NONSEQ || $past(HTRANS) == SEQ)
  ) else $error("ERR: SEQ Transfer Issued Without Preceding NONSEQ/SEQ");


  //-------------------------------------------------------------------------
  // SPEC-3 (Section 3.6): Wait State Stability
  // Master Must Hold Address/Control Stable if HREADY is LOW
  //-------------------------------------------------------------------------
  assert_wait_state_stability: assert property (
      (!HREADY) |=> ($stable(HADDR) && $stable(HWRITE) &&
                     $stable(HSIZE) && $stable(HBURST) && $stable(HTRANS))
  ) else $error("ERR: Master Changed Control Signals While HREADY was LOW");


  //-------------------------------------------------------------------------
  // SPEC-4 (Section 3.5): Burst Continuity
  // Fixed-length Bursts Must Finish Declared Beats
  // EXAMPLE: INCR4 (4 Beats) = 1 NONSEQ + 3 SEQ Beats
  //-------------------------------------------------------------------------
  assert_burst_continuity_incr4: assert property (
      (HTRANS == NONSEQ && HBURST == 3'b011) |=> (HTRANS == SEQ)[*3]
  ) else $error("ERR: INCR4 Burst Interrupted Before Completion");


  //-------------------------------------------------------------------------
  // SPEC-5 (Section 3.5): 1KB Boundary 
  // Incrementing Bursts Must Not Cross a 1KB Address Boundary 
  //-------------------------------------------------------------------------
  assert_1kb_boundary_cross: assert property (
      (HTRANS == SEQ) |-> (HADDR[31:10] == $past(HADDR[31:10])) 
  ) else $error("ERR: Burst Crossed 1KB address boundary");


  //-------------------------------------------------------------------------
  // SPEC-6 (Section 5.1): Error Response Protocol  
  // Cycle 1: HRESP == 1 and HREADY == 0 , Cycle 2: HRESP == 1 and HREADY == 1  
  //-------------------------------------------------------------------------
  assert_error_resp_timing: assert property (
      (HRESP == 1'b1 && $past(HRESP) == 1'b0) |-> (!HREADYOUT ##1 (HRESP == 1'b1 &&
        HREADYOUT))
  ) else $error("ERR: Invalid 2-cycle ERROR Response Sequence");


  //-------------------------------------------------------------------------
  // SPEC-7 (Section 3.5.1): Illegal BUSY In SINGLE Transfer    
  //-------------------------------------------------------------------------
  assert_no_busy_in_single: assert property (
      (HBURST == 3'b000) |-> (HTRANS != BUSY)
  ) else $error("ERR: BUSY Transfer Type Used During SINGLE Burst");



  //=========================================================================
  // --------------- 2. MEMORY-SPECIFIC FUNCTIONAL ASSERTIONS ---------------
  //=========================================================================


  //-------------------------------------------------------------------------
  // SPEC-8 (Section 7.1): Reset State  
  // Immediately After Reset, HREADY Must be HIGH and HRESP = OKAY  
  //-------------------------------------------------------------------------
  assert_reset_behaviour: assert property (
      $past(!HRESETn) && HRESETn |-> (HREADYOUT == 1'b1 && HRESP == 1'b0)
  )else $error ("ERR: Slave Not Ready/OKAY Immediately After Reset");


  //-------------------------------------------------------------------------
  // SPEC-9:   
  // Memory Should Only Change If HWRITE is HIGH and Slave is Selected
  //-------------------------------------------------------------------------
  assert_write_condition: assert property (
      (HWRITE && HSEL && HREADY && HTRANS != IDLE) |-> (HRESP == 1'b0)
  ) else $error("ERR: Valid Write Rejected By Slave");


  //-------------------------------------------------------------------------
  // SPEC-10: Byte-Lane Protection    
  // Byte Write Shouldn't Affect Other Bytes
  //-------------------------------------------------------------------------
  assert_valid_hsize: assert property (
      (HTRANS != IDLE) |-> (HSIZE <= 3'b010) //HSIZE > Word is Invalid (RAM=32-Bits)
  )else $error("ERR: HSIZE Exceeds Data Bus Width");



  //=========================================================================
  // ---------------------- 3. LIVENESS PROPERTY CHECK ----------------------
  //=========================================================================
  
  
  //-------------------------------------------------------------------------
  // SPEC-11: Liveness    
  // Slave Must Eventually Respond
  //-------------------------------------------------------------------------
  assert_liveness_hready: assert property (
      (HSEL && HREADY && HTRANS != IDLE) |-> s_eventually (HREADYOUT == 1'b1)
  )else $error("ERR: Slave Deadlocked - HREADY Never Returned HIGH");



  //-------------------------------------------------------------------------    
  // ASSUMPTION: Master Must Send Aligned WRAP Addresses
  //-------------------------------------------------------------------------
  assume_master_wrap_align: assume property (
       (HBURST inside {3'b010, 3'b100, 3'b110}) |-> (
           (HSIZE == 3'b001 -> HADDR[0] == 1'b0) &&
           (HSIZE == 3'b010 -> HADDR[1:0] == 2'b00)
       )
  );



  //-------------------------------------------------------------------------
  // SPEC-12 (Section 3.5.1): Illegal Busy Termination    
  // Fixed Length Bursts (INCR4/8/16) Must Not Be Terminated by Deselecting
  // the Slave During BUSY
  //-------------------------------------------------------------------------
  assert_no_busy_term: assert property (
      (HBURST != 3'b000 && HBURST != 3'b001) |-> !(HTRANS == 2'b01 && $fell(HSEL))
  )else $error("ERR: Fixed Length Bursts Cannot End with BUSY");


  //-------------------------------------------------------------------------
  // SPEC-13 (Section 3.5.1): BUSY Cycle Slave Response    
  // Slave Must Provide a Zero Wait-State OKAY Response to a BUSY Transfer
  //-------------------------------------------------------------------------
  assert_busy_ok_response: assert property (
      (HTRANS == 2'b01 && HSEL) |-> (HREADYOUT == 1'b1 && HRESP == 1'b0) 
  )else $error("ERR: BUSY Transfer Must Receive Zero Wait-State OKAY");


  //-------------------------------------------------------------------------
  // SPEC-14 (Section 3.2): SEQ Address Calculation (Incrementing)    
  // Verify that Address Actually Increments During SEQ Beats
  //-------------------------------------------------------------------------
  assert_seq_addr_calc: assert property (
      (HREADY && HTRANS == 2'b11 && HBURST[0] == 1) |-> (HADDR == $past(HADDR) + (1          << $past(HSIZE)))
  )else $error("ERR: SEQ Address Calculation Mismatch");


  //-------------------------------------------------------------------------
  // SPEC-15 (Section 3.5): WRAP4 Word Boundary Check    
  // 4-Beat Wrapping Word Transfers (16-Byte Boundary)
  //-------------------------------------------------------------------------
  property p_wrap4_word;
     (HREADY && HTRANS == 2'b11 && HBURST == 3'b010 && HSIZE == 3'b010) |-> 
     (HADDR[3:0] == ($past(HADDR[3:0]) + 4) % 16) && (HADDR[31:4] == $past(HADDR[31:4]));
  endproperty
  assert_wrap4_boundary: assert property (p_wrap4_word)
  else $error(ERR: WRAP4 Boundary Violation);




  //=========================================================================
  // ---- VACUITY COVERS: ENSURE TESTS ACTUALLY TRIGGERED THESE SCENERIOS ---
  //=========================================================================
  cover_full_incr16: cover property (HBURST == 3'b111 && HTRANS == SEQ [*15]);
  cover_wrap4_event: cover property (HBURST == 3'b010 && HTRANS == SEQ [*3]);
  cover_error_response: cover property (HRESP == 1'b1);



endmodule