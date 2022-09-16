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
- Create new app in SP4

  - Set app name and color
  - Add app icon

- Delete predefined `*.swift` files in app
- Copy&paste Swift files from repository to app

  - Get repository on iPad (Working Copy)
  - Copy files from WC to SP4 folder (Textastic)

- Add ROM image with SP4 as resource to app
- Import [Z80 emulator package](https://github.com/otabuzzman/z80) repository with SP4

### Which file for what
|File|Comment|
|:---|:------|
|Resources/SDK85.pdf|Pages with monitor listing taken from SDK-85 User's Manual|
|Resources/SDK85.LST|Monitor listing transcription (ISIS-II 8080/8085 MACRO ASSEMBLER).|
|Resources/sdk85-0000.bin|Monitor ROM image made with 8085 assembler (asm85).|
|Sdk85.swift|Main program.|
|I8279.swift|8279 keyboard/ display interface abstraction.|
|IPorts.swift|I/O ports and interrupts abstraction fpr Z80 emulator.|
|Keyborad.swift|SDK-85 keyboard view.|
|BarreledRectangle.swift|A barreled shaped rectangle.|
|TriangledRectangle.swift|A double crossed rectangle.|
|Display.swift|SDK-85 keyboard view.|
|SevenSegmenDisplay.swift|A single seven segment digit.|
|Queue.swift|Queue implementation.|
|SDK85.SRC|Monitor assembler source (ISIS-II 8080/8085 MACRO ASSEMBLER) generated from listing (.LST).|
|sdk85.asm|Monitor assembler source (asm85) hand-crafted from .SRC.|
