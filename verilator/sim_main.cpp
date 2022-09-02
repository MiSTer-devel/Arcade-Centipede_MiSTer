#include <verilated.h>
#include "Vtop.h"

#include "imgui.h"
#include "implot.h"
#ifndef _MSC_VER
#include <stdio.h>
#include <SDL.h>
#include <SDL_opengl.h>
#else
#define WIN32
#include <dinput.h>
#endif

#include "sim_console.h"
#include "sim_bus.h"
#include "sim_video.h"
#include "sim_audio.h"
#include "sim_input.h"
#include "sim_clock.h"

#define FMT_HEADER_ONLY
#include <fmt/core.h>

#include "../imgui/imgui_memory_editor.h"
#include <verilated_vcd_c.h> //VCD Trace
#include "../imgui/ImGuiFileDialog.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int initialReset = 48;
bool run_enable = 1;
int batchSize = 150000;
bool single_step = 0;
bool multi_step = 0;
int multi_step_amount = 1024;

// Debug GUI 
// ---------
const char* windowTitle = "Verilator Sim: Arcade-Centipede";
const char* windowTitle_Control = "Simulation control";
const char* windowTitle_DebugLog = "Debug log";
const char* windowTitle_Video = "VGA output";
const char* windowTitle_Trace = "Trace/VCD control";
const char* windowTitle_Audio = "Audio output";
bool showDebugLog = true;
DebugConsole console;
MemoryEditor mem_edit;

// HPS emulator
// ------------
SimBus bus(console);

// Input handling
// --------------
SimInput input(12, console);
const int input_right = 0;
const int input_left = 1;
const int input_down = 2;
const int input_up = 3;
const int input_fire1 = 4;
const int input_fire2 = 5;
const int input_start_1 = 6;
const int input_start_2 = 7;
const int input_coin_1 = 8;
const int input_coin_2 = 9;
const int input_coin_3 = 10;
const int input_pause = 11;

int mouse_speed = 2;
int joystick_sensitivity = 0;
bool pause;
bool flip;

unsigned char mouse_clock = 0;
unsigned char mouse_buttons = 0;
signed short mouse_x = 0;
signed short mouse_y = 0;

// Video
// -----
#define VGA_WIDTH 256
#define VGA_HEIGHT 256
#define VGA_ROTATE -1  // 90 degrees anti-clockwise
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 2.5;

// Verilog module
// --------------
Vtop* top = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}

int clk_sys_freq = 48000000;
SimClock clk_48(1); // 48mhz
SimClock clk_12(2); // 12mhz



// Audio
// -----
#define DISABLE_AUDIO
#ifndef DISABLE_AUDIO
SimAudio audio(clk_sys_freq, true);
#endif

// Reset simulation variables and clocks
void resetSim() {
	main_time = 0;
	top->RESET = 1;
	clk_48.Reset();
	clk_12.Reset();
}


// CPU debugging

//#define DEBUG_CPU

#ifdef DEBUG_CPU
bool debug_6502 = 1;
bool debug_cpu1 = 0;
bool debug_cpu2 = 0;
bool debug_data = 0;

int cpu_sync;
int cpu_sync_last;
long cpu_sync_count;
int cpu_clock;
int cpu_clock_last;
const int ins_size = 48;
int ins_index = 0;
int ins_pc[ins_size];
int ins_in[ins_size];
int ins_out[ins_size];
int ins_ma[ins_size];

// MAME debug log
std::vector<std::string> log_mame;
std::vector<std::string> log_cpu;
long log_index;
long log_breakpoint = 2222;

bool stop_on_log_mismatch = 1;

#define DEBUG_CPU_CLOCK top->top__DOT__uut__DOT__phi0
#define DEBUG_CPU_RESET top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__reset
#define DEBUG_CPU_DATAIN top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__di
#define DEBUG_CPU_DATAOUT top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__dout
#define DEBUG_CPU_ADDR top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__ma
#define DEBUG_CPU_PC top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__pc_reg
#define DEBUG_CPU_A top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__a_reg
#define DEBUG_CPU_X top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__x_reg
#define DEBUG_CPU_Y top->top__DOT__uut__DOT__p6502__DOT__bc6502__DOT__y_reg
#define DEBUG_CPU_SYNC top->top__DOT__uut__DOT__p6502__DOT__sync
#define DEBUG_HCNT top->top__DOT__uut__DOT__h_counter
#define DEBUG_VCNT top->top__DOT__uut__DOT__v_counter

bool writeLog(const char* line)
{
	// Write to cpu log
	log_cpu.push_back(line);

	// Compare with MAME log
	bool match = true;

	std::string c_line = std::string(line);
	std::string c = "CPU > " + c_line;
	if (log_index < log_mame.size()) {
		std::string m_line = log_mame.at(log_index);
		std::string m = "MAME > " + m_line;
		//std::string f = fmt::format("{0}: h={1} v={2} dout={3:X} {4} {5}", log_index, DEBUG_HCNT, DEBUG_VCNT, DEBUG_CPU_DATAOUT, m, c);
		std::string f = fmt::format("{0}: A={1:X} X={2:X} Y={3:X} DO={3:X} {4} {5}", log_index, DEBUG_CPU_A, DEBUG_CPU_X, DEBUG_CPU_Y, DEBUG_CPU_DATAOUT, m, c);
		console.AddLog(f.c_str());

		if (stop_on_log_mismatch && m_line != c_line) {
			console.AddLog("DIFF at %d", log_index);
			console.AddLog(c.c_str());
			console.AddLog(m.c_str());
			match = false;
		}
	}
	//if (log_breakpoint > 0 && log_index == log_breakpoint) {
	//	console.AddLog("BREAK at %d", log_index);
	//	console.AddLog(m.c_str());
	//	console.AddLog(c.c_str());
	//	match = false;
	//}

	log_index++;
	return match;
}

enum instruction_type {
	implied,
	immediate,
	absolute,
	absoluteX,
	absoluteY,
	zeroPage,
	zeroPageX,
	zeroPageY,
	relative,
	accumulator,
	indirect,
	indirectX,
	indirectY
};

void DumpInstruction() {

	cpu_sync_count++;
	if (cpu_sync_count > 1) {

		std::string log = "{0:04X}: ";
		const char* f = "";
		const char* sta;

		instruction_type type = implied;

		int arg1 = 0;
		int arg2 = 0;

		switch (ins_in[0])
		{
		case 0x00: sta = "brk"; break;
		case 0x98: sta = "tya"; break;
		case 0xA8: sta = "tay"; break;
		case 0xAA: sta = "tac"; break;
		case 0x8A: sta = "txa"; break;
		case 0x40: sta = "rti"; break;
		case 0x60: sta = "rts"; break;
		case 0x9A: sta = "txs"; break;
		case 0xBA: sta = "tsx"; break;

		case 0x18: sta = "clc"; break;
		case 0x58: sta = "cli"; break;
		case 0xB8: sta = "clo"; break;
		case 0xD8: sta = "cld"; break;

		case 0xE8: sta = "inx"; break;
		case 0xC8: sta = "iny"; break;

		case 0x80: sta = "nop"; type = immediate; break;

		case 0x38: sta = "sec"; break;
		case 0x78: sta = "sei"; break;
		case 0xF8: sta = "sed"; break;

		case 0x48: sta = "pha"; break;
		case 0x08: sta = "php"; break;
		case 0x68: sta = "pla"; break;
		case 0x28: sta = "plp"; break;

		case 0x0A: sta = "asl"; type = accumulator; break;
		case 0x06: sta = "asl"; type = zeroPage; break;
		case 0x16: sta = "asl"; type = zeroPageX; break;
		case 0x0E: sta = "asl"; type = absolute; break;
		case 0x1E: sta = "asl"; type = absoluteX; break;

		case 0x09: sta = "ora"; type = immediate; break;
		case 0x05: sta = "ora"; type = zeroPage; break;
		case 0x15: sta = "ora"; type = zeroPageX; break;
		case 0x0D: sta = "ora"; type = absolute; break;
		case 0x1D: sta = "ora"; type = absoluteX; break;
		case 0x19: sta = "ora"; type = absoluteY; break;
		case 0x01: sta = "ora"; type = indirectX; break;
		case 0x11: sta = "ora"; type = indirectY; break;

		case 0x49: sta = "eor"; type = immediate; break;
		case 0x45: sta = "eor"; type = zeroPage; break;
		case 0x55: sta = "eor"; type = zeroPageX; break;
		case 0x4d: sta = "eor"; type = absolute; break;
		case 0x5d: sta = "eor"; type = absoluteX; break;
		case 0x59: sta = "eor"; type = absoluteY; break;
		case 0x41: sta = "eor"; type = indirectX; break;
		case 0x51: sta = "eor"; type = indirectY; break;

		case 0x29: sta = "and"; type = immediate; break;
		case 0x25: sta = "and"; type = zeroPage; break;
		case 0x35: sta = "and"; type = zeroPageX; break;
		case 0x2D: sta = "and"; type = absolute; break;
		case 0x3D: sta = "and"; type = absoluteX; break;
		case 0x39: sta = "and"; type = absoluteY; break;


		case 0xE9: sta = "sbc"; type = immediate; break;
		case 0xE5: sta = "sbc"; type = zeroPage; break;
		case 0xF5: sta = "sbc"; type = zeroPageX; break;
		case 0xED: sta = "sbc"; type = absolute; break;
		case 0xFD: sta = "sbc"; type = absoluteX; break;
		case 0xF9: sta = "sbc"; type = absoluteY; break;
		case 0xE1: sta = "sbc"; type = indirectX; break;
		case 0xF1: sta = "sbc"; type = indirectY; break;

		case 0xC9: sta = "cmp"; type = immediate; break;
		case 0xC5: sta = "cmp"; type = zeroPage; break;
		case 0xD5: sta = "cmp"; type = zeroPageX; break;
		case 0xCD: sta = "cmp"; type = absolute; break;
		case 0xDD: sta = "cmp"; type = absoluteX; break;
		case 0xD9: sta = "cmp"; type = absoluteY; break;

		case 0xE0: sta = "cpx"; type = immediate; break;
		case 0xE4: sta = "cpx"; type = zeroPage; break;
		case 0xEC: sta = "cpx"; type = absolute; break;

		case 0xC0: sta = "cpy"; type = immediate; break;
		case 0xC4: sta = "cpy"; type = zeroPage; break;
		case 0xCC: sta = "cpy"; type = absolute; break;

		case 0xA2: sta = "ldx"; type = immediate; break;
		case 0xA6: sta = "ldx"; type = zeroPage; break;
		case 0xB6: sta = "ldx"; type = zeroPageY; break;
		case 0xAE: sta = "ldx"; type = absolute; break;
		case 0xBE: sta = "ldx"; type = absoluteY; break;

		case 0xA0: sta = "ldy"; type = immediate; break;
		case 0xA4: sta = "ldy"; type = zeroPage; break;
		case 0xB4: sta = "ldy"; type = zeroPageX; break;
		case 0xAC: sta = "ldy"; type = absolute; break;
		case 0xBC: sta = "ldy"; type = absoluteX; break;

		case 0xA9: sta = "lda"; type = immediate; break;
		case 0xA5: sta = "lda"; type = zeroPage; break;
		case 0xB5: sta = "lda"; type = zeroPageX; break;
		case 0xAD: sta = "lda"; type = absolute; break;
		case 0xBD: sta = "lda"; type = absoluteX; break;
		case 0xB9: sta = "lda"; type = absoluteY; break;
		case 0xA1: sta = "lda"; type = indirectX; break;
		case 0xB1: sta = "lda"; type = indirectY; break;


		case 0x8D: sta = "sta"; type = absolute; break;
		case 0x85: sta = "sta"; type = zeroPage; break;
		case 0x95: sta = "sta"; type = zeroPageX; break;
		case 0x9D: sta = "sta"; type = absoluteX; break;
		case 0x99: sta = "sta"; type = absoluteY; break;
		case 0x81: sta = "sta"; type = indirectX; break;
		case 0x91: sta = "sta"; type = indirectY; break;

		case 0x86: sta = "stx"; type = zeroPage; break;
		case 0x96: sta = "stx"; type = zeroPageY; break;
		case 0x8E: sta = "stx"; type = absolute; break;
		case 0x84: sta = "sty"; type = zeroPage; break;
		case 0x94: sta = "sty"; type = zeroPageX; break;
		case 0x8C: sta = "sty"; type = absolute; break;

		case 0x69: sta = "adc"; type = immediate; break;
		case 0x65: sta = "adc"; type = zeroPage; break;
		case 0x75: sta = "adc"; type = zeroPageX; break;
		case 0x6D: sta = "adc"; type = absolute; break;
		case 0x7D: sta = "adc"; type = absoluteX; break;
		case 0x79: sta = "adc"; type = absoluteY; break;

		case 0xC6: sta = "dec"; type = zeroPage;  break;
		case 0xD6: sta = "dec"; type = zeroPageX;  break;
		case 0xCE: sta = "dec"; type = absolute;  break;
		case 0xDE: sta = "dec"; type = absoluteX;  break;

		case 0xCA: sta = "dex"; break;
		case 0x88: sta = "dey"; break;

		case 0x24: sta = "bit"; type = zeroPage; break;
		case 0x2C: sta = "bit"; type = absolute; break;

		case 0x30: sta = "bmi"; type = relative; break;
		case 0x90: sta = "bcc"; type = relative; break;
		case 0xB0: sta = "bcs"; type = relative; break;
		case 0xD0: sta = "bne"; type = relative; break;
		case 0xF0: sta = "beq"; type = relative; break;
		case 0x50: sta = "bvc"; type = relative; break;
		case 0x70: sta = "bvs"; type = relative; break;
		case 0x10: sta = "bpl"; type = relative; break;

		case 0x2a: sta = "rol"; type = absolute; break;
		case 0x26: sta = "rol"; type = zeroPage; break;
		case 0x36: sta = "rol"; type = zeroPageX; break;

		case 0x6A: sta = "ror"; type = absolute; break;
		case 0x66: sta = "ror"; type = zeroPage; break;

		case 0x4A: sta = "lsr"; type = accumulator; break;
		case 0x46: sta = "lsr"; type = zeroPage; break;

		case 0xE6: sta = "inc"; type = zeroPage; break;
		case 0xF6: sta = "inc"; type = zeroPageX; break;
		case 0xEE: sta = "inc"; type = absolute; break;
		case 0xFE: sta = "inc"; type = absoluteX; break;

		case 0x20: sta = "jsr"; type = absolute; break;

		case 0x4C: sta = "jmp"; type = absolute; break;
		case 0x6C: sta = "jmp"; type = indirect; break;

		default: sta = "???"; f = "\t\tPC={0:X} arg1={1:X} arg2={2:X} IN0={3:X} IN1={4:X} IN2={5:X} IN3={6:X} IN4={7:X} MA0={8:X} MA1={9:X} MA2={10:X} MA3={11:X} MA4={12:X}";
		}

		switch (type) {
		case implied: f = ""; break;
		case immediate: arg1 = ins_in[2]; f = " #${1:02x}"; break;
		case absolute: arg1 = ins_in[4]; arg2 = ins_in[2]; f = " ${1:02x}{2:02x}"; break;
		case absoluteX: arg1 = ins_in[4]; arg2 = ins_in[2]; f = " ${1:02x}{2:02x}, x"; break;
		case absoluteY: arg1 = ins_in[4]; arg2 = ins_in[2]; f = " ${1:02x}{2:02x}, y"; break;
		case zeroPage: arg1 = ins_in[2]; f = " ${1:02x}"; break;
		case zeroPageX: arg1 = ins_in[2]; f = " ${1:02x}, x"; break;
		case zeroPageY: arg1 = ins_in[2]; f = " ${1:02x}, y"; break;
		case relative:  arg1 = ins_ma[4] + ((signed char)ins_in[3]); f = " ${1:04x}"; break;
		case indirect: arg1 = ins_in[2]; f = " (${1:02x})"; break;
		case indirectX: arg1 = ins_in[2]; f = " (${1:02x}), x"; break;
		case indirectY: arg1 = ins_in[2]; f = " (${1:02x}), y"; break;
		case accumulator: f = " a"; break;
		}

		log.append(sta);
		log.append(f);
		if (sta == "???") {
			log.append("\t\t\PC={0:X} arg1={1:X} arg2={2:X} IN0={3:X} IN1={4:X} IN2={5:X} IN3={6:X} IN4={7:X} MA0={8:X} MA1={9:X} MA2={10:X} MA3={11:X} MA4={12:X}");
		}
		log = fmt::format(log, ins_pc[0], arg1, arg2, ins_in[0], ins_in[1], ins_in[2], ins_in[3], ins_in[4], ins_ma[0], ins_ma[1], ins_ma[2], ins_ma[3], ins_ma[4]);

		if (!writeLog(log.c_str())) {
			run_enable = 0;
		}

		if (sta == "???") {
			console.AddLog(log.c_str());
			run_enable = 0;
		}
	}
}

void debugCPU() {
	// Log 6502 instructions
	cpu_clock = DEBUG_CPU_CLOCK;
	bool cpu_reset = DEBUG_CPU_RESET;
	if (cpu_clock != cpu_clock_last && cpu_reset == 0) {

		ins_pc[ins_index] = DEBUG_CPU_PC;
		ins_in[ins_index] = DEBUG_CPU_DATAIN;
		ins_out[ins_index] = DEBUG_CPU_DATAOUT;
		ins_ma[ins_index] = DEBUG_CPU_ADDR;
		ins_index++;
		if (ins_index > ins_size - 1) { ins_index = 0; }
		cpu_sync = DEBUG_CPU_SYNC;

		bool cpu_rising = cpu_sync == 1 && cpu_sync_last == 0;
		if (cpu_rising) {
			if (ins_index > 0) {
				DumpInstruction();
			}
			// Clear instruction cache
			ins_index = 0;
			for (int i = 0; i < ins_size; i++) {
				ins_in[i] = 0;
				ins_out[i] = 0;
				ins_ma[i] = 0;
			}
		}

		cpu_sync_last = cpu_sync;
	}
	cpu_clock_last = cpu_clock;
}
#endif

int verilate() {

	if (!Verilated::gotFinish()) {

		// Assert reset during startup
		if (main_time < initialReset) { top->RESET = 1; }
		// Deassert reset after startup
		if (main_time == initialReset) { top->RESET = 0; }

		// Clock dividers
		clk_48.Tick();
		clk_12.Tick();

		// Set clocks in core
		top->clk_48 = clk_48.clk;
		top->clk_12 = clk_12.clk;

		// Simulate both edges of system clock
		if (clk_48.clk != clk_48.old) {
			if (clk_12.clk) {
				input.BeforeEval();
				bus.BeforeEval();
			}
			top->eval();

#ifdef DEBUG_CPU
			debugCPU();
#endif

			if (clk_12.clk) { bus.AfterEval(); }
		}

#ifndef DISABLE_AUDIO
		if (clk_48.IsRising())
		{
			audio.Clock(top->AUDIO_L, top->AUDIO_R);
		}
#endif

		// Output pixels on rising edge of pixel clock
		if (clk_48.IsRising() && top->top__DOT__ce_pix) {
			uint32_t colour = 0xFF000000 | top->VGA_B << 16 | top->VGA_G << 8 | top->VGA_R;
			video.Clock(top->VGA_HB, top->VGA_VB, top->VGA_HS, top->VGA_VS, colour);
		}

		if (clk_48.IsRising()) {
			main_time++;
		}
		return 1;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

int main(int argc, char** argv, char** env) {

	// Create core and initialise
	top = new Vtop();
	Verilated::commandArgs(argc, argv);

#ifdef DEBUG_CPU
	// Load MAME debug log
	std::string line;
	std::ifstream fin("centiped.tr");
	while (getline(fin, line)) {
		log_mame.push_back(line);
	}
#endif

#ifdef WIN32
	// Attach debug console to the verilated code
	Verilated::setDebug(console);
#endif

	// Attach bus
	bus.ioctl_addr = &top->ioctl_addr;
	bus.ioctl_index = &top->ioctl_index;
	bus.ioctl_wait = &top->ioctl_wait;
	bus.ioctl_download = &top->ioctl_download;
	bus.ioctl_upload = &top->ioctl_upload;
	bus.ioctl_wr = &top->ioctl_wr;
	bus.ioctl_dout = &top->ioctl_dout;
	bus.ioctl_din = &top->ioctl_din;

#ifndef DISABLE_AUDIO
	audio.Initialise();
#endif

	// Set up input module
	input.Initialise();
#ifdef WIN32
	input.SetMapping(input_up, DIK_UP);
	input.SetMapping(input_right, DIK_RIGHT);
	input.SetMapping(input_down, DIK_DOWN);
	input.SetMapping(input_left, DIK_LEFT);
	input.SetMapping(input_fire1, DIK_SPACE);
	input.SetMapping(input_start_1, DIK_1);
	input.SetMapping(input_start_2, DIK_2);
	input.SetMapping(input_coin_1, DIK_5);
	input.SetMapping(input_coin_2, DIK_6);
	input.SetMapping(input_coin_3, DIK_7);
	input.SetMapping(input_pause, DIK_P);
#else
	input.SetMapping(input_up, SDL_SCANCODE_UP);
	input.SetMapping(input_right, SDL_SCANCODE_RIGHT);
	input.SetMapping(input_down, SDL_SCANCODE_DOWN);
	input.SetMapping(input_left, SDL_SCANCODE_LEFT);
	input.SetMapping(input_fire1, SDL_SCANCODE_SPACE);
	input.SetMapping(input_start_1, SDL_SCANCODE_1);
	input.SetMapping(input_start_2, SDL_SCANCODE_2);
	input.SetMapping(input_coin_1, SDL_SCANCODE_3);
	input.SetMapping(input_coin_2, SDL_SCANCODE_4);
	input.SetMapping(input_coin_3, SDL_SCANCODE_5);
	input.SetMapping(input_pause, SDL_SCANCODE_P);
#endif
	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }

	bus.QueueDownload("./roms/centiped/136001-407.d1", 0, false);
	bus.QueueDownload("./roms/centiped/136001-408.e1", 0, false);
	bus.QueueDownload("./roms/centiped/136001-409.fh1", 0, false);
	bus.QueueDownload("./roms/centiped/136001-410.j1", 0, false);
	bus.QueueDownload("./roms/centiped/136001-211.f7", 0, false);
	bus.QueueDownload("./roms/centiped/136001-212.hj7", 0, false);
	bus.QueueDownload("./roms/centiped/136001-213.p4", 0, false);

	bus.QueueDownload("./roms/earom", 4, true);

#ifdef WIN32
	MSG msg;
	ZeroMemory(&msg, sizeof(msg));
	while (msg.message != WM_QUIT)
	{
		if (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			continue;
		}
#else
	bool done = false;
	while (!done)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			ImGui_ImplSDL2_ProcessEvent(&event);
			if (event.type == SDL_QUIT)
				done = true;
		}
#endif
		video.StartFrame();

		input.Read();


		// Draw GUI
		// --------
		ImGui::NewFrame();

		// Simulation control window
		ImGui::Begin(windowTitle_Control);
		ImGui::SetWindowPos(windowTitle_Control, ImVec2(0, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Control, ImVec2(500, 150), ImGuiCond_Once);
		if (ImGui::Button("Reset simulation")) { resetSim(); } ImGui::SameLine();
		if (ImGui::Button("Start running")) { run_enable = 1; } ImGui::SameLine();
		if (ImGui::Button("Stop running")) { run_enable = 0; } ImGui::SameLine();
		ImGui::Checkbox("RUN", &run_enable);
		//ImGui::PopItemWidth();
		ImGui::SliderInt("Run batch size", &batchSize, 1, 250000);
		if (single_step == 1) { single_step = 0; }
		if (ImGui::Button("Single Step")) { run_enable = 0; single_step = 1; }
		ImGui::SameLine();
		if (multi_step == 1) { multi_step = 0; }
		if (ImGui::Button("Multi Step")) { run_enable = 0; multi_step = 1; }
		//ImGui::SameLine();
		ImGui::SliderInt("Multi step amount", &multi_step_amount, 8, 1024);


		if (ImGui::Button("SCORE!")) { 
			top->top__DOT__uut__DOT__ram__DOT__mem[0xa8] = 80;
			top->top__DOT__uut__DOT__ram__DOT__mem[0xaa] = 80;
			top->top__DOT__uut__DOT__ram__DOT__mem[0xac] = 80;
		}

#ifdef DEBUG_CPU
		int pc = DEBUG_CPU_PC;
		int addr = DEBUG_CPU_ADDR;
		ImGui::Text(fmt::format("PC: {0:X}  MA: {1:X}", pc, addr).c_str());
#endif
		ImGui::End();

		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

		// Memory debug
		//ImGui::Begin("PGROM");
		//mem_edit.DrawContents(&top->top__DOT__uut__DOT__rom__DOT__mem, 2048, 0);
		//ImGui::End();
		//ImGui::Begin("PFROM 1");
		//mem_edit.DrawContents(&top->top__DOT__uut__DOT__pf_rom0__DOT__mem, 2048, 0);
		//ImGui::End();
		//ImGui::Begin("PFROM 2");
		//mem_edit.DrawContents(&top->top__DOT__uut__DOT__pf_rom1__DOT__mem, 2048, 0);
		//ImGui::End();
		//ImGui::Begin("VPROM");
		//mem_edit.DrawContents(&top->top__DOT__uut__DOT__vprom__DOT__mem, 2048, 0);
		//ImGui::End();
		ImGui::Begin("RAM");
		mem_edit.DrawContents(&top->top__DOT__uut__DOT__ram__DOT__mem, 2048, 0);
		ImGui::End();
		ImGui::Begin("EAROM");
		mem_edit.DrawContents(&top->top__DOT__uut__DOT__hs_ram__DOT__mem, 64, 0);
		ImGui::End();

		int windowX = 550;
		int windowWidth = (VGA_WIDTH * VGA_SCALE_X) + 24;
		int windowHeight = (VGA_HEIGHT * VGA_SCALE_Y) + 90;

		// Video window
		ImGui::Begin(windowTitle_Video);
		ImGui::SetWindowPos(windowTitle_Video, ImVec2(windowX, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Video, ImVec2(windowWidth, windowHeight), ImGuiCond_Once);

		ImGui::SetNextItemWidth(400);
		ImGui::SliderFloat("Zoom", &vga_scale, 1, 8); ImGui::SameLine();
		ImGui::SetNextItemWidth(200);
		ImGui::SliderInt("Rotate", &video.output_rotate, -1, 1); ImGui::SameLine();
		ImGui::Checkbox("Flip V", &video.output_vflip);
		ImGui::Text("main_time: %d frame_count: %d sim FPS: %f", main_time, video.count_frame, video.stats_fps);
		ImGui::Text("mousex: %d mousey: %d", mouse_x, mouse_y);


		// Draw VGA output
		ImGui::Image(video.texture_id, ImVec2(video.output_width * VGA_SCALE_X, video.output_height * VGA_SCALE_Y));
		ImGui::End();


#ifndef DISABLE_AUDIO

		ImGui::Begin(windowTitle_Audio);
		ImGui::SetWindowPos(windowTitle_Audio, ImVec2(windowX, windowHeight), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Audio, ImVec2(windowWidth, 250), ImGuiCond_Once);


		//float vol_l = ((signed short)(top->AUDIO_L) / 256.0f) / 256.0f;
		//float vol_r = ((signed short)(top->AUDIO_R) / 256.0f) / 256.0f;
		//ImGui::ProgressBar(vol_l + 0.5f, ImVec2(200, 16), 0); ImGui::SameLine();
		//ImGui::ProgressBar(vol_r + 0.5f, ImVec2(200, 16), 0);

		int ticksPerSec = (24000000 / 60);
		if (run_enable) {
			audio.CollectDebug((signed short)top->AUDIO_L, (signed short)top->AUDIO_R);
		}
		int channelWidth = (windowWidth / 2) - 16;
		ImPlot::CreateContext();
		if (ImPlot::BeginPlot("Audio - L", ImVec2(channelWidth, 220), ImPlotFlags_NoLegend | ImPlotFlags_NoMenus | ImPlotFlags_NoTitle)) {
			ImPlot::SetupAxes("T", "A", ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks, ImPlotAxisFlags_AutoFit | ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks);
			ImPlot::SetupAxesLimits(0, 1, -1, 1, ImPlotCond_Once);
			ImPlot::PlotStairs("", audio.debug_positions, audio.debug_wave_l, audio.debug_max_samples, audio.debug_pos);
			ImPlot::EndPlot();
		}
		ImGui::SameLine();
		if (ImPlot::BeginPlot("Audio - R", ImVec2(channelWidth, 220), ImPlotFlags_NoLegend | ImPlotFlags_NoMenus | ImPlotFlags_NoTitle)) {
			ImPlot::SetupAxes("T", "A", ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks, ImPlotAxisFlags_AutoFit | ImPlotAxisFlags_NoLabel | ImPlotAxisFlags_NoTickMarks);
			ImPlot::SetupAxesLimits(0, 1, -1, 1, ImPlotCond_Once);
			ImPlot::PlotStairs("", audio.debug_positions, audio.debug_wave_r, audio.debug_max_samples, audio.debug_pos);
			ImPlot::EndPlot();
		}
		ImPlot::DestroyContext();
		ImGui::End();
#endif

		video.UpdateTexture();


		// Pass inputs to sim
		top->inputs = 0;
		for (int i = 0; i < input.inputCount; i++)
		{
			if (input.inputs[i]) { top->inputs |= (1 << i); }
		}

		mouse_buttons = 0 | (input.inputs[4]);
		int acc = 16;
		int dec = 1;
		int fric = 2;

		if (input.inputs[input_left]) { mouse_x -= acc; }
		else if (mouse_x < 0) { mouse_x += (dec + (-mouse_x / fric)); }

		if (input.inputs[input_right]) { mouse_x += acc; }
		else if (mouse_x > 0) { mouse_x -= (dec + (mouse_x / fric)); }

		if (input.inputs[input_up]) { mouse_y += acc; }
		else if (mouse_y > 0) { mouse_y -= (dec + (mouse_y / fric)); }

		if (input.inputs[input_down]) { mouse_y -= acc; }
		else if (mouse_y < 0) { mouse_y += (dec + (-mouse_y / fric)); }

		int lim = 255;
		if (mouse_x > lim) { mouse_x = lim; }
		if (mouse_x < -lim) { mouse_x = -lim; }
		if (mouse_y > lim) { mouse_y = lim; }
		if (mouse_y < -lim) { mouse_y = -lim; }

		unsigned char ps2_mouse1;
		unsigned char ps2_mouse2;
		signed int x = -mouse_x;
		mouse_buttons |= (x < 0) ? 0x10 : 0x00;
		if (x < -255)
		{
			// min possible value + overflow flag
			mouse_buttons |= 0x40;
			ps2_mouse1 = 1; // -255
		}
		else if (x > 255)
		{
			// max possible value + overflow flag
			mouse_buttons |= 0x40;
			ps2_mouse1 = 255;
		}
		else
		{
			ps2_mouse1 = (char)x;
		}

		// ------ Y axis -----------
		// store sign bit in first byte
		signed int y = -mouse_y;
		mouse_buttons |= (y < 0) ? 0x20 : 0x00;
		if (y < -255)
		{
			// min possible value + overflow flag
			mouse_buttons |= 0x80;
			ps2_mouse2 = 1; // -255;
		}
		else if (y > 255)
		{
			// max possible value + overflow flag
			mouse_buttons |= 0x80;
			ps2_mouse2 = 255;
		}
		else
		{
			ps2_mouse2 = (char)y;
		}

		unsigned long mouse_temp = mouse_buttons;
		mouse_temp += (((unsigned char)ps2_mouse1) << 8);
		mouse_temp += (((unsigned char)ps2_mouse2) << 16);
		
		if (mouse_clock) { mouse_temp |= (1UL << 24); }
		mouse_clock = !mouse_clock;
		top->ps2_mouse = mouse_temp;

		//top->ps2_mouse_ext = mouse_x + (mouse_buttons << 8);

		// Run simulation
		if (run_enable) {
			for (int step = 0; step < batchSize; step++) { verilate(); }
		}
		else {
			if (single_step) { verilate(); }
			if (multi_step) {
				for (int step = 0; step < multi_step_amount; step++) { verilate(); }
			}
		}
	}

	// Clean up before exit
	// --------------------

#ifndef DISABLE_AUDIO
	audio.CleanUp();
#endif 
	video.CleanUp();
	input.CleanUp();

	return 0;
}
