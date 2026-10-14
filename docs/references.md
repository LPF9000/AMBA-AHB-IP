# Engineering references

Checked 2026-10-14. Protocol revision is a design input: use IHI 0033A for this
profile even when an index offers a newer AHB specification.

| Topic | Primary reference | Use |
| --- | --- | --- |
| AMBA 3 AHB-Lite | [Arm IHI 0033A](https://developer.arm.com/documentation/ihi0033/a) / [official PDF](https://documentation-service.arm.com/static/5f914801f86e16515cdc2a27) | Normative protocol, all seven chapters |
| AMBA family | [Arm specification index](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) | Identify later revisions without importing their features into AMBA 3 |
| SystemVerilog | [IEEE 1800-2023](https://standards.ieee.org/ieee/1800/7743/) | Language, types, processes, elaboration and assertions |
| UVM | [Accellera UVM working group](https://www.accellera.org/activities/working-groups/uvm) | IEEE 1800.2-2020 methodology/library context for the external VIP |
| UVM library | [Official releases](https://accellera.org/downloads/standards/uvm) / [reference implementation](https://github.com/accellera-official/uvm-core) | Simulator library release selection and provenance |
| RTL structure | [OpenTitan source](https://github.com/lowRISC/opentitan) | Explicit module ownership and integration patterns; use the local checkout for comparisons |
| Simulation | [Verilator documentation](https://verilator.org/guide/latest/) | Lint, compiled simulation, parameter overrides and tool limitations |
| Existing verification | [AMBA-AHB-VIP](https://github.com/LPF9000/AMBA-AHB-VIP) | Reuse protocol stimulus/checking and its documented test limitations |

The Arm PDF is downloaded into ignored local references with its source and hash.
It is not redistributed in Git. UVM references guide verification ownership;
UVM components are not synthesizable RTL architecture.
