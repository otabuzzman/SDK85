# SDK85

A kind of replica of the [Intel SDK-85](https://en.wikipedia.org/wiki/Intel_System_Development_Kit#SDK-85) for iPadOS. The app uses a Z80 emulator instead of 8085, so the original ROM required changes: RIM and SIM opcodes were replaced by no-ops and 8085’s interrupts 4.5, 5.5, and 6.5 were mapped to Z80’s IM 0.

The original ROM was taken from the *SDK-85 User's Manual* ([PDF](https://retro.hansotten.nl/uploads/sdk85/9800451B.pdf)). A transcript of the relevant pages (67 - 93) had been done with [AWS Textract](https://aws.amazon.com/textract/), followed by numerous AWK scripts, and eventually manually edited. Though the assembler is happy, overseen errors might still hide in the code.

### Tools
- [Swift on Windows](https://www.swift.org/blog/swift-on-windows/) 5.6
- [8085 assembler](http://github.com/TomNisbet/asm85) (optional)
- [Cygwin](https://www.cygwin.com/) with development tools (to compile 8085 assembler)

### Usage
- Clone repository from GitHub
- Checkout `swindows` branch
- Run commands in top-level directory

  ```
  rem build and run
  swift run

  rem build and run for production
  swift run -c release
  ```

### Build ROM image
- Compile 8085 assembler (asm85)
- Append PATH variable to contain asm85
- Run `make` in top-level directory

### Which file for what
|File|Comment|
|:---|:------|
|`Resources/SDK85.pdf`|Pages with monitor listing taken from SDK-85 User's Manual|
|`Resources/SDK85.LST`|Monitor listing transcription (ISIS-II 8080/8085 MACRO ASSEMBLER).|
|`Resources/sdk85-0000.bin`|Monitor ROM image made with 8085 assembler (asm85).|
|`Sources/SDK85/Sdk85.swift`|Main program.|
|SDK85.SRC|Monitor assembler source (ISIS-II 8080/8085 MACRO ASSEMBLER) generated from listing (.LST).|
|sdk85.asm|Monitor assembler source (asm85) hand-crafted from .SRC.|
