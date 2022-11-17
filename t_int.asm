; I got 99 problems but ASM ain't one

ROM_SIZE	equ	65536
GFX_CTRL	equ	$C00004
GFX_DATA	equ	$C00000
HV_COUNTER	equ	$C00008
CTRL1		equ	$A10009
DATA1		equ	$A10003
Z80_BUSREQ	equ	$A11100
Z80_RESET	equ	$A11200
muteHInt		equ	$FF0300
INDEX		equ	$FF0301
hCnt		equ	$FF0304
vCnt		equ	$FF0306
initialSP	equ	$1000000
initialUSP	equ	initialSP-$100


	DC.L	initialSP
	DC.L	START
	DC.L	INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, H_INT, INT, V_INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	0				; Exception Vector #48
	DC.L	0,0,0,0,0,0,0
	DC.L	0,0,0,0,0,0,0,0

	DC.B	'SEGA MEGA DRIVE '		; Console name (16B)
	DC.B	'(C)OB1  2022.NOV'		; Copyright notice (16B)
	DC.B	'60 H_INT/S ON A '
	DC.B	'PAL MEGADRIVE   '
	DC.B	'                '		; Domestic game name (48B)
	DC.B	'60 H_INT/S ON A '
	DC.B	'PAL MEGADRIVE   '
	DC.B	'                '		; Overseas game name (48B)
	DC.B	'GM'				; Type of product (2B)
	DC.B	' 00000000-00'			; Product code, version nbr (12B)
	DC.W	0				; Checksum (2B)
	DC.B	'J               '		; I/O support (16B)
	DC.L	0, ROM_SIZE-1			; ROM start/end (4B each)
	DC.L	$FF0000,$FFFFFF			; RAM start/end (4B each)
	DC.B	'            '			; Padder (12B)
	DC.B	'            '			; Modem (12B)
	DC.B	'                '
	DC.B	'                '
	DC.B	'        '			; Memo (40B)
	DC.B	'E               '		; Country game (16B)

START
	include "ICD_BLK4.PRG"
	
	MOVE.W	#$8014,GFX_CTRL		; 0 0 0 HINT 0 1 M2 0
	MOVE.W	#$8164,GFX_CTRL		; 0 DISP VINT DMA V30 1 0 0

	MOVEA.L	#$FF0000,A2

	MOVEA.L	(48*4),A0		; Get USP from Exception Vector #48
	MOVE.L	A0,USP
	MOVE.W  #$0300,SR		; Set user mode, enable interrupts > 3



; =============================================================================
MAIN
	BRA	MAIN


; PAL   0      20      40      60      80      100
; ------+-------+-------+-------+-------+-------+---------------------------->
;
; ------+-----+------+------+------+------+-----+---------------------------->
; NTSC  0     16    33      50     66     83   100
;
; Line
; nbr   0    223    215    161    107    54   222
; PAL224
;
; If we generate an H_INT on these lines, we get an almost regular 60fps

; On each V_INT, we modify reg #10.
; * On first frame, reg #10 = 223. So we generate an H_INT each 223th line,
; that is 223, 446, 669, ... and so on. This isn't a problem since this is
; cleared ; as soon as line 224 with V_INT.
; * On second frame, we set reg #10 = 215. So we generate an H_INT each 215th
; line, that is 215, 430, 645, ... and so on. This isn't a problem since this
; is cleared as soon as line 224 with V_INT.
; * On third frame, we set reg #10 = 161. So we generate an H_INT each 161th
; line, that is 161, 483, ... and so on. This isn't a problem since this
; is cleared as soon as line 224 with V_INT.
; * On fourth frame, we set reg #10 = 107. So we generate an H_INT each 107th
; line, that is 107, and 214. This is a problem because we do NOT want an H_INT
; on 214th line. Changing reg #10 on line 107 is useless since this register
; will only be read on next H_INT, that is 214. Thus, we can't prevent the next
; H_INT to be on line 214. So, in this case, we mute the next H_INT.
; * On fifth frame, we set reg #10 = 54. So we generate an H_INT each 54th
; line, that is 54, 108, 162, ... and so on. This is a problem because we do
; NOT want an H_INT on these next lines ; but we DO want an H_INT on line 222.
; So, we set reg #10 to 72h = 114, and we mute the next H_INT. Then, when the
; next H_INT happens on line 108, reg #10 will be read and asked to raise H_INT
; on line 108 + 114 = 222. That's the sixth H_INT in our 5 PAL 224 frames.

; =============================================================================
INT:
	MOVE.W	#$2700,SR		; Disable Interrupts
@INF_LOOP:
	BRA.S	@INF_LOOP





H_INT:
	TST.B	(muteHInt)
	BEQ.S	@DO
	CLR.B	(muteHInt)
	RTE
@DO

	MOVE.L	D0,-(SP)

	ADDQ.W	#1,(hCnt)

	MOVE.W	(HV_COUNTER),D0
	LSR.W	#8,D0
	CMPI.W	#$70,D0
	BGE.S	@NO_STUTTER
	MOVE.B	#1,(muteHInt)
@NO_STUTTER
	MOVE.W	#$8A72,GFX_CTRL

	MOVE.L	(SP)+,D0
	RTE
H_INT_END:





V_INT:
	MOVEM.L	A0/D0-D1,-(SP)
	ADDQ.W	#1,(vCnt)

	LEA	@TABLE,A0
	MOVEQ	#0,D0
	MOVE.B	(INDEX),D0
	MOVEQ	#0,D1
	MOVE.B	(A0,D0),D1

	ANDI.W	#$FF,D1
	ORI.W	#$8A00,D1
	MOVE.W	D1,GFX_CTRL

	ADDQ	#1,D0
	CMPI.B	#5,D0
	BLT.S	@NO_OVERFLOW
	MOVEQ	#0,D0
@NO_OVERFLOW
	MOVE.B	D0,(INDEX)

	MOVEM.L	(SP)+,A0/D0-D1
	RTE
@TABLE	DC.B	$DF,$D7,$A1,$6B,$36
	even
V_INT_END:


	DS.B	ROM_SIZE-*
