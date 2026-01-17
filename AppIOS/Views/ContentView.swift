import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.isLocked {
                    // --- SCHERMATA DI SBLOCCO ---
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.spendyPrimary)
                        Text("Spendy è bloccata")
                            .font(.title2.bold())
                        Button("Sblocca con FaceID") {
                            authManager.unlockWithBiometrics()
                        }
                        .padding().background(Color.spendyPrimary).foregroundColor(.white).cornerRadius(10)
                    }
                    .onAppear { authManager.unlockWithBiometrics() }
                } else {
                    // --- APP SBLOCCATA ---
                    DashboardView()
                }
            } else {
                // --- LOGIN (LA TUA VISTA) ---
                AuthView()
            }
        }
    }
}
