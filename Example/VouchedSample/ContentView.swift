import SwiftUI
import Vouched

struct ContentView: View {
    @State private var showIDVFlow = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Vouched Sample App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.onBackground)

                Text("Identity Verification Demo")
                    .font(.title3)
                    .foregroundColor(AppColors.onBackgroundVariant)

                Text("SDK Version: 1.0.0")
                    .font(.body)
                    .padding(.bottom, 8)

                Text("Running on: iOS \(UIDevice.current.systemVersion)")
                    .font(.callout)
                    .padding(.bottom, 16)

                Spacer()

                Button {
                    showIDVFlow = true
                } label: {
                    Text("Start Verification")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .navigationDestination(isPresented: $showIDVFlow) {
                IDVFlowView()
            }
        }
    }
}

#Preview {
    ContentView()
}
