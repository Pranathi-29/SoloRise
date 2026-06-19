import SwiftUI

struct EditNameView: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.sysBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("CANCEL")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                            .tracking(2)
                    }
                    Spacer()
                    Text("HUNTER NAME")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sysBlue)
                        .tracking(3)
                    Spacer()
                    Button {
                        let trimmed = draft.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            name = trimmed
                        }
                        dismiss()
                    } label: {
                        Text("SAVE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.sysGold)
                            .tracking(2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.sysPanel)

                LinearGradient(colors: [.clear, .sysBlue.opacity(0.5), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1)

                Spacer()

                VStack(spacing: 20) {
                    Text("[ IDENTIFY YOURSELF ]")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.sysBlue.opacity(0.6))
                        .tracking(4)

                    // Name input
                    VStack(spacing: 0) {
                        TextField("", text: $draft)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .focused($focused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.sysCard2)

                        Rectangle()
                            .fill(Color.sysBlue)
                            .frame(height: 2)
                            .shadow(color: Color.sysBlue.opacity(0.8), radius: 4)
                    }
                    .padding(.horizontal, 32)

                    Text("This is your hunter identity.\nChoose wisely.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                }

                Spacer()
                Spacer()
            }
        }
        .presentationBackground(Color.sysBG)
        .onAppear {
            draft = name
            focused = true
        }
    }
}
