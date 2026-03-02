import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var isLoading: Bool = false

    // MARK: - Animation State
    @State private var avatarVisible: Bool = false
    @State private var readOnlyVisible: Bool = false
    @State private var editableVisible: Bool = false
    @State private var actionsVisible: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: - Avatar Section
                        avatarSection
                            .opacity(avatarVisible ? 1 : 0)
                            .offset(y: avatarVisible ? 0 : -20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: avatarVisible)

                        if let user = authManager.currentUser {

                            // MARK: - Read-Only Info Card
                            readOnlyCard(user: user)
                                .opacity(readOnlyVisible ? 1 : 0)
                                .offset(y: readOnlyVisible ? 0 : 18)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: readOnlyVisible)

                            // MARK: - Editable Fields Card
                            editableCard
                                .opacity(editableVisible ? 1 : 0)
                                .offset(y: editableVisible ? 0 : 18)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.25), value: editableVisible)

                            // MARK: - Actions Card
                            actionsCard(user: user)
                                .opacity(actionsVisible ? 1 : 0)
                                .offset(y: actionsVisible ? 0 : 18)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.35), value: actionsVisible)

                        } else {
                            ProgressView()
                                .tint(.spendyPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                                .onAppear {
                                    Task {
                                        await authManager.fetchUserProfile()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        Task {
                            await authManager.fetchUserProfile()
                            await MainActor.run {
                                dismiss()
                            }
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.spendyPrimary)
                }
            }
            .toolbarBackground(Color.spendyBackground, for: .navigationBar)
            .onAppear {
                if let user = authManager.currentUser {
                    name = user.name
                    surname = user.surname
                }
                triggerStaggeredEntrance()
            }
            .onChange(of: authManager.currentUser) { _, newUser in
                if let user = newUser {
                    if !isLoading {
                        name = user.name
                        surname = user.surname
                    }
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer gradient ring
                Circle()
                    .stroke(Color.spendyGradient, lineWidth: 3.5)
                    .frame(width: 114, height: 114)

                // Inner fill circle
                Circle()
                    .fill(Color.spendyGradientSubtle)
                    .frame(width: 106, height: 106)

                // Initials
                if let user = authManager.currentUser {
                    Text(user.initials)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.spendyGradient)
                }
            }
            .shadow(color: Color.spendyShadowPrimary, radius: 16, x: 0, y: 6)

            if let user = authManager.currentUser {
                Text(user.fullName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Read-Only Info Card

    private func readOnlyCard(user: User) -> some View {
        SpendyCard(style: .default, padding: 0) {
            VStack(spacing: 0) {
                profileRow(
                    icon: "envelope.fill",
                    iconColor: .spendyBlue,
                    iconBackground: Color.spendyBlueLight,
                    title: "Email",
                    value: user.email,
                    showDivider: true
                )
                profileRow(
                    icon: "at",
                    iconColor: .spendyAccent,
                    iconBackground: Color.spendyAccent.opacity(0.1),
                    title: "Username",
                    value: "@\(user.username)",
                    showDivider: false
                )
            }
        }
    }

    private func profileRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        value: String,
        showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.spendyTertiaryText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(value)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.spendySecondaryText)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.spendyTertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if showDivider {
                Rectangle()
                    .fill(Color.spendyBorderSubtle)
                    .frame(height: 0.5)
                    .padding(.leading, 66)
            }
        }
    }

    // MARK: - Editable Fields Card

    private var editableCard: some View {
        SpendyCard(style: .default, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.spendyGradient)
                    Text("Modifica Profilo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.spendySecondaryText)
                }
                .padding(.bottom, 2)

                SpendyTextField(
                    label: "Nome",
                    text: $name,
                    icon: "person.fill",
                    autocapitalization: .words
                )

                SpendyTextField(
                    label: "Cognome",
                    text: $surname,
                    icon: "person.fill",
                    autocapitalization: .words
                )
            }
        }
    }

    // MARK: - Actions Card

    private func actionsCard(user: User) -> some View {
        VStack(spacing: 12) {
            SpendyButton(
                "Salva Modifiche",
                variant: .primary,
                isLoading: isLoading,
                isDisabled: !hasChanges(user: user),
                leadingIcon: "checkmark.circle.fill"
            ) {
                saveProfile()
            }

            SpendyButton(
                "Esci dall'account",
                variant: .destructive,
                leadingIcon: "rectangle.portrait.and.arrow.right"
            ) {
                authManager.logout()
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func hasChanges(user: User) -> Bool {
        return name != user.name || surname != user.surname
    }

    private func saveProfile() {
        guard !name.isEmpty, !surname.isEmpty else { return }

        isLoading = true
        Task {
            _ = await authManager.updateProfile(name: name, surname: surname)
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func triggerStaggeredEntrance() {
        avatarVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { readOnlyVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { editableVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { actionsVisible = true }
    }
}

