# Configurable Integer Arithmetic & Matrix Multiplication Unit

This SystemVerilog project builds integer arithmetic from logic gates, adders, and custom datapaths. The work so far includes unsigned array and shift-and-add multipliers, signed Booth multipliers, a matrix multiplier that reuses a scalar core, and an SPI interface prototype for the Booth–Wallace multiplier.

The broader goals are to compare latency and logic usage across multiplication architectures, explore restoring, non-restoring, and SRT division, and evaluate throughput and area for 3×3, 5×5, and 7×7 matrices. The original scalar width targets are 8, 16, 32, 64, and 128 bits. Divider RTL, a Dadda multiplier, and comparative synthesis results are still pending.

## Repository layout

| Directory | Contents |
| --- | --- |
| `rtl/adders/` | Half adder, full adder, and bit-serial adder |
| `rtl/multipliers/array/` | Fixed and configurable array multipliers and the Booth-encoded array draft |
| `rtl/multipliers/shift_and_add/` | Combinational and sequential shift-and-add designs |
| `rtl/multipliers/booth/` | Standalone radix-2 and radix-4 Booth designs |
| `rtl/multipliers/booth_wallace/` | Booth encoder, Wallace compressor, and combined multiplier |
| `rtl/matrix/` | Configurable matrix multiplication controller |
| `rtl/interfaces/spi/` | SPI receiver and multiplier interface prototypes |
| `testbench/` | Simulation testbenches |

## Scalar arithmetic

| File | Current implementation |
| --- | --- |
| [HalfAdder.sv](rtl/adders/HalfAdder.sv) | One-bit half adder with sum and carry outputs. |
| [FullAdder.sv](rtl/adders/FullAdder.sv) | One-bit full adder used by both array multipliers. |
| [bit_serial_adder.sv](rtl/adders/bit_serial_adder.sv) | Adds two operands one bit at a time, stores the carry between bits, and returns an `N+1`-bit result. The state machine stays in `DONE` until reset. |
| [array_mult.sv](rtl/multipliers/array/array_mult.sv) | Hand-wired unsigned 4×4-bit array multiplier with an 8-bit product. Its partial-product wiring is fixed at four bits even though the module declares `N`. |
| [array_mult_configurable.sv](rtl/multipliers/array/array_mult_configurable.sv) | Generates unsigned partial products and full-adder rows from `N`. Defaults to 16-bit operands and produces a `2*N`-bit product. |
| [shift_and_add_multiplier.sv](rtl/multipliers/shift_and_add/shift_and_add_multiplier.sv) | Unrolls the unsigned shift-and-conditional-add algorithm into combinational stages. Defaults to 16-bit operands. |
| [shift_and_add_multiplier_seq.sv](rtl/multipliers/shift_and_add/shift_and_add_multiplier_seq.sv) | Sketches a clocked implementation with an accumulator and control FSM. The next-accumulator logic, reset initialization, and `done` handling are unfinished. |
| [radix2_booth.sv](rtl/multipliers/booth/radix2_booth.sv) | Iterative signed two’s-complement multiplier with `start` and `done`. Uses one Booth step per multiplier bit and returns a `2*N`-bit product. |
| [radix4_booth.sv](rtl/multipliers/booth/radix4_booth.sv) | Iterative signed multiplier that examines overlapping three-bit windows and advances two bits per iteration. Its `-2*M` term overflows when `M` is the most negative input, which accounts for the observed 4-bit test failures. |
| [booth_encoded_array_mult.sv](rtl/multipliers/array/booth_encoded_array_mult.sv) | Placeholder with ports and an accumulator declaration. The datapath and output assignment are pending. |
| [radix4_booth_comb.sv](rtl/multipliers/booth/radix4_booth_comb.sv) | Starts the combinational Booth variant by generating `M`, `-M`, `2*M`, and `-2*M`. The module still needs an `N` declaration, Booth selection, and a product assignment. |

## Radix-4 Booth–Wallace multiplier

This combinational datapath recodes signed operands into radix-4 partial products, adds a correction row for negative terms, compresses the rows to two, and adds the final pair. The core defaults to 8-bit operands and forms `N/2` Booth windows, so the current grouping assumes an even operand width.

| File in `rtl/multipliers/booth_wallace/` | Role |
| --- | --- |
| [radix4_booth_wallace.sv](rtl/multipliers/booth_wallace/radix4_booth_wallace.sv) | Generates partial products, sizes the Wallace reduction layers, and computes the signed `2*N`-bit product. |
| [booth_r4_encoder.sv](rtl/multipliers/booth_wallace/booth_r4_encoder.sv) | Decodes each three-bit window into sign and magnitude selection signals. |
| [wallace_compressor_3to2.sv](rtl/multipliers/booth_wallace/wallace_compressor_3to2.sv) | Uses full adders to compress three rows into sum and shifted carry rows. |
| [FullAdder.sv](rtl/multipliers/booth_wallace/FullAdder.sv) | Local full-adder definition used by the compressor. Compile only one `FullAdder` definition per simulation library. |

## Matrix multiplication

[config_matrix_mult.sv](rtl/matrix/config_matrix_mult.sv) accepts two signed square matrices, with dimension `N` and element width `W` set when the design is elaborated. It defaults to a 3×3 matrix with 8-bit elements. Its FSM walks the row, column, and inner-product indices and reuses a single `radix2_booth` instance to accumulate the terms of each dot product. The external interface uses `start`, `done`, `clk`, and `reset`.

The matrix datapath and control are in place, with these issues still open before end-to-end verification:

- The FSM advances the row and column indices before writing a finished dot product. `LOAD_C` can therefore write a result to the next output position.
- The Booth core exposes its signed product as an unsigned port. The matrix module connects it to a wider accumulator input, so negative products need explicit sign extension before accumulation.
- Each result element is `2*W` bits wide. A dot product can require more bits than a single scalar product, so the current assignment can truncate it. The row, column, and inner-product counters are also fixed at three bits.

## SPI prototypes

| File in `rtl/interfaces/spi/` | Current behavior |
| --- | --- |
| [spi_slave_rx.sv](rtl/interfaces/spi/spi_slave_rx.sv) | Draft receiver intended to shift MOSI on rising SCLK edges while chip select is low and flag each complete byte. The datapath still uses fixed 8-bit slices and counts, and syntax errors prevent compilation. |
| [spi_slave_top1.sv](rtl/interfaces/spi/spi_slave_top1.sv) | Routes the last received byte to eight LEDs. This wrapper still instantiates the older `spi_slave` module name. |
| [spi_slave_top2.sv](rtl/interfaces/spi/spi_slave_top2.sv) | Captures two operand bytes, feeds them to the 8-bit signed Booth–Wallace core, and shows the low product byte on LEDs. It depends on the draft receiver. |
| [spi_slave_top3.sv](rtl/interfaces/spi/spi_slave_top3.sv) | Extends the two-operand wrapper with a draft falling-edge MISO shifter. The shifter has syntax errors and still needs product loading and transmit framing. |

## Simulation

The three existing testbenches were compiled and run in Questa Intel Starter FPGA Edition.

| Testbench | Coverage and observed result |
| --- | --- |
| [shift_and_add_multiplier_tb.sv](testbench/shift_and_add_multiplier_tb.sv) | Monitors three unsigned 4-bit examples. Outputs were 0, 15, and 70 for `0*0`, `5*3`, and `10*7`. |
| [radix2_booth_tb.sv](testbench/radix2_booth_tb.sv) | Compares directed and randomized signed 4-bit inputs against SystemVerilog multiplication. All 62 checks passed. |
| [tb_radix4_booth.sv](testbench/tb_radix4_booth.sv) | Runs directed cases and an exhaustive signed 4-bit sweep with a completion timeout. Of 294 checks, 283 passed and 11 failed. Every failure had `M = -8`. |

From the repository root, with the Questa tools available on your path:

```powershell
vlib work
vlog -sv rtl/multipliers/shift_and_add/shift_and_add_multiplier.sv rtl/multipliers/booth/radix2_booth.sv rtl/multipliers/booth/radix4_booth.sv testbench/shift_and_add_multiplier_tb.sv testbench/radix2_booth_tb.sv testbench/tb_radix4_booth.sv
vsim -c shift_and_add_multiplier_tb -do "run -all; quit -f"
vsim -c radix2_booth_tb -do "run -all; quit -f"
vsim -c tb_radix4_booth -do "run -all; quit -f"
```

Use the explicit source list above for these tests. The matrix controller, Booth–Wallace core, array multipliers, bit-serial adder, and SPI wrappers have no dedicated testbenches in this repository snapshot.

[.gitattributes](.gitattributes) configures Git’s automatic text and line-ending normalization.
