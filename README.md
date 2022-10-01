# SDK85

A kind of replica of the [Intel SDK-85](https://en.wikipedia.org/wiki/Intel_System_Development_Kit#SDK-85) for iPadOS. The app uses a Z80 emulator instead of 8085, so the original ROM required changes: `RIM` and `SIM` were replaced by `XRA A` and `NOP` instructions and 8085’s interrupts TRAP (4.5), RST 5.5 and RST 7.5 were mapped to Z80’s NMI and INT (IM 0), the latter executing the commands `RST 28h` and `RST 38h`. RST 6.5 is ignored.

The original ROM was taken from the *SDK-85 User's Manual* ([PDF](http://retro.hansotten.nl/uploads/sdk85/9800451B.pdf)). A transcript of the relevant pages (67 - 93) had been done with [AWS Textract](https://aws.amazon.com/textract/), followed by numerous AWK scripts, and eventually manually edited. Though the assembler is happy, overseen errors might still hide in the code.



**Working**
- GO command (run a program)
- SUBST MEM command (enter a program)
- EXAM REG command (examine/ set registers)
- SINGLE STEP command (debug a program)

**Wanted**
- Improved 8279 (keyboard/ display interface)
- 8155 support (RAM, I/O ports and timer)
- TTY monitor

**Example (video)**
1. Set stack pointer (EXAM REG) to address 0x20C2
2. Enter program (SUBST MEM) at address 0x2000:

   |No|Opcode(s)|Mnemonic|Description|
   |:---|:---|:---|:---|
   |1|3E 42|MVI A,42H|Load register A with 0x42.|
   |2|CF|RST 1|Jump to warm start routine.|
3. Run programm (GO) at address 0x2000
4. Check value in register A (EXAM REG)

https://user-images.githubusercontent.com/16709212/191330797-6c84e86a-3d4a-4d4d-8560-75289ef487b6.mp4

### Tools
Apps used on iPad
- [Swift Playgrounds 4](https://apps.apple.com/de/app/swift-playgrounds/id908519492) (SP4)
- [Working Copy](https://workingcopyapp.com/) (WC)
- [Textastic](https://www.textasticapp.com/) (can handle files in *Swift Playgrounds* and *Working Copy* folders)
- [GitHub](https://apps.apple.com/us/app/github/id1477376905)
 
Apps used on Winos or Linos
- [8085 assembler](https://github.com/TomNisbet/asm85) (optional)
- [Cygwin](https://www.cygwin.com/) with development tools (to compile 8085 assembler on Winos)

### Build
- Create and open a new app in SP4
- Delete predefined `*.swift` files
- Copy Swift files (except Package.swift) from repository:

  - Get repository on iPad (Working Copy)
  - Copy Sources folder from WC to SP4 (Textastic)

- Add ROM image (pick from WC Recources folder)
- Add background photo (pick from WC Resources folder)
- Add key press/ release sound file
- Add [Z80 emulator package](https://github.com/otabuzzman/z80)

### Which file for what
|File|Comment|
|:---|:------|
|Intel/SDK85.pdf|Pages with monitor listing taken from SDK-85 User's Manual|
|Intel/SDK85.LST|Monitor transcription (ISIS-II 8080/8085 MACRO ASSEMBLER).|
|Intel/SDK85.SRC|Monitor assembler source (ISIS-II 8080/8085 MACRO ASSEMBLER) generated from SDK85.LST.|
|Resources/sdk85-0000.bin|Monitor ROM image made with 8085 assembler (asm85).|
|Resources/sdk85-pcb.jpg|Photo of SDK-85 printed circuit board.|
|sdk85.asm|Monitor assembler source (asm85) hand-crafted from SDK85.SRC.|
|Sources/SDK85|Swift sources folder.|
|Sdk85.swift|The main program.|
|I8279.swift|8279 keyboard/ display interface abstraction.|
|IPorts.swift|I/O ports and interrupts abstraction for Z80 emulator.|
|Keyboard.swift|SDK-85 keyboard view.|
|BarreledRectangle.swift|A barrel-shaped rectangle.|
|TriangledRectangle.swift|A double-crossed rectangle.|
|Display.swift|SDK-85 display view.|
|SevenSegmentDisplay.swift|A single seven segment digit.|
|Sound.swift|A simple sound file player.|
|Queue.swift|A Queue (FIFO) implementation.|

### License
Copyright (c) 2022 Jürgen Schuck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the „Software“), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED „AS IS“, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### SDK-85 User’s Manual and Monitor
Copyright (c) 1978 Intel Corporation

#### Photo of SDK-85 printed circuit board
[Photo](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) by [Hans Otten](http://retro.hansotten.nl/contact/) licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)

#### Z80 emulator package (referenced)
[License information](https://github.com/otabuzzman/z80#license) in emulator’s repository.
