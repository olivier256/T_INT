; I got 99 problems but ASM ain't one

ROM_SIZE	equ	$10000
GFX_CTRL	equ	$C00004
GFX_DATA	equ	$C00000
HV_COUNTER	equ	$C00008
CTRL1		equ	$A10009
DATA1		equ	$A10003
Z80_BUSREQ	equ	$A11100
Z80_RESET	equ	$A11200
tTimer		equ	$FF0000
freq_index	equ	$FF0002
freq_index2	equ	$FF0003
clearHInt	equ	$FF0004
clearVInt	equ	$FF0005
initialSP	equ	$FFFE00
initialUSP	equ	initialSP-$100
H_INT_RAM	equ	$FFFE00
V_INT_RAM	equ	$FFFF00


	DC.L	initialSP
	DC.L	init
	DC.L	INT, INT, INT, INT, INT, INT
	dc.l	INT, INT, INT, INT, INT, INT, INT, INT
	dc.l	INT, INT, INT, INT, INT, INT, INT, INT
	dc.l	INT, INT, INT, INT, H_INT, INT, V_INT, INT
	dc.l	INT, INT, INT, INT, INT, INT, INT, INT
	dc.l	INT, INT, INT, INT, INT, INT, INT, INT
	dc.l	initialUSP			; Exception Vector #48
	dc.l	0,0,0,0,0,0,0
	dc.l	0,0,0,0,0,0,0,0

	DC.B	'SEGA MEGA DRIVE '		; Console name (16B)
	DC.B	'(C)OB1  2022.NOV'		; Copyright notice (16B)
	DC.B	'T_INT           '
	DC.B	'                '
	DC.B	'                '		; Domestic game name (48B)
	DC.B	'T_INT           '
	DC.B	'                '
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
	DC.B	'JUE             '		; Country game (16B)

init:
	include "ICD_BLK4.PRG"
	
	move.w	#$8014,GFX_CTRL		; 0 0 0 HINT 0 1 M2 0
	move.w	#$8164,GFX_CTRL		; 0 DISP VINT DMA V30 1 0 0
;	move.w	#$8ADF,GFX_CTRL		; H_INT Register

	BSR	waitForVBlankSet
	BSR	waitForVBlankCleared
	MOVE.B	#1,(clearHInt)
	MOVE.W	#-1,D6

	movea.l	($C0),a0		; Get USP from Exception Vector #48
	move.l	a0,usp
	move.w  #$0300,sr		; Set user mode, enable interrupts > 3

	MOVE.W	#$8ADF,GFX_CTRL

	bra	main


; *memcpy(void *dest, const void * src, size_t n)
memcpy:
	LINK	A6,#0
	MOVE.L	(8,A6),A1	; A1 = *dest
	MOVE.L	(12,A6),A0	; A0 = *src
	MOVE.W	(16,A6),D0	; D0 = n
	LSR.W	#1,D0
@loop:
	MOVE.W	(A0)+,(A1)+
	DBRA	D0,@loop
	UNLK	A6
	RTS

















waitForVBlankCleared:
@waitForVBlank:
	btst	#3,(GFX_CTRL+1)
	bne.s	@waitForVBlank
	rts



waitForVBlankSet:
@waitForVBlank:
	btst	#3,(GFX_CTRL+1)
	beq.s	@waitForVBlank
	rts



















; =============================================================================
main:
	addq.w	#1,(tTimer)
	;move.w	sr,d3


	BRA	main



















; =============================================================================
INT:
	move.w	#$2700,SR		; Disable Interrupts
@infLoop:
	bra.s	@infLoop

H_INT:
	MOVE.B	(clearHInt),d0
	TST.B	D0
	BEQ.S	@noClear
	MOVE.B	#0,(clearHInt)
	BRA.S	@epilog
@noClear:
	addq.w	#1,d4
	moveq	#0,d0
	move.b	(freq_index2),d0
	lea	@freq2(pc),a1
	move.b	(a1,d0),d1
	andi.w	#$FF,d1
	addi.w	#$8A00,d1
	move.w	d1,GFX_CTRL
	addq.b	#1,d0
	cmpi.b	#6,d0
	blt	@skip2
	moveq	#0,d0
@skip2:
	move.b	d0,(freq_index2)
@epilog:
	rte
@freq2:
	DC.B	$FF,$FF,$FF,$FF,$00,$72
	even
H_INT_END:





V_INT:
	MOVE.B	(clearVInt),d0
	CMPI.B	#0,D0
	BEQ.S	@noClear
	MOVE.B	#0,(clearVInt)
	BRA.S	@epilog
@noClear:
	addq.w	#1,d6
	moveq	#0,d0
	move.b	(freq_index),d0
	lea	@freq,a1
	move.b	(a1,d0),d1
	andi.w	#$FF,d1
	addi.w	#$8A00,d1
	move.w	d1,GFX_CTRL
	addq.w	#1,d0
	cmpi.w	#5,d0
	blt	@skip
	moveq	#0,d0
@skip:
	move.b	d0,(freq_index)
@epilog
	rte
@freq:
	DC.B	223,215,161,107,54
	even
V_INT_END:


	DS.B	ROM_SIZE-*
