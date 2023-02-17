import Foundation
import z80

class C80: Z80 { // custom Z80
    private var intIO: IntIO!

    struct State {
        var timeStarted: TimeInterval
        var tStatesSum: UInt
    }
    private var state = State(
        timeStarted: Date.timeIntervalSinceReferenceDate,
        tStatesSum: 0)

    init(_ mem: Memory, _ intIO: IntIO, traceMemory: TraceMemory? = nil, traceOpcode: TraceOpcode? = nil, traceNmiInt: TraceNmiInt? = nil) {
        self.intIO = intIO
        super.init(mem, intIO,
                   traceMemory: traceMemory,
                   traceOpcode: traceOpcode,
                   traceNmiInt: traceNmiInt)

        Task { @MainActor in
            while true {
                let t1 = Date.timeIntervalSinceReferenceDate - state.timeStarted
                intIO.MHz = Double(state.tStatesSum) / t1
                try! await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    @discardableResult
    override func parse() -> Int {
        let tStates = super.parse()
        state.tStatesSum += UInt(tStates)

        if intIO.RESET {
            reset()
        }
        if intIO.TIMER_IN(pulses: UShort(tStates)) {
            intIO.NMI = true
            if _isDebugAssertConfiguration() { print(super.dumpStateCompact()) }
        }
        return tStates
    }
}
