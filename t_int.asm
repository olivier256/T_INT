; I got 99 problems but ASM ain't one

ROM_SIZE	equ	$10000
GFX_CTRL	equ	$C00004
GFX_DATA	equ	$C00000
HV_COUNTER	equ	$C00008
CTRL1		equ	$A10009
DATA1		equ	$A10003
Z80_BUSREQ	equ	$A11100
Z80_RESET	equ	$A11200
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
	move.w	#$8A00,GFX_CTRL		; H_INT Register

	MOVEA.L	#$FF0000,A2
	MOVEA.L	#$FF0200,A3

	movea.l	($C0),a0		; Get USP from Exception Vector #48
	move.l	a0,usp
	move.w  #$0300,sr		; Set user mode, enable interrupts > 3


	bra	main






; =============================================================================
main:
	MOVE.W	$C00008,d2	; d2 = VC7 ... VC0 HC8 ... HC1
	MOVEQ	#0,D3
	MOVE.B	D2,D3
	CMPI.W	#$50,D3
	BMI.S	@sameLine
	ADDA.L	#$10,A2
	MOVE.W	#0,(A2)
@sameLine:
	MOVE.W	HV_COUNTER,D2	; d2 = VC7 ... VC0 HC8 ... HC1
	LSR.W	#8,D2		; D2 = 00000000 VC7 ... VC0
	CMP.B	D4,D2
	BEQ.S	main
	MOVE.B	D2,(A2)
	MOVE.B	D2,D4

	BRA	main



















; =============================================================================
INT:
	move.w	#$2700,SR		; Disable Interrupts
@infLoop:
	bra.s	@infLoop



H_INT:
	MOVE.W	HV_COUNTER,D0
	LSR.W	#8,D0
	MOVE.B	D0,(1,A2)
	RTE
	even
H_INT_END:





V_INT:
	MOVEA.L	#$FF0000,A2
	rte
	even
V_INT_END:


	DS.B	ROM_SIZE-*
