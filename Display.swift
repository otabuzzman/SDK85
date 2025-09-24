import SwiftUI

struct Display: View {
    @EnvironmentObject var circuitIO: CircuitIO

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact

        VStack {
            HStack {
                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(pgfedcba: circuitIO.AF1)
                        SevenSegmentDisplay(pgfedcba: circuitIO.AF2)
                        SevenSegmentDisplay(pgfedcba: circuitIO.AF3)
                        SevenSegmentDisplay(pgfedcba: circuitIO.AF4)
                    }
                    .padding(8)
                    .background(.package)
                }
                .padding(.trailing, 16)

                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(pgfedcba: circuitIO.DF1)
                        SevenSegmentDisplay(pgfedcba: circuitIO.DF2)
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
