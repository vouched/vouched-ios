import SwiftUI

struct FaceInstructionsScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 72))
                .foregroundColor(AppColors.primary)

            Text("Prepare for Selfie")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.onBackground)

            VStack(alignment: .leading, spacing: 12) {
                bullet("Hold your phone at eye level")
                bullet("Make sure your face is well-lit")
                bullet("Remove hats, glasses, and masks")
                bullet("Follow the on-screen prompts")
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
    FaceInstructionsScreen(onContinue: {})
}
