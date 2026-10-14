# AMBA AHB IP

Synthesizable SystemVerilog building blocks for Arm AMBA AHB. The first profile
is AMBA 3 AHB-Lite, Arm IHI 0033A: one master, 32-bit addresses, and configurable
8 through 1024-bit data buses. Later AHB revisions require separate implementation
and qualification; they are not enabled by changing a width parameter.

The RTL includes a reusable slave frontend, an inferred SRAM endpoint, a
single-master address decoder/response multiplexor, and a default slave for holes
in the memory map. All modules use explicit ports and have no UVM dependencies.

Read the [architecture and integration contract](docs/architecture.md),
[protocol requirement matrix](docs/compliance.md), and
[official references](docs/references.md) before integration.
The [validation record](docs/validation.md) describes the current RTL results.

## Source and setup

`rtl/` contains one module per file and the common protocol package.
`amba_ahb_lite.f` lists files in compilation order. The existing UVM VIP is pinned
at `dv/amba_ahb_vip`; no new verification components or tests are included here.

```sh
git clone --branch production/amba3-ahb-lite https://github.com/LPF9000/AMBA-AHB-IP.git
cd AMBA-AHB-IP
git submodule update --init --recursive
make lint VERILATOR=/path/to/verilator
make lint-matrix VERILATOR=/path/to/verilator
```

The VIP has its own simulator and UVM setup instructions. Its self-tests qualify
the VIP until their DUT wiring selects this RTL; passing self-tests alone is not
IP verification. Specifications, local connection glue and detailed validation
records are kept outside tracked source.

## Implementation status

This branch contains the initial RTL implementation. Production release requires
the remaining gates in the requirement matrix, including four-state simulation,
synthesis/timing checks, parameter behavior, assertion activation and coverage
closure. SRAM contents are undefined until written and persist across reset.
Its combinational read implementation is suitable for inferred register/LUT
storage; technology-specific synchronous SRAM macros need a separate backend.

Changes reach `main` through pull requests. Development and validation stay on
named branches; this production development branch is not a release certificate.
