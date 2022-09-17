# SDK85

A kind of replica of the [Intel SDK-85](https://en.wikipedia.org/wiki/Intel_System_Development_Kit#SDK-85) for iPadOS. The app uses a Z80 emulator instead of 8085, so the original ROM required changes: RIM and SIM opcodes were replaced by no-ops and 8085’s interrupts 4.5, 5.5, and 6.5 were mapped to Z80’s IM 0.

The original ROM was taken from the *SDK-85 User's Manual* ([PDF](http://retro.hansotten.nl/uploads/sdk85/9800451B.pdf)). A transcript of the relevant pages (67 - 93) had been done with [AWS Textract](https://aws.amazon.com/textract/), followed by numerous AWK scripts, and eventually manually edited. Though the assembler is happy, overseen errors might still hide in the code.

**Working**
- GO command (run a program)
- Subst Mem command (enter a program)
- Exam Reg command (examine/ set registers)

**Wanted**
- Single step command (debug a program)
- TTY support
- Improved 8279 (keyboard/ display interface)
- 8155 support (RAM, I/O ports and timer)

### Tools
Apps used on iPad
- [Swift Playgrounds 4](https://apps.apple.com/de/app/swift-playgrounds/id908519492) (SP4)
- [Working Copy](https://workingcopyapp.com/)
- [Textastic](https://www.textasticapp.com/) (can handle files in *Swift Playgrounds* and *Working Copy* folders)
- [GitHub](https://apps.apple.com/us/app/github/id1477376905)
 
Apps used on Winos or Linos
- [8085 assembler](https://github.com/TomNisbet/asm85) (optional)
- [Cygwin](https://www.cygwin.com/) with development tools (to compile 8085 assembler on Winos)

### Build
- Create and open a new app in SP4
- Delete predefined `*.swift` files
- Copy Swift files from repository:

  - Get repository on iPad (Working Copy)
  - Copy files from WC to SP4 folder (Textastic)

- Add ROM image
- Add background photo
- Add [Z80 emulator package](https://github.com/otabuzzman/z80)

### Which file for what
|File|Comment|
|:---|:------|
|Resources/SDK85.pdf|Pages with monitor listing taken from SDK-85 User's Manual|
|Resources/SDK85.LST|Monitor transcription (ISIS-II 8080/8085 MACRO ASSEMBLER).|
|Resources/sdk85-0000.bin|Monitor ROM image made with 8085 assembler (asm85).|
|Sdk85.swift|The main program.|
|I8279.swift|8279 keyboard/ display interface abstraction.|
|IPorts.swift|I/O ports and interrupts abstraction for Z80 emulator.|
|Keyboard.swift|SDK-85 keyboard view.|
|BarreledRectangle.swift|A barrel-shaped rectangle.|
|TriangledRectangle.swift|A double-crossed rectangle.|
|Display.swift|SDK-85 display view.|
|SevenSegmentDisplay.swift|A single seven segment digit.|
|Queue.swift|A Queue (FIFO) implementation.|
|SDK85.SRC|Monitor assembler source (ISIS-II 8080/8085 MACRO ASSEMBLER) generated from SDK85.LST.|
|sdk85.asm|Monitor assembler source (asm85) hand-crafted from SDK85.SRC.|

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
[License information](https://github.com/otabuzzman/z80) in emulator’s repository.
