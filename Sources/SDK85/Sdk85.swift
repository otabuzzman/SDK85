import Foundation
import z80

struct Sdk85 {
}

final class IOPorts: IPorts
{
    func rdPort(_ port: UShort) -> Byte
    {
        print(String(format: "  \(#function) : IN 0x%04X", port))
        return 0
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        print(String(format: "  \(#function) : OUT 0x%04X, 0x%02X", port, data))
    }

    var NMI: Bool { false }
    var INT: Bool { false }
    var data: Byte { 0x00 }
}

final class MMPorts: MPorts
{
    init(_ mmap: ClosedRange<UShort>) {
        self.mmap = mmap
    }

    func rdPort(_ port: UShort) -> Byte
    {
        print(String(format: "  \(#function) : IN 0x%04X (memory mapped)", port))
        return 0
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        print(String(format: "  \(#function) : OUT 0x%04X (memory mapped), 0x%02X", port, data))
    }

    var mmap: ClosedRange<UShort>
}

#if os(Windows)

@main
extension Sdk85 {
    static func main() {
        var ram = Array<Byte>(repeating: 0, count: 0x10000)
        let rom = NSData(contentsOfFile: "Resources/sdk85-0000.bin")
        ram.replaceSubrange(0..<rom!.count, with: rom!)

        let ioports = IOPorts()
        let mmports = MMPorts(0x1800...0x19FF)
        let mem = Memory(ram, 0x1000, [mmports])
        var z80 = Z80(mem, ioports)

        _ = Task { Stdwin.shared.record() }
        defer {
            try? FileManager.default.removeItem(atPath: Stdwin.bufferFilePath)
        }

        while (!z80.Halt)
        {
            z80.parse()
            if let ch = Stdwin.shared.getch() {
                if ch == 0x04 {
                 return
                }
            }
        }
    }
}

struct Stdwin {
    static var shared: Stdwin = {
        let this = Stdwin()
        FileManager.default.createFile(atPath: bufferFilePath, contents: nil)
        return this
    }()
    private init() {}

    private(set) static var bufferFilePath = ".stdwin"

    private var bufferFileOffset: UInt64 = 0

    func record() {
        while true {
            guard
                let line = readLine()
            else {
                return
            }
            if let fh = FileHandle(forWritingAtPath: Stdwin.bufferFilePath) {
                fh.seekToEndOfFile()
                fh.write(line.data(using: .utf8)!)
                try? fh.close()
            }
        }
    }

    mutating func getch() -> UInt8? {
        guard
            let fh = FileHandle(forReadingAtPath: Stdwin.bufferFilePath),
            let fa = try? FileManager.default.attributesOfItem(atPath: Stdwin.bufferFilePath)
        else {
            return nil
        }
        let bufferFileSize = fa[.size] as! UInt64
        if bufferFileSize>bufferFileOffset {
            try? fh.seek(toOffset: bufferFileOffset)
            let ch = try? fh.read(upToCount: 1)
            try? fh.close()

            bufferFileOffset += 1
            return ch![0]
        }
        return nil
    }
}

#endif
