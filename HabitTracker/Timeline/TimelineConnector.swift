import SwiftUI

struct TimelineConnector: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2)
        }
    }
}

#Preview {
    TimelineConnector(color: .blue)
}
