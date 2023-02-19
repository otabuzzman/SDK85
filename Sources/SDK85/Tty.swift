import SwiftUI

struct Tty: View {
    var intIO: IntIO
    var isPortrait: Bool

    var body: some View {
        VStack {
            Monitor(intIO: intIO)
            Keyboard(intIO: intIO)
        }
        .padding(16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}
