// SPDX-License-Identifier: MIT
// One master; combinational address decode and registered data-phase selection.
module amba_ahb_lite_interconnect #(
    parameter int unsigned AddrWidth = amba_ahb_pkg::DefaultAddrWidth,
    parameter int unsigned DataWidth = amba_ahb_pkg::DefaultDataWidth,
    parameter int unsigned NumSlaves = 1,
    parameter logic [AddrWidth-1:0] BaseAddr [NumSlaves] = '{default: '0},
    parameter logic [AddrWidth-1:0] AddrMask [NumSlaves] = '{default: 32'hffff_f000}
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic hready_i,
    input  logic [AddrWidth-1:0] haddr_i,
    input  logic [1:0] htrans_i,
    output logic [NumSlaves-1:0] hsel_o,
    output logic hready_o,
    output logic hresp_o,
    output logic [DataWidth-1:0] hrdata_o,
    input  logic [NumSlaves-1:0] hreadyout_i,
    input  logic [NumSlaves-1:0] hresp_i,
    input  logic [NumSlaves-1:0][DataWidth-1:0] hrdata_i
);
    logic [NumSlaves-1:0] select_q;
    logic default_select_q;
    logic default_ready, default_resp;

    initial begin
        if (NumSlaves == 0 || AddrWidth != 32 || !amba_ahb_pkg::valid_data_width(DataWidth))
            $fatal(1, "Invalid AMBA 3 interconnect dimensions");
        for (int unsigned i = 0; i < NumSlaves; i++) begin
            // High-bit contiguous masks, at least 1KB, with no overlapping regions.
            if ((AddrMask[i] & 32'h3ff) != 0 ||
                ((~AddrMask[i]) & ((~AddrMask[i]) + 1'b1)) != 0 ||
                (BaseAddr[i] & ~AddrMask[i]) != 0)
                $fatal(1, "Decode regions must be aligned power-of-two blocks of at least 1KB");
            for (int unsigned j = 0; j < i; j++) begin
                if (((BaseAddr[i] ^ BaseAddr[j]) & AddrMask[i] & AddrMask[j]) == 0)
                    $fatal(1, "Decode regions must not overlap");
            end
        end
    end

    always_comb begin
        for (int unsigned i = 0; i < NumSlaves; i++) begin
            hsel_o[i] = rst_ni && ((haddr_i & AddrMask[i]) == BaseAddr[i]);
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            select_q <= '0;
            default_select_q <= 1'b0;
        end else if (hready_i) begin
            select_q <= htrans_i[1] ? hsel_o : '0;
            default_select_q <= htrans_i[1] && !(|hsel_o);
        end
    end

    amba_ahb_lite_default_slave u_default (
        .clk_i, .rst_ni, .hsel_i(!(|hsel_o)), .hready_i,
        .htrans_i, .hreadyout_o(default_ready), .hresp_o(default_resp)
    );

    always_comb begin
        hready_o = 1'b1;
        hresp_o = 1'b0;
        hrdata_o = '0;
        if (rst_ni) begin
            if (default_select_q) begin
                hready_o = default_ready;
                hresp_o = default_resp;
            end
            for (int unsigned i = 0; i < NumSlaves; i++) begin
                if (select_q[i]) begin
                    hready_o = hreadyout_i[i];
                    hresp_o = hresp_i[i];
                    hrdata_o = hrdata_i[i];
                end
            end
        end
    end
endmodule
