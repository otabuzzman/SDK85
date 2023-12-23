import SwiftUI

struct Display: View {
    @ObservedObject var circuit: CircuitVM

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact

        VStack {
            HStack {
                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(dcbapgfe: circuit.AF1)
                        SevenSegmentDisplay(dcbapgfe: circuit.AF2)
                        SevenSegmentDisplay(dcbapgfe: circuit.AF3)
                        SevenSegmentDisplay(dcbapgfe: circuit.AF4)
                    }
                    .padding(8)
                    .background(.package)
                }
                .padding(.trailing, 16)

                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(dcbapgfe: circuit.DF1)
                        SevenSegmentDisplay(dcbapgfe: circuit.DF2)
                    }
                    .padding(8)
                    .background(.package)
                }
                .padding(.leading, 16)
            }
            .font(.system(size: isCompact ? 32 : 64))
            .padding(isCompact ? 12 : 32)
            .background(.display)
            .cornerRadius(4)
        }
    }
}
