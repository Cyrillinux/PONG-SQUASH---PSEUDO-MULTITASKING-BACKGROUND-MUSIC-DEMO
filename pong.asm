
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.DATA                

    FRAMES_DELAY equ 41 ;24 fps
    
    current_time db ?   ;used in delay function
    initial_time db ?   ;used in delay function

    ball_center_x dw 160
    ball_center_y dw 100
    ball_radius  dw 7
    ball_radius_square dw ? ;will be calculated in main
    
    ball_velocity_x dw 5
    ball_velocity_y dw 2
           
.CODE 

MAIN    PROC FAR

    mov ax, @DATA
    mov ds, ax
    
    mov ax, ball_radius
    mul ball_radius
    mov ball_radius_square, ax
                     
    call SET_GRAPHIC_MODE
    
    move_ball_loop:
        call CLEAR_BALL
        call MOVE_BALL
        call DRAW_BALL
        call DELAY
        jmp move_ball_loop
    
    mov ah, 4ch ;exit status
    int 21h
    
MAIN    ENDP
;---------------------
DRAW_BALL   PROC
    
    ;call SET_GRAPHIC_MODE
       
    mov dx, ball_center_y       ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    draw_ball_loop1:
        mov cx, ball_center_x    ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        draw_ball_loop2:
            call CHECK_INSIDE_BALL
            cmp bx, 0000h
            je pass_this_pixel
            mov ah, 0ch         ;code for drawing pixel
            mov al, 0Fh         ;color (white)
            int 10h             ;interupt
            pass_this_pixel:
                inc cx              ;go to next column
                mov ax, ball_center_x    ;checking if code reached end of column
                add ax, ball_radius    
                cmp cx, ax
                jnz draw_ball_loop2
                
                inc dx                  ;go to next row
                mov ax, ball_center_y    ;checking if code reached end of row
                add ax, ball_radius
                cmp dx, ax
                jnz draw_ball_loop1
            
        
            
    RET
            
DRAW_BALL   ENDP    
;---------------------
CHECK_INSIDE_BALL   PROC ;checks if coordinate inside cx and dx is inside the ball's circle. bx=1 for yes, bx=0 for no
    
    push cx     
    push dx     ;keep row and column inside stack
    
    cmp cx, ball_center_x   ;check if current point is left or right of center
    jge cx_is_positive
    
    mov ax, ball_center_x
    sub ax, cx
    xchg ax, cx                 ;now center_x - current_x is in cx
    jmp delta_x_is_calculated
        
    cx_is_positive: 
        sub cx, ball_center_x   ;now current_x - center_x is in cx
        jmp delta_x_is_calculated
    
    delta_x_is_calculated:
        mov al, cl
        mul cl          ;delta_x^2 inside ax
        push ax         ;push ax to stack
        
    cmp dx, ball_center_y   ;check if current point is up or down of center
    jge dx_is_positive
    
    mov ax, ball_center_y
    sub ax, dx
    xchg ax, dx                 ;now center_y - current_y is in cx
    jmp delta_y_is_calculated
    
    dx_is_positive:
        sub dx, ball_center_y   ;now current_y - center_y is in cx
        jmp delta_y_is_calculated
    
    delta_y_is_calculated:
        mov al, dl
        mul dl          ;delta_y^2 is inside ax
        push ax         ;push ax to stack
        
    calculate_distance_squared:
        pop bx                          
        pop ax
        add bx, ax                      ;calculate delta_x^2 + delta_y^2
        cmp bx, ball_radius_square
        jle point_is_inside_circle
        jg point_is_outside_circle
        
    point_is_inside_circle:
        mov bx, 1
        jmp check_inside_ball_exit
    
    point_is_outside_circle:
        mov bx, 0
        jmp check_inside_ball_exit         

    check_inside_ball_exit:
        pop dx
        pop cx    
        RET
    
CHECK_INSIDE_BALL   ENDP    
;---------------------
MOVE_BALL   PROC       
    
    mov ax, ball_velocity_x
    add ball_center_x, ax
    mov ax, ball_velocity_y
    add ball_center_y, ax
    
    RET
    
MOVE_BALL   ENDP    
;---------------------
DELAY PROC       
        
    mov ah, 86h
    mov cx, 0h
    mov dx, 0a028h  ;wait for 41 miliseconds (for 24 fps)
    int 15h
    
    RET
    
DELAY ENDP    
;---------------------
CLEAR_BALL  PROC    ;same as draw ball, with black color
    
    mov dx, ball_center_y        ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    clear_ball_loop1:
        mov cx, ball_center_x    ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        clear_ball_loop2:
            mov ah, 0ch         ;code for drawing pixel
            mov al, 00h         ;color (black)
            int 10h             ;interupt
            inc cx              ;go to next column
            mov ax, ball_center_x    ;checking if code reached end of column
            add ax, ball_radius    
            cmp cx, ax
            jnz clear_ball_loop2
            
            inc dx                  ;go to next tow
            mov ax, ball_center_y    ;checking if code reached end of row
            add ax, ball_radius
            cmp dx, ax
            jnz clear_ball_loop1
    
    RET
    
CLEAR_BALL  ENDP    
;---------------------
CLEAR_SCREEN    PROC
    
    mov ah, 06H     ;scroll up
    mov al, 00h     ;clear entire window
    mov bh, 00h     ;color    
    mov cx, 0000    ;start row, column
    mov dx, 184fh   ;end  row, column
    int 10h
      
    RET
    
CLEAR_SCREEN    ENDP
;---------------------
SET_GRAPHIC_MODE    PROC
       
    mov ah, 00h     ;setting video mode
    mov al, 13h     ;320x200 256 colors 
    int 10h         ;call interruption      
    
    RET
    
SET_GRAPHIC_MODE    ENDP    
;---------------------
END MAIN

ret




