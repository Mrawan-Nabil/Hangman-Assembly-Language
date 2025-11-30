.MODEL SMALL
.STACK 200h

.DATA
; ==================== MEMORY CONFIGURATION ====================
WORD_BUF_SIZE  EQU 8000     ; Maximum word file buffer size
MAX_WORDS      EQU 100      ; Maximum words that can be loaded
MAX_WORD_LEN   EQU 30       ; Maximum length of any word

; ==================== GAME STATE VARIABLES ====================
file_handle     DW 0        ; Handle for wordlist file
file_len        DW 0        ; Size of loaded word file
word_buf        DB WORD_BUF_SIZE DUP(0)  ; Buffer for word file content

; Word database pointers
word_ptrs       DW MAX_WORDS DUP(0)      ; Pointers to each word
hint_ptrs       DW MAX_WORDS DUP(0)      ; Pointers to each hint
word_count      DW 0                     ; Number of words loaded

; Current game word tracking
cur_word_off    DW 0        ; Offset of current word in buffer
cur_hint_off    DW 0        ; Offset of current hint in buffer  
cur_word_len    DW 0        ; Length of current word

; Game display and state
mask_buf        DB MAX_WORD_LEN+3 DUP(0) ; Display buffer with _ for hidden letters
lives           DB 6                     ; Player's remaining lives
used_hint       DB 0                     ; Hint usage flag (0=available, 1=used)
guessed_table   DB 26 DUP(0)             ; Track which letters have been guessed A-Z

; System variables
rand_seed       DW 0        ; Seed for random number generator
input_char      DB 0        ; Stores player's current input

; Game progression variables
score           DW 0                     ; Player's current score
difficulty      DB 0                     ; 1=Easy, 2=Medium, 3=Hard
max_lives_array DB 8, 6, 4              ; Lives per difficulty level
reveal_animation DB 0                   ; Animation state flag

; ==================== USER INTERFACE MESSAGES ====================
; --- WELCOME MESSAGE ---
msg_welcome DB 0Dh, 0Ah
    DB "         __   __  _______  __    _  _______  __   __  _______  __    _       ", 0Dh, 0Ah
    DB "        |  | |  ||   _   ||  |  | ||       ||  | |  ||   _   ||  |  | |      ", 0Dh, 0Ah
    DB "        |  |_|  ||  |_|  ||   |_| ||    ___||  |_|  ||  |_|  ||   |_| |      ", 0Dh, 0Ah
    DB "        |       ||       ||       ||   | __ |       ||       ||       |      ", 0Dh, 0Ah
    DB "        |       ||       ||  _    ||   ||  ||       ||       ||  _    |      ", 0Dh, 0Ah
    DB "        |   _   ||   _   || | |   ||   |_| || ||_|| ||   _   || | |   |      ", 0Dh, 0Ah
    DB "        |__| |__||__| |__||_|  |__||_______||_|   |_||__| |__||_|  |__|      ", 0Dh, 0Ah
    DB 0Dh, 0Ah
    DB "        Copyright (C) 2025  Mrawan Nabil                        ", 0Dh, 0Ah
    DB "                            Malak Elgizawy                       ", 0Dh, 0Ah
    DB "                            Nour Eladrosy                        ", 0Dh, 0Ah
    DB "$"

msg_error_file  DB 'Error: Could not read wordlist.txt', 0Dh, 0Ah, '$'
msg_prompt      DB 0Dh, 0Ah, 'Guess (A-Z) or ? for Hint: $'

; --- UPDATED WIN MESSAGE ---
msg_win         DB 0Dh, 0Ah
                DB "                               +------+       ", 0Dh, 0Ah
                DB "                               |      |       ", 0Dh, 0Ah
                DB "                               |              ", 0Dh, 0Ah
                DB "                               |      O       ", 0Dh, 0Ah
                DB "                               |     /|\      ", 0Dh, 0Ah
                DB "                               |     / \      ", 0Dh, 0Ah
                DB "                               +------------+ ", 0Dh, 0Ah
                DB "                               | YOU   WIN  | ", 0Dh, 0Ah
                DB "                               +------------+ ", 0Dh, 0Ah
                DB 0Dh, 0Ah, '                           CONGRATULATIONS! YOU WON!', 0Dh, 0Ah, '$'

; --- UPDATED LOSE MESSAGE ---
msg_lose        DB 0Dh, 0Ah
                DB "                               +------+       ", 0Dh, 0Ah
                DB "                               |      |       ", 0Dh, 0Ah
                DB "                               |      O       ", 0Dh, 0Ah
                DB "                               |     /|\      ", 0Dh, 0Ah
                DB "                               |     / \      ", 0Dh, 0Ah
                DB "                               |              ", 0Dh, 0Ah
                DB "                               +------------+ ", 0Dh, 0Ah
                DB "                               |  YOU  DIE  | ", 0Dh, 0Ah
                DB "                               +------------+ ", 0Dh, 0Ah
                DB 0Dh, 0Ah, '                        GAME OVER. The word was: $'

msg_hint_lbl    DB 0Dh, 0Ah, 'HINT: $'
msg_again       DB 0Dh, 0Ah, 'Play Again? (Y/N): $'
msg_lives       DB 0Dh, 0Ah, 'Lives remaining: $'
msg_guessed     DB 0Dh, 0Ah, 'Guessed letters: $'

; Tutorial system messages
msg_tutorial1   DB 0Dh, 0Ah, '                             === HOW TO PLAY ===', 0Dh, 0Ah, '$'
msg_tutorial2   DB '            1. Guess letters (A-Z) to reveal the hidden word', 0Dh, 0Ah, '$'
msg_tutorial3   DB '            2. Each wrong guess adds a part to the hangman', 0Dh, 0Ah, '$'
msg_tutorial4   DB '            3. Use "?" for a hint (one-time use)', 0Dh, 0Ah, '$'
msg_tutorial5   DB '            4. Win by guessing all letters before hangman is executed *_*', 0Dh, 0Ah, '$'
msg_tutorial6   DB '            5. Lose if hangman is completed (reveal all lives remaining)', 0Dh, 0Ah, '$'
msg_continue    DB 0Dh, 0Ah, 'Press any key to continue...$'

; Score and difficulty display
msg_score       DB ' Score: $'
msg_difficulty  DB '             Select Difficulty (1 = Easy, 2 = Medium, 3 = Hard): $'
msg_difficulty_display DB ' Difficulty: $'

; Utility strings
newline         DB 0Dh, 0Ah, '$'
space_char      DB ' $'
filename        DB 'wordlist.txt', 0

; ==================== HANGMAN ASCII ART ====================
art_ptr_table   DW art_6, art_5, art_4, art_3, art_2, art_1, art_0

; 6 Lives (Start)
art_6   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 5 Lives
art_5   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah 
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 4 Lives
art_4   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 3 Lives
art_3   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |     /|       ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 2 Lives
art_2   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |     /|\      ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 1 Life
art_1   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |     /|\      ", 0Dh, 0Ah
        DB           "                                 |     /        ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

; 0 Lives (Loss)
art_0   DB 0Dh, 0Ah, "                                 +------+       ", 0Dh, 0Ah
        DB           "                                 |      |       ", 0Dh, 0Ah
        DB           "                                 |      O       ", 0Dh, 0Ah
        DB           "                                 |     /|\      ", 0Dh, 0Ah
        DB           "                                 |     / \      ", 0Dh, 0Ah
        DB           "                                 |              ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah
        DB           "                                 |   Gallows  | ", 0Dh, 0Ah
        DB           "                                 +------------+ ", 0Dh, 0Ah, '$'

.CODE
; =============================================================
; PROGRAM INITIALIZATION AND MAIN GAME LOOP
; =============================================================
start:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; System initialization sequence
    call initialize_buffers    ; Clear all game buffers
    call init_rng             ; Seed random number generator  
    call read_file            ; Load wordlist.txt into memory
    cmp ax, 0                 ; Check if file read succeeded
    je file_ok                ; Continue if file loaded successfully
    jmp file_error_exit       ; Handle file error otherwise

file_ok:
    ; Parse loaded word file and build word database
    call parse_buffer
    
    ; User onboarding sequence
    call show_tutorial        ; Display game instructions
    call select_difficulty    ; Let player choose difficulty level

; ==================== MAIN GAME CONTROL FLOW ====================
new_game:
    call reset_game          ; Reset game state for new round
    call pick_word           ; Randomly select a word from database

game_loop:
    ; Main game rendering and input handling
    call draw_screen         ; Display current game state
    mov dx, OFFSET msg_prompt
    call print_str           ; Show input prompt
    call get_char_no_echo    ; Get player input without echo
    mov input_char, al       ; Store input for processing

    ; Input filtering and routing
    cmp al, 27              ; Check for ESC key (exit)
    je exit_app_esc         
    cmp al, '?'             ; Check for hint request
    je handle_hint_temp     

    ; Input normalization: convert lowercase to uppercase
    cmp al, 'a'
    jb check_upper_range
    cmp al, 'z'
    ja check_upper_range
    sub al, 20h             ; Convert to uppercase
    mov input_char, al

check_upper_range:
    ; Validate input is A-Z
    cmp al, 'A'
    jb game_loop            ; Invalid - get new input
    cmp al, 'Z'
    ja game_loop            ; Invalid - get new input

    ; Check if letter was already guessed
    mov bl, al
    sub bl, 'A'             ; Convert to 0-25 index
    mov bh, 0
    mov si, OFFSET guessed_table
    add si, bx              ; Point to guessed letter flag
    mov al, [si]
    cmp al, 1
    je game_loop            ; Already guessed - get new input

    jmp continue_game       ; Valid new guess - process it

; ==================== INPUT HANDLING BRANCHES ====================
exit_app_esc:               ; ESC key handler
    jmp exit_app

handle_hint_temp:           ; Hint request handler  
    jmp handle_hint

continue_game:
    ; Process valid new letter guess
    mov BYTE PTR [si], 1    ; Mark letter as guessed
    call process_guess      ; Check if letter is in word
    
    ; Check game state after guess
    call check_win
    cmp al, 1
    jne check_lose          ; Not won yet - check for loss

    ; Player won - show celebration
    call animate_word_reveal ; Flash animation for win
    jmp do_win

check_lose:
    ; Check if player has run out of lives
    cmp lives, 0
    jne game_loop           ; Still alive - continue game
    jmp do_lose             ; No lives left - game over

; ==================== FILE ERROR HANDLING ====================
file_error_exit:
    call clear_screen
    mov dx, OFFSET msg_error_file
    call print_str
    mov dx, OFFSET msg_again  
    call print_str
    call get_char_no_echo
    cmp al, 'y'
    je try_restart
    cmp al, 'Y'
    je try_restart
    jmp exit_app

try_restart:
    jmp start

; ==================== TUTORIAL SYSTEM ====================
show_tutorial:
    ; Display comprehensive game instructions
    call clear_screen
    mov dx, OFFSET msg_welcome
    call print_str
    
    ; Display all tutorial messages sequentially
    mov dx, OFFSET msg_tutorial1
    call print_str
    mov dx, OFFSET msg_tutorial2
    call print_str
    mov dx, OFFSET msg_tutorial3
    call print_str
    mov dx, OFFSET msg_tutorial4
    call print_str
    mov dx, OFFSET msg_tutorial5
    call print_str
    mov dx, OFFSET msg_tutorial6
    call print_str
    
    mov dx, OFFSET msg_continue
    call print_str
    call wait_for_key       ; Wait for player acknowledgement
    call clear_screen
    ret

; ==================== DIFFICULTY SYSTEM ====================
select_difficulty:
    ; Let player choose game difficulty
    call clear_screen
    mov dx, OFFSET msg_welcome
    call print_str
    call print_newline
    mov dx, OFFSET msg_difficulty
    call print_str
    
    ; Get and validate difficulty choice
    call get_char_no_echo
    cmp al, '1'
    je set_easy
    cmp al, '2'  
    je set_medium
    cmp al, '3'
    je set_hard
    jmp select_difficulty   ; Invalid input - try again

set_easy:
    mov difficulty, 1
    mov al, max_lives_array[0]  ; 8 lives for easy
    mov lives, al
    ret
    
set_medium:
    mov difficulty, 2
    mov al, max_lives_array[1]  ; 6 lives for medium
    mov lives, al
    ret
    
set_hard:
    mov difficulty, 3
    mov al, max_lives_array[2]  ; 4 lives for hard
    mov lives, al
    ret

; ==================== SCORING SYSTEM ====================
update_score:
    ; Award points for correct guesses: 100 * difficulty
    push ax
    push bx
    
    mov ax, 100            ; Base points per correct guess
    mov bl, difficulty     ; Multiply by difficulty (1,2,3)
    mov bh, 0
    mul bx
    add score, ax          ; Add to total score
    
    pop bx
    pop ax
    ret

; ==================== VICTORY ANIMATION SYSTEM ====================
animate_word_reveal:
    ; Flash animation when player wins the game
    push cx
    push si
    push di
    push bx
    mov reveal_animation, 1  ; Set animation flag
    
    ; Flash word 3 times with different characters
    mov cx, 3
flash_loop:
    push cx
    
    ; Stage 1: Flash with asterisks
    mov cx, cur_word_len
    mov si, OFFSET mask_buf
    mov di, si
flash_asterisks:
    mov BYTE PTR [di], '*'   ; Fill with asterisks
    inc di
    loop flash_asterisks
    call draw_screen_mini    ; Update display
    call short_delay         ; Pause for effect
    
    ; Stage 2: Flash with actual word
    mov cx, cur_word_len
    mov si, cur_word_off
    mov di, OFFSET mask_buf
    rep movsb               ; Copy actual word to display
    call draw_screen_mini    ; Update display  
    call short_delay         ; Pause for effect
    
    pop cx
    loop flash_loop         ; Repeat flash sequence
    
    ; Final display of complete word
    mov cx, cur_word_len
    mov si, cur_word_off
    mov di, OFFSET mask_buf
    rep movsb
    call draw_screen_mini
    
    mov reveal_animation, 0  ; Clear animation flag
    pop bx
    pop di
    pop si
    pop cx
    ret

; ==================== GAME MECHANICS HANDLERS ====================
handle_hint:
    ; Process player hint request
    cmp used_hint, 1
    jne give_hint
    jmp game_loop           ; Hint already used - ignore

give_hint:
    call reveal_random      ; Reveal random hidden letter
    mov used_hint, 1        ; Mark hint as used
    jmp game_loop

process_guess:
    ; Check if guessed letter exists in current word
    push ax
    push bx
    push cx
    push si
    push di
    
    mov al, input_char      ; Get guessed letter
    mov si, cur_word_off    ; Point to current word
    mov di, OFFSET mask_buf ; Point to display buffer
    mov cx, cur_word_len    ; Word length as loop counter
    mov bx, 0               ; Match found flag

scan_word_loop:
    ; Search for letter in word
    cmp BYTE PTR [si], al
    jne next_char
    mov [di], al            ; Reveal letter in display
    mov bx, 1               ; Set match found flag
next_char:
    inc si
    inc di
    loop scan_word_loop

    ; Handle guess result
    cmp bx, 0
    jne guess_correct
    
    ; Wrong guess - penalize player
    dec lives
    jmp guess_done
    
guess_correct:
    ; Correct guess - reward player
    call update_score
guess_done:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; ==================== GAME OUTCOME HANDLERS ====================
do_win:
    ; Handle player victory
    call draw_screen
    mov dx, OFFSET msg_win
    call print_str
    jmp ask_again

do_lose:
    ; Handle player defeat
    mov score, 0            ; Reset score on loss
    call draw_screen
    mov dx, OFFSET msg_lose
    call print_str
    ; Reveal the word player failed to guess
    mov si, cur_word_off
    call print_si_string_safe
    call print_newline
    jmp ask_again

ask_again:
    ; Prompt for replay
    mov dx, OFFSET msg_again
    call print_str
    call get_char_no_echo
    cmp al, 'y'
    je restart_game
    cmp al, 'Y'
    je restart_game
    jmp exit_app
    
restart_game:
    jmp new_game

; ==================== DISPLAY AND RENDERING SYSTEM ====================
draw_screen:
    ; Render complete game interface
    call clear_screen
    
    ; Display score and difficulty information
    call print_newline
    mov dx, OFFSET msg_score
    call print_str
    mov ax, score
    call print_number
    
    mov dx, OFFSET msg_difficulty_display
    call print_str
    mov al, difficulty
    call print_small_number
    
    call print_newline
    
    
    ; ... (????? ?????? ????? ???????? ???????? ??? ??) ...
    
    call print_newline
    
    ; --- FIX START: Logic to handle lives > 6 ---
    xor bx, bx
    mov al, lives       ; Load current lives
    cmp al, 6           
    jbe use_actual_lives ; If lives <= 6, proceed normally
    mov al, 6           ; If lives > 6 (e.g., 8), treat it as 6 for drawing (Empty Gallows)

use_actual_lives:
    mov bl, 6
    sub bl, al          ; Calculate index: 6 - lives
    shl bx, 1           ; Multiply by 2 for WORD offset
    mov si, OFFSET art_ptr_table
    add si, bx
    mov dx, [si]        ; Get pointer to correct hangman art
    call print_str
    ; --- FIX END ---

    ; ... (???? ????? ????? ???? ?????? ??????? ??? ??) ...

    ; Display the word being guessed (with hidden letters)
    call print_newline
    call center_word        ; Center the word on screen
    mov si, OFFSET mask_buf
    call print_si_string
    call print_newline

    ; Display game status information
    mov dx, OFFSET msg_lives
    call print_str
    mov al, lives
    add al, '0'
    call print_char
    call print_newline

    ; Show which letters have been guessed
    mov dx, OFFSET msg_guessed
    call print_str
    call display_guessed_letters
    call print_newline

    ; Display hint if it has been used
    cmp cur_hint_off, 0
    je draw_done
    cmp used_hint, 1
    jne draw_done
    mov dx, OFFSET msg_hint_lbl
    call print_str
    mov si, cur_hint_off
    call print_si_string_safe
    call print_newline
    
draw_done:
    ret

center_word:
    ; Center the word display on 80-column screen
    push cx
    push dx
    mov ax, 80
    sub ax, cur_word_len    ; Calculate padding needed
    shr ax, 1               ; Divide by 2 for centering
    mov cx, ax              ; Number of spaces to print
    jcxz center_done        ; Skip if no centering needed
    
center_loop:
    mov dl, ' '
    mov ah, 02h
    int 21h
    loop center_loop
    
center_done:
    pop dx
    pop cx
    ret

draw_screen_mini:
    
    ; Fast screen update for animations (minimal redraw)
    ; Show basic game state during animations
    mov dx, OFFSET msg_score
    call print_str
    mov ax, score
    call print_number
    call print_newline
    
    ; --- FIX START: Logic to handle lives > 6 ---
    xor bx, bx
    mov al, lives
    cmp al, 6
    jbe use_actual_lives_mini
    mov al, 6

use_actual_lives_mini:
    mov bl, 6
    sub bl, al
    shl bx, 1
    mov si, OFFSET art_ptr_table
    add si, bx
    mov dx, [si]
    call print_str
    ; --- FIX END ---
    
    ; Show current word state
    call print_newline
    call center_word
    mov si, OFFSET mask_buf
    call print_si_string
    call print_newline
    ret

; ==================== UTILITY AND HELPER FUNCTIONS ====================
initialize_buffers:
    ; Initialize all game buffers to zero
    push cx
    push di
    
    ; Clear word file buffer
    mov cx, WORD_BUF_SIZE
    mov di, OFFSET word_buf
    mov al, 0
    rep stosb
    
    ; Clear word display buffer
    mov cx, MAX_WORD_LEN+3
    mov di, OFFSET mask_buf
    mov al, 0
    rep stosb
    
    ; Clear guessed letters table
    mov cx, 26
    mov di, OFFSET guessed_table
    mov al, 0
    rep stosb
    
    ; Clear word and hint pointer arrays
    mov cx, MAX_WORDS
    mov di, OFFSET word_ptrs
    mov ax, 0
    rep stosw
    
    mov cx, MAX_WORDS
    mov di, OFFSET hint_ptrs
    mov ax, 0
    rep stosw
    
    pop di
    pop cx
    ret

print_si_string_safe:
    ; Safely print string at SI with length limit
    push ax
    push dx
    push cx
    mov cx, 50              ; Maximum characters to print
safe_pr_loop:
    mov dl, [si]
    cmp dl, 0
    je safe_pr_done
    cmp cx, 0
    je safe_pr_done
    mov ah, 02h
    int 21h
    inc si
    dec cx
    jmp safe_pr_loop
safe_pr_done:
    pop cx
    pop dx
    pop ax
    ret

print_number:
    ; Print decimal number in AX
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
    ; Handle zero case
    cmp ax, 0
    jne convert_loop
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp print_done
    
convert_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz convert_loop
    
print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop
    
print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_small_number:
    ; Print 2-digit number in AL (0-99)
    push ax
    push dx
    
    mov ah, 0
    mov dl, 10
    div dl
    
    ; Print tens digit
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Print ones digit
    add ah, '0'
    mov dl, ah
    mov ah, 02h
    int 21h
    
    pop dx
    pop ax
    ret

clear_screen:
    ; Clear screen using BIOS interrupt
    push ax
    push bx
    push cx
    push dx
    mov ax, 0600h           ; BIOS scroll up function
    mov bh, 07h             ; White on black
    mov cx, 0000h           ; Upper left corner
    mov dx, 184Fh           ; Lower right corner
    int 10h
    mov ah, 02h             ; Set cursor position
    mov bh, 00h             ; Page 0
    mov dx, 0000h           ; Row 0, column 0
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret

wait_for_key:
    ; Wait for any key press
    mov ah, 08h
    int 21h
    ret

short_delay:
    ; Create delay for animations
    push cx
    mov cx, 0ffffh          ; Delay counter
short_delay_loop:
    dec cx
    jnz short_delay_loop
    pop cx
    ret

display_guessed_letters:
    ; Show which letters player has guessed
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cx, 26              ; A-Z letters
    mov bl, 'A'             ; Start with letter A
    mov si, OFFSET guessed_table
    
guess_display_loop:
    mov al, [si]
    cmp al, 1
    jne next_guess
    
    ; Print guessed letter
    mov dl, bl
    mov ah, 02h
    int 21h
    mov dl, ' '             ; Space separator
    int 21h
    
next_guess:
    inc si
    inc bl
    loop guess_display_loop
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_char:
    ; Print single character in AL
    push ax
    push dx
    mov dl, al
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret

; ==================== GAME SETUP AND WORD MANAGEMENT ====================
reset_game:
    ; Reset game state for new round
    ; Set lives based on selected difficulty
    call select_difficulty
    mov al, difficulty
    dec al
    mov bl, al
    mov bh, 0
    mov al, max_lives_array[bx]
    mov lives, al
    
    mov used_hint, 0        ; Reset hint availability
    
    ; Clear guessed letters table
    mov cx, 26
    mov di, OFFSET guessed_table
    mov al, 0
    rep stosb
    
    ; Clear word display buffer
    mov cx, MAX_WORD_LEN+3
    mov di, OFFSET mask_buf
    mov al, 0
    rep stosb
    
    ret

pick_word:
    ; Select random word from loaded word database
    mov cx, word_count
    cmp cx, 0
    jne pick_continue
    
    ; Handle case where no words were loaded
    call clear_screen
    mov dx, OFFSET msg_error_file
    call print_str
    mov dx, OFFSET msg_again
    call print_str
    call get_char_no_echo
    cmp al, 'y'
    je restart_pick
    cmp al, 'Y'
    je restart_pick
    jmp exit_app
    
restart_pick:
    jmp new_game

pick_continue:
    ; Generate random index and select word
    call rand_val       
    xor ah, ah
    xor dx, dx
    div cx                  ; AX % word_count -> DX
    mov bx, dx          
    shl bx, 1               ; Convert to word pointer offset
    
    ; Validate pointer is within bounds
    cmp bx, MAX_WORDS * 2
    jb pointers_ok
    mov bx, 0               ; Fallback to first word
    
pointers_ok:
    ; Get pointer to selected word
    mov si, OFFSET word_ptrs
    add si, bx
    mov ax, [si]
    
    ; Validate word pointer is within buffer range
    cmp ax, OFFSET word_buf
    jb pointer_invalid
    cmp ax, OFFSET word_buf + WORD_BUF_SIZE
    jae pointer_invalid
    jmp pointer_valid
    
pointer_invalid:
    ; Use first word as safe fallback
    mov si, OFFSET word_ptrs
    mov ax, [si]
    
pointer_valid:
    mov cur_word_off, ax
    
    ; Get corresponding hint pointer
    mov si, OFFSET hint_ptrs 
    add si, bx
    mov ax, [si]
    mov cur_hint_off, ax

    ; Initialize display buffer with hidden letters
    mov si, cur_word_off
    mov di, OFFSET mask_buf
    xor cx, cx
    
    ; Clear display buffer first
    push di
    push cx
    mov cx, MAX_WORD_LEN+2
    mov al, 0
    rep stosb
    pop cx
    pop di
    
    mov si, cur_word_off
    
calc_len:
    ; Build display mask with _ for letters, keep punctuation visible
    cmp cx, MAX_WORD_LEN
    jae len_done
    
    mov al, [si]
    cmp al, 0
    je len_done
    
    ; Check we're within word buffer
    cmp si, OFFSET word_buf + WORD_BUF_SIZE
    jae len_done
    
    ; Replace A-Z with _, keep other characters visible
    cmp al, 'A'
    jb not_alpha
    cmp al, 'Z'
    ja not_alpha
    mov BYTE PTR [di], '_'
    jmp next_mask
not_alpha:
    mov [di], al
next_mask:
    inc si
    inc di
    inc cx
    jmp calc_len
    
len_done:
    mov BYTE PTR [di], 0    ; Null terminate display string
    mov cur_word_len, cx    ; Store word length
    ret

reveal_random:
    ; Reveal random hidden letters when hint is used
    push cx
    push si
    push di
    push bx
    
    mov cx, cur_word_len
    mov si, cur_word_off
    mov di, OFFSET mask_buf
    xor bx, bx
    xor dx, dx              ; Count of revealed letters
    
rev_loop:
    cmp bx, cx
    jae rev_done
    
    ; Look for next hidden letter position
    mov al, [di+bx]
    cmp al, '_'
    jne rev_next
    
    ; Found hidden letter - reveal it
    mov al, [si+bx]
    mov [di+bx], al
    inc dx                  ; Track how many revealed
    
    ; Stop after revealing 2 letters
    cmp dx, 2
    jae rev_done
    
rev_next:
    inc bx
    jmp rev_loop
    
rev_done:
    pop bx
    pop di
    pop si
    pop cx
    ret

check_win:
    ; Check if player has guessed all letters
    mov si, OFFSET mask_buf
win_loop:
    mov al, [si]
    cmp al, 0
    je win_yes              ; End of string - all letters guessed
    cmp al, '_'
    je win_no               ; Found hidden letter - not won yet
    inc si
    jmp win_loop
win_yes:
    mov al, 1               ; Return win status
    ret
win_no:
    mov al, 0               ; Return continue status
    ret

; ==================== FILE I/O AND PARSING SYSTEM ====================
read_file:
    ; Load wordlist.txt file into memory buffer
    mov dx, OFFSET filename
    mov ax, 3D00h           ; DOS open file function
    int 21h
    jc file_err             ; Jump if file error
    
    mov file_handle, ax     ; Store file handle
    mov bx, ax
    mov cx, WORD_BUF_SIZE   ; Maximum bytes to read
    mov dx, OFFSET word_buf ; Destination buffer
    mov ah, 3Fh             ; DOS read file function
    int 21h
    mov file_len, ax        ; Store actual bytes read
    
    mov bx, file_handle
    mov ah, 3Eh             ; DOS close file function
    int 21h
    mov ax, 0               ; Return success
    ret
    
file_err:
    mov dx, OFFSET msg_error_file
    call print_str
    mov ax, 1               ; Return error
    ret

parse_buffer:
    ; Parse loaded word file and build word/hint database
    mov si, 0               ; Buffer position counter
    mov di, 0               ; Word index counter
    call save_word_ptr      ; Save first word pointer
    
parse_loop:
    ; Process file buffer character by character
    cmp si, WORD_BUF_SIZE - 100  ; Buffer overflow protection
    jae parse_done
    cmp si, file_len
    jae parse_done
    
    mov al, word_buf[si]    ; Get current character
    
    cmp al, 0
    je parse_done           ; End of buffer
    cmp al, '|'
    je found_pipe           ; Word/hint separator
    cmp al, 13 
    je found_end            ; Carriage return - end of entry
    cmp al, 10 
    je found_end            ; Line feed - end of entry
    
    ; Convert lowercase letters to uppercase
    cmp al, 'a'
    jb no_conv
    cmp al, 'z'
    ja no_conv
    sub al, 20h
    mov word_buf[si], al
    
no_conv:
    inc si
    jmp parse_loop

found_pipe:
    ; Handle word|hint separator
    mov BYTE PTR word_buf[si], 0 ; Null terminate word
    inc si
    call save_hint_ptr      ; Save hint pointer
    jmp parse_loop

found_end:
    ; Handle end of word/hint entry
    mov BYTE PTR word_buf[si], 0 ; Null terminate
    inc si
    cmp si, file_len
    jae finalize_word
    ; Handle CRLF sequences
    mov al, word_buf[si]
    cmp al, 10
    jne finalize_word
    inc si

finalize_word:
    ; Complete current word entry
    inc word_count
    inc di
    cmp si, file_len
    jae parse_done
    call save_word_ptr      ; Setup next word
    jmp parse_loop

parse_done:
    ret

save_word_ptr:
    ; Store pointer to word in word database
    mov bx, di
    shl bx, 1               ; Convert index to word offset
    mov ax, OFFSET word_buf
    add ax, si              ; Calculate word position
    mov word_ptrs[bx], ax   ; Store word pointer
    mov hint_ptrs[bx], 0    ; Initialize hint pointer to null
    ret

save_hint_ptr:
    ; Store pointer to hint in hint database
    mov bx, di
    shl bx, 1               ; Convert index to word offset
    mov ax, OFFSET word_buf
    add ax, si              ; Calculate hint position
    mov hint_ptrs[bx], ax   ; Store hint pointer
    ret

; ==================== SYSTEM UTILITIES ====================
print_str: 
    ; Print $-terminated string at DX
    mov ah, 09h
    int 21h
    ret

print_si_string: 
    ; Print null-terminated string at SI
    push ax
    push dx
pr_loop:
    mov dl, [si]
    cmp dl, 0
    je pr_done
    mov ah, 02h
    int 21h
    inc si
    jmp pr_loop
pr_done:
    pop dx
    pop ax
    ret

print_newline:
    ; Print newline sequence
    mov dx, OFFSET newline
    call print_str
    ret

get_char_no_echo:
    ; Get character without echo
    mov ah, 08h
    int 21h
    ret

init_rng:
    ; Initialize random number generator with system time
    mov ah, 2Ch             ; Get system time
    int 21h         
    mov rand_seed, dx       ; Use time as seed
    ret

rand_val: 
    ; Generate pseudo-random number in AL
    mov ax, rand_seed
    mov bx, 25173           ; Multiplier for LCG
    mul bx
    add ax, 13849           ; Increment for LCG
    mov rand_seed, ax
    mov al, ah              ; Return high byte
    ret

exit_app:
    ; Clean program termination
    mov ax, 4C00h
    int 21h

END start