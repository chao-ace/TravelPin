import SwiftUI

struct SettingsView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("settings.language".localized)) {
                    Picker("settings.language".localized, selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
