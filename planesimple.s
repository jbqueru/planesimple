; Copyright 2024 Jean-Baptiste M. "JBQ" "Djaybee" Queru
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU Affero General Public License as
; published by the Free Software Foundation, either version 3 of the
; License, or (at your option) any later version.
;
; As an added restriction, if you make the program available for
; third parties to use on hardware you own (or co-own, lease, rent,
; or otherwise control,) such as public gaming cabinets (whether or
; not in a gaming arcade, whether or not coin-operated or otherwise
; for a fee,) the conditions of section 13 will apply even if no
; network is involved.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU Affero General Public License for more details.
;
; You should have received a copy of the GNU Affero General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; SPDX-License-Identifier: AGPL-3.0-or-later

; Coding style:
;	- ASCII
;	- hard tabs, 8 characters wide, except in ASCII art
;	- 120 columns overall
;	- Standalone block comments in the first 80 columns
;	- Code-related block comments allowed in the last 80 columns
;	- Note: rulers at 40, 80 and 120 columns help with source width
;
;	- Assembler directives are .lowercase
;	- Mnemomics and registers are lowercase unless otherwise required
;	- Global symbols for code are CamelCase
;	- Symbols for variables are snake_case
;	- Symbols for hardware registers and OS constants are ALL_CAPS
;	- Related symbols start with the same prefix (so they sort together)
;	- hexadecimal constants are lowercase ($eaf00d).
;
;	- Include but comment out instructions that help readability but
;		don't do anything (e.g. redundant CLC on 6502 when the carry is
;		guaranteed already to be clear). The comment symbol should be
;		where the instruction would be, i.e. not on the first column.
;		There should be an explanation in a comment.
;	- Use the full instruction mnemonic when a shortcut would potentially
;		cause confusion. E.g. use movea instead of move on 680x0 when
;		the code relies on the flags not getting modified.

; #############################################################################
; #############################################################################
; ###                                                                       ###
; ###                                                                       ###
; ###                     System and hardware constants                     ###
; ###                                                                       ###
; ###                                                                       ###
; #############################################################################
; #############################################################################

; ######################
; ######################
; ###                ###
; ###  Trap numbers  ###
; ###                ###
; ######################
; ######################

GEMDOS	.equ	1
XBIOS	.equ	14

; #########################
; #########################
; ###                   ###
; ###  XBIOS functions  ###
; ###                   ###
; #########################
; #########################

SUPEXEC	.equ	38

; ##########################
; ##########################
; ###                    ###
; ###  GEMDOS functions  ###
; ###                    ###
; ##########################
; ##########################

TERM0	.equ	0

; ############################
; ############################
; ###                      ###
; ###  Exception handlers  ###
; ###                      ###
; ############################
; ############################

HANDLER_VBL	.equ	$70
HANDLER_TIMER_B	.equ	$120

; ############################
; ############################
; ###                      ###
; ###  Graphics registers  ###
; ###                      ###
; ############################
; ############################

GFX_VBAH	.equ	$ffff8201
GFX_VBAM	.equ	$ffff8203
GFX_SYNC	.equ	$ffff820a
GFX_COLOR0	.equ	$ffff8240
GFX_PALETTE	.equ	GFX_COLOR0
GFX_RES		.equ	$ffff8260

; #################################
; #################################
; ###                           ###
; ###  MC68901 (MFP) registers  ###
; ###                           ###
; #################################
; #################################

MFP_IERA	.equ	$fffffa07
MFP_IERB	.equ	$fffffa09
MFP_IPRA	.equ	$fffffa0b
MFP_IPRB	.equ	$fffffa0d
MFP_IMRA	.equ	$fffffa13
MFP_IMRB	.equ	$fffffa15
MFP_VR		.equ	$fffffa17
MFP_TBCR	.equ	$fffffa1b
MFP_TBDR	.equ	$fffffa21

; #############################################################################
; #############################################################################
; ###                                                                       ###
; ###                                                                       ###
; ###                                 Init                                  ###
; ###                                                                       ###
; ###                                                                       ###
; #############################################################################
; #############################################################################

	.68000
	.bss
	.even
BssStart:				; marker at start of BSS so that we can
					; clear the whole BSS for environments
					; that don't clear it for us

	.text
	.even

; #####################
; #####################
; ###               ###
; ###  Entry point  ###
; ###               ###
; #####################
; #####################

UserStart:

; ***************
; **           **
; ** Clear BSS **
; **           **
; ***************

; TODO: optimize. A lot.
; TODO: run this from a clear screen, with music on

	lea.l	BssStart, a0
BssClear:
	clr.w	(a0)+
	cmpa.l	#BssEnd, a0
	bne.s	BssClear

; *******************************
; **                           **
; ** Switch to supervisor mode **
; **                           **
; *******************************

	pea.l	SupervisorStart
	move.w	#SUPEXEC, -(sp)
	trap	#XBIOS
	lea.l	6(sp), sp

; ***************************
; **                       **
; ** Exit back to launcher **
; **                       **
; ***************************

	move.w	#TERM0, -(sp)
	trap	#GEMDOS

; ################################
; ################################
; ###                          ###
; ###  Supervisor entry point  ###
; ###                          ###
; ################################
; ################################

SupervisorStart:
	btst.b	#1, GFX_RES.w
	beq.s	.ColorMonitor
	rts
.ColorMonitor:

	move.w	sr, save_sr
	move.w	#$2700, sr

	move.b	MFP_TBCR.w, save_tbcr
	move.b	#0, MFP_TBCR.w
	move.b	MFP_IERA.w, save_iera
	move.b	#0, MFP_IERA.w
	move.b	MFP_IERB.w, save_ierb
	move.b	#0, MFP_IERB.w
	move.b	MFP_IMRA.w, save_imra
	move.b	#0, MFP_IMRA.w
	move.b	MFP_IMRB.w, save_imrb
	move.b	#0, MFP_IMRB.w
	move.b	#0, MFP_IPRA.w
	move.b	#0, MFP_IPRB.w
	move.b	MFP_VR.w, save_vr
	move.b	#64, MFP_VR.w

	move.l	HANDLER_VBL.w, save_vbl
	move.l	#VBL, HANDLER_VBL.w
	move.l	HANDLER_TIMER_B.w, save_hbl
	move.l	#HBL, HANDLER_TIMER_B.w
	move.w	#$2300, sr

	lea.l	vbl_count, a0
	move.l	(a0), d0
.WaitVbl:
	cmp.l	(a0), d0
	beq.s	.WaitVbl

	lea.l	Palette, a0
	lea.l	$ffff8240.w, a1
	lea.l	save_palette, a2
	moveq.l	#15, d7
CopyPalette:
	move.w	(a1), (a2)+
	move.w	(a0)+, (a1)+
	dbra	d7, CopyPalette

	move.b	#20, MFP_TBDR.w
	move.b	#8, MFP_TBCR.w
	move.b	#1, MFP_IERA.w
	move.b	#1, MFP_IMRA.w

	moveq.l	#0, d0
	move.b	GFX_VBAH.w, d0
	lsl.l	#8, d0
	move.b	GFX_VBAM.w, d0
	lsl.l	#8, d0
	movea.l	d0, a0
	move.l	d0, framebuffer

	move.w	#15999, d7
ClearScreen:
	clr.w	(a0)+
	dbra	d7, ClearScreen

	movea.l	framebuffer, a0
	moveq.l	#8, d0
	moveq.l	#24, d7
MBRow:
	moveq.l	#9, d6
MBUnit:
	move.w	#%1100011011111100, (a0)
	move.w	#%1110111011000110, 160(a0)
	move.w	#%1111111011000110, 320(a0)
	move.w	#%1101011011111100, 480(a0)
	move.w	#%1100011011000110, 640(a0)
	move.w	#%1100011011000110, 800(a0)
	move.w	#%1100011011111100, 960(a0)
	lea.l	16(a0), a0
	dbra	d6, MBUnit
	adda.w	d0, a0
	neg.w	d0
	lea.l	1120(a0), a0
	dbra	d7, MBRow

	move.w	#$cafe, d5
	moveq.l	#99, d7
OneBall:
	movea.l	framebuffer, a1

	moveq.l	#0, d0
	move.w	d5, d0
	divu	#304, d0
	swap	d0
	move.w	d0, d1
	andi	#$fff0, d0
	lsr.w	d0
	adda.w	d0, a1
	andi	#15, d1

	clr.w	d0
	swap	d0
	divu	#185, d0
	swap	d0
	mulu	#160, d0
	adda.w	d0, a1

	lea.l	BallData, a0
	moveq.l	#15, d6
BallRow:
	move.l	(a0)+, d0
	ror.l	d1, d0
	and.w	d0, 10(a1)
	swap	d0
	and.w	d0,2(a1)
	move.l	(a0)+, d0
	ror.l	d1, d0
	or.w	d0, 10(a1)
	swap	d0
	or.w	d0,2(a1)
	lea.l	160(a1), a1
	dbra	d6, BallRow

	ror.w	#3, d5
	addi.w	#$beef, d5

	dbra	d7, OneBall

	movea.l	framebuffer, a0
	adda.w	#2572, a0
	moveq.l	#17, d7
Hloop:
	move.w	#$ffff, (a0)
	move.w	#$ffff, 160(a0)
	move.w	#$ffff, 2*160(a0)
	move.w	#$ffff, 3*160(a0)
	move.w	#$ffff, 164*160(a0)
	move.w	#$ffff, 165*160(a0)
	move.w	#$ffff, 166*160(a0)
	move.w	#$ffff, 167*160(a0)
	adda.w	#8, a0
	dbra	d7, Hloop
	adda.w	#496, a0
	move.w	#159, d7
Vloop:
	move.w	#$f000, (a0)
	move.w	#$000f, 136(a0)
	adda.w	#160, a0
	dbra	d7, Vloop

	movea.l	framebuffer, a0
	lea.l	88(a0), a0
	moveq.l	#$ffffffff, d0
	move.w	#199, d7
Split:
	move.w	d0, 6(a0)
	move.w	d0, 14(a0)
	move.w	d0, 22(a0)
	move.w	d0, 30(a0)
	move.w	d0, 38(a0)
	move.w	d0, 46(a0)
	move.w	d0, 54(a0)
	move.w	d0, 62(a0)
	move.w	d0, 70(a0)
	lea.l	160(a0), a0
	dbra	d7, Split


	lea.l	distortdata, a0
	moveq.l	#-1, d0
	.rept	32
	move.l	d0, (a0)+
	lsr.l	d0
	.endr
	lea.l	distortdata + 256, a0
	moveq.l	#-1, d0
	.rept	32
	move.l	d0, -(a0)
	lsr.l	d0
	.endr

	move.l	#distortdata, readdistort
Loop:

	movea.l	framebuffer, a1
	lea.l	78(a1), a1
	move.w	#199, d7
	movea.l	readdistort, a0
	lea.l	4(a0), a0
	cmpa.l	#distortdata + 256, a0
	bne.s	IOK
	lea.l	-256(a0), a0
IOK:
	move.l	a0, readdistort
Distort:
	move.w	(a0)+, (a1)
	move.w	(a0)+, 8(a1)
	cmpa.l	#distortdata + 256, a0
	bne.s	BOK
	lea.l	-256(a0), a0
BOK:
	lea.l	160(a1), a1
	dbra	d7, Distort

	move.l	vbl_count, d0
WaitVBL:
	cmp.l	vbl_count, d0
	beq.s	WaitVBL

	cmp.b	#$39, $fffffc02.w
	beq.s	Exit

	bra.s	Loop

Exit:
	move.w	#$2700, sr

	lea.l	save_palette, a0
	lea.l	$ffff8240.w, a1
	moveq.l	#15, d7
RestorePalette:
	move.w	(a0)+, (a1)+
	dbra	d7,RestorePalette

	move.b	#0, MFP_TBCR.w
	move.b	save_vr, MFP_VR.w
	move.b	save_imrb, MFP_IMRB.w
	move.b	save_imra, MFP_IMRA.w
	move.b	save_ierb, MFP_IERB.w
	move.b	save_iera, MFP_IERA.w
	move.b	save_tbcr, MFP_TBCR.w
	move.l	save_hbl, HANDLER_TIMER_B
	move.l	save_vbl, HANDLER_VBL
	move.w	save_sr, sr
	rts

VBL:
	addq.l	#1, vbl_count
	rte

HBL:
	not.w	$ffff8240.w
	rte

	.data
	.even
Palette:
	.dc.w	$000, $742, $000, $742
	.dc.w	$657, $657, $657, $657
	.dc.w	$000, $000, $463, $463
	.dc.w	$657, $657, $657, $657

BallData:
	.dc.l	%11111000000111111111111111111111, %00000000000000000000000000000000
	.dc.l	%11100000000001111111111111111111, %00000011110000000000000000000000
	.dc.l	%11000000000000111111111111111111, %00001111111100000000000000000000
	.dc.l	%10000000000000011111111111111111, %00011011111110000000000000000000
	.dc.l	%10000000000000011111111111111111, %00110111111111000000000000000000
	.dc.l	%00000000000000001111111111111111, %00101111111111000000000000000000
	.dc.l	%00000000000000001111111111111111, %01101111111111100000000000000000
	.dc.l	%00000000000000001111111111111111, %01111111111111100000000000000000
	.dc.l	%00000000000000001111111111111111, %01111111111111100000000000000000
	.dc.l	%00000000000000001111111111111111, %01111111111111100000000000000000
	.dc.l	%00000000000000001111111111111111, %00111111111111000000000000000000
	.dc.l	%10000000000000011111111111111111, %00111111111111000000000000000000
	.dc.l	%10000000000000011111111111111111, %00011111111110000000000000000000
	.dc.l	%11000000000000111111111111111111, %00001111111100000000000000000000
	.dc.l	%11100000000001111111111111111111, %00000011110000000000000000000000
	.dc.l	%11111000000111111111111111111111, %00000000000000000000000000000000

	.bss
	.even

; #############################################################################
; #############################################################################
; ###                                                                       ###
; ###                                                                       ###
; ###                          Save system values                           ###
; ###                                                                       ###
; ###                                                                       ###
; #############################################################################
; #############################################################################

save_sr:
	.ds.w	1

save_iera:
	.ds.b	1
save_ierb:
	.ds.b	1
save_imra:
	.ds.b	1
save_imrb:
	.ds.b	1
save_vr:
	.ds.b	1
save_tbcr:
	.ds.b	1

	.even
save_vbl:
	.ds.l	1
save_hbl:
	.ds.l	1

save_palette:
	.ds.w	16

vbl_count:
	.ds.l	1

framebuffer:
	.ds.l	1

readdistort:
	.ds.l	1

distortdata:
	.ds.l	64

	.even
BssEnd:					; marker at end of BSS so that we can
					; clear the whole BSS for environments
					; that don't clear it for us
	.end
