import Foundation

enum AppConfig {
    static var geminiAPIKey: String {
        sanitizedInfoValue("GeminiAPIKey")
    }

    static var geminiModel: String {
        let value = sanitizedInfoValue("GeminiModel")
        return value.isEmpty ? "gemini-2.5-flash" : value
    }

    static var usesLocalAI: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["ATRIAWALL_USE_LOCAL_AI"] == "1"
    }

    static var revenueCatAPIKey: String {
        sanitizedInfoValue("RevenueCatAPIKey")
    }

    private static func sanitizedInfoValue(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return ""
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("$(") || trimmed.contains("YOUR_") {
            return ""
        }

        return trimmed
    }
}
