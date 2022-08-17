#if os(Windows)

import Foundation
import z80

@main
struct Sdk85 {
    static func main() {
        var ram = Array<Byte>(repeating: 0, count: 0x10000)
        let rom = NSData(contentsOfFile: "Resources/sdk85-0000.bin")
        ram.replaceSubrange(0..<rom!.count, with: rom!)

        let ports = IOPorts()
        let mports = MIOPorts(0x1800...0x19FF)
        let mem = Memory(ram, 0x2000, [mports])
        var z80 = Z80(mem, ports)

        while (!z80.Halt)
        {
            z80.parse()
        }
    }
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

final class MIOPorts: MPorts
{
    private var block: Array<Byte>

    init(_ mmap: ClosedRange<UShort>) {
        self.mmap = mmap
        block = Array<Byte>(repeating: 0, count: Int(mmap.upperBound - mmap.lowerBound + 1))
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

#endif