; I got 99 problems but ASM ain't one

ROM_SIZE	equ	65536
GFX_CTRL	equ	$C00004
GFX_DATA	equ	$C00000
HV_COUNTER	equ	$C00008
CTRL1		equ	$A10009
DATA1		equ	$A10003
Z80_BUSREQ	equ	$A11100
Z80_RESET	equ	$A11200
hCnt		equ	$FF0300
initialSP	equ	$1000000
initialUSP	equ	initialSP-$100


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
	MOVE.W	#$8A00,GFX_CTRL

	MOVEA.L	#$FF0000,A2

	movea.l	($C0),a0		; Get USP from Exception Vector #48
	move.l	a0,usp
	move.w  #$0300,sr		; Set user mode, enable interrupts > 3


	bra	main






; =============================================================================
main:
	BRA	main



















; =============================================================================
INT:
	move.w	#$2700,SR		; Disable Interrupts
@infLoop:
	bra.s	@infLoop



H_INT:
	ADDQ.W	#1,(hCnt)
	LEA	@table,A0
	MOVEQ	#0,D1
	MOVE.B	(A0,D2),D1
	MOVE.W	HV_COUNTER,D0
	LSR.W	#8,D0
	CMP.B	D0,D1
	BEQ.S	@do
	RTE
@do
	ADDQ	#1,D4
	MOVE.B	D0,(A2)+
	ADDQ.B	#1,D2
	CMPI.B	#6,D2
	BLT.S	@skip
	MOVEQ	#0,D2
@skip
	RTE
@table	DC.B	$DF,$D7,$A1,$6B,$36,$00
	even
H_INT_END:





V_INT:
	ADDQ	#1,D6
	CLR.W	(hCnt)
	ADDQ	#1,D3
	CMPI.B	#5,D3
	BLT.S	@skip
	MOVEQ	#0,D3
	MOVEA.L	#$FF0000,A2
	MOVE.L	#0,(A2)
	MOVE.L	#0,(4,A2)
	MOVE.L	#0,(8,A2)
	MOVE.L	#0,($C,A2)
@skip
	rte
	even
V_INT_END:


	DS.B	ROM_SIZE-*
