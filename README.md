# Configurable Integer Arithmetic & Matrix Multiplication Unit

* Designing configurable 8/16/32/64/128-bit integer multiplier and divider units in SystemVerilog, built entirely from scratch without vendor IP or libraries.
* Investigating and comparing multiple hardware architectures (e.g., array, Wallace tree, Booth, and Dadda for multiplication; restoring, non-restoring, and SRT for division) to select designs optimized for latency versus logic resource utilization.
* Implementing a configurable matrix multiplier supporting 3×3, 5×5, and 7×7 matrices, evaluated based on throughput and area.
