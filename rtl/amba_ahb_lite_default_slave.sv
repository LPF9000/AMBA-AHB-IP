// SPDX-License-Identifier: MIT
module amba_ahb_lite_default_slave (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic hsel_i,
    input  logic hready_i,
    input  logic [1:0] htrans_i,
    output logic hreadyout_o,
    output logic hresp_o
);
    typedef enum logic [1:0] {Idle, ErrorFirst, ErrorLast} state_e;
    state_e state_q;
    assign hreadyout_o = !rst_ni || state_q != ErrorFirst;
    assign hresp_o = rst_ni && state_q != Idle;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) state_q <= Idle;
        else if (state_q == ErrorFirst) state_q <= ErrorLast;
        else if (hready_i) begin
            state_q <= hsel_i && (htrans_i inside {2'b10, 2'b11}) ? ErrorFirst : Idle;
        end
    end
endmodule
