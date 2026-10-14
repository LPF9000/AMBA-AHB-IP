// SPDX-License-Identifier: MIT
// Inferred single-port storage with combinational read; memory persists across reset.
module amba_ahb_lite_sram #(
    parameter int unsigned AddrWidth = amba_ahb_pkg::DefaultAddrWidth,
    parameter int unsigned DataWidth = amba_ahb_pkg::DefaultDataWidth,
    parameter int unsigned DepthWords = 1024,
    parameter logic [AddrWidth-1:0] BaseAddr = '0,
    parameter int unsigned WaitStates = 0,
    parameter bit BigEndian = 1'b0,
    parameter bit ReadOnly = 1'b0,
    parameter bit PrivilegedOnly = 1'b0,
    parameter bit AllowInstruction = 1'b1
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
    output logic [DataWidth-1:0] hrdata_o
);
    localparam int unsigned DataBytes = DataWidth / 8;
    localparam int unsigned IndexWidth = DepthWords > 1 ? $clog2(DepthWords) : 1;
    localparam int unsigned WaitWidth = WaitStates > 0 ? $clog2(64'(WaitStates) + 1) : 1;
    localparam logic [63:0] MemBytes = 64'(DepthWords) * DataBytes;
    logic [DataWidth-1:0] mem [DepthWords];
    logic valid, commit, write_access, backend_ready, backend_error;
    logic [AddrWidth-1:0] addr;
    logic [3:0] prot;
    logic [2:0] unused_size, unused_burst;
    logic unused_lock;
    logic [1:0] unused_prot;
    logic [DataBytes-1:0] strb;
    logic [DataWidth-1:0] wdata, rdata;
    logic [AddrWidth:0] offset;
    logic [IndexWidth-1:0] word_index;
    logic [WaitWidth-1:0] wait_count_q;

    initial begin
        if (DepthWords == 0 || BaseAddr % DataBytes != 0 ||
            MemBytes == 0 || (64'(BaseAddr) + MemBytes) > 64'h1_0000_0000)
            $fatal(1, "SRAM depth/base must describe aligned storage within the address space");
    end

    amba_ahb_lite_slave #(
        .AddrWidth(AddrWidth), .DataWidth(DataWidth), .BigEndian(BigEndian),
        .MaxWaitCycles(WaitStates)
    ) u_slave (
        .clk_i, .rst_ni, .hsel_i, .hready_i, .haddr_i, .htrans_i, .hwrite_i,
        .hsize_i, .hburst_i, .hprot_i, .hmastlock_i, .hwdata_i,
        .hreadyout_o, .hresp_o, .hrdata_o,
        .req_valid_o(valid), .req_commit_o(commit), .req_addr_o(addr),
        .req_write_o(write_access), .req_size_o(unused_size), .req_burst_o(unused_burst),
        .req_prot_o(prot), .req_lock_o(unused_lock), .req_strb_o(strb),
        .req_wdata_o(wdata), .req_ready_i(backend_ready),
        .req_error_i(backend_error), .req_rdata_i(rdata)
    );

    assign offset = {1'b0, addr} - {1'b0, BaseAddr};
    assign unused_prot = prot[3:2];
    assign word_index = IndexWidth'(offset / DataBytes);
    assign backend_error = 64'(offset) >= MemBytes || (ReadOnly && write_access) ||
        (PrivilegedOnly && !prot[1]) || (!AllowInstruction && !prot[0]);
    assign backend_ready = wait_count_q == WaitWidth'(WaitStates);

    always_comb begin
        rdata = '0;
        if (valid && !write_access && !backend_error) begin
            for (int unsigned lane = 0; lane < DataBytes; lane++) begin
                if (strb[lane]) rdata[lane*8 +: 8] = mem[word_index][lane*8 +: 8];
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) wait_count_q <= '0;
        else if (!valid || (hready_i && hreadyout_o)) wait_count_q <= '0;
        else if (!backend_ready) wait_count_q <= wait_count_q + 1'b1;
    end

    // Storage has no reset tree. Unwritten bytes are undefined and must not be read.
    always_ff @(posedge clk_i) begin
        if (commit && write_access) begin
            for (int unsigned lane = 0; lane < DataBytes; lane++) begin
                if (strb[lane]) mem[word_index][lane*8 +: 8] <= wdata[lane*8 +: 8];
            end
        end
    end
endmodule
