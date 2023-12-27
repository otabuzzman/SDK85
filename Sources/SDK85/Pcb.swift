import SwiftUI

struct Pcb: View {
    var circuit: CircuitVM
    var isPortrait: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("sdk85-pcb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    maxWidth: isPortrait ? UIScreen.main.bounds.width : nil,
                    maxHeight: isPortrait ? nil : UIScreen.main.bounds.height,
                    alignment: .bottomTrailing)
                .overlay(Headline(circuit: circuit), alignment: .topLeading)

            VStack {
                Display(circuit: circuit)
                Hexboard(circuit: circuit)
            }
            .padding(8)
            .background(Color.pcbLabel.opacity(0.8)) // https://stackoverflow.com/a/71935851
            .cornerRadius(16)
        }
    }
}

struct Headline: View {
    @ObservedObject var circuit: CircuitVM
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                Text("Credit: [SDK-85 printed circuit board](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) photo by [Hans Otten](http://retro.hansotten.nl/contact/) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)")
                Spacer()
                Text(String(format: "%.2f MHz", circuit.CLK / 1_000_000))
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
