; Requirements
; 68000+
; OCS PAL+
; 1.2+


; Code optimized for O.M.A. 2.0 Assembler


; A collection of copper effects with different priorities on one display
; Layer 1: Glowing bars are moving up and down with a sine function controlled
; by the music
; Layer 2: VU meters visualize the volume of each channel
; Layer 3: Vertical colourscroll


; Execution time 68000: 97 rasterlines


	MC68000


	INCDIR "include3.5:"

	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"

	INCLUDE "dos/dos.i"
	INCLUDE "dos/dos_lib.i"
	INCLUDE "dos/dosextens.i"

	INCLUDE "graphics/gfxbase.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "graphics/videocontrol.i"

	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"

	INCLUDE "libraries/any_lib.i"

	INCLUDE "resources/cia_lib.i"

	INCLUDE "hardware/adkbits.i"
	INCLUDE "hardware/blit.i"
	INCLUDE "hardware/cia.i"
	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/dmabits.i"
	INCLUDE "hardware/intbits.i"


	INCDIR "custom-includes-ocs:"


START_SECOND_COPPERLIST		SET 1
PROTRACKER_VERSION_3		SET 1


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory		EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled		EQU FALSE
screen_fader_enabled		EQU FALSE
text_output_enabled		EQU FALSE

pt_ciatiming_enabled		EQU TRUE
pt_usedfx			EQU pt_cmdbits
pt_usedefx			EQU pt_ecmdbits
pt_mute_enabled			EQU FALSE
pt_music_fader_enabled		EQU FALSE
pt_fade_out_delay		EQU 2	; ticks
pt_split_module_enabled		EQU FALSE
pt_track_notes_played_enabled	EQU TRUE
pt_track_volumes_enabled	EQU TRUE
pt_track_periods_enabled	EQU FALSE
pt_track_data_enabled		EQU FALSE
	IFD PROTRACKER_VERSION_3
pt_metronome_enabled		EQU FALSE
pt_metrochanbits		EQU pt_metrochan1
pt_metrospeedbits		EQU pt_metrospeed4th
	ENDC

dma_bits			EQU DMAF_COPPER|DMAF_MASTER|DMAF_SETCLR

	IFEQ pt_ciatiming_enabled
intena_bits			EQU INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ELSE
intena_bits			EQU INTF_VERTB|INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ENDC

ciaa_icr_bits			EQU CIAICRF_SETCLR
	IFEQ pt_ciatiming_enabled
ciab_icr_bits			EQU CIAICRF_TA|CIAICRF_TB|CIAICRF_SETCLR
	ELSE
ciab_icr_bits			EQU CIAICRF_TB|CIAICRF_SETCLR
	ENDC

copcon_bits			EQU 0

pf1_x_size1			EQU 0
pf1_y_size1			EQU 0
pf1_depth1			EQU 0
pf1_x_size2			EQU 0
pf1_y_size2			EQU 0
pf1_depth2			EQU 0
pf1_x_size3			EQU 0
pf1_y_size3			EQU 0
pf1_depth3			EQU 0
pf1_colors_number		EQU 0	; 1

pf2_x_size1			EQU 0
pf2_y_size1			EQU 0
pf2_depth1			EQU 0
pf2_x_size2			EQU 0
pf2_y_size2			EQU 0
pf2_depth2			EQU 0
pf2_x_size3			EQU 0
pf2_y_size3			EQU 0
pf2_depth3			EQU 0
pf2_colors_number		EQU 0
pf_colors_number		EQU pf1_colors_number+pf2_colors_number
pf_depth			EQU pf1_depth3+pf2_depth3

pf_extra_number			EQU 0

spr_number			EQU 0
spr_x_size1			EQU 0
spr_y_size1			EQU 0
spr_x_size2			EQU 0
spr_y_size2			EQU 0
spr_depth			EQU 0
spr_colors_number		EQU 0

	IFD PROTRACKER_VERSION_2 
audio_memory_size		EQU 0
	ENDC
	IFD PROTRACKER_VERSION_3
audio_memory_size		EQU 1*WORD_SIZE
	ENDC

disk_memory_size		EQU 0

chip_memory_size		EQU 0

	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 0
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ; = 0.709379 MHz * [20000 탎 = 50 Hz duration for one frame on a PAL machine]
; ciab_ta_time			EQU 14318 ; = 0.715909 MHz * [20000 탎 = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362 ; = 0.709379 MHz * [511.43 탎 = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					; = 0.715909 MHz * [506.76 탎 = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU $135

bplcon0_bits			EQU BPLCON0F_COLOR|BPLCON0F_COLOR|(pf_depth*BPLCON0F_BPU0)
color00_bits			EQU $012

cl2_display_x_size		EQU 0
cl2_display_width		EQU cl2_display_x_size/8
cl2_display_y_size		EQU 112
cl2_hstart1			EQU HSTART_320_PIXEL-2
cl2_vstart1			EQU VSTART_256_LINES
cl2_hstart2			EQU 0
cl2_vstart2			EQU beam_position&CL_Y_WRAPPING
cl2_column_width		EQU 80

sine_table_length		EQU 256

; Vert-Colorscroll
vcs_bar_height			EQU 64
vcs_bars_number			EQU 2
vcs_step			EQU 1
vcs_speed			EQU 1

; Glopwing-Sine-Bars
gsb_bars_number			EQU 4
gsb_bar_height			EQU 16
gsb_y_radius			EQU (cl2_display_y_size-gsb_bar_height)/2
gsb_y_center			EQU (cl2_display_y_size-gsb_bar_height)/2
gsb_y_angle_speed		EQU 2
gsb_y_distance			EQU 8
gsb_y_distance_min		EQU 8
gsb_y_distance_angle_speed	EQU 4
gsb_y_distance_step		EQU 3

; Bar-Fader
bf_rgb4_start_color		EQU 0
bf_rgb4_color_table_offset	EQU 0
bf_rgb4_colors_number		EQU (gsb_bar_height/2)*gsb_bars_number

; Bar-Fader-Out
bfo_rgb4_fader_speed		EQU 1
bfo_delay			EQU 2	; ticks


color_step1			EQU 16/(vcs_bar_height/2)
color_values_number1		EQU vcs_bar_height/2
segments_number1		EQU vcs_bars_number*2
color_step2			EQU 16/(gsb_bar_height/2)
color_values_number2		EQU gsb_bar_height/2
segments_number2		EQU gsb_bars_number

ct_size1			EQU color_values_number1*segments_number1
ct_size2			EQU color_values_number2*segments_number2

gsb_color_table_size		EQU ct_size2*2

extra_memory_size		EQU gsb_color_table_size*WORD_SIZE


	INCLUDE "except-vectors.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


; PT-Replay
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


	RSRESET

cl1_begin			RS.B 0

	INCLUDE "copperlist1.i"

cl1_COPJMP2			RS.L 1

cl1_copperlist_size		RS.B 0



	RSRESET

cl2_extension1			RS.B 0

cl2_ext1_WAIT1			RS.L 1
cl2_ext1_COLOR00_1		RS.L 1
cl2_ext1_WAIT2			RS.L 1
cl2_ext1_COLOR00_2		RS.L 1
cl2_ext1_WAIT3			RS.L 1
cl2_ext1_COLOR00_3		RS.L 1
cl2_ext1_WAIT4			RS.L 1
cl2_ext1_COLOR00_4		RS.L 1
cl2_ext1_WAIT5			RS.L 1
cl2_ext1_COLOR00_5		RS.L 1

cl2_extension1_size		RS.B 0


	RSRESET

cl2_begin			RS.B 0

cl2_extension1_entry		RS.B cl2_extension1_size*(cl2_display_y_size+1)

cl2_WAIT1			RS.L 1
cl2_WAIT2			RS.L 1
cl2_INTREQ			RS.L 1

cl2_end				RS.L 1

cl2_copperlist_size		RS.B 0


cl1_size1			EQU 0
cl1_size2			EQU 0
cl1_size3			EQU cl1_copperlist_size

cl2_size1			EQU 0
cl2_size2			EQU cl2_copperlist_size
cl2_size3			EQU cl2_copperlist_size


spr0_x_size1			EQU spr_x_size1
spr0_y_size1			EQU 0
spr1_x_size1			EQU spr_x_size1
spr1_y_size1			EQU 0
spr2_x_size1			EQU spr_x_size1
spr2_y_size1			EQU 0
spr3_x_size1			EQU spr_x_size1
spr3_y_size1			EQU 0
spr4_x_size1			EQU spr_x_size1
spr4_y_size1			EQU 0
spr5_x_size1			EQU spr_x_size1
spr5_y_size1			EQU 0
spr6_x_size1			EQU spr_x_size1
spr6_y_size1			EQU 0
spr7_x_size1			EQU spr_x_size1
spr7_y_size1			EQU 0

spr0_x_size2			EQU spr_x_size2
spr0_y_size2			EQU 0
spr1_x_size2			EQU spr_x_size2
spr1_y_size2			EQU 0
spr2_x_size2			EQU spr_x_size2
spr2_y_size2			EQU 0
spr3_x_size2			EQU spr_x_size2
spr3_y_size2			EQU 0
spr4_x_size2			EQU spr_x_size2
spr4_y_size2			EQU 0
spr5_x_size2			EQU spr_x_size2
spr5_y_size2			EQU 0
spr6_x_size2			EQU spr_x_size2
spr6_y_size2			EQU 0
spr7_x_size2			EQU spr_x_size2
spr7_y_size2			EQU 0


	RSRESET

	INCLUDE "main-variables.i"

; PT-Replay
	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-variables.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-variables.i"
	ENDC

; Vert-Colorscroll
vcs_color_table_start		RS.W 1

; Glowing-Sine-Bars
gsb_y_angle			RS.W 1
gsb_y_distance_angle		RS.W 1

; Bars-Fader
bf_rgb4_colors_counter		RS.W 1
bf_rgb4_copy_colors_active	RS.W 1

; Bars-Fader-Out
bfo_rgb4_active			RS.W 1
bfo_counter			RS.W 1

variables_size			RS.B 0


	SECTION code,CODE


	INCLUDE "sys-wrapper.i"


	CNOP 0,4
init_main_variables
; PT-Replay
	IFD PROTRACKER_VERSION_2 
		PT2_INIT_VARIABLES
	ENDC
	IFD PROTRACKER_VERSION_3
		PT3_INIT_VARIABLES
	ENDC

; Vert-Colorscroll
	moveq	#TRUE,d0
	move.w	d0,vcs_color_table_start(a3)

; Glowing-Sine-Bars
	move.w	d0,gsb_y_angle(a3)	; 0�
	move.w	d0,gsb_y_distance_angle(a3) ; 0�

; Bars-Fader
	move.w	#bf_rgb4_colors_number*3,bf_rgb4_colors_counter(a3)
	move.w	d0,bf_rgb4_copy_colors_active(a3)

; Bars-Fader-Out
	move.w	#FALSE,bfo_rgb4_active(a3)
	move.w	#bfo_delay,bfo_counter(a3)
	rts


	CNOP 0,4
init_main
	bsr.s	pt_DetectSysFrequ
	bsr	pt_InitRegisters
	bsr	pt_InitAudTempStrucs
	bsr	pt_ExamineSongStruc
	bsr	pt_InitFtuPeriodTableStarts
	bsr	init_CIA_timers
	bsr	init_colors
	bsr	cl1_init_copperlist
	bsr	cl2_init_copperlist
	bsr	cl2_copy_copperlist
	bsr	cl2_swap_copperlist
	bsr	cl2_set_copperlist
	rts


; PT-Replay 
	PT_DETECT_SYS_FREQUENCY

	PT_INIT_REGISTERS

	PT_INIT_AUDIO_TEMP_STRUCTURES

	PT_EXAMINE_SONG_STRUCTURE

	PT_INIT_FINETUNE_TABLE_STARTS


	CNOP 0,4
init_CIA_timers

; PT-Replay
	PT_INIT_TIMERS
	rts


	CNOP 0,4
init_colors
	CPU_LOAD_COLORMAP COLOR00,1,pf1_rgb4_color_table
	rts


	CNOP 0,4
cl1_init_copperlist
	move.l	cl1_display(a3),a0
	bsr.s	cl1_init_playfield_props
	COP_MOVEQ 0,COPJMP2
	rts

	COP_INIT_PLAYFIELD_REGISTERS cl1,BLANK


	CNOP 0,4
cl2_init_copperlist
	move.l	cl2_construction2(a3),a0
	bsr.s	cl2_init_color00_screen
	bsr.s	cl2_init_copper_interrupt
	COP_LISTEND
	rts

	CNOP 0,4
cl2_init_color00_screen
	move.l	#(((cl2_vstart1<<24)|(((cl2_hstart1/4)*2)<<16))|$10000)|$fffe,d0 ; CWAIT
	move.l	#(COLOR00<<16)|color00_bits,d1
	move.l	#(cl2_column_width/2)<<16,d4
	move.l	#1<<16,d5		; CWAIT bit
	move.l	#1<<24,d6		; next rasterline
	MOVEF.W	cl2_display_y_size-1,d7
cl2_init_color00_screen_loop
; Channel 1
	move.l	d0,(a0)+		; CWAIT
	move.l	d1,(a0)+		; COLOR00
; Channel 2
	move.l	d0,d2			; store horizontal position
	add.l	d4,d2			; next channel horizontal position
	or.l	d5,d2			; set CWAIT bit
	move.l	d2,(a0)+		; CWAIT
	move.l	d1,(a0)+		; COLOR00
; Channel 3
	add.l	d4,d2
	or.l	d5,d2
	move.l	d2,(a0)+		; CWAIT
	move.l	d1,(a0)+		; CMOVE COLOR00
; Channel 4
	add.l	d4,d2
	or.l	d5,d2
	move.l	d2,(a0)+		; CWAIT
	move.l	d1,(a0)+		; CMOVE COLOR00
; Horizontal Blank
	add.l	d4,d2
	or.l	d5,d2
	move.l	d2,(a0)+		; CWAIT
	move.l	d1,(a0)+		; CMOVE COLOR00
	add.l	d6,d0			; next rasterline
	dbf	d7,cl2_init_color00_screen_loop
	rts

	COP_INIT_COPINT cl2,cl2_hstart2,cl2_vstart2,YWRAP

	COPY_COPPERLIST cl2,2


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bsr.s	beam_routines
	rts


	CNOP 0,4
no_sync_routines
	rts


	CNOP 0,4
beam_routines
	bsr	wait_copint
	bsr.s	cl2_swap_copperlist
	bsr.s	cl2_set_copperlist
	bsr	check_audio_channels
	bsr	vert_colorscroll
	bsr	display_vu_meters
	bsr	rgb4_bars_fader_out
	bsr	gsb_init_mirror_color_table
	bsr	gsb_get_y_coordinates
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; LMB pressed ?
	bne.s	beam_routines
	rts


	SWAP_COPPERLIST cl2,2


	SET_COPPERLIST cl2


	CNOP 0,4
check_audio_channels
	move.l	a4,-(a7)
	lea	pt_audchan1temp(pc),a0
	lea	vm_channels_peak(pc),a1
	lea	gsb_rgb4_color_table2(pc),a2
	lea	gsb_rgb4_color_table(pc),a4
	bsr.s	check_audio_channel
	lea	pt_audchan2temp(pc),a0
	bsr.s	check_audio_channel
	lea	pt_audchan3temp(pc),a0
	bsr.s	check_audio_channel
	lea	pt_audchan4temp(pc),a0
	bsr.s	check_audio_channel
	move.l	(a7)+,a4
	rts

; Input
; a0.l	Temporary audio channel structure
; a1.l	Volume prak of each channel
; a2.l	Source: Colour table bright bar
; a4.l	Destination: Colours buffer
; Result
; no return value
	CNOP 0,4
check_audio_channel
	tst.b	n_notetrigger(a0)	; new note played ?
	bne.s	check_audio_channel_skip1
	move.b	#FALSE,n_notetrigger(a0)
	moveq	#0,d0
	move.b	n_volume(a0),d0
	move.w	d0,(a1)+		; store channel volume
	REPT gsb_bar_height/2
	move.w	(a2)+,(a4)+		; RGB4
	ENDR
	move.w	#bf_rgb4_colors_number*3,bf_rgb4_colors_counter(a3)
	clr.w	bfo_rgb4_active(a3)
	move.w	#bfo_delay,bfo_counter(a3)
	bra.s	check_audio_channel_skip2
	CNOP 0,4
check_audio_channel_skip1
	addq.w	#WORD_SIZE,a1		; next channel volume
	ADDF.W  (gsb_bar_height/2)*WORD_SIZE,a2 ; skip bar bright colours
	ADDF.W  (gsb_bar_height/2)*WORD_SIZE,a4 ; skip colours buffer
check_audio_channel_skip2
	rts


	CNOP 0,4
vert_colorscroll
	move.w	vcs_color_table_start(a3),d3
	move.w	d3,d0		
	addq.w	#vcs_speed*WORD_SIZE,d0	; increase table start
	MOVEF.W ct_size1*WORD_SIZE,d5
	cmp.w	d5,d0			; end of table ?
	blt.s	vert_colorscroll_skip1
	sub.w	d5,d0			; reset table start
vert_colorscroll_skip1
	move.w	d0,vcs_color_table_start(a3)
	lea	vcs_rgb4_color_table(pc),a0
	move.l	cl2_construction2(a3),a1
	lea	cl2_extension1_entry+WORD_SIZE(a1),a1
	move.w	#cl2_extension1_size,a2
	MOVEF.W cl2_display_y_size-1,d7
vert_colorscroll_loop
	move.w	(a0,d3.w),d0		; RGB4
	move.w	d0,cl2_ext1_COLOR00_1(a1) ; store colours in cl
	move.w	d0,cl2_ext1_COLOR00_2(a1)
	move.w	d0,cl2_ext1_COLOR00_3(a1)
	move.w	d0,cl2_ext1_COLOR00_4(a1)
	add.l	a2,a1			; next line in cl
	addq.w	#vcs_step*WORD_SIZE,d3	; next entry
	cmp.w	d5,d3			; end of table ?
	blt.s	vert_colorscroll_skip2
	sub.w	d5,d3			; reset table start
vert_colorscroll_skip2
	dbf	d7,vert_colorscroll_loop
	rts


	CNOP 0,4
display_vu_meters
	movem.l	a4-a5,-(a7)
	lea	vm_channels_peak(pc),a0
	lea	vm_rgb4_color_table1(pc),a2
	move.l	cl2_construction2(a3),a4
	ADDF.W	cl2_extension1+cl2_ext1_COLOR00_1+WORD_SIZE,a4
	move.w	#cl2_extension1_size,a5
	bsr.s	vm_display_channel_peak
	lea	vm_rgb4_color_table2(pc),a2
	move.l	cl2_construction2(a3),a4
	ADDF.W	cl2_extension1+cl2_ext1_COLOR00_2+WORD_SIZE,a4
	bsr.s	vm_display_channel_peak
	lea	vm_rgb4_color_table3(pc),a2
	move.l	cl2_construction2(a3),a4
	ADDF.W	cl2_extension1+cl2_ext1_COLOR00_3+WORD_SIZE,a4
	bsr.s	vm_display_channel_peak
	lea	vm_rgb4_color_table4(pc),a2
	move.l	cl2_construction2(a3),a4
	ADDF.W	cl2_extension1+cl2_ext1_COLOR00_4+WORD_SIZE,a4
	bsr.s	vm_display_channel_peak
	movem.l	(a7)+,a4-a5
	rts

; Input
; a0.l	Volume peak of each channel
; a2.l	Colour table
; a4.l	Copperlist
; a5.l	Constant extension1 size
; Result
; no return value
	CNOP 0,4
vm_display_channel_peak
	move.w	(a0),d0			; channel current volume
	move.w	d0,d1			; store volume
	MULUF.W	WORD_SIZE,d1		; offset in colour table
	lea	(a2,d1.w),a1
	REPT cl2_display_y_size
	move.w	(a1)+,d2
	beq.s	vm_display_channel_peak_skip\@
	move.w	d2,(a4)			; RGB4
vm_display_channel_peak_skip\@
	add.l	a5,a4			; next rasterline in cl
	ENDR
	tst.w	d0
	beq.s	vm_display_channel_peak_skip
	subq.w	#1,d0			; decrement volume peak
	move.w	d0,(a0)			; store new volume peak
vm_display_channel_peak_skip
	addq.w	#WORD_SIZE,a0		; next channel peak
	rts


	CNOP 0,4
rgb4_bars_fader_out
	movem.l a4-a5,-(a7)
	tst.w	bfo_rgb4_active(a3)
	bne.s	rgb4_bars_fader_out_quit
	subq.w	#1,bfo_counter(a3)
	bne.s	rgb4_bars_fader_out_quit
	move.w	#bfo_delay,bfo_counter(a3)
	MOVEF.W bf_rgb4_colors_number*3,d6 ; RGB counter
	lea	gsb_rgb4_color_table+(bf_rgb4_color_table_offset*WORD_SIZE)(pc),a0 ; colors buffer
	lea	bfo_rgb4_color_table+(bf_rgb4_color_table_offset*WORD_SIZE)(pc),a1 ; destination colors
	move.w	#bfo_rgb4_fader_speed<<8,a2 ; increase/decrease red
	move.w	#bfo_rgb4_fader_speed<<4,a4 ; increase/decrease green
	move.w	#bfo_rgb4_fader_speed,a5 ; increase/decrease blue
	MOVEF.W bf_rgb4_colors_number-1,d7
	bsr.s	bf_rgb4_fader_loop
	move.w	d6,bf_rgb4_colors_counter(a3) ; fading finished ?
	bne.s	rgb4_bars_fader_out_quit
	move.w	#FALSE,bfo_rgb4_active(a3)
rgb4_bars_fader_out_quit
	movem.l (a7)+,a4-a5
	rts

	RGB4_COLOR_FADER bf


	INIT_MIRROR_COLOR_TABLE gsb,color_values_number2,segments_number2,gsb_rgb4_color_table,extra_memory,a3


	CNOP 0,4
gsb_get_y_coordinates
	movem.l	a4-a6,-(a7)
	move.w	gsb_y_distance_angle(a3),d2
	move.w	d2,d0
	moveq	#pt_defaultticks,d1
	sub.w	pt_CurrSpeed(a3),d1	; song speed controls y movement speed
	addq.w	#4,d1			; prevent 0
	bpl.s	gsb_get_y_coordinates_skip1
	neg.w	d1
	bra.s	gsb_get_y_coordinates_skip2
	CNOP 0,4
gsb_get_y_coordinates_skip1
	MULUF.W 2,d1			; double angle speed for song speed < default
gsb_get_y_coordinates_skip2
	MULUF.W	WORD_SIZE,d1
	MOVEF.W (sine_table_length-1)*WORD_SIZE,d5 ; overflow 360�
	add.w	d1,d0
	and.w	d5,d0			; remove overflow
	move.w	d0,gsb_y_distance_angle(a3)
	move.w	gsb_y_angle(a3),d3
	move.w	d3,d0
	moveq	#pt_defaultticks,d1
	sub.w	pt_CurrSpeed(a3),d1	; Song speed controls y movement speed
	addq.w	#1,d1			; prevent 0
	bpl.s	gsb_get_y_coordinates_skip3
	neg.w	d1
	bra.s	gsb_get_y_coordinates_skip4
	CNOP 0,4
gsb_get_y_coordinates_skip3
	MULUF.W 2,d1			; double angle speed
gsb_get_y_coordinates_skip4
	MULUF.W	WORD_SIZE,d1
	add.w	d1,d0
	and.w	d5,d0			; remove overflow
	move.w  d0,gsb_y_angle(a3)
	moveq	#gsb_y_distance+gsb_y_distance_min,d6
	lea	sine_table(pc),a0
	move.w	#gsb_y_center,a1
	move.l	extra_memory(a3),a4	; colour table
	move.l	cl2_construction2(a3),a5
	ADDF.W	cl2_extension1_entry+WORD_SIZE,a5
	move.w	#cl2_extension1_size,a6
	moveq	#gsb_bars_number-1,d7
gsb_get_y_coordinates_loop
	move.w	(a0,d2.w),d4		; sin(w)
	MULSF.W	gsb_y_distance*2,d4,d0	; yd' = (yd*sin(w))/2^15
	swap	d4
	add.w	d6,d4			; yd' + yd center
	MULUF.W WORD_SIZE,d4
	move.w	(a0,d3.w),d0		; sin(w)
	MULSF.W	gsb_y_radius*2,d0,d1	; y' = (yr*sin(w))/2^15
	swap	d0
	add.w	a1,d0			; y' + y center
	MULUF.W	cl2_extension1_size,d0,d1
	lea	(a5,d0.w),a2		; y offset in cl
	REPT gsb_bar_height
	move.w	(a4)+,d0		; RGB4
	move.w	d0,cl2_ext1_COLOR00_1(a2) ; store colours in cl
	move.w	d0,cl2_ext1_COLOR00_2(a2)
	move.w	d0,cl2_ext1_COLOR00_3(a2)
	move.w	d0,cl2_ext1_COLOR00_4(a2)
	add.l	a6,a2			; next line in cl
	ENDR
	addq.w	#gsb_y_distance_step*WORD_SIZE,d2
	and.w	d5,d2			; remove overflow
	add.w	d4,d3			; y distance next bar
	and.w	d5,d3			; remove overflow
	dbf	d7,gsb_get_y_coordinates_loop
	movem.l	(a7)+,a4-a6
	rts


	INCLUDE "int-autovectors-handlers.i"


	IFEQ pt_ciatiming_enabled
		CNOP 0,4
ciab_ta_interrupt_server
	ELSE
		CNOP 0,4
vertb_interrupt_server
	ENDC


; PT-Replay
	IFEQ pt_music_fader_enabled
		bsr.s	pt_music_fader
		bsr.s	pt_PlayMusic
		rts

		PT_FADE_OUT_VOLUME

		CNOP 0,4
	ENDC

	IFD PROTRACKER_VERSION_2
		PT2_REPLAY
	ENDC
	IFD PROTRACKER_VERSION_3
		PT3_REPLAY
	ENDC


	CNOP 0,4
ciab_tb_interrupt_server
	PT_TIMER_INTERRUPT_SERVER


	CNOP 0,4
exter_interrupt_server
	rts


	CNOP 0,4
nmi_interrupt_server
	rts


	INCLUDE "help-routines.i"


	INCLUDE "sys-structures.i"


	CNOP 0,2
pf1_rgb4_color_table
	DC.W color00_bits


	CNOP 0,2
sine_table
	INCLUDE "sine-table-256x16.i"


; PT-Replay
	INCLUDE "music-tracker/pt-invert-table.i"

	INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-period-table.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-period-table.i"
	ENDC

	INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

	INCLUDE "music-tracker/pt-sample-starts-table.i"

	INCLUDE "music-tracker/pt-finetune-starts-table.i"

; Vert-Colorscroll
	CNOP 0,2
vcs_rgb4_color_table
	INCLUDE "MelODeeFx:colorpalettes/2x64-Colorgradient.ct"
	dc.w $f0f

; VU-Meter
	CNOP 0,2
vm_channels_peak
	DS.W pt_chansnum

	CNOP 0,2
vm_rgb4_color_table1
	REPT cl2_display_y_size
	DC.W 0
	ENDR
	INCLUDE "MelODeeFx:colorpalettes/64-Colorgradient1.ct"

	CNOP 0,2
vm_rgb4_color_table2
	REPT cl2_display_y_size
	DC.W 0
	ENDR
	INCLUDE "MelODeeFx:colorpalettes/64-Colorgradient2.ct"

	CNOP 0,2
vm_rgb4_color_table3
	REPT cl2_display_y_size
	DC.W 0
	ENDR
	INCLUDE "MelODeeFx:colorpalettes/64-Colorgradient3.ct"

	CNOP 0,2
vm_rgb4_color_table4
	REPT cl2_display_y_size
	DC.W 0
	ENDR
	INCLUDE "MelODeeFx:colorpalettes/64-Colorgradient4.ct"


; Glowing-Sine-Bars
	CNOP 0,2
gsb_rgb4_color_table
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient1-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient2-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient3-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient4-dark.ct"

	CNOP 0,2
gsb_rgb4_color_table2
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient1-bright.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient2-bright.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient3-bright.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient4-bright.ct"


; Bars-Fader out
	CNOP 0,2
bfo_rgb4_color_table
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient1-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient2-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient3-dark.ct"
	INCLUDE "MelODeeFx:colorpalettes/8-Colorgradient4-dark.ct"


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"


	DC.B "$VER: "
	DC.B "CopperFx "
	DC.B "1.0 "
	DC.B "(1.11.26)",0
	EVEN


; Audio data

; PT-Replay
	IFEQ pt_split_module_enabled
pt_auddata			SECTION pt_audio,DATA
		INCBIN "MelODeeFx:trackermodules/mod.Assteroidzz.song"
pt_audsmps			SECTION pt_audio2,DATA_C
		INCBIN "MelODeeFx:trackermodules/mod.Assteroidzz.smps"
	ELSE
pt_auddata			SECTION pt_audio,DATA_C
		INCBIN "MelODeeFx:trackermodules/mod.Assteroidzz"
	ENDC

	END
