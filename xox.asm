name "XOX"

org 100h
         
.data
    ; Degiskenler                            
    ; =======================================
    board db 9 dup(" ")
    
    is_game_over db 0 ; Oyun bitince 1 olur.
    move_counter db 0 ; Her hamlede 1 artar. Sira belirlemede kullanilir. Eski ismi: turn_counter 
    ;last_move    db ? ; 0 -> Oyundan cik | 1..9 -> Hamlenin yeri | >9 -> Mumkun degil
    ;last_human_move db 10; 0 -> Oyundan cik | 1..9 -> Son Hamlenin (insan) yeri | 10 -> Baslangic degeri (bos)
    winner       db 0 ; 0 -> Belli degil / Berabere | 1 -> X | 2 -> O | >2 -> Mumkun degil
    gamemode     db 0 ; 0 -> Belli degil | 1 -> 1 Kisilik | 2 -> 2 Kisilik 
    
    ; SABITLER
    ; =======================================
    demo_board db "123456789" 
    
    ; XOX tahtasi cizerken kullanilmak uzere: 
    linediv:    
    db "----------", 0Dh,0Ah, 24h    

    rowdiv:
        db " | ", 24h 
     
    ; Her yerde genel amacla kullanilmak uzere:
    exit_app_msg:
        db "Program sonlandirildi! Tekrar gorusmek uzere.", 24h
    
    press_any_key_to_continue:
        db "Devam etmek icin bir tusa basin...", 24h
        
    press_any_key_to_return_to_main_menu:
        db "Ana menuye donmek icin bir tusa basin...", 24h
         
    newline: 
        db 0Dh,0Ah, 24h  
        
    str_buffer: ; Muhtemelen kullanmicam.
        db 256 dup(24h) ; Tek seferde max. 255 (+1 24h icin) karakter basabilmek icin alan.      
                  
                  
    ; Oyun modu secimi icin satir satir basilmak uzere: 
    gamemode_selection_prompt0:
        db "====================================================", 24h
                 
    gamemode_selection_prompt1:
        db "XOX oyununa hosgeldiniz! Lutfen bir oyun modu secin:",24h 
        
    gamemode_selection_prompt2:
        db "====================================================", 24h
    
    gamemode_selection_prompt3:
        db "1 - Oyuncu vs CPU",24h
        
    gamemode_selection_prompt4:
        db "2 - Oyuncu vs Oyuncu", 24h
        
    gamemode_selection_prompt5:
        db "3 - Programdan Cikis", 24h    
        
    gamemode_selection_prompt6:
        db "====================================================", 24h
        
    gamemode_selection_prompt7:
        db "Seciminiz: ", 24h
        
        
    ; Oyuna baslamadan basilmak uzere:    
    move_tutorial_prompt:
        db "Hamleler ve yerleri asagidadir. Oyuna baslamak icin bir tusa basin...", 24h       
        
        
        
   ; Oyun yuklenirken (kullanim disi)
   loading_text:
        db "Oyun yukleniyor...", 24h
        
   cpu_thinking_text:
        db "CPU dusunuyor...", 24h
        
   
   ; Oyuncu secim
   player_1_prompt_move:
        db "[X] Lutfen 1 (sol ust) - 9 (sag alt) olmak uzere bir hamle giriniz (cikmak icin: 0): ", 24h
        
   player_2_prompt_move:
        db "[O] Lutfen 1 (sol ust) - 9 (sag alt) olmak uzere bir hamle giriniz (cikmak icin: 0): ", 24h
              
   ; Hatali secim yapilirsa
   player_1_prompt_invalid_move:
        db "[X] Hatali secim!", 24h 
   player_2_prompt_invalid_move:
        db "[O] Hatali secim!", 24h     
   user_prompt_invalid_move:
        db "Hatali secim!", 24h     
                                
                                
   ; Status bari
   status_bar_tur:
        db "Tur: ",24h
        
   status_bar_sira:
        db 9h, "Sira: ",24h ; 9h: tab
        
        
   ; Oyun bitti
   game_over_winner_text:
        db "Oyun bitti! Kazanan: ", 24h
        
   game_over_tie_text:
        db "Oyun bitti! Berabere kaldiniz!", 24h
   
                                     
     

.code       
; proc'lar zaten tanimli. ama eger jmp yapamzsak ret yuzunden sonsuz dongu oluyor.
; ayrica linediv vs. de tanimli. proc zaten label'in ret'i otomatik olan hali gibi.

jmp main 
         
;linediv:    
;    db "----------", 0Dh,0Ah, 24h    
;
;rowdiv:
;    db " | ", 24h 
;    
;newline: 
;    db 0Dh,0Ah, 24h     
;    
;row1:
;    db board[0], " | ",  board[1], " | ", board[2]   

initialize_game proc 
    push bx ; bx'i index icin kullanacagiz.
    ;mov bl, 0
    xor bx, bx
    
    ;mov last_human_move, 10 ; Baslangic degeri (Bos)
    mov is_game_over, 0     ; Oyun daha yeni basladi
    ;mov turn_counter, 0     ; Oyun daha yeni basladi
    mov move_counter, 0
    mov winner, 0           ; 0 -> Beraberlik / Yok (Yok, cunku is_game_over = 0)
    
    mov cx, 9 ; 9 kez yapilacak
    unmark_cell:
    ;mov board[bl], " "
    ;inc bl
    mov board[bx], " "
    inc bx
    loop unmark_cell
    
     
    pop bx 
    ret
    
    
endp initialize_game

clear_screen proc
    ;Kaynak: https://stackoverflow.com/a/70344117
    
    ;Clear screen
    mov ax, 3
    int 10h 
    xor ax, ax 
    ret
endp clear_screen

get_input_char proc
    ; Klavyeden 1 karakter al ve si'a at.
    xor si, si
              
    ; Kaynak: https://github.com/selectiveduplicate/8086-assembly/blob/c7c1e9e2a0841a9ed775cb10380122fb6c8122b6/taking%20input%20and%20displaying.asm#L15C5-L18C44          
    ; NOT: Degistirildi.
    MOV AH, 1               ;single character input
    INT 021H                ;take input
    xor ah, ah
    MOV si, Ax              ;the input from keyboard is stored in AL, move it to si
    
    
    ret
endp get_input_char
 
wait_for_key proc
    push si
    call get_input_char
    xor si, si ; kullanmicaz girdiyi.
    pop si    
    ret
endp wait_for_key

print_char proc
    xor ax, ax
    xor dx, dx
    
    ;pop si ; si (source index) genel register olarak kullaniliyor. Aslinda parametre ve return gibi (proc fn)
    ;mov dl, si
    ;pop dx olmaliydi: pop dl ; dl'ye direkt poplamak daha mantikliydi.
    ;pop dx
    
    xor dh, dh ; bize dl lazim. ne olur ne olmaz sifirlayacagim dh'i.
    mov dx, si
    xor si, si ; si parametre register'i olarak kullanilacak bu programda. 
     
    mov ah, 02h
    int 21h
    
    xor ax, ax
    xor dx, dx    
        
    ret
endp print_char
    
print_newline proc
    xor ax, ax
    xor dx, dx 
    
    ;mov dl, newline
    mov dx, newline
    mov ah, 09h
    int 21h 
    
    xor ax, ax
    xor dx, dx
    
    ret
endp print_newline

; Muhtemelen kullanmam ama dursun.
; Kullanirsam si'a zarar gelir mi? Neyse riske atmayalim. print_char var zaten.
print_str_buffer proc
    xor si, si
    xor ax, ax
    
    ; Once buffer'i bas.
    ; Kullanici buffer'i call'dan onceden ayarlamali. 
    xor dx, dx
    mov dx, str_buffer
    mov ah, 09h
    int 21h
    
    ; Simdi ilk karakteri 24h yaparak yanlislikla call olmasi durumunda
    ; Hicbir sey basmamayi sagla. Kriptografi yapmiyoruz, tum bufferi
    ; silmeye gerek yok.
    mov str_buffer[0], 24h
    xor ax, ax
    xor dx, dx
    xor si, si                                
    
    ret
endp print_buffer

print_exit_app_msg proc
    xor si, si
    xor ax, ax
    xor dx, dx
    
    mov dx, exit_app_msg ; = lea dx, exit_app_msg = mov dx, offset exit_app_msg
    mov ah, 09h
    int 21h
    
    ret
endp

print_invalid_move proc
    xor si, si
    xor ax, ax
    
    xor dx, dx
    mov dx, user_prompt_invalid_move
    mov ah, 09h
    int 21h
    
    ret
endp

print_tutorial_text proc
    xor si, si
    xor ax,ax
    
    xor dx, dx     
    mov dx, move_tutorial_prompt
    mov ah, 09h
    int 21h
                       
    call print_newline 
     
    
    
    xor si, si
    xor ax,ax
    ret
endp print_tutorial_text 

set_gamemode_from_selection_prompt proc
    ; bir sayi girilmediyse si 48'den kucuk olabilir (mesela space: 32)
    ; oyle bir durumda yine cikis sayalim.
    cmp si, 48
    js exit_app_with_msg
    ;hlt
    
    ; bilgi su anda si'da ama once sayi degerini almaliyiz
    sub si, 48
    
    
    
    cmp si, 2 ; 1: pvc 2: pvp 3: cikis (3+: cikis yapmak istedim.)
    
    js pvc_gamemode_set
    je pvp_gamemode_set
    
    ;hlt ; jg yapmak yerine direkt burada sonlandiralim programi.
    jg exit_app_with_msg
    hlt
    
    
    pvc_gamemode_set: 
        mov gamemode, 0
        
        ret
        hlt
    
    pvp_gamemode_set:
        mov gamemode, 1
        
        ret
        hlt
    
    
    
    ret
endp set_gamemode_from_selection_prompt
 
print_gamemode_selection_prompt proc
    xor si, si
    xor ax, ax
                      
                      
    xor dx, dx     
    mov dx, gamemode_selection_prompt0
    mov ah, 09h
    int 21h                   
    call print_newline
                  
    xor dx, dx     
    mov dx, gamemode_selection_prompt1
    mov ah, 09h
    int 21h  
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt2
    mov ah, 09h
    int 21h  
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt3
    mov ah, 09h
    int 21h  
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt4
    mov ah, 09h
    int 21h  
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt5
    mov ah, 09h
    int 21h 
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt6
    mov ah, 09h
    int 21h
    
    call print_newline
    
    xor dx, dx     
    mov dx, gamemode_selection_prompt7
    mov ah, 09h
    int 21h    
                      
    xor si, si
    xor ax, ax
    xor dx, dx
    
    ret
endp print_gamemode_selection_prompt       


print_loading_text proc
    xor si, si
    xor ax,ax
    
    ;call print_newline
    
    xor dx, dx     
    mov dx, loading_text
    mov ah, 09h
    int 21h
                       
    call print_newline 
        
    xor si, si
    xor ax,ax
    ret
endp print_loading_text

print_cpu_thinking_text proc
    xor si, si
    xor ax,ax
    
    call print_newline
    
    xor dx, dx     
    mov dx, cpu_thinking_text
    mov ah, 09h
    int 21h
                       
    call print_newline 
        
    xor si, si
    xor ax,ax
    ret
endp print_cpu_thinking_text
                   
; player_1_prompt_move                   
print_P1_selection_prompt proc
    xor si, si
    xor ax,ax
    
    call print_newline
    
    xor dx, dx     
    mov dx, player_1_prompt_move
    mov ah, 09h
    int 21h
                       
    ;call print_newline 
        
    xor si, si
    xor ax,ax
    ret
endp print_P1_selection_prompt

; player_2_prompt_move
print_P2_selection_prompt proc
    xor si, si
    xor ax,ax
    
    call print_newline
    
    xor dx, dx     
    mov dx, player_2_prompt_move
    mov ah, 09h
    int 21h
                       
    ;call print_newline 
        
    xor si, si
    xor ax,ax
    ret
endp print_P2_selection_prompt

print_valid_moves proc
    ret
endp print_valid_moves

print_X_won proc
    ret
endp print_X_won

print_O_won proc
    ret
endp print_O_won

print_tie proc
    ret
endp print_tie


; Diger proc'lardan once yazdigim icin biraz uzun ve tekrarli oldu. Olsun, calisiyorsa dokunulmaz.            
print_board proc 

    ;mov     dx, linediv  ; load offset of msg into dx.
    ;mov     ah, 09h  ; print function is 9.
    ;int     21h      ; do it!        
    xor ax, ax
    
    ; Cell 1 
    xor dx, dx
    mov dl, board[0]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 2  
    xor dx, dx
    mov dl, board[1]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 3 
    xor dx, dx
    mov dl, board[2]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
             
    xor dx, dx
    mov dx, linediv
    mov ah, 09h
    int 21h      
    
    
    
    ; 
    ; Cell 4 
    xor dx, dx
    mov dl, board[3]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 5  
    xor dx, dx
    mov dl, board[4]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 6 
    xor dx, dx
    mov dl, board[5]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
             
    xor dx, dx
    mov dx, linediv
    mov ah, 09h
    int 21h
    ;       
    
    
    ;
    ; Cell 7 
    xor dx, dx
    mov dl, board[6]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 8  
    xor dx, dx
    mov dl, board[7]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 9 
    xor dx, dx
    mov dl, board[8]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
    ;
     
     
    ;mov     ah, 0 
    ;int     16h      ; Herhangi bir tusa basilmasini bekle  
    
    xor ax, ax
    xor dx, dx              
                  
                  
    ret ; Cagirilan yere geri don
endp print_board   
 
; Diger proc'lardan once yazdigim icin biraz uzun ve tekrarli oldu. Olsun, calisiyorsa dokunulmaz.
; Tek amaci var: 1-9 hamlelerin yerini gostermek.            
print_demo_board proc 

    ;mov     dx, linediv  ; load offset of msg into dx.
    ;mov     ah, 09h  ; print function is 9.
    ;int     21h      ; do it!        
    xor ax, ax
    
    ; Cell 1 
    xor dx, dx
    mov dl, demo_board[0]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 2  
    xor dx, dx
    mov dl, demo_board[1]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 3 
    xor dx, dx
    mov dl, demo_board[2]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
             
    xor dx, dx
    mov dx, linediv
    mov ah, 09h
    int 21h      
    
    
    
    ; 
    ; Cell 4 
    xor dx, dx
    mov dl, demo_board[3]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 5  
    xor dx, dx
    mov dl, demo_board[4]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 6 
    xor dx, dx
    mov dl, demo_board[5]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
             
    xor dx, dx
    mov dx, linediv
    mov ah, 09h
    int 21h
    ;       
    
    
    ;
    ; Cell 7 
    xor dx, dx
    mov dl, demo_board[6]
    mov ah, 02h
    int 21h
         
    xor dx, dx     
    mov dx, rowdiv
    mov ah, 09h
    int 21h 
    
    ; Cell 8  
    xor dx, dx
    mov dl, demo_board[7]
    mov ah, 02h
    int 21h
           
    xor dx, dx       
    mov dx, rowdiv
    mov ah, 09h
    int 21h
    
    ; Cell 9 
    xor dx, dx
    mov dl, demo_board[8]
    mov ah, 02h
    int 21h
        
    ; Newline    
    xor dx, dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h 
    xor dx, dx
    mov dl, 0Ah
    int 21h
    ;
    
    ;mov     ah, 0 
    ;int     16h      ; Herhangi bir tusa basilmasini bekle  
    
    xor ax, ax
    xor dx, dx              
                  
                  
    ret ; Cagirilan yere geri don
endp print_demo_board   


;get_valid_moves proc
;    
;ret
;endp  

check_game_over proc
    push cx ; game_loop bozulmasin diye
    push bx ; bx'i belki kullanan bir instruction vardir.
    
    mov cx, 9 ; 9 hucrenin kontrol edilmesi gerekicek beraberlik icin. Loop'ta.
    mov bx, 0 ; Bunu da o loop'ta kullanicaz.
    
    ; Once kazanan var mi diye bakalim.
    ; Bu kontrolu yaparken once X'e bakacaz.
    ; X kazanmadiysa ardindan O'ya bakicaz.
    
    
    ; X kazandi mi?
    ; =================
    ; Yatay: 3 ihtimal
    X_hor1:
        cmp board[0], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_hor2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[1], "X"
        jnz X_hor2
        
        cmp board[2], "X"
        jnz X_hor2
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
        
        
        
    
    X_hor2:
        cmp board[3], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_hor3 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "X"
        jnz X_hor3
        
        cmp board[5], "X"
        jnz X_hor3
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    X_hor3:
        cmp board[6], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_ver1 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[7], "X"
        jnz X_ver1
        
        cmp board[8], "X"
        jnz X_ver1
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over 
     
    hlt
    ; Dikey: 3 ihtimal
    X_ver1:
        cmp board[0], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_ver2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[3], "X"
        jnz X_ver2
        
        cmp board[6], "X"
        jnz X_ver2
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    X_ver2:
        cmp board[1], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_ver3 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "X"
        jnz X_ver3
        
        cmp board[7], "X"
        jnz X_ver3
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    X_ver3:
        cmp board[2], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_diag1 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[5], "X"
        jnz X_diag1
        
        cmp board[8], "X"
        jnz X_diag1
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    
    hlt
    ; Capraz: 2 ihtimal
    X_diag1:
        cmp board[0], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz X_diag2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "X"
        jnz X_diag2
        
        cmp board[8], "X"
        jnz X_diag2
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    X_diag2:
        cmp board[2], "X" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_hor1 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "X"
        jnz O_hor1
        
        cmp board[6], "X"
        jnz O_hor1
        
        mov winner, 1 ; X kazanmis.
        jmp set_game_over
    
    hlt
    
    ; O kazandi mi?
    ; =================
    ; Yatay: 3 ihtimal
    O_hor1:
        cmp board[0], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_hor2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[1], "O"
        jnz O_hor2
        
        cmp board[2], "O"
        jnz O_hor2
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
        
        
        
    
    O_hor2:
        cmp board[3], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_hor3 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "O"
        jnz O_hor3
        
        cmp board[5], "O"
        jnz O_hor3
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    O_hor3:
        cmp board[6], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_ver1 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[7], "O"
        jnz O_ver1
        
        cmp board[8], "O"
        jnz O_ver1
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over 
     
    hlt
    ; Dikey: 3 ihtimal
    O_ver1:
        cmp board[0], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_ver2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[3], "O"
        jnz O_ver2
        
        cmp board[6], "O"
        jnz O_ver2
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    O_ver2:
        cmp board[1], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_ver3 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "O"
        jnz O_ver3
        
        cmp board[7], "O"
        jnz O_ver3
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    O_ver3:
        cmp board[2], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_diag1 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[5], "O"
        jnz O_diag1
        
        cmp board[8], "O"
        jnz O_diag1
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    
    hlt
    ; Capraz: 2 ihtimal
    O_diag1:
        cmp board[0], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz O_diag2 ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "O"
        jnz O_diag2
        
        cmp board[8], "O"
        jnz O_diag2
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    O_diag2:
        cmp board[2], "O" ; ZF=1 ise esittir. Yoksa degildir.
        jnz no_winners ; ZF=0 yani bir 2. yatay ihtimalini dene.
        
        cmp board[4], "O"
        jnz no_winners
        
        cmp board[6], "O"
        jnz no_winners
        
        mov winner, 2 ; O kazanmis.
        jmp set_game_over
    
    hlt
    
    
    no_winners:
 
    ; Demek ki kazanan yok.
    mov winner, 0 ; Berabere / Oyun devam ediyor
    
    ; Bakalim oyun devam ediyor mu:
    
    check_cells:
        inc bx
        
        cmp board[bx], " "
        
        jz game_is_not_over ; Beraberlik yok.
        
         
        
    loop check_cells
    
    ; Donguden ciktik ama jz olmamis. Demek ki oyun bitti. Beraberlik var yani.
    jmp set_game_over 
    
    game_is_not_over:
        mov is_game_over, 0
        pop bx ; bx, stack lifo old. ustte poplandi.
        pop cx
        ret
    
    
    set_game_over: 
        mov is_game_over, 1
        pop bx ; bx, stack lifo old. ustte poplandi.
        pop cx
        ret
   
        
    
       

endp check_game_over

print_press_any_key_to_return_to_main_menu proc
    xor si, si
    xor dx, dx
    xor ax, ax
    
    mov dx, press_any_key_to_return_to_main_menu
    mov ah, 09h
    int 21h
    
    ret
endp press_any_key_to_return_to_main_menu

print_winner proc
    ; Eski fikir:
    ; "Kazanan: "
    ; Kaznanin harfi veya "Yok."
    
    ; Yeni fikir:
    ; Bu proc sadece oyun bittiginde cagrilir.
    ; Sadece kazanan var mi diye baksak yeter. Oyun bitti mi diye bakmaya gerek yok.
    xor si, si
    xor dx, dx
    xor ax, ax
    
    
    cmp winner, 1 ; X kazandiysa 1'dir. O kazandiysa 2'dir. Berabere ise 0'dir (bu sefer kesin)
    js print_winner_proc_TIE
    je print_winner_proc_X
    jg print_winner_proc_O
    
    hlt
   
    
    print_winner_proc_TIE:
        mov dx, game_over_tie_text
        mov ah, 09h
        int 21h
        ret
        hlt
    
    print_winner_proc_X:
        mov dx, game_over_winner_text
        mov ah, 09h
        int 21h
        
        mov si, "X"
        call print_char
        ret
        hlt
        
    print_winner_proc_O:
        mov dx, game_over_winner_text
        mov ah, 09h
        int 21h
        
        mov si, "O"
        call print_char
        ret
        hlt
        
    ;xor si, si
    ;xor dx, dx
    ;xor ax, ax 
    
    
            
    ret
endp
                      
print_game_status proc
    xor si, si
    xor ax,ax
    
    xor dx, dx     
    mov dx, status_bar_tur
    mov ah, 09h
    int 21h
    
    ; Tur sayisini girer.                   
    mov si, word ptr move_counter
    add si, 48 ; 48 eklemezsek sayilari degil de mutlu yuzleri basiyor.
    call print_char 
     
    xor dx, dx     
    mov dx, status_bar_sira
    mov ah, 09h
    int 21h
    
    ; Sira kimdeyse onu gosterir
    test move_counter, 1 ; ZF=0 ise X
    jnz status_X_sirasi
    jz status_O_sirasi
    hlt
    
    status_X_sirasi:
        mov si, "X"
        jmp status_ending 
        hlt
    status_O_sirasi:
        mov si, "O" 
        ;jmp status_ending
        
    status_ending:
    
    call print_char
    
    xor dx, dx
    xor si, si
    xor ax,ax
    
    ret
endp

                      
; Etiketler karismasin diye comment.                      
;print_game_status_SLOW proc
;    ; Tur: 1 [TAB] Sira: [X ya da O]
;    mov si, "T"
;    call print_char
;    
;    mov si, "u"
;    call print_char
;    
;    mov si, "r"
;    call print_char
;    
;    mov si, ":"
;    call print_char
;    
;    mov si, " "
;    call print_char
;    
;    mov si, word ptr move_counter
;    add si, 48 ; 48 eklemezsek sayilari degil de mutlu yuzleri basiyor.
;    call print_char
;    
;    mov si, " "
;    call print_char
;    
;    mov si, 9 ; TAB
;    call print_char
;    
;    mov si, " "
;    call print_char
;    
;    mov si, "S"
;    call print_char
;    
;    mov si, "i"
;    call print_char
;    
;    mov si, "r"
;    call print_char
;    
;    mov si, "a"
;    call print_char
;    
;    mov si, ":"
;    call print_char
;    
;    mov si, " "
;    call print_char
;    
;    test move_counter, 1 ; ZF=0 ise X
;    jnz status_X_sirasi
;    jz status_O_sirasi
;    hlt
;    
;    status_X_sirasi:
;        mov si, "X"
;        jmp status_ending 
;        hlt
;    status_O_sirasi:
;        mov si, "O" 
;        ;jmp status_ending
;        
;    status_ending:
;    
;    call print_char
;        
;    ret
;endp print_game_status

get_move proc ; FROM PLAYER.
    ;begin_GET_MOVE:
    xor si, si
    
    call get_input_char
    ; get_move
    call print_newline
    call print_newline
        
    call is_move_valid ; ayni zamanda si 0 ise cikmayi saglar.
    jnz invalid_move
    jmp end_GET_MOVE
    
    invalid_move:
        call print_invalid_move ; Hatali hamle yaptiniz.
        call print_newline
        
        ; Simdi basa donelim. Oyun modu kontrolu yeterli olur.
        test gamemode, 1 ; ZF=1 ise 1p. ZF=0 ise 2p.
        jz tek_kisilik
        jnz iki_kisilik
        hlt
        ; evet. bunu yapinca stack'te bosu bosuna alan kullandik (ret)
        ; bunu engellemek icin pop yapabilirim (2 defa mi 1 defa mi?)
        ; ama 10 tur surucek zaten. bos ver kalsin.
        ; ============================================================
        
        ; P1 mi P2 mi icin:
        ; ne yazik ki en bastan oyun modu kontrolu yapmaliyiz once.
        ;test game_mode, 1; 
        
        ;invalid_move_P1:call print_P1_selection_prompt
        ;invalid_move_P2:call print_P2_selection_prompt
        
        
        
        ;jmp begin_GET_MOVE
        
        
    end_GET_MOVE:
        call place_move
        ret
                   
proc get_random_move_index
    ;mov ah, 2ah
    mov ah, 2ch
    int 21h
    
    ;push cx
    push dx
    
    ;INT 21h / AH=2Ch - get system time;
    ;return: CH = hour. CL = minute. DH = second. DL = 1/100 seconds.
    
    ; Simdi aritmatik islemler ile pseudorandom 0-8 (dahil) sayi uretelim
    mov al, dl
    mov ah, 0
    mov bl, 9     ; 0-8 arasi istiyorsak 9'a boleriz. Kalani aliriz en son.
    div bl        ; AL = AL / BL ve AH = kalan
    ;mov al, ah    ; AH (mod sonucu) artik 0-8 arasi.
    
    mov al, ah
    xor ah, ah
    
    ;mov si, ah ; Si bizim hamlemizi tutacak.
    mov si, ax
        
    pop dx
    ;pop cx
    
    ; place_move ile uyumlu olsun diye. si-1 artik duzgun calisacak.
    ; bu yuzden cpu_make_move_random'u da degistirdim (si-1 yaptim)
    inc si
    
    
    ret
endp get_random_move_index

cpu_make_move_random proc
    cpu_random_begin:
    xor si, si
    call get_random_move_index
    
    cmp board[si-1], " "
    jne cpu_random_begin
    
    call place_move ; Her zaman "O" olmali ama kontrol etmem bozuk degilse.
    
    ret
endp


place_move proc
    ; si-1'e su anki sira kiminse onu yerlestirir.
    test move_counter, 1 ; ZF=0 ise sira X'te.
    jnz sira_X
    jz sira_O
    hlt
     
    sira_X:
        mov board[si-1], "X"
        ret
        hlt
    
    sira_O:
        mov board[si-1], "O"
        ret
        hlt
    
    
    
    hlt
endp place_move


; Sadece insanlarda kullanilir.
is_move_valid proc
    ; si ile verilen hamle dogru mu degil mi kontrol eder.
    ; si = 1 - 9 iken calisicak. 0 ise oyundan cikariz.
    
    ; si 0 icin 48 degerini alir.
    ; bu yuzden si'dan 48 cikarmaliyiz.
    ; si 48'den kucuk ise zaten hatali bir deger girildigini anlayabiliriz.
    ; OF=1 ise oyledir.
    sub si, 48
    ;gerci underflow deil bu... jo invalid_move ; Bunu yaptigim icin stack'te adres birikiyor. Farkindayim.
    ; -127'ye kadar yolu var OF=1 olmasi icin de...
    cmp si, 0
    js invalid_move ; Bunu yaptigim icin stack'te adres birikiyor. Farkindayim.
    
    cmp si, 0 ; si 0 ise zf = 1 yani oyundan cik.
    jz exit_game ; Bunu yaptigim icin stack'te adres birikiyor. Farkindayim.
    
    ; si > 9 olmamali.9 olursa sorun yok.
    cmp si, 9 
    jg invalid_move ; Bunu yaptigim icin stack'te adres birikiyor. Farkindayim.
    
    cmp board[si-1], " " ; Uygunsa ZF=1. Degisle 0.
    jnz invalid_move ; Bunu yaptigim icin stack'te adres birikiyor. Farkindayim.
    
    ret
endp is_move_valid
      
main: 






; hlt   
; Asagisi sadece test kodlari. En son hlt'yi uncommentlemeyi unutmamak lazim tabi...     
      
;test2:
; Oyun modunu kullanicidan al
call print_gamemode_selection_prompt     
call get_input_char ; si'a kaydedildi ama bunu islememiz lazim yoksa sonraki call'lar si'i degistirebilir.
call set_gamemode_from_selection_prompt
call clear_screen    

;call print_newline
;call print_char ; zaten si'da.


; Tek seferligine kullaniciya hamle yerlerini goster
call print_tutorial_text 
call print_newline
call print_demo_board 
call wait_for_key   
call clear_screen   

; Oyuna basla       
call print_loading_text ; call loading_text yaparsan cok kotu seyler oluyor.
call initialize_game                        
call clear_screen

;mov cx, 0FFFFh ; Gecici olarak FF dedim. Sonsuz dongu gibi. Yine de 9!'den kucuk tabi.
mov cx, 9 ; 9 hamle var en fazla.

game_loop:
call clear_screen
inc move_counter

call print_game_status;_top_bar
call print_newline
call print_newline
call print_board  
call print_newline
call print_newline
 

; Simdi oyun moduna ve siraya gore ya girdi almaliyiz ya da CPU hamle yapmali.

; Once oyun modu kontrolu
test gamemode, 1 ; test -> and ama sadece flag ayarlar. 0 & 1 = 0 ama 1 & 1 = 1. zf = 1 ise tek kisilik yani.
;cmp gamemode, 0 ; test -> and ama sadece flag ayarlar. 0 & 0 = 0 ama 1 & 0 = 1. zf = 1 ise tek kisilik yani.
jz tek_kisilik 
jmp iki_kisilik ; jz calismazsa iki kisilik deriz.
hlt

; loop'a geri don (proc gibia aslinda ama kosullularda call diyemedigim icin label kullandim)
back_to_game_loop:

; Kazanan var mi? Oyun bitti mi?
call check_game_over ; is_game_over = 1 yaparsa oyun biter.
test is_game_over, 1 ; 1 ve 1 = 1 yani ZF=0
jnz game_over 
 
loop game_loop                      

 
hlt ;2p'de ise yaradi :D - 20.4.2025 14:57

  
tek_kisilik:
    ; Tamam. Tek kisilik. Sadece X'ten girdi bekliyoruz yani.
    
    ; Simdi sira kontrolu yapalim. Yine test kullanarak yapabiliriz bu islemi.
    ; Cunku sira & 1 = sira'nin ilk biti (1 ise sira x'te. 0 ise sira o'da)
    test move_counter, 1 ; zf=0 ise sira x'te. degilse ise sira o'da.
    ;test move_counter, 0
    ;cmp move_counter,
     
    jnz insan_sirasi
    jz cpu_sirasi 
    hlt
    
    insan_sirasi:
        call print_P1_selection_prompt
        xor si, si
        ;call get_input_char
        ; Simdi kontrol etmeliyiz. Bir hata varsa hamle uygun degil demek icin.
        ; Kontrolu get_move icinde halletmeye karar verdim. Burada yapacak bir sey kalmadi. 
        call get_move
        ;call print_newline
        jmp back_to_game_loop
        hlt
    
    cpu_sirasi:
        call print_cpu_thinking_text
        call print_newline
        
        call cpu_make_move_random
         
        jmp back_to_game_loop
        hlt
    
    
    ; Guvenlik amacli.
    ;jmp back_to_game_loop
    hlt ; Bir sorun olursa program durur. Debug kolaylassin diye koydum.
    
iki_kisilik:
    test move_counter, 1
    
    jnz birinci_oyuncu_sirasi
    jz ikinci_oyuncu_sirasi
    hlt
    
    birinci_oyuncu_sirasi:
        call print_P1_selection_prompt
        
        xor si, si
        call get_move

        jmp back_to_game_loop
        hlt
        
    ikinci_oyuncu_sirasi:
        call print_P2_selection_prompt
        
        xor si, si
        call get_move
        
        jmp back_to_game_loop
        hlt     
   
        
    
    ;jmp back_to_game_loop
    hlt      
       
game_over:
    call clear_screen
    ;call print_newline
    call print_game_status
    call print_newline
    call print_newline
    call print_board
    call print_newline
    call print_winner
    call print_newline
    call print_press_any_key_to_return_to_main_menu
    call wait_for_key 
    call clear_screen
    ;jmp exit_game
    ;hlt       
       
       
;oyundan_cik:
exit_game:
    jmp main
    hlt      
        
exit_app_with_msg:
    call clear_screen
    call print_exit_app_msg
    hlt        
        
exit_app:
    hlt      
      
      
      
      
      
      
      
      
      
      
     
test1:     
call print_board
 
 
;push byte ptr "H"
mov si, "H"
call print_char

mov si, "e"
;push si
call print_char

mov si, "y"
;push si       
call print_char 

call print_newline

mov si, "!"
call print_char   
        
hlt
