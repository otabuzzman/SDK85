import SwiftUI

struct Tty: View {
    var isPortrait: Bool

    var body: some View {
        VStack {
            Monitor()
            Keyboard()
        }
        .padding(16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}
