; T_INT v2 - Tick musical a ~60 Hz sur Mega Drive PAL, via H_INT
;
; Principe (PAL, 313 lignes/trame, 1 ligne = 64 us) :
;   Un tick NTSC dure 1/59,92 s = 16,69 ms = 260,7 lignes PAL.
;   Sur un cycle de 5 trames (1565 lignes) on emet 6 ticks.
;   Les H_INT n'existent que sur les lignes 0-224 : un tick tombe forcement
;   dans le VBlank (89 lignes > ecart de 52 lignes entre deux ticks).
;   On le place sur la V_INT (ligne 224) de la trame 0, et on met la H_INT
;   de cette meme trame a la ligne 0 pour que l'ecart court soit le plus
;   grand possible (224 lignes). Les 5 autres ecarts valent 268/269 lignes.
;
;   Trame   tick H_INT   tick V_INT   ecart avec le tick precedent
;     0      ligne   0       oui       269 puis 224
;     1      ligne 179        -        268
;     2      ligne 134        -        268
;     3      ligne  89        -        268
;     4      ligne  44        -        268
;
; Compteur H_INT : charge avec le reg #10 pendant le VBlank, decremente sur
; les lignes 0-224, H_INT quand il passe sous 0, puis recharge avec la valeur
; du reg #10 A CET INSTANT. Ecrire le reg #10 dans le handler n'agit donc
; qu'apres la H_INT suivante : avec T <= 111 une 2e H_INT a la ligne 2T+1 est
; inevitable. Elle est simplement ignoree grace a hintDone.
;
; Sur console NTSC : H_INT coupee, un tick par V_INT, comme d'habitude.

ROM_SIZE	equ	65536
GFX_CTRL	equ	$C00004
GFX_DATA	equ	$C00000
VERSION		equ	$A10001		; bit 6 = 1 : console 50 Hz
tickCnt		equ	$FF0300		; .W ticks musicaux emis
vCnt		equ	$FF0302		; .W trames ecoulees
frameIdx	equ	$FF0304		; .B trame courante dans le cycle PAL (0-4)
hintDone	equ	$FF0305		; .B <> 0 : tick H_INT deja emis cette trame
isPAL		equ	$FF0306		; .B $FF si PAL
initialSP	equ	$1000000


	DC.L	initialSP
	DC.L	START
	DC.L	INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, H_INT, INT, V_INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	INT, INT, INT, INT, INT, INT, INT, INT
	DC.L	0,0,0,0,0,0,0,0
	DC.L	0,0,0,0,0,0,0,0

	DC.B	'SEGA MEGA DRIVE '		; Console name (16B)
	DC.B	'(C)OB1  2026.NOV'		; Copyright notice (16B)
	DC.B	'60 TICKS/S ON A '
	DC.B	'PAL MEGADRIVE   '
	DC.B	'                '		; Domestic game name (48B)
	DC.B	'60 TICKS/S ON A '
	DC.B	'PAL MEGADRIVE   '
	DC.B	'                '		; Overseas game name (48B)
	DC.B	'GM'				; Type of product (2B)
	DC.B	' 00000000-01'			; Product code, version nbr (12B)
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

START
	include "ICD_BLK4.PRG"			; sort avec SR = $2700, RAM a 0, reg #10 = $FF

	BTST	#6,(VERSION)
	SNE	(isPAL)				; SNE ne touche pas aux flags du BTST
	BEQ.S	@NTSC

	MOVE.B	#4,(frameIdx)			; la 1re V_INT fera passer a la trame 0
	MOVE.B	#1,(hintDone)			; ignore toute H_INT de la trame partielle
	MOVE.W	#$8AFF,GFX_CTRL
	MOVE.W	#$8014,GFX_CTRL			; reg 0 : H_INT autorisee
	BRA.S	@COMMON
@NTSC
	MOVE.W	#$8004,GFX_CTRL			; reg 0 : H_INT coupee
@COMMON
	MOVE.W	#$8164,GFX_CTRL			; reg 1 : DISP, V_INT, M5, V28
	MOVE.W	#$2300,SR			; superviseur, niveaux 4 et 6 acceptes

; =============================================================================
MAIN
	BRA.S	MAIN


; =============================================================================
INT:
	MOVE.W	#$2700,SR
@INF_LOOP:
	BRA.S	@INF_LOOP


; =============================================================================
H_INT:
	TST.B	(hintDone)
	BNE.S	@OUT				; H_INT parasite (ligne 2T+1) : on ignore
	MOVE.B	#1,(hintDone)
	MOVE.W	#$8AFF,GFX_CTRL			; plus de H_INT apres la parasite
	MOVEM.L	D0-D7/A0-A6,-(SP)
	BSR	MUSIC_TICK
	MOVEM.L	(SP)+,D0-D7/A0-A6
@OUT
	RTE


; =============================================================================
V_INT:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	ADDQ.W	#1,(vCnt)

	TST.B	(isPAL)
	BNE.S	@PAL
	BSR	MUSIC_TICK			; NTSC : un tick par trame
	BRA.S	@END

@PAL
	MOVEQ	#0,D0
	MOVE.B	(frameIdx),D0
	MOVE.W	D0,D2				; D2 = trame qui se termine
	ADDQ.W	#1,D0
	CMPI.W	#5,D0
	BLT.S	@NO_WRAP
	MOVEQ	#0,D0
@NO_WRAP
	MOVE.B	D0,(frameIdx)

	MOVE.W	#$8A00,D1			; reg #10 = ligne de la H_INT de la
	MOVE.B	@HLINE(PC,D0.W),D1		; trame suivante (recharge en VBlank)
	MOVE.W	D1,GFX_CTRL
	CLR.B	(hintDone)

	TST.W	D2				; fin de trame 0 : 2e tick de la trame
	BNE.S	@END
	BSR	MUSIC_TICK
@END
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTE

@HLINE	DC.B	0,179,134,89,44
	EVEN


; =============================================================================
; Point d'entree du driver son (ici : simple compteur pour la mesure).
; Sur 500 trames : ~600 ticks en PAL, 500 en NTSC.
MUSIC_TICK:
	ADDQ.W	#1,(tickCnt)
	RTS


	DS.B	ROM_SIZE-*
