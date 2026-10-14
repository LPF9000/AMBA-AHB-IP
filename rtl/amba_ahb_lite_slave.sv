// SPDX-License-Identifier: MIT
// One outstanding data-phase request. See docs/architecture.md for backend contract.
module amba_ahb_lite_slave #(
    parameter int unsigned AddrWidth = amba_ahb_pkg::DefaultAddrWidth,
    parameter int unsigned DataWidth = amba_ahb_pkg::DefaultDataWidth,
    parameter bit BigEndian = 1'b0,
    parameter int unsigned MaxWaitCycles = 16
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic hsel_i,
    input  logic hready_i,
    input  logic [AddrWidth-1:0] haddr_i,
    input  logic [1:0] htrans_i,
    input  logic hwrite_i,
    input  logic [2:0] hsize_i,
    input  logic [2:0] hburst_i,
    input  logic [3:0] hprot_i,
    input  logic hmastlock_i,
    input  logic [DataWidth-1:0] hwdata_i,
    output logic hreadyout_o,
    output logic hresp_o,
    output logic [DataWidth-1:0] hrdata_o,
    output logic req_valid_o,
    output logic req_commit_o,
    output logic [AddrWidth-1:0] req_addr_o,
    output logic req_write_o,
    output logic [2:0] req_size_o,
    output logic [2:0] req_burst_o,
    output logic [3:0] req_prot_o,
    output logic req_lock_o,
    output logic [DataWidth/8-1:0] req_strb_o,
    output logic [DataWidth-1:0] req_wdata_o,
    input  logic req_ready_i,
    input  logic req_error_i,
    input  logic [DataWidth-1:0] req_rdata_i
);
    localparam int unsigned DataBytes = DataWidth / 8;
    localparam int unsigned SizeMax = $clog2(DataBytes);
    localparam int unsigned WaitWidth = MaxWaitCycles > 0 ? $clog2(64'(MaxWaitCycles) + 1) : 1;
    typedef enum logic [1:0] {Idle, Access, ErrorLast} state_e;
    state_e state_q;
    logic invalid_q;
    logic invalid_addr;
    logic invalid_size;
    logic error_first;
    logic [WaitWidth-1:0] wait_count_q;

    initial begin
        if (AddrWidth != 32 || !amba_ahb_pkg::valid_data_width(DataWidth))
            $fatal(1, "IHI0033A requires 32-bit addresses and power-of-two 8..1024-bit data");
    end

    // Alignment and transfer width are checked before a backend can see a request.
    if (SizeMax < 7) begin : gen_size_check
        assign invalid_size = int'(hsize_i) > SizeMax;
    end else begin : gen_all_sizes
        assign invalid_size = 1'b0;
    end
    assign invalid_addr = invalid_size ||
        (haddr_i & ((AddrWidth'(1) << hsize_i) - 1'b1)) != 0;

    assign req_valid_o = rst_ni && state_q == Access && !invalid_q;
    assign req_wdata_o = hwdata_i;
    assign error_first = state_q == Access &&
                        (invalid_q || (req_ready_i && req_error_i) ||
                        (!req_ready_i && wait_count_q == WaitWidth'(MaxWaitCycles)));
    assign req_commit_o = req_valid_o && hready_i && hreadyout_o && !hresp_o;

    always_comb begin
        hreadyout_o = 1'b1;
        hresp_o = 1'b0;
        hrdata_o = '0;
        if (rst_ni) begin
            case (state_q)
                Access: begin
                    hreadyout_o = req_ready_i && !error_first;
                    hresp_o = error_first;
                    if (!invalid_q && !req_write_o && !hresp_o) hrdata_o = req_rdata_i;
                end
                ErrorLast: hresp_o = 1'b1;
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= Idle;
            wait_count_q <= '0;
            invalid_q <= 1'b0;
            req_addr_o <= '0;
            req_write_o <= 1'b0;
            req_size_o <= '0;
            req_burst_o <= '0;
            req_prot_o <= '0;
            req_lock_o <= 1'b0;
            req_strb_o <= '0;
        end else if (error_first) begin
            // First ERROR cycle has HREADYOUT low: advance without global HREADY.
            state_q <= ErrorLast;
        end else if (hready_i) begin
            state_q <= Idle;
            wait_count_q <= '0;
            if (hsel_i && htrans_i inside {2'b10, 2'b11}) begin
                state_q <= Access;
                invalid_q <= invalid_addr;
                req_addr_o <= haddr_i;
                req_write_o <= hwrite_i;
                req_size_o <= hsize_i;
                req_burst_o <= hburst_i;
                req_prot_o <= hprot_i;
                req_lock_o <= hmastlock_i;
                for (int lane = 0; lane < int'(DataBytes); lane++) begin
                    req_strb_o[BigEndian ? DataBytes - 1 - lane : lane] <=
                        !invalid_addr && lane >= int'(haddr_i % DataBytes) &&
                        lane < int'(haddr_i % DataBytes) + (1 << hsize_i);
                end
            end
        end else if (state_q == Access && !req_ready_i && !invalid_q) begin
            wait_count_q <= wait_count_q + 1'b1;
        end
    end
endmodule
