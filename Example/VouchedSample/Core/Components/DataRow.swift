import SwiftUI

struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(AppColors.onBackgroundVariant)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(AppColors.onBackground)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        DataRow(label: "First Name", value: "John")
        DataRow(label: "Last Name", value: "Doe")
        DataRow(label: "Birth Date", value: "1990-01-01")
    }
    .padding()
}
