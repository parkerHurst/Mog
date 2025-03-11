import SwiftUI

struct ContentView: View {
    @ObservedObject var mouseTracker: MouseTracker
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Mog - Mouse Position Tracker")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: mouseTracker.isAccessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(mouseTracker.isAccessibilityEnabled ? .green : .red)
                Text("Accessibility Permissions: \(mouseTracker.isAccessibilityEnabled ? "Enabled" : "Disabled")")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text("Last Stored Position:")
                    .fontWeight(.medium)
                if let position = mouseTracker.lastStoredPosition {
                    Text("X: \(Int(position.x)), Y: \(Int(position.y))")
                } else {
                    Text("No position stored yet")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Instructions:")
                    .fontWeight(.medium)
                Text("1. Keep mouse still for 1+ second to store position")
                Text("2. Press Cmd+Control+R to reset mouse to stored position")
                
                if !mouseTracker.isAccessibilityEnabled {
                    Button("Request Accessibility Permissions") {
                        mouseTracker.checkAccessibilityPermissions()
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

#Preview {
    ContentView(mouseTracker: MouseTracker())
}
