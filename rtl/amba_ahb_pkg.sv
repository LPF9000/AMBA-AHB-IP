// SPDX-License-Identifier: MIT
package amba_ahb_pkg;
    typedef enum logic [1:0] {
        HtransIdle = 2'b00, HtransBusy = 2'b01,
        HtransNonseq = 2'b10, HtransSeq = 2'b11
    } htrans_e;
    typedef enum logic [2:0] {
        HburstSingle = 3'b000, HburstIncr = 3'b001,
        HburstWrap4 = 3'b010, HburstIncr4 = 3'b011,
        HburstWrap8 = 3'b100, HburstIncr8 = 3'b101,
        HburstWrap16 = 3'b110, HburstIncr16 = 3'b111
    } hburst_e;
    typedef enum logic {HrespOkay = 1'b0, HrespError = 1'b1} hresp_e;
    parameter int unsigned DefaultAddrWidth = 32;
    parameter int unsigned DefaultDataWidth = 32;

    function automatic bit valid_data_width(int unsigned width);
        return width >= 8 && width <= 1024 && (width & (width - 1)) == 0;
    endfunction
endpackage
