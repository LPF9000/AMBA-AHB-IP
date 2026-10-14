# Architecture and integration

## Ownership

| Block | Responsibility |
| --- | --- |
| `amba_ahb_pkg` | Protocol encodings, default dimensions, supported width predicate |
| `amba_ahb_lite_slave` | Address acceptance, data-phase state, byte enables, bounded backend waits, two-cycle ERROR |
| `amba_ahb_lite_sram` | Storage, range/protection policy, fixed wait count, read payload and successful writes |
| `amba_ahb_lite_interconnect` | Combinational address select, registered response select, default-slave integration |
| `amba_ahb_lite_default_slave` | Two-cycle ERROR for unmapped active transfers, zero-wait OKAY for IDLE/BUSY |
| Existing VIP | Stimulus, passive observations, independent prediction, comparisons, assertions and coverage |

UVM classes belong in verification IP. RTL follows the same principle of explicit
ownership using synthesizable modules, signals and parameters.

## Slave frontend contract

An address is accepted at a rising clock edge when `hready_i && hsel_i` is true
and HTRANS is NONSEQ or SEQ. It becomes the backend request in the following data
phase. HREADY is the global response multiplexor output, not a private ready
signal. The frontend accepts a new address on the same edge the previous transfer
completes. No extra idle cycle is required. Address/control state is held during
waits, independent of changes on unaccepted address inputs.

`req_valid_o` identifies a legal active data phase. Address, direction, size,
burst, protection, lock and byte enables are registered; write data comes from
the current AHB data phase. HWDATA must not be sampled in the address phase.
`req_addr_o` is the byte address. Byte enables and data use bus lane order;
BigEndian reverses address-byte to lane mapping. Do not shift write data again.

The backend drives `req_ready_i` when its response is available, `req_error_i`
with that response, and read data in active lanes on successful reads. While
global HREADY is low, the backend must hold an available response until accepted.
`req_commit_o` is the single successful completion event at a rising edge. Apply
all write side effects on that event, never on valid alone. In particular,
`valid && ready` is insufficient when global HREADY is held low or ERROR is issued.
No request means no backend operation. Metadata may retain old values when invalid.

Misalignment and sizes exceeding the bus width are rejected locally without a
backend request. A backend error produces ERROR with HREADYOUT low, then ERROR
with HREADYOUT high. The first ERROR cycle advances state independently of global
HREADY. The next address is sampled only at the final response edge, after the
master has had time to cancel it. No failing write commits.

`MaxWaitCycles` bounds backend wait cycles (default 16). If ready is still low at
the limit, the frontend starts an ERROR response. Zero requires immediate backend
readiness. Global stalls after an available response do not consume this bound.
A backend must cancel its pending work when valid falls without commit, including
reset, timeout or ERROR. It must not deliver a late response as the next request.
Backends with asynchronous operations need their own cancellation/tagging policy;
the frontend is a single synchronous request interface, not an independent queue.

## SRAM endpoint

`DepthWords`, `BaseAddr`, `DataWidth`, `WaitStates`, `BigEndian`, `ReadOnly`,
`PrivilegedOnly` and `AllowInstruction` are compile-time parameters. Address width
is an explicit parameter validated as 32 for IHI 0033A. Data width is a power of
two from 8 to 1024. Configuration guards reject empty storage, misaligned bases,
and ranges outside the 32-bit address space. Non-power-of-two depths are permitted.

Storage addresses are relative to BaseAddr. The full extended subtraction and
range check occur before truncated indexing, preventing below-base addresses and
high addresses from aliasing valid words. An access beyond the endpoint, a write
to read-only storage, or a configured protection violation receives ERROR.
Fixed waits precede backend range/protection ERROR responses. Locally malformed
size/alignment errors are immediate two-cycle responses.

Only active write bytes change. Reads drive active bytes and zero inactive lanes.
No memory initialization or memory reset loop is synthesized: unwritten bytes
are undefined and software must initialize them. Reset clears protocol/control
state, aborts pending transfers and preserves previously committed bytes. This
separates bus reset from destructive memory clearing. A system that requires
zeroization must supply an explicit initialization mechanism.

All seven burst encodings are accepted beat by beat. The master supplies each
address, including wrapping addresses. The slave never predicts a burst address,
requires a fixed burst to finish, or treats BUSY as a data operation. HPROT's
cacheable/bufferable bits are advisory here; no cache or posted-write path exists.
HMASTLOCK metadata is preserved in the frontend. This single-port endpoint has
no competing master/backend access, so accepted transfers already remain ordered.
Multi-master arbitration and external concurrent storage access are outside scope.

## Interconnect

There is one master and `NumSlaves` downstream endpoints. `BaseAddr` and `AddrMask`
are unpacked parameter arrays; each match is `(HADDR & mask) == base`. Masks must
describe aligned, nonoverlapping power-of-two regions of at least 1KB. A zero
mask maps the entire address space and is legal only without another region.
Guards diagnose invalid/overlapping maps rather than assigning priority silently.

Broadcast master HADDR, HTRANS, HWRITE, HSIZE, HBURST, HPROT, HMASTLOCK and HWDATA
directly to every slave. Connect each hsel_o bit to that slave's HSEL. Connect
hready_o to the master HREADY, every slave hready_i and the interconnect's own
hready_i. If the system inserts another ready gate, feed the resulting global
HREADY to all of those hready_i inputs, so response selection and endpoint
side effects freeze together. Return each slave's
HREADYOUT/HRESP/HRDATA through the packed response arrays. AHB-Lite has one-bit
HRESP; no RETRY or SPLIT is implemented. The interconnect does not buffer traffic.

Address decode is combinational; response selection belongs to the accepted data
phase and changes only when HREADY is high. During IDLE/BUSY data phases the
master sees zero-wait OKAY and zero read data. Unmapped active addresses select
the default slave. ERROR cancellation and wait states cannot switch the response
to a speculative next address. Dimension/endian conversion is not performed.

For two 4KB regions, pass explicitly typed localparam arrays to the instance:

```systemverilog
localparam logic [31:0] RegionBase [2] = '{32'h0000_0000, 32'h0000_1000};
localparam logic [31:0] RegionMask [2] = '{default: 32'hffff_f000};
// Instance parameters: .NumSlaves(2), .BaseAddr(RegionBase), .AddrMask(RegionMask)
```

Each SRAM endpoint's own BaseAddr/depth must agree with its intended storage
range; addresses in a larger decoded region outside storage produce endpoint
ERROR. Typed arrays also avoid tools sizing anonymous override patterns using
the default NumSlaves before specialization.

## Clock, reset and synthesis

Use one HCLK domain. Reset assertion is asynchronous; the system must deassert
reset synchronously after a rising clock edge. All slaves present HREADYOUT high
and OKAY during reset. Memory writes are gated by the reset-qualified commit.
Initial blocks contain constant parameter validation only and must be treated as
elaboration diagnostics by the synthesis flow. There are no delays, initial
memory contents, associative arrays or verification classes in the RTL.
Clock/reset distribution, CDC, technology memory mapping and timing closure belong
to the integrating system and require their own validation.
