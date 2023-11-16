// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Francesco Conti - f.conti@unibo.it                         //
//                                                                            //
// Additional contributions by:                                               //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    RISC-V register file                                       //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Register file with 31x 32 bit wide registers. Register 0   //
//                 is fixed to 0. This register file is based on flip-flops.  //
//                 Also supports the fp-register file now if FPU=1            //
//                 If ZFINX is 1, floating point operations take values       //
//                 from the X register file                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cv32e40px_register_file #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter FPU        = 0,
    parameter ZFINX      = 0,
    parameter COREV_X_IF = 0,
    parameter X_DUALREAD = 0,
    parameter X_DUALWRITE = 0
) (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    input logic scan_cg_en_i,

    input logic dualread_i,
    input logic dualwrite_i,

    //Read port R1
    input  logic [ADDR_WIDTH-1:0] raddr_a_i,
    output logic [X_DUALREAD:0][DATA_WIDTH-1:0] rdata_a_o,

    //Read port R2
    input  logic [ADDR_WIDTH-1:0] raddr_b_i,
    output logic [X_DUALREAD:0][DATA_WIDTH-1:0] rdata_b_o,

    //Read port R3
    input  logic [ADDR_WIDTH-1:0] raddr_c_i,
    output logic [X_DUALREAD:0][DATA_WIDTH-1:0] rdata_c_o,

    // Write port W1
    input logic [X_DUALWRITE:0][ADDR_WIDTH-1:0] waddr_a_i,
    input logic [X_DUALWRITE:0][DATA_WIDTH-1:0] wdata_a_i,
    input logic [X_DUALWRITE:0]                 we_a_i,

    // Write port W2
    input logic [X_DUALWRITE:0][ADDR_WIDTH-1:0] waddr_b_i,
    input logic [X_DUALWRITE:0][DATA_WIDTH-1:0] wdata_b_i,
    input logic [X_DUALWRITE:0]                 we_b_i
);

  // number of integer registers
  localparam NUM_WORDS = 2 ** (ADDR_WIDTH - 1);
  // number of floating point registers
  localparam NUM_FP_WORDS = 2 ** (ADDR_WIDTH - 1);
  localparam NUM_TOT_WORDS = FPU ? (ZFINX ? NUM_WORDS : NUM_WORDS + NUM_FP_WORDS) : NUM_WORDS;

  // integer register file
  logic [    NUM_WORDS-1:0][DATA_WIDTH-1:0] mem;

  // fp register file
  logic [ NUM_FP_WORDS-1:0][DATA_WIDTH-1:0] mem_fp;

  // masked write addresses
  logic [X_DUALWRITE:0] [   ADDR_WIDTH-1:0]                 waddr_a;
  logic [X_DUALWRITE:0] [   ADDR_WIDTH-1:0]                 waddr_b;

  // write enable signals for all registers
  logic [X_DUALWRITE:0] [NUM_TOT_WORDS-1:0]                 we_a_dec;
  logic [X_DUALWRITE:0] [NUM_TOT_WORDS-1:0]                 we_b_dec;


  //-----------------------------------------------------------------------------
  //-- READ : Read address decoder RAD
  //-----------------------------------------------------------------------------
  generate
    if (COREV_X_IF != 0) begin
      if (X_DUALREAD) begin
        always_comb begin
          if (dualread_i) begin
            rdata_a_o[0] = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
            rdata_b_o[0] = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
            rdata_c_o[0] = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];
            rdata_a_o[1] = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0] | 5'b00001] : mem[raddr_a_i[4:0] | 5'b00001];
            rdata_b_o[1] = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0] | 5'b00001] : mem[raddr_b_i[4:0] | 5'b00001];
            rdata_c_o[1] = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0] | 5'b00001] : mem[raddr_c_i[4:0] | 5'b00001];
          end else begin
            rdata_a_o[0] = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
            rdata_b_o[0] = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
            rdata_c_o[0] = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];
            rdata_b_o[1] = '0;
            rdata_a_o[1] = '0;
            rdata_c_o[1] = '0;
          end
        end
      end else begin
        assign rdata_a_o = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
        assign rdata_b_o = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
        assign rdata_c_o = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];
      end
    end else begin
      assign rdata_a_o = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
      assign rdata_b_o = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
      assign rdata_c_o = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];
    end
  endgenerate

  //-----------------------------------------------------------------------------
  //-- WRITE : Write Address Decoder (WAD), combinatorial process
  //-----------------------------------------------------------------------------

  // Mask top bit of write address to disable fp regfile
  generate
    if (COREV_X_IF != 0) begin
      if (X_DUALWRITE) begin
        always_comb begin
          if (dualwrite_i) begin
            waddr_a[0]  = waddr_a_i[0];
            waddr_b[0]  = waddr_b_i[0];
            waddr_a[1]  = waddr_a_i[0]^1'b1;
            waddr_b[1]  = waddr_b_i[0]^1'b1;
          end else begin
            waddr_a[0]  = waddr_a_i[0];
            waddr_b[0]  = waddr_b_i[0];
            waddr_a[1]  = '0;
            waddr_b[1]  = '0; 
          end
        end
      end else begin
        assign waddr_a   = waddr_a_i;
        assign waddr_b   = waddr_b_i;
      end
    end else begin
      assign waddr_a   = waddr_a_i;
      assign waddr_b   = waddr_b_i;
    end
  endgenerate



  genvar gidx;
  generate
    for (gidx = 0; gidx < NUM_TOT_WORDS; gidx++) begin : gen_we_decoder
      assign we_a_dec[gidx] = (waddr_a == gidx) ? we_a_i : 1'b0;
      assign we_b_dec[gidx] = (waddr_b == gidx) ? we_b_i : 1'b0;
    end
  endgenerate

  genvar i, l;
  
  generate

    //-----------------------------------------------------------------------------
    //-- WRITE : Write operation
    //-----------------------------------------------------------------------------
    // R0 is nil
    always_ff @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
        // R0 is nil
        mem[0] <= 32'b0;
      end else begin
        // R0 is nil
        mem[0] <= 32'b0;
      end
    end

    // loop from 1 to NUM_WORDS-1 as R0 is nil
    for (i = 1; i < NUM_WORDS; i++) begin : gen_rf
      always_ff @(posedge clk, negedge rst_n) begin : register_write_behavioral
        if (rst_n == 1'b0) begin
          mem[i] <= 32'b0;
        end else begin
          if (COREV_X_IF != 0) begin
              if (dualwrite_i) begin
                if (we_b_dec[i] == 1'b1)
                  mem[i] <= wdata_b_i[0];
                else if (we_a_dec[i] == 1'b1)
                  mem[i] <= wdata_a_i[0];
              end else begin
                if (we_b_dec[i] == 1'b1) mem[i] <= wdata_b_i;
                else if (we_a_dec[i] == 1'b1) mem[i] <= wdata_a_i;
              end
          end
        end
      end
    end


    if (FPU == 1 && ZFINX == 0) begin : gen_mem_fp_write
      // Floating point registers
      for (l = 0; l < NUM_FP_WORDS; l++) begin
        always_ff @(posedge clk, negedge rst_n) begin : fp_regs
          if (rst_n == 1'b0) mem_fp[l] <= '0;
          else if (we_b_dec[l+NUM_WORDS] == 1'b1) mem_fp[l] <= wdata_b_i;
          else if (we_a_dec[l+NUM_WORDS] == 1'b1) mem_fp[l] <= wdata_a_i;
        end
      end
    end else begin : gen_no_mem_fp_write
      assign mem_fp = 'b0;
    end

  endgenerate

endmodule
