verilator \
-cc -exe --public \
--compiler msvc +define+SIMULATION=1 \
-Wno-fatal \
-O3 --x-assign fast --x-initial fast --noassert \
--error-limit 1000 \
--converge-limit 6000 \
-Wno-UNOPTFLAT \
--top-module top centipede_sim.v \
-I../rtl/pokey \
-I../rtl
