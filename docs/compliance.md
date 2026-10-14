# AMBA 3 AHB-Lite requirement matrix

The normative profile is Arm IHI 0033A. This matrix covers the complete protocol
by responsibility, including requirements on the connected master. It is a review
map, not a certification or a claim that all configurations have been simulated.

| Specification | Requirement | Implementation / integration contract |
| --- | --- | --- |
| Chapters 1–2 | Single-master pipelined AHB-Lite, signal widths and directions | Explicit slave ports; one-master interconnect; 32-bit addresses; one-bit HRESP |
| §3.1, §4.1 | Rising-edge accepted address phase; sample HSEL/control only with HREADY | Frontend register enable uses global HREADY; interconnect response select registered |
| §3.1, §3.6 | Overlap address/data; extend data and next address with waits | Frontend holds accepted state; SRAM waits; same-edge completion/new acceptance |
| §3.2 | IDLE/BUSY ignored with zero-wait OKAY | No backend request; idle response, including unmapped default slave |
| §3.2 | NONSEQ and SEQ are real transfers | Each accepted beat processed independently |
| §3.3 | Locked sequences are indivisible | Metadata preserved; single-master/port ordering; master/arbitration owns competing access exclusion |
| §3.4 | Size encoding, naturally aligned accesses, size no wider than bus | Parameterized lane mask; oversized/misaligned requests get two-cycle ERROR |
| §3.5 | SINGLE, INCR, WRAP4/8/16, INCR4/8/16 | Accept every beat/address; master owns sequencing, wrapping, size consistency and 1KB boundary rules |
| §3.5 | Bursts can end early; BUSY allowed per burst rules | No outstanding burst counter; slave accepts early NONSEQ/IDLE; master owns BUSY legality |
| §3.6 | Permitted HTRANS/address changes while waited or after ERROR | Unaccepted controls never mutate current data phase; final edge accepts current controls |
| §3.7 | HPROT address-phase timing and optional policy | Captured metadata; optional privilege/instruction restriction; cache/buffer hints do not reorder storage |
| §4.1 | Combinational HSEL; minimum 1KB regions | Base/mask decode with alignment, size and overlap guards |
| §4.1.1 | Default ERROR for unmapped active transfers, OKAY for IDLE/BUSY | Integrated default slave |
| §4.2 | Multiplex responses from the data-phase slave | Registered select; defaults high-ready/OKAY after reset/idle |
| §5.1 | OKAY complete/pending; bounded wait policy | Backend completion, MaxWaitCycles timeout, configurable fixed SRAM waits |
| §5.1.3 | ERROR low-ready first cycle, high-ready second, cancel opportunity | Frontend/default FSMs; failed requests have no write commit |
| §6.1 | HWDATA belongs to data phase and stays stable through write waits | Direct data-phase payload, successful edge write gating; master owns stability |
| §6.1 | Read data valid on active lanes at OKAY completion | SRAM active-lane payload; masked inactive lanes; backend contract |
| §6.1.3 | Consistent system byte order, no dynamic endian switching | Static BigEndian parameter; interconnect performs no conversion |
| §6.2 | Data widths 8/16/32/64/128/256/512/1024 | Width guard and size/lane computation; no width conversion bridge |
| §7.1 | One rising-edge HCLK; asynchronous assert/synchronous release | always_ff state; external reset release contract |
| §7.1.2 | Slave HREADYOUT high during reset; master HTRANS IDLE | Reset-qualified slave outputs; master reset behavior is a system requirement |

## Qualification gates

Strict lint, UVM DUT simulation and source review are separate evidence. Width
elaboration does not establish behavioral correctness. The VIP currently limits
transaction-level qualification to 32-bit little-endian operation. Its existing
tests include expected values of zero for unwritten locations; a two-state
simulator can supply those values, but the RTL deliberately leaves unwritten
memory undefined. Such reads do not qualify power-up memory behavior.

Before release, close these gates using the existing VIP and appropriate tools:

- Every data width and static endian mode: narrow/full-width accesses and active
  lanes, read-after-write and back-to-back operations.
- Backend ERROR and timeout, invalid size/alignment, reset during each response
  phase, cancellation/continuation, and global HREADY gating of side effects.
- Multi-slave response switching, unmapped/default responses, no speculative
  address acceptance, and legal/invalid decode parameter maps.
- Reset retention with initialized storage; four-state X handling and assertions.
- Burst encodings, wrap boundaries, BUSY insertion, early termination and locks.
- Synthesis, inferred storage, area/timing, another simulator, assertion activation
  and protocol/functional coverage reviewed against this matrix.

No new DV is developed in this repository. Gaps requiring new verification
scenarios must be addressed in the existing VIP project under its own review.
