# Validation record

2026-10-14, initial AMBA 3 AHB-Lite implementation. These results use the actual
frontend, SRAM and two-slave interconnect, not the VIP's temporary memory model.

| Gate | Result |
| --- | --- |
| Default SRAM and interconnect, Verilator strict `--Wall` lint | Pass |
| Width/endian elaboration: 8–1024 bits, both static endian modes | 16/16 pass |
| Depth/base/wait elaboration: depths 1/3/256, base 1024, waits 0/1/16/20 | 12/12 pass |
| Existing five integration tests, directed, seeds 1 and 17 | 10/10 pass |
| Existing five integration tests, randomized, seeds 1/17/29/43 | 20/20 pass |
| Existing extended scenarios, directed, seed 1 | 15/15 pass |

Each UVM pass requires zero reported errors and fatals and a functional report;
process exit alone is insufficient. Extended cases cover pipeline and pipeline
wait transfers across 0x3fc/0x400, all burst encodings with BUSY insertion, serial
bursts, burst errors, IDLE, base sequence reuse, reset during write/read/ERROR,
reset retention, repeated reset, reset before acceptance, global ready and long
waits. This evidence is 32-bit, little-endian, two-state simulation.

Dependencies: Verilator 5.052, Accellera UVM 2020.3.1 at
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`, AHB VIP at
`ac23b083fc3704d28e3fa4d19b05d05f066ed69d`, and its checker dependency at
`5d0edc2fc5ce292ac4d2a24447563667fdf754da`.

The local connection snapshot uses the VIP's published tests, sequences,
assertions, predictor and scoreboards. It substitutes real RTL for the temporary
DUT, expresses the existing write-error intent as a privilege fault, and selects
fixed-wait endpoint configurations. Its copied environment permits pipeline and
mid-transfer reset with real RTL while retaining the guard against an active
slave VIP driving alongside the DUT. That temporary-model guard rejected nine
initial extended runs at time zero; logs and source were reviewed before making
this topology adjustment. No protocol verdict or expected result was suppressed.
The published submodule is unchanged.

Detailed commands, connection changes, source hashes, logs, waves and reports
are local ignored artifacts. `make lint-matrix` reproduces the delivered RTL lint
gate. A fresh clone must connect these modules to an external DUT harness before
reproducing the UVM results; the unmodified VIP integration command runs its own
temporary model, not this IP. No new DV components or test scenarios are delivered.

Wide/endian behavioral qualification, default/unmapped and malformed-access
scenarios, frontend timeout, four-state and second-simulator checks, synthesis,
timing and assertion/functional coverage closure remain open. Existing tests that
read unwritten memory see zero in Verilator; the RTL provides no hardware power-up
value guarantee. See the [requirement matrix](compliance.md) for release gates.
