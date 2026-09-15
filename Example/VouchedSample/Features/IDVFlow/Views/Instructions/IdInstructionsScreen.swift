import SwiftUI

struct IdInstructionsScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 72))
                .foregroundColor(AppColors.primary)

            Text("Prepare Your ID")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.onBackground)

            VStack(alignment: .leading, spacing: 12) {
                bullet("Use a government-issued photo ID")
                bullet("Find a well-lit area")
                bullet("Place your ID on a dark, flat surface")
                bullet("Make sure all corners are visible")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.primary)
            Text(text)
                .font(.body)
                .foregroundColor(AppColors.onBackground)
        }
    }
}

#Preview {
    IdInstructionsScreen(onContinue: {})
}
