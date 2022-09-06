; Sound Server A
;== Ici commence le programme v‚ritable ================================

code      segment para 'CODE'             ;D‚finition du segment de CODE

	org 100h

	assume cs:code, ds:code, es:code, ss:code

start:    jmp PROGRAMMini              ;La premiŠre instruction ex‚cut‚e

;== Donn‚es (restent en m‚moire) =======================================

ancint    equ this dword              ;Ancien vecteur d'interruption 1Ch
ofsancint dw (?)            ;Adresse d'offset vecteur d'interruption 1Ch
segancint dw (?)               ;Adresse de segment vecteur d'interr. 1Ch

; Song to play
SONG     dw offset song1

; ------
; - Music Song Table
; --
song1part1 macro
        dw Fsh_low,w,C,Csh,Gsh,p,Csh,w,Gsh_low,p,C,Csh,p,Gsh_low,p
        endm
song1part2 macro
        dw Ash_low,w,C,Csh,Gsh,p,Csh,F_low,w,C,Csh,p,Gsh_low,Ash_low
        endm
song1part3 macro
        dw Ash_low,w,C,Csh,Gsh,p,Csh,F_low,w,C,Csh,C,Gsh_low,Ash_low
        endm
song1:
    song1part1
    song1part2
    song1part1
    song1part3
    dw 1 ; 0 = END ; 1 = loop

; ------
; - Notes/Keys frequencies equivalent
; --
  sii equ 2415       ;nada si oktaf 1  (7)
  la  equ 2711       ;nada la oktaf 1  (6)
  sol equ 3043       ;nada sol oktaf 1 (5)
  fa  equ 3416       ;nada fa oktaf 1 (4)
  mi  equ 3619       ;nada mi oktaf 1 (3)
  re  equ 4061       ;2
  do  equ 4560       ;1
  
  F_low equ 6833
  Fsh_low equ 6449
  Gsh_low equ 5746
  Ash_low equ 5119

  C equ 4560
  Csh equ 4304
  D equ 4063
  Dsh equ 3834
  E equ 3619
  F equ 3416
  Fsh equ 3224
  G equ 3043
  Gsh equ 2873
  
  w equ 00Fh ; White note
  p equ 0F0h ; Pause
    
  clock equ es:6Ch  ; clock pada es
  tone dw ?         ; deklarasi variabel tone yang kosong
  lastnote dw 0F0h; Pause

hlg       dw 0

; Message flag on/off
MSG      db ' '
FLAG     db '0'
         db '$'
         
SONGSAV  dw ?

;== Voici la nouvelle interruption (reste en m‚moire) ==================

newint    proc far

	jmp  short newintbs

	db "SD"                           ;Identification du programme

newintbs: pushf
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es
	push ss

	push cs                                 ;Ranger CS sur la pile
	pop  ds                            ;Retirer de la pile pour DS

;-- Programme ----------------------------------------------------------
    
playnote:

    mov  ax, hlg
    cmp  ax, 2 ; 1200 for wait 1s and 600 for 1/2s
    jne  fin
    mov  hlg, 0
    
playparsenote:
    mov  bx, SONG
    mov  ax, ds:[bx]
    mov  FLAG, al
    cmp  ax, 0F0h ; pause ?
    jne  playcontinue
    call matisuara
    jmp  playnext
playcontinue:
    cmp  ax, 00Fh ; white ?
    jne  playcontinue1
    jmp  playnext
playcontinue1:
    cmp  ax, 0 ; end ?
    jne  playcontinue2
    call matisuara
    jmp  fin
playcontinue2:
    cmp  ax, 1 ; reloop ?
    jne  playsounder
    call matisuara
    mov  bx, SONGSAV
    mov  SONG, bx
    jmp  fin
playsounder:
    cmp  ax, lastnote
    je   playnext
    mov  lastnote, ax
    mov  tone, ax
    call sounder
playnext:
    inc  SONG
    inc  SONG
    jmp  affCadre

fin:
    inc  hlg
    jmp  finprog

;-Affichage cadre-

affCadre:
    ;inc  cdr
    ;mov  ax, cdr
    ;cmp  ax, 20
    ;jne  fin
    ;mov  cdr, 0
    
    mov  ah, 3
    mov  bx, 0
    int  10h
    
    push dx
    
    mov  ah, 2
    mov  bx, 0
    mov  dh, 0
    mov  dl, 78
    int  10h
    mov  bx, offset MSG
    call aff

    pop  dx

    mov  ah, 2
    mov  bx, 0
    int  10h

;-- Fin ----------------------------------------------------------------

finprog:  pop  ss
	pop  es
	pop  ds
	pop  di
	pop  si
	pop  dx
	pop  cx
	pop  bx
	pop  ax
	popf

	jmp  cs:[ancint]               ;Vers l'ancienne routine de 1Ch

newint    endp

;== Sous-programmes ====================================================
; ------
; - Afficher --
; - DS:BX = Chaine … afficher
; - Tout les accus sont modifi‚s
; --
aff  proc near

bcl:  mov  ax, [bx]
	cmp  al, '$'
	je   affin
	cmp  al, 0
	je   afsort

	push ax
	push bx
	push cx

	mov  ah, 9
	mov  bx, 1
	mov  cx, 1
	int  10h

	mov  bx, 0
	mov  ah, 3
	int  10h
	add  dx, 1
	mov  ah, 2
	int  10h

	pop  cx
	pop  bx
	pop  ax

	inc  bx
	jmp  bcl

afsort:   mov  ax,0
	sub  ax, 1
affin:    ret
aff       endp
; ------
; -- sounder proc
; --
; untuk membunyikan suara oleh sound card
  sounder proc
    push ax
    in al, 61h
    or al, 00000011b          ; mengakses soundcard
    out 61h, al                 ; mengirim control word untuk ganti frekuensi
    mov al, 0B6h
    out 43h, al
    mov ax, [tone]            ; tone merupakan acuan untuk mengambil nada dari acuan
    out 42h, al               ; mengirim lower byte
    mov al, ah
    out 42h, al               ; mengirim upper  byte
    pop ax
    ret
  sounder endp
; ------
; - matisuara proc
; --
;agar suaranya mati
  
  matisuara proc
      in al,61h
      and al, 11111100b       ; menutup soundcard (invers dari akses soundcard)
      out 61h, al
      ret
  matisuara endp

instend   equ this byte                ;Jusqu'… cette cellule de m‚moire
				      ;tout doit rester r‚sident

;== Donn‚es (peuvent ˆtre effac‚es par le DOS) =========================

installm  db 13,10,"Song Server - Cyril BARBATO (c) 2022",13,10
	db "Sound Server enabled.",13,10,"$"

elimine   db 13,10,"Sound Server disabled.",13,10,"$"

;== Programme (peut ˆtre effac‚ par le DOS) ============================
;-- Routine de lancement et initialisation -----------------------------

PROGRAMMini   label near

    call matisuara
    
	mov  ax,351Ch         ;Lire contenu vecteur d'interruption 1Ch
	int  21h                                 ;Appeler fonction DOS
	cmp  word ptr es:[bx+2],"DS"     ;Tester si programme PROGRAMM
	jne  install             ;Pas de PROGRAMM install‚ --> INSTALL

;-- PROGRAMM est d‚sactiv‚ ---------------------------------------------

	mov  dx,es:ofsancint   ;Adresse d'offset de l'interruption 1Ch
	mov  ax,es:segancint ;Adresse de segment de l'interruption 1Ch
	mov  ds,ax                                            ;dans DS
	mov  ax,251Ch     ;Replacer contenu vecteur d'interruption 1Ch
	int  21h                                 ;sur ancienne routine

	mov  bx,es             ;Ranger adresse de segment du programme
	mov  es,es:[2Ch]  ;Retirer du PSP adr. seg. de l'environnement
	mov  ah,49h                         ;Lib‚rer … nouveau m‚moire
	int  21h                                 ;d'ancien environnent

	mov  es,bx                       ;Lib‚rer … nouveau la m‚moire
	mov  ah,49h                              ;de l'ancien PROGRAMM
	int  21h                     ;… travers la fonction 49h du DOS

	push cs                                 ;Sauver CS sur la pile
	pop  ds                                       ;Ramener dans DS

	mov  dx,offset elimine            ;Message : programme ‚limin‚
	mov  ah,9               ;Num‚ro de fonction pour Ecrire chaŒne
	int  21h                                 ;Appeler fonction DOS

	mov  ax,4C00h                 ;Terminer programme correctement
	int  21h                ;Appeler fonction pour terminer progr.

;-- Installation de PROGRAMM -------------------------------------------

install   label near

    call matisuara
    
    mov  bx, SONG
    mov  SONGSAV, bx        ;for reloop

	mov  ax,351Ch      ;Lire contenu du vecteur d'interruption 1Ch
	int  21h                                 ;Appeler fonction DOS
	mov  segancint,es      ;Ranger adresses de segment et d'offset
	mov  ofsancint,bx           ;Ranger vecteur d'interruption 1Ch

	mov  dx,offset newint    ;Adresse offset new routine d'interr.
	mov  ax,251Ch           ;Contenu du vecteur d'interruption 1Ch
	int  21h                              ;sur routine utilisateur

	mov  dx,offset installm          ;Message : programme install‚
	mov  ah,9               ;Num‚ro de fonction pour Sortir chaŒne
	int  21h                                 ;Appeler fonction DOS

	   ;-- Seuls le PSP, la nouvelle routine d'interruption et les
	   ;-- donn‚es correspondantes doivent rester r‚sidentes.     

	mov  dx,offset instend ;Calculer nombre de paragraphes (unit‚s
	mov  cl,4       ;de 08 octets) dont doit disposer le programme
	shr  dx,cl
	inc  dx
	mov  ax,3100h      ;Terminer programme par code de fin 0 (o.k)
	int  21h                                 ;mais rester r‚sident

;== Fin ================================================================

code      ends                                   ;Fin du segment de CODE
	end  start
