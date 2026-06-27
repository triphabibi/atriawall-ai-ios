import Foundation

enum AppConfig {
    static var geminiAPIKey: String {
        sanitizedInfoValue("GeminiAPIKey")
    }

    static var geminiModel: String {
        let value = sanitizedInfoValue("GeminiModel")
        return value.isEmpty ? "gemini-3.5-flash" : value
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
