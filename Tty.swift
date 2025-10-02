import SwiftUI

struct Tty: View {
    var isPortrait: Bool
    
    @EnvironmentObject var watchdog: Watchdog
    @EnvironmentObject var circuitIO: CircuitIO
    
    private let interval = UserDefaults.standard.double(forKey: "watchdogInterval")
    
    var body: some View {
        ZStack {
            VStack {
                Monitor()
                    .padding(16)
                Divider()
                    .frame(height: 2)
                    .overlay(.gray)
                    .padding(2)
                Keyboard()
            }
            .padding(.bottom, 16)
            .background(Color.black) // https://stackoverflow.com/a/71935851
            
            if watchdog.alarm {
                BatterySaver {
                    Task { await circuitIO.cancel() }
                } resume: {
                    circuitIO.resume()
                    watchdog.alarm = false
                    watchdog.restart(interval)
                }
            }
        }
    }
}
