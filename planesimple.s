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
;	- Symbols for hardware registers are ALL_CAPS
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

	.68000
	.text
	.even
	pea.l	Super
	move.w	#38, -(sp)
	trap	#14

Super:	move.w	#$2700, sr
	lea.l	Palette, a0
	lea.l	$ffff8240.w, a1
	moveq.l	#15, d7
CopyPalette:
	move.w	(a0)+, (a1)+
	dbra	d7, CopyPalette

	moveq.l	#0, d0
	move.b	$ffff8201.w, d0
	lsl.l	#8, d0
	move.b	$ffff8203.w, d0
	lsl.l	#8, d0
	movea.l	d0, a0
	move.l	d0, framebuffer

	move.w	#15999, d7
ClearScreen:
	clr.w	(a0)+
	dbra	d7, ClearScreen

	movea.l	framebuffer, a0
	moveq.l	#8, d0
	moveq.l	#12, d7
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
	lea.l	2400(a0), a0
	dbra	d7, MBRow

Loop:
	bra.s	Loop

	.data
	.even
Palette:
	.dc.w	$000, $742, $463, $463
	.dc.w	$657, $657, $657, $657
	.dc.w	$663, $663, $663, $663
	.dc.w	$663, $663, $663, $663

	.bss
	.even
framebuffer:
	.ds.l	1
