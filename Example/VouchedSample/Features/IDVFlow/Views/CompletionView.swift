import SwiftUI
import Vouched

struct CompletionView: View {
    let jobResult: JobResult?
    let jobId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primary)

                    Text("Verification Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.onBackground)

                    Text("Your identity has been successfully verified.")
                        .font(.body)
                        .foregroundColor(AppColors.onBackgroundVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                if let jobId = jobId {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Verification Details")
                            .font(.headline)
                            .foregroundColor(AppColors.onBackground)
                            .padding(.bottom, 8)

                        DataRow(label: "Job ID", value: jobId)

                        if let result = jobResult {
                            if let firstName = result.firstName {
                                DataRow(label: "First Name", value: firstName)
                            }

                            if let middleName = result.middleName {
                                DataRow(label: "Middle Name", value: middleName)
                            }

                            if let lastName = result.lastName {
                                DataRow(label: "Last Name", value: lastName)
                            }

                            if let birthDate = result.birthDate {
                                DataRow(label: "Birth Date", value: birthDate)
                            }

                            if let gender = result.gender {
                                DataRow(label: "Gender", value: gender.gender ?? "-")
                            }

                            if let country = result.country {
                                DataRow(label: "Country", value: country)
                            }

                            if let state = result.state {
                                DataRow(label: "State", value: state)
                            }

                            if let type = result.type {
                                DataRow(label: "ID Type", value: type)
                            }

                            if let confidences = result.confidences {
                                if let idConfidence = confidences.id {
                                    DataRow(
                                        label: "ID Confidence",
                                        value: String(format: "%.2f", idConfidence.doubleValue)
                                    )
                                }

                                if let selfieConfidence = confidences.selfie {
                                    DataRow(
                                        label: "Selfie Confidence",
                                        value: String(format: "%.2f", selfieConfidence.doubleValue)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.white)
    }
}

#Preview {
    CompletionView(
        jobResult: nil,
        jobId: "12345-test-job-id"
    )
}
