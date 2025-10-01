import SwiftUI

struct Pcb: View {
    var isPortrait: Bool
    
    @EnvironmentObject var watchdog: Watchdog
    @EnvironmentObject var circuitIO: CircuitIO
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let interval = UserDefaults.standard.double(forKey: "watchdogInterval")
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("sdk85-pcb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height, alignment: .bottomTrailing)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Headline()
                }
            VStack {
                Display()
                Hexboard()
            }
            .padding(8)
            .padding(.bottom, horizontalSizeClass == .regular ? 16 : 42)
            .background(Color.pcbLabel.opacity(0.8)) // https://stackoverflow.com/a/71935851
            .cornerRadius(16)
            
            if watchdog.alarm {
                BatterySaver {
                    circuitIO.cancel()
                } resume: {
                    circuitIO.resume()
                    watchdog.alarm = false
                    watchdog.restart(interval)
                }
            }
        }
    }
}

struct Headline: View {
    @EnvironmentObject var circuitIO: CircuitIO
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                Text("Credit: [SDK-85 printed circuit board](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) photo by [Hans Otten](http://retro.hansotten.nl/contact/) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)")
                Spacer()
                Text(String(format: "%.2f MHz", circuitIO.CLK / 1_000_000))
            }
            .foregroundColor(.pcbText)
            .accentColor(.pcbLink)
            .padding(4)
        }
        .background(.pcbLabel)
        .cornerRadius(12)
        .padding(4)
    }
}
