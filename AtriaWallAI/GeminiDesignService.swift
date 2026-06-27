import Foundation

struct GeminiDesignService {
    func generatePlan(for request: AIDesignRequest) async throws -> AIDesignPlan {
        guard !AppConfig.geminiAPIKey.isEmpty else {
            return AIDesignPlan.fallback(for: request)
        }

        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(AppConfig.geminiModel):generateContent"
        guard let url = URL(string: endpoint) else {
            throw GeminiDesignError.invalidEndpoint
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(AppConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [.init(parts: [.init(text: prompt(for: request))])]))

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Gemini request failed."
            throw GeminiDesignError.requestFailed(message)
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = decoded.candidates.first?.content.parts.compactMap(\.text).joined(separator: "\n") ?? ""
        return try decodePlan(from: text, fallback: request)
    }

    private func prompt(for request: AIDesignRequest) -> String {
        """
        You are a luxury interior stylist and installation planner for an iOS app called AtriaWall AI.

        Create one gallery wall layout plan for a DIY homeowner.

        Constraints:
        - Room: \(request.room)
        - Desired style: \(request.styleMood)
        - Wall size: \(request.wallWidth) x \(request.wallHeight) inches
        - Number of frames: \(request.frameCount)
        - Must include: \(request.mustInclude.isEmpty ? "balanced family photos and art prints" : request.mustInclude)
        - Keep all frame x/y/width/height values as ratios from 0.0 to 1.0.
        - Avoid overlaps.
        - Use premium, realistic frame colors.
        - Return JSON only. No markdown fences.

        JSON schema:
        {
          "title": "short plan title",
          "summary": "one paragraph",
          "styleDirection": "short style phrase",
          "palette": ["HEX", "HEX", "HEX"],
          "frames": [
            {
              "title": "frame name",
              "xRatio": 0.25,
              "yRatio": 0.20,
              "widthRatio": 0.18,
              "heightRatio": 0.25,
              "frameColorHex": "241F1C",
              "artColorHex": "D8C6A5",
              "note": "placement or content note"
            }
          ],
          "hangingNotes": ["specific install note", "specific install note"]
        }
        """
    }

    private func decodePlan(from text: String, fallback request: AIDesignRequest) throws -> AIDesignPlan {
        let cleaned = extractJSONObject(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiDesignError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(AIDesignPlan.self, from: data)
        } catch {
            return AIDesignPlan.fallback(for: request)
        }
    }

    private func extractJSONObject(from text: String) -> String {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return text
        }
        return String(text[start...end])
    }
}

enum GeminiDesignError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The Gemini endpoint could not be created."
        case .invalidResponse:
            return "The AI response could not be converted into a layout plan."
        case .requestFailed(let message):
            return message
        }
    }
}

private struct GeminiRequest: Encodable {
    var contents: [GeminiContent]
    var generationConfig = GeminiGenerationConfig()
}

private struct GeminiGenerationConfig: Encodable {
    var temperature = 0.75
    var responseMimeType = "application/json"

    enum CodingKeys: String, CodingKey {
        case temperature
        case responseMimeType = "responseMimeType"
    }
}

private struct GeminiContent: Codable {
    var parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    var text: String?
}

private struct GeminiResponse: Decodable {
    var candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    var content: GeminiContent
}
