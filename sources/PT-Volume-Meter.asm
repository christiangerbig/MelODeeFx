; Requirements
; 68000+
; OCS PAL+
; 1.2+


; Rotating filled objects with a diffuse lightsource.
; Every object has its own shading table.
; Two rotating cuboids represent the left and the right audio channel.
; The height of each cuboid is the volume for each audio channel pair (left/right).
; The volume peek is automatically decreased.
; RMB activates xz center rotation.


; Execution time 68000: 227 rasterlines


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
	INCLUDE "intuition/screens.i"

	INCLUDE "libraries/any_lib.i"

	INCLUDE "resources/cia_lib.i"

	INCLUDE "hardware/adkbits.i"
	INCLUDE "hardware/blit.i"
	INCLUDE "hardware/cia.i"
	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/dmabits.i"
	INCLUDE "hardware/intbits.i"


	INCDIR "custom-includes-ocs:"


PROTRACKER_VERSION_3		SET 1
START_SECOND_COPPERLIST		SET 1


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory    	EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled 	EQU FALSE
screen_fader_enabled		EQU FALSE
text_output_enabled     	EQU FALSE

; PT-Replay
pt_ciatiming_enabled		EQU TRUE
pt_usedfx			EQU pt_allusedfx
pt_usedefx			EQU pt_allusedefx
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

dma_bits			EQU DMAF_BLITTER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER|DMAF_SETCLR

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

pf1_x_size1			EQU 320
pf1_y_size1			EQU 112
pf1_depth1			EQU 2
pf1_x_size2			EQU 320
pf1_y_size2			EQU 112
pf1_depth2			EQU 2
pf1_x_size3			EQU 320
pf1_y_size3			EQU 112
pf1_depth3			EQU 2
pf1_colors_number		EQU 4

pf2_x_size1			EQU 320
pf2_y_size1			EQU 112
pf2_depth1			EQU 2
pf2_x_size2			EQU 320
pf2_y_size2			EQU 112
pf2_depth2			EQU 2
pf2_x_size3			EQU 320
pf2_y_size3			EQU 112
pf2_depth3			EQU 2
pf2_colors_number		EQU 4
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

extra_memory_size		EQU 0

chip_memory_size		EQU 0

	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 0
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ; = 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
; ciab_ta_time			EQU 14318 ; = 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362 ; = 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					; = 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU $135

pixel_per_line			EQU 320
visible_pixels_number		EQU 320
visible_lines_number		EQU 112
MINROW				EQU VSTART_256_LINES+72

display_window_hstart		EQU HSTART_320_PIXEL
display_window_vstart		EQU MINROW
display_window_hstop		EQU HSTOP_320_pixel
display_window_vstop		EQU MINROW+visible_lines_number

pf1_plane_width			EQU pf1_x_size3/8
pf2_plane_width			EQU pf2_x_size3/8
data_fetch_width		EQU pixel_per_line/8
pf1_plane_moduli		EQU (pf1_plane_width*(pf1_depth3-1))+pf1_plane_width-data_fetch_width
pf2_plane_moduli		EQU (pf2_plane_width*(pf2_depth3-1))+pf2_plane_width-data_fetch_width

diwstrt_bits			EQU ((display_window_vstart&$ff)*DIWSTRTF_V0)|(display_window_hstart&$ff)
diwstop_bits			EQU ((display_window_vstop&$ff)*DIWSTOPF_V0)|(display_window_hstop&$ff)
ddfstrt_bits			EQU DDFSTRT_320_PIXEL
ddfstop_bits			EQU DDFSTOP_320_PIXEL
bplcon0_bits			EQU BPLCON0F_COLOR|(pf_depth*BPLCON0F_BPU0)|BPLCON0F_DPF
bplcon1_bits			EQU 0
bplcon2_bits			EQU 0
color00_bits			EQU $012

cl1_hstart			EQU 0
cl1_vstart			EQU beam_position&CL_Y_WRAPPING

sine_table_length		EQU 256

; Blenk-Vectors
bv_rotation_d			EQU 256
bv_rotation_y_center		EQU 111
bv_rotation_x_angle_speed	EQU 1
bv_rotation_y_angle_speed	EQU 1
bv_rotation_z_angle_speed	EQU 900*8

bv_object_edge_points_number	EQU 8
bv_object_edge_points_per_face	EQU 4
bv_object_faces_number		EQU 6

bv_object_face1_color		EQU 1
bv_object_face1_lines_number	EQU 4
bv_object_face2_color		EQU 1
bv_object_face2_lines_number	EQU 4
bv_object_face3_color		EQU 2
bv_object_face3_lines_number	EQU 4
bv_object_face4_color		EQU 2
bv_object_face4_lines_number	EQU 4
bv_object_face5_color		EQU 3
bv_object_face5_lines_number	EQU 4
bv_object_face6_color		EQU 3
bv_object_face6_lines_number	EQU 4

bv_shade_values_number		EQU 16
bv_light_z_coordinate		EQU -40
bv_EpRGB			EQU bv_shade_values_number-1 ; light source intensity
bv_kdRGB			EQU 12	; face reflection = object brightness
bv_D0				EQU 13	; loss of brightness
bv_EpRGB_max			EQU bv_shade_values_number-1

bv_clear_blit_x_size		EQU pf1_x_size3
bv_clear_blit_y_size		EQU pf1_y_size3
bv_clear_blit_depth		EQU pf1_depth3

bv_fill_blit_x_size		EQU pf1_x_size3
bv_fill_blit_y_size		EQU pf1_y_size3
bv_fill_blit_depth		EQU pf1_depth3

; Rotate-XZ-Center
bv_rotate_x_center_radius	EQU (visible_pixels_number-56)/2
bv_rotate_x_center_center	EQU 28+((visible_pixels_number-56)/2)
bv_rotate_x_center_angle_speed	EQU 2

bv_rotate_z_center_radius	EQU 240*8
bv_rotate_z_center_center	EQU 240*8
bv_rotate_z_center_angle_speed	EQU 1

; Volume-Meter
vm_cuboid_min_heigth		EQU 14


color_values_number1		EQU bv_shade_values_number
segments_number1		EQU 1


	INCLUDE "except-vectors.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


; PT-Replay
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


; Blenk-Vectors
	RSRESET

object_info			RS.B 0

object_info_edges		RS.L 1
object_info_face_color		RS.W 1
object_info_lines_number	RS.W 1

object_info_size		RS.B 0


	RSRESET

cl1_begin			RS.B 0

	INCLUDE "copperlist1.i"

cl1_WAIT1			RS.L 1
cl1_WAIT2			RS.L 1
cl1_INTREQ			RS.L 1

cl1_end				RS.L 1

cl1_copperlist_size		RS.B 0


	RSRESET

cl2_begin			RS.B 0

cl2_end				RS.L 1

cl2_copperlist_size		RS.B 0


cl1_size1			EQU 0
cl1_size2			EQU cl1_copperlist_size
cl1_size3			EQU cl1_copperlist_size

cl2_size1			EQU 0
cl2_size2			EQU 0
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

save_a7				RS.L 1

; Blenk-Vectors
bv_rotation_x_angle		RS.W 1
bv_rotation_y_angle		RS.W 1
bv_rotation_z_angle		RS.W 1

bv_rotation_object1_x_center	RS.W 1
bv_rotation_object2_x_center	RS.W 1
bv_rotation_object1_z_center	RS.W 1
bv_rotation_object2_z_center	RS.W 1

; Rotate-XZ-Center
bv_rotate_xz_center_active	RS.W 1

bv_object1_x_center_angle	RS.W 1
bv_object1_z_center_angle	RS.W 1

bv_object2_x_center_angle	RS.W 1
bv_object2_z_center_angle	RS.W 1

; Volume-Meter
vm_left_channel_volume		RS.W 1
vm_right_channel_volume		RS.W 1

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

; Blenk-Vectors
	moveq	#TRUE,d0
	move.w	d0,bv_rotation_x_angle(a3) ; 0°
	move.w	d0,bv_rotation_y_angle(a3) ; 0°
	move.w	d0,bv_rotation_z_angle(a3) ; 0°

; Rotate-XZ-Center
	moveq	#FALSE,d1
	move.w	d1,bv_rotate_xz_center_active(a3)

	move.w	#(sine_table_length/4)*WORD_SIZE,bv_object1_x_center_angle(a3) ; 90°
	move.w	#(sine_table_length/2)*WORD_SIZE,bv_object1_z_center_angle(a3) ; 180°

	move.w	#((sine_table_length/2)+(sine_table_length/4))*WORD_SIZE,bv_object2_x_center_angle(a3) ; 270°
	move.w	#(sine_table_length)*WORD_SIZE,bv_object2_z_center_angle(a3) ; 360°

; Volume-Meter
	move.w	d0,vm_left_channel_volume(a3)
	move.w	d0,vm_right_channel_volume(a3)
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
	bsr	bv_init_object_info
	bsr	cl1_init_copperlist
	bsr	cl2_init_copperlist
	rts


	PT_DETECT_SYS_FREQUENCY


	PT_INIT_REGISTERS


	PT_INIT_AUDIO_TEMP_STRUCTURES


	PT_EXAMINE_SONG_STRUCTURE


	PT_INIT_FINETUNE_TABLE_STARTS


	CNOP 0,2
init_colors
	CPU_INIT_COLOR COLOR00,1,pf1_rgb4_color_table
	rts


	CNOP 0,4
init_CIA_timers

; PT-Replay
	PT_INIT_TIMERS
	rts


; Blenk-Vectors
	CNOP 0,4
bv_init_object_info
	lea	bv_object_info+object_info_edges(pc),a0
	lea	bv_object_edges(pc),a1
	move.w	#object_info_size,a2
	moveq	#bv_object_faces_number-1,d7
bv_init_object_info_loop
	move.w	object_info_lines_number(a0),d0
	addq.w	#2,d0			; number of lines + 1 = number of edge points
	move.l	a1,(a0)			; edge points table
	move.w	d0,d1
	MULUF.W	WORD_SIZE,d1,d2
	lea	(a1,d1.w),a1		; next edge points table
	add.l	a2,a0			; next object info structure
	dbf	d7,bv_init_object_info_loop
	rts


	CNOP 0,4
cl1_init_copperlist
	move.l	cl1_construction2(a3),a0 
	bsr.s	cl1_init_playfield_props
	bsr.s	cl1_init_colors
	bsr	cl1_init_plane_pointers
	bsr	cl1_init_copper_interrupt
	COP_LISTEND
	bsr	cl1_set_plane_pointers
	bsr	cl1_copy_copperlist
	rts

	COP_INIT_PLAYFIELD_REGISTERS cl1

	CNOP 0,4
cl1_init_colors
	COP_INIT_COLOR COLOR00,4,pf1_rgb4_color_table

	COP_INIT_COLOR COLOR08,4,pf2_rgb4_color_table	; Dual playfield colours
	rts

	COP_INIT_BITPLANE_POINTERS cl1

	COP_INIT_COPINT cl1,cl1_hstart,cl1_vstart,YWRAP

	COP_SET_BITPLANE_POINTERS cl1,construction2,pf1_depth3,pf2_depth3

	COPY_COPPERLIST cl1,2


	CNOP 0,4
cl2_init_copperlist
	move.l	cl2_display(a3),a0
	COP_LISTEND
	rts


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bsr	beam_routines
	rts


	CNOP 0,4
no_sync_routines
	rts


	CNOP 0,4
beam_routines
	bsr	wait_copint
	bsr.s	cl1_swap_copperlist
	bsr	cl1_set_copperlist
	bsr	pf1_swap_playfield
	bsr	pf1_set_dual_playfield
	bsr	pf2_swap_playfield
	bsr	pf2_set_dual_playfield

	bsr	get_channels_volume
	bsr	volume_meter

	bsr	bv_draw_object1_lines
	bsr	bv_draw_object2_lines

	bsr	bv_fill_playfield1
	bsr	bv_object1_rotate_xz_center
	bsr	bv_object1_rotation
	bsr	bv_clear_playfield1

	bsr	bv_fill_playfield2
	bsr	bv_object2_rotate_xz_center
	bsr	bv_object2_rotation
	bsr	bv_clear_playfield2

	bsr	mouse_handler
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; LMB pressed ?
	bne.s	beam_routines
	rts


	SWAP_COPPERLIST cl1,2


	SET_COPPERLIST cl1


	SWAP_PLAYFIELD_BUFFERS pf1,3,pf1_depth3


	SET_DUAL_PLAYFIELD pf1,pf1_depth3


	SWAP_PLAYFIELD_BUFFERS pf2,3,pf2_depth3


	SET_DUAL_PLAYFIELD pf2,pf2_depth3


	CNOP 0,4
get_channels_volume
; left channels
	move.w	vm_left_channel_volume(a3),d1
	lea	pt_audchan2temp(pc),a0
	tst.b	n_notetrigger(a0)	; new note ?
	bne.s	get_channel_period_skip1
	move.b	#FALSE,n_notetrigger(a0)
	move.w	n_currentvolume(a0),d1
get_channel_period_skip1
	lea	pt_audchan3temp(pc),a0
	tst.b	n_notetrigger(a0)	; new note ?
	bne.s	get_channel_period_skip2
	move.b	#FALSE,n_notetrigger(a0)
	cmp.w	n_currentvolume(a0),d1
	bgt.s	get_channel_period_skip2
	move.w	n_currentvolume(a0),d1
get_channel_period_skip2
	move.w	d1,vm_left_channel_volume(a3)
; right channels
	move.w	vm_right_channel_volume(a3),d1
	lea	pt_audchan1temp(pc),a0
	tst.b	n_notetrigger(a0)	; new note ?
	bne.s	get_channel_period_skip3
	move.b	#FALSE,n_notetrigger(a0)
	move.w	n_currentvolume(a0),d1
get_channel_period_skip3
	lea	pt_audchan4temp(pc),a0
	tst.b	n_notetrigger(a0)	; new note ?
	bne.s	get_channel_period_skip4
	move.b	#FALSE,n_notetrigger(a0)
	cmp.w	n_currentvolume(a0),d1
	bgt.s	get_channel_period_skip4
	move.w	n_currentvolume(a0),d1
get_channel_period_skip4
	move.w	d1,vm_right_channel_volume(a3)
	rts


	CNOP 0,4
volume_meter
; Left channels
	lea	vm_left_channel_volume(a3),a0
	lea	bv_object1_coordinates,a1
	bsr.s	set_object_heigth
; Right channels
	lea	vm_right_channel_volume(a3),a0
	lea	bv_object2_coordinates,a1
	bsr.s	set_object_heigth
	rts

; Input
; a0.l	Pointer channel volume peak
; a1.l	Pointer table object x,y,z coordinates
; Result
	CNOP 0,4
set_object_heigth
	moveq	#vm_cuboid_min_heigth,d1
	add.w	(a0),d1
	move.w	d1,d0
	lsl.w	#3,d0
	neg.w	d0
	move.w	d0,2(a1)		; p0(z)
	move.w	d0,8(a1)		; p1(z)
	move.w	d0,26(a1)		; p4(z)
	move.w	d0,32(a1)		; p5(z)
	sub.w	#2*8,d1			; decrease height
	bmi.s	set_cuboid_heigth_skip
	move.w	d1,(a0)			; new height
set_cuboid_heigth_skip
	rts


; Object 1
	CNOP 0,4
bv_clear_playfield1
	movem.l a3-a6,-(a7)
	move.l	a7,save_a7(a3)	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	move.l	d0,a0
	move.l	d0,a1
	move.l	d0,a2
	move.l	d0,a4
	move.l	d0,a5
	move.l	d0,a6
	move.l	pf1_construction1(a3),a7
	move.l	d0,a3
	add.l	#pf1_plane_width*pf1_y_size3*pf1_depth3,a7 ; end of playfield
	REPT (pf1_plane_width*pf1_y_size3*pf1_depth3)/60
	movem.l d0-d7/a0-a6,-(a7)	; clear 60 bytes
	ENDR
	movem.l d0-d4,-(a7)		; clear remaining 20 bytes
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a6
	rts


	CNOP 0,4
bv_object1_rotate_xz_center
	movem.l	a4-a5,-(a7)
	lea	bv_object1_x_center_angle(a3),a1
	lea	bv_rotation_object1_x_center(a3),a2
	lea	bv_object1_z_center_angle(a3),a4
	lea	bv_rotation_object1_z_center(a3),a5
	bsr.s	bv_rotate_xz_center
	movem.l	(a7)+,a4-a5
	rts

; Input
; a1.l	Pointer rotation x center angle
; a2.l  Pointer rotation x center
; a4.l	Pointer rotation z center angle
; a5.l	Pointer rotation z center
; Result
	CNOP 0,4
bv_rotate_xz_center
	move.w	(a1),d1			; x center angle
	tst.w	bv_rotate_xz_center_active(a3)
	bne.s	bv_rotate_xz_center_skip1
	move.w	d1,d0
	subq.w	#bv_rotate_x_center_angle_speed*WORD_SIZE,d0
	and.w	#(sine_table_length*WORD_SIZE)-1,d0 ; remove overflow 360°
	move.w	d0,(a1)			; new x center angle
bv_rotate_xz_center_skip1
	lea	sine_table(pc),a0
	move.w  (a0,d1.w),d0		; sin(w)
	muls.w	#bv_rotate_x_center_radius*2,d0 ; x' = (xr*sin(w))/2^15
	swap	d0
	add.w	#bv_rotate_x_center_center,d0 ; x' + x center
	move.w	d0,(a2)			; new rotation x center

	move.w	(a4),d1			; z center angle
	move.l	cl1_construction2(a3),a1
	move.w	cl1_BPLCON2+WORD_SIZE(a1),d2
	and.b	#~BPLCON2F_PF2PRI,d2	; clear priority for playfield 2
	tst.w	bv_rotate_xz_center_active(a3)
	bne.s	bv_rotate_xz_center_skip2
	move.w	d1,d0
	addq.w	#bv_rotate_z_center_angle_speed*WORD_SIZE,d0
	and.w	#(sine_table_length*WORD_SIZE)-1,d0 ; remove overflow 360°
	move.w	d0,(a4)			; new z center angle
bv_rotate_xz_center_skip2
	move.w  (a0,d1.w),d0		; cos(w)
	bpl.s	bv_rotate_xz_center_skip3
	or.b	#BPLCON2F_PF2PRI,d2	; set priority for playfield 2
bv_rotate_xz_center_skip3
	move.w	d2,cl1_BPLCON2+WORD_SIZE(a1)
	muls.w	#bv_rotate_z_center_radius*2,d0 ; z' = (zr*cos(w))/2^15
	swap	d0
	add.w	#bv_rotate_z_center_center,d0 ; z' + z center
	move.w	d0,(a5)			; new rotation z center
bv_rotate_xz_center_quit
	rts


	CNOP 0,4
bv_object1_rotation
	movem.l a4-a6,-(a7)
	move.w	bv_rotation_x_angle(a3),d1
	move.w	d1,d0		
	lea	sine_table(pc),a2
	move.w	(a2,d0.w),d4		; sin(a)
	move.w	#(sine_table_length/4)*WORD_SIZE,a4
	MOVEF.W (sine_table_length*WORD_SIZE)-1,d3 ; overflow 360°
	add.w	a4,d0			; + 90°
	swap	d4			; high word: sin(a)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d4		; low word: cos(a)
	addq.w	#bv_rotation_x_angle_speed*WORD_SIZE,d1
	and.w	d3,d1			; remove overflow
	move.w	d1,bv_rotation_x_angle(a3)
	move.w	bv_rotation_y_angle(a3),d1
	move.w	d1,d0		
	move.w	(a2,d0.w),d5		; sin(b)
	add.w	a4,d0			; + 90°
	swap	d5			; high word = sin(b)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d5		; low word: cos(b)
	addq.w	#bv_rotation_y_angle_speed*WORD_SIZE,d1
	and.w	d3,d1			; remove overflow
	move.w	d1,bv_rotation_y_angle(a3)
	move.w	bv_rotation_z_angle(a3),d1
	move.w	d1,d0		
	move.w	(a2,d0.w),d6		; sin(c)
	add.w	a4,d0			; + 90°
	swap	d6			; high word: sin(c)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d6		; low word: cos(c)
	add.w	#bv_rotation_z_angle_speed*WORD_SIZE,d1
	and.w	d3,d1			; remove overflow
	move.w	d1,bv_rotation_z_angle(a3)

	lea	bv_object1_coordinates(pc),a0
	lea	bv_rotation_xyz_coordinates1(pc),a1
	move.w	bv_rotation_object1_z_center(a3),a4
	move.w	bv_rotation_object1_x_center(a3),a5
	bsr.s	bv_rotate_object
	movem.l (a7)+,a4-a6
	rts

; Input
; a0.l	Pointer table object coordinates
; a1.l	Pointer table coordinates after rotation
; a4.w	Rotation z center
; a5.w	Rotation x center
; d4.l	High word: sin(a), low word: cos(a)
; d5.l	High word: sin(b), low word: cos(b)
; d6.l	High word: sin(c), low word: cos(c)
; Result
	CNOP 0,4
bv_rotate_object
	add.w	#bv_rotation_d*8,a4
	move.w	#bv_rotation_y_center,a6
	moveq	#bv_object_edge_points_number-1,d7
bv_rotate_object_loop
	move.w	(a0)+,d0		; x
	move.l	d7,a2			; store loop counter
	move.w	(a0)+,d1		; y
	move.w	(a0)+,d2		; z
	ROTATE_Y_AXIS
; Central projection and translation
	move.w	d2,d3			; store z
	ext.l	d0
	add.w	a4,d3			; z+d
	MULUF.L bv_rotation_d,d0,d7	; x projection
	ext.l	d1
	divs.w	d3,d0			; x' = (x*d)/(z+d)
	MULUF.L bv_rotation_d,d1,d7	; y projection
	add.w	a5,d0			; x' + x center
	move.w	d0,(a1)+		; x position
	divs.w	d3,d1			; y' = (y*d)/(z+d)
	add.w	a6,d1			; y' + y center
	move.w	d1,(a1)+		; y position
	asr.w	#3,d2			; z/8
	move.w	d2,(a1)+		; z position
	move.l	a2,d7			; restore loop counter
	dbf	d7,bv_rotate_object_loop
	rts


	CNOP 0,4
bv_draw_object1_lines
	movem.l a3-a5,-(a7)
	lea	bv_rotation_xyz_coordinates1(pc),a1
	move.l	pf1_construction2(a3),a2
	move.l	cl1_construction2(a3),a4
	ADDF.W	cl1_COLOR00+WORD_SIZE,a4 ; offfset colour palette offset in cl
	lea	bv_object1_color_table(pc),a5
	bsr.s	bv_draw_lines
	movem.l (a7)+,a3-a5
	rts

; Input
; a1.l	Pointer table x,y,z coordinates
; a2.l	Playfield address
; a4.l	Pointer table colour palette offset in cl
; a5.l	Pointer table object shading RGB colours
; Result
	CNOP 0,4
bv_draw_lines
	move.l	a7,save_a7(a3)
	bsr	bv_draw_lines_init
	lea	bv_object_info(pc),a0
	move.l	#((BC0F_SRCA|BC0F_SRCC|BC0F_DEST+NANBC|NABC|ABNC)<<16)|(BLTCON1F_LINE+BLTCON1F_SING),a3 ; mintern line mode
	move.l	a5,a7			; object shading table
	moveq	#bv_object_faces_number-1,d7
bv_draw_lines_loop1
; Calculate cross product u x v
	move.l	(a0)+,a5		; points starts
	swap	d7			; store loop counter in high word
	move.w	(a5),d4			; p1 start
	move.w	WORD_SIZE(a5),d5	; p2 start
	move.w	LONGWORD_SIZE(a5),d6	; p3 start
	movem.w (a1,d5.w),d0-d1		; p2(x,y)
	movem.w (a1,d6.w),d2-d3		; p3(x,y)
	sub.w	d0,d2			; xv = xp3-xp2
	sub.w	(a1,d4.w),d0		; xu = xp2-xp1
	sub.w	d1,d3			; yv = yp3-yp2
	sub.w	WORD_SIZE(a1,d4.w),d1	; yu = yp2-yp1
	muls.w	d3,d0			; xu*yv
	muls.w	d2,d1			; yu*xv
	sub.l	d0,d1			; zn = (yu*xv)-(xu*yv)
	bpl	bv_draw_lines_skip5
; Calculate face depth
	move.w	6(a5),d7		; p4 start
	move.w	LONGWORD_SIZE(a1,d4.w),d0 ; zm = zp1+zp2+zp3+zp4
	add.w	LONGWORD_SIZE(a1,d5.w),d0
	add.w	LONGWORD_SIZE(a1,d6.w),d0
	move.l	#bv_kdRGB*bv_EpRGB,d1	; (kdRGB*EpRGB)
	add.w	LONGWORD_SIZE(a1,d7.w),d0
	asr.w	#2,d0			; zm = face average z
	sub.w	#bv_light_z_coordinate,d0 ; D = zm-zl
; Calculate face colour intensity
	sub.w	#bv_D0,d0		; D-D0
	bgt.s	bv_draw_lines_skip1
	moveq	#1,d0			; D = 1 to avoid division by zero
bv_draw_lines_skip1
	divu.w	d0,d1			; RtdRGB = (kdRGB*EpRGB)/(D-D0)
	move.w	(a0),d7			; face colour number
	move.w	d7,d2
	MULUF.W	LONGWORD_SIZE,d2
	MULUF.W	WORD_SIZE,d1
	move.w	(a7,d1.w),(a4,d2.w)	; RGB4 face colour
	move.w	object_info_lines_number-object_info_face_color(a0),d6 ; number of lines
bv_draw_lines_loop2
	move.w	(a5)+,d0		; p1,p2 starts
	move.w	(a5),d2
	movem.w (a1,d0.w),d0-d1		; p1(x,y)
	movem.w (a1,d2.w),d2-d3		; p2(x,y)
	GET_LINE_PARAMETERS bv,AREAFILL,,,bv_draw_lines_skip4
	add.l	a3,d0			; remaining BLTCON0 & BLTCON1 bits
	add.l	a2,d1			; add playfield address

	btst	#0,d7			; bitplane 1 ?
	beq.s	bv_draw_lines_skip3
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6)	; high word: BLTCON0, low word: BLTCON1
	move.w	d3,BLTAPTL-DMACONR(a6)	; (4*dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	; playfield read
	move.l	d1,BLTDPT-DMACONR(a6)	; playfield write
	move.l	d4,BLTBMOD-DMACONR(a6)	; high word: 4*dy, low word: 4*(dy-dx)
	move.w	d2,BLTSIZE-DMACONR(a6)
bv_draw_lines_skip3
	btst	#1,d7			; bitplane 2 ?
	beq.s	bv_draw_lines_skip4
	moveq	#pf1_plane_width,d5
	add.l	d5,d1			; next bitplane
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6)	; high word: BLTCON0, low word: BLTCON1
	move.w	d3,BLTAPTL-DMACONR(a6) 	; (4*dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	; playfield read
	move.l	d1,BLTDPT-DMACONR(a6)	; playfield write
	move.l	d4,BLTBMOD-DMACONR(a6)	; high word: 4*dy, low word: 4*(dy-dx)
	move.w	d2,BLTSIZE-DMACONR(a6)
bv_draw_lines_skip4
	dbf	d6,bv_draw_lines_loop2
bv_draw_lines_skip5
	swap	d7			; restore loop counter
	addq.w	#LONGWORD_SIZE,a0	; skip face colour number and number of lines
	dbf	d7,bv_draw_lines_loop1
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
	move.l	variables+save_a7(pc),a7
	rts
	CNOP 0,4
bv_draw_lines_init
	move.w	#DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.l	#$ffff8000,BLTBDAT-DMACONR(a6) ; high word: line texture, low word: start line texture with MSB
	moveq	#-1,d0
	move.l	d0,BLTAFWM-DMACONR(a6)	; no mask
	moveq	#pf1_plane_width*pf1_depth3,d0 ; moduli for interleaved bitmaps
	move.w	d0,BLTCMOD-DMACONR(a6)
	move.w	d0,BLTDMOD-DMACONR(a6)
	rts


	CNOP 0,4
bv_fill_playfield1
	move.l	pf1_construction2(a3),a0
	add.l	#(pf1_plane_width*pf1_y_size3*pf1_depth3)-2,a0 ; end of bitplanes
	WAITBLIT
	move.l	#((BC0F_SRCA|BC0F_DEST|ANBNC|ANBC|ABNC|ABC)<<16)|(BLTCON1F_DESC+BLTCON1F_EFE),BLTCON0-DMACONR(a6) ; minterm D = A, fill mode, backwards
	move.l	a0,BLTAPT-DMACONR(a6)	; source
	move.l	a0,BLTDPT-DMACONR(a6)	; destination
	moveq	#0,d0
	move.l	d0,BLTAMOD-DMACONR(a6)	; A&D moduli
	move.w	#((bv_fill_blit_y_size*bv_fill_blit_depth)<<6)|(bv_fill_blit_x_size/WORD_BITS),BLTSIZE-DMACONR(a6)
	rts


; Object 2
	CNOP 0,4
bv_clear_playfield2
	movem.l a3-a6,-(a7)
	move.l	a7,save_a7(a3)	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	move.l	d0,a0
	move.l	d0,a1
	move.l	d0,a2
	move.l	d0,a4
	move.l	d0,a5
	move.l	d0,a6
	move.l	pf2_construction1(a3),a7
	move.l	d0,a3
	add.l	#pf2_plane_width*pf2_y_size3*pf1_depth3,a7 ; end of playfield
	REPT (pf2_plane_width*pf2_y_size3*pf1_depth3)/60
	movem.l d0-d7/a0-a6,-(a7)	; clear 60 bytes
	ENDR
	movem.l d0-d4,-(a7)		; clear remaining 20 bytes
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a6
	rts


	CNOP 0,4
bv_object2_rotate_xz_center
	movem.l	a4-a5,-(a7)
	lea	bv_object2_x_center_angle(a3),a1
	lea	bv_rotation_object2_x_center(a3),a2
	lea	bv_object2_z_center_angle(a3),a4
	lea	bv_rotation_object2_z_center(a3),a5
	bsr	bv_rotate_xz_center
	movem.l	(a7)+,a4-a5
	rts


	CNOP 0,4
bv_object2_rotation
	movem.l a4-a6,-(a7)
	move.w	bv_rotation_x_angle(a3),d1
	move.w	d1,d0		
	lea	sine_table(pc),a2
	move.w	(a2,d0.w),d4		; sin(a)
	move.w	#(sine_table_length/4)*WORD_SIZE,a4
	MOVEF.W (sine_table_length*WORD_SIZE)-1,d3 ; overflow 360°
	add.w	a4,d0			; + 90°
	swap	d4			; high word: sin(a)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d4		; low word: cos(a)
	move.w	bv_rotation_y_angle(a3),d1
	move.w	d1,d0		
	move.w	(a2,d0.w),d5		; sin(b)
	add.w	a4,d0			; + 90°
	swap	d5			; high word = sin(b)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d5		; low word: cos(b)
	move.w	bv_rotation_z_angle(a3),d1
	move.w	d1,d0		
	move.w	(a2,d0.w),d6		; sin(c)
	add.w	a4,d0			; + 90°
	swap	d6			; high word: sin(c)
	and.w	d3,d0			; remove overflow
	move.w	(a2,d0.w),d6		; low word: cos(c)

	lea	bv_object2_coordinates(pc),a0
	lea	bv_rotation_xyz_coordinates2(pc),a1
	move.w	bv_rotation_object2_z_center(a3),a4
	move.w	bv_rotation_object2_x_center(a3),a5
	bsr	bv_rotate_object
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
bv_draw_object2_lines
	movem.l a3-a5,-(a7)
	lea	bv_rotation_xyz_coordinates2(pc),a1
	move.l	pf2_construction2(a3),a2
	move.l	cl1_construction2(a3),a4
	ADDF.W	cl1_COLOR08+WORD_SIZE,a4 ; offset colour palette in cl
	lea	bv_object2_color_table(pc),a5
	bsr	bv_draw_lines
	movem.l (a7)+,a3-a5
	rts


	CNOP 0,4
bv_fill_playfield2
	move.l	pf2_construction2(a3),a0
	add.l	#(pf2_plane_width*pf2_y_size3*pf2_depth3)-2,a0 ; end of bitplanes
	WAITBLIT
	move.l	#((BC0F_SRCA|BC0F_DEST|ANBNC|ANBC|ABNC|ABC)<<16)|(BLTCON1F_DESC+BLTCON1F_EFE),BLTCON0-DMACONR(a6) ; minterm D = A, fill mode, backwards
	move.l	a0,BLTAPT-DMACONR(a6)	; source
	move.l	a0,BLTDPT-DMACONR(a6)	; destination
	moveq	#0,d0
	move.l	d0,BLTAMOD-DMACONR(a6)	; A&D moduli
	move.w	#((bv_fill_blit_y_size*bv_fill_blit_depth)<<6)|(bv_fill_blit_x_size/WORD_BITS),BLTSIZE-DMACONR(a6)
	rts


	CNOP 0,4
mouse_handler
	btst	#POTINPB_DATLY,POTINP-DMACONR(a6) ; RMB pressed ?
	bne.s	mouse_handler_quit
	clr.w	bv_rotate_xz_center_active(a3)
mouse_handler_quit
	rts


	INCLUDE "int-autovectors-handlers.i"


; PT-Replay
	IFEQ pt_ciatiming_enabled
		CNOP 0,4
ciab_ta_interrupt_server
	ENDC

	IFNE pt_ciatiming_enabled
		CNOP 0,4
vertb_interrupt_server
	ENDC

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
	REPT pf1_colors_number-1
	DC.W color00_bits
	ENDR

	CNOP 0,2
pf2_rgb4_color_table
	DC.W color00_bits
	REPT pf1_colors_number-1
	DC.W color00_bits
	ENDR


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


; Blenk-Vectors
	CNOP 0,2
bv_object1_color_table
	INCLUDE "MelODeeFx:colorpalettes/16-Colorgradient1.ct"

	CNOP 0,2
bv_object2_color_table
	INCLUDE "MelODeeFx:colorpalettes/16-Colorgradient2.ct"

; Cuboid shape for both objects
	CNOP 0,2
bv_object1_coordinates
	DC.W -(20*8),-(64*8),-(20*8)	; p0
	DC.W 20*8,-(64*8),-(20*8)	; p1
	DC.W 20*8,0,-(20*8)		; p2
	DC.W -(20*8),0,-(20*8)		; p3
	DC.W -(20*8),-(64*8),20*8	; p4
	DC.W 20*8,-(64*8),20*8		; p5
	DC.W 20*8,0,20*8		; p6
	DC.W -(20*8),0,20*8		; p7

	CNOP 0,2
bv_object2_coordinates
	DC.W -(20*8),-(64*8),-(20*8)	; p0
	DC.W 20*8,-(64*8),-(20*8)	; p1
	DC.W 20*8,0,-(20*8)		; p2
	DC.W -(20*8),0,-(20*8)		; p3
	DC.W -(20*8),-(64*8),20*8	; p4
	DC.W 20*8,-(64*8),20*8		; p5
	DC.W 20*8,0,20*8		; p6
	DC.W -(20*8),0,20*8		; p7

	CNOP 0,4
bv_object_info
; Face 1
	DC.L 0				; edge points table
	DC.W bv_object_face1_color
	DC.W bv_object_face1_lines_number-1
; Face 2
	DC.L 0				; edge points table
	DC.W bv_object_face2_color
	DC.W bv_object_face2_lines_number-1
; Face 3
	DC.L 0				; edge points table
	DC.W bv_object_face3_color
	DC.W bv_object_face3_lines_number-1
; Face 4
	DC.L 0				; edge points table
	DC.W bv_object_face4_color
	DC.W bv_object_face4_lines_number-1
; Face 5
	DC.L 0				; edge points table
	DC.W bv_object_face5_color
	DC.W bv_object_face5_lines_number-1
; Face 6
	DC.L 0				; edge points table
	DC.W bv_object_face6_color
	DC.W bv_object_face6_lines_number-1
	
	CNOP 0,2
bv_object_edges
	DC.W 0*3*WORD_SIZE,1*3*WORD_SIZE,2*3*WORD_SIZE,3*3*WORD_SIZE,0*3*WORD_SIZE ; front face
	DC.W 5*3*WORD_SIZE,4*3*WORD_SIZE,7*3*WORD_SIZE,6*3*WORD_SIZE,5*3*WORD_SIZE ; back face
	DC.W 4*3*WORD_SIZE,0*3*WORD_SIZE,3*3*WORD_SIZE,7*3*WORD_SIZE,4*3*WORD_SIZE ; left face
	DC.W 1*3*WORD_SIZE,5*3*WORD_SIZE,6*3*WORD_SIZE,2*3*WORD_SIZE,1*3*WORD_SIZE ; right face
	DC.W 4*3*WORD_SIZE,5*3*WORD_SIZE,1*3*WORD_SIZE,0*3*WORD_SIZE,4*3*WORD_SIZE ; upper face
	DC.W 3*3*WORD_SIZE,2*3*WORD_SIZE,6*3*WORD_SIZE,7*3*WORD_SIZE,3*3*WORD_SIZE ; lower face

	CNOP 0,2
bv_rotation_xyz_coordinates1
	DS.W bv_object_edge_points_number*3

	CNOP 0,2
bv_rotation_xyz_coordinates2
	DS.W bv_object_edge_points_number*3


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"


	DC.B "$VER: "
	DC.B "PT-Volume-Meter"
	DC.B "1.0 "
	DC.B "(11.4.26) "
	EVEN


; Audio data

; PT-Replay
	IFEQ pt_split_module_enabled
pt_auddata			SECTION pt_audio,DATA
		INCBIN "MelODeeFx:trackermodules/MOD.condom_corruption.song"
pt_audsmps			SECTION pt_audio2,DATA_C
		INCBIN "MelODeeFx:trackermodules/MOD.condom_corruption.smps"
	ELSE
pt_auddata			SECTION pt_audio,DATA_C
		INCBIN "MelODeeFx:trackermodules/MOD.condom_corruption"
	ENDC

	END
