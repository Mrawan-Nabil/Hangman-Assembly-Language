# x86 Assembly Hangman

A feature-rich implementation of the classic Hangman game written in 8086 Assembly Language. This project demonstrates file I/O, memory management, string manipulation, and custom ASCII graphics.

## ✨ Features

- **Dynamic Word Loading**: Reads words and hints dynamically from an external file (`wordlist.txt`)
- **Difficulty System**: Choose between Easy, Medium, and Hard modes, which adjust the player's starting lives
- **Hint System**: Players can request a hint to reveal the definition of the word
- **Scoring Engine**: Calculates score based on correct guesses and difficulty multipliers
- **ASCII Graphics**: Progressive gallows animation drawn using ASCII characters
- **Input Validation**: Handles case-insensitive input and prevents repeated guesses

## 🛠 Prerequisites

To run this program, you will need:

1. **DOS Emulator**: DOSBox
2. **Assembler**: A standard 16-bit TASM (Turbo Assembler)

> **⚠️ Important**: The file `wordlist.txt` must be present in the same directory as the executable file, or the game will display a "File Error".

## 🎮 How to Play

1. **Launch the game**. You will be greeted by the tutorial screen.
2. **Select Difficulty**:
   - **Easy**: 8 Lives (More room for error)
   - **Medium**: 6 Lives (Standard hangman)
   - **Hard**: 4 Lives (Challenge mode)
3. **The Game Loop**:
   - Type letters (A-Z) to guess the hidden word
   - Type `?` to reveal a Hint (The definition of the word)
   - Press `ESC` to quit the game at any time
4. **Winning/Losing**:
   - **Win**: Reveal the entire word before the hangman is fully drawn
   - **Lose**: Run out of lives. The word will be revealed

## 📊 Scoring

- **Easy**: 100 points per correct letter
- **Medium**: 200 points per correct letter  
- **Hard**: 300 points per correct letter

## 📁 File Structure

- `h33.asm`: The main source code
- `wordlist.txt`: The database of words and hints

## ⚙️ Configuration (Word List)

You can modify the `wordlist.txt` file to add your own words. The format is strict:

```
Plaintext WORD|Hint Description
```

## 🔧 Technical Details

- **Memory Model**: Small (`.MODEL SMALL`)
- **Stack Size**: 512 bytes (`200h`)
- **File I/O**: Uses DOS Interrupt 21h (Functions `3Dh` to open, `3Fh` to read) to load the word buffer
- **RNG**: Implements a Linear Congruential Generator utilizing the system clock (Interrupt 21h, Function `2Ch`) as a seed
- **Video**: Uses BIOS Interrupt 10h for screen clearing and DOS Interrupt 21h for string output
