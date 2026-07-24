import Foundation
import UIKit

/// Everything the AI needs to design a gallery wall on a real photo.
struct WallDesignBrief {
    var room: String
    var styleMood: String
    var frameCount: Int
    var mustInclude: String
    var widthInches: Double
    var heightInches: Double
    var sizeClass: String
    var isCornerWall: Bool

    var promptDescription: String {
        var lines = [
            "Room: \(room)",
            "Style mood: \(styleMood.isEmpty ? "warm, editorial, collected" : styleMood)",
            "Approximate wall size: \(Int(widthInches.rounded())) x \(Int(heightInches.rounded())) inches (\(sizeClass))",
            "Number of framed pieces: \(frameCount)"
        ]
        if !mustInclude.isEmpty {
            lines.append("Must include: \(mustInclude)")
        }
        if isCornerWall {
            lines.append("Important: this photo wraps around a room corner with two wall planes. Respect the corner: do not place a single frame across the crease, and keep frames flat on each wall plane with correct perspective.")
        }
        return lines.joined(separator: "\n")
    }
}

enum WallDesignError: LocalizedError {
    case notConfigured
    case invalidEndpoint
    case encodingFailed
    case requestFailed(String)
    case noImageReturned

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add a Gemini image key in Settings to generate a photorealistic design on your wall."
        case .invalidEndpoint:
            return "The image endpoint could not be created."
        case .encodingFailed:
            return "The wall photo could not be prepared for the AI."
        case .requestFailed(let message):
            return message
        case .noImageReturned:
            return "The AI did not return an image. Please try again."
        }
    }
}

/// Calls a Gemini image-capable model to paint a gallery wall design directly
/// onto the person's real wall photo, preserving the room, lighting and
/// perspective. Falls back with a clear error so the UI can degrade gracefully.
struct WallDesignService {

    var isConfigured: Bool {
        !AppConfig.usesLocalAI && !AppConfig.geminiAPIKey.isEmpty
    }

    func renderDesign(on wallImage: UIImage, brief: WallDesignBrief) async throws -> UIImage {
        guard isConfigured else { throw WallDesignError.notConfigured }

        // Downscale to keep the upload light and the response fast.
        let prepared = wallImage.resizedForUpload(maxDimension: 1280)
        guard let jpeg = prepared.jpegData(compressionQuality: 0.85) else {
            throw WallDesignError.encodingFailed
        }
        let base64 = jpeg.base64EncodedString()

        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(AppConfig.geminiImageModel):generateContent"
        guard let url = URL(string: endpoint) else { throw WallDesignError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(AppConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")

        let payload = ImageGenRequest(
            contents: [
                ImageGenContent(parts: [
                    ImageGenPart(text: prompt(for: brief), inlineData: nil),
                    ImageGenPart(text: nil, inlineData: ImageGenInlineData(mimeType: "image/jpeg", data: base64))
                ])
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WallDesignError.requestFailed("No response from the image service.")
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Image request failed (\(http.statusCode))."
            throw WallDesignError.requestFailed(message)
        }

        let decoded = try JSONDecoder().decode(ImageGenResponse.self, from: data)
        for candidate in decoded.candidates {
            for part in candidate.content.parts {
                if let inline = part.inlineData,
                   let bytes = Data(base64Encoded: inline.data),
                   let image = UIImage(data: bytes) {
                    return image
                }
            }
        }
        throw WallDesignError.noImageReturned
    }

    private func prompt(for brief: WallDesignBrief) -> String {
        """
        You are a luxury interior design visualiser. Edit the attached photograph of a real wall so it shows a beautifully composed gallery wall of framed pictures hung on it.

        Requirements:
        - Keep the original room, wall texture, lighting, colour temperature, furniture and perspective exactly as in the photo. Only add the framed pictures.
        - Hang the frames flat against the wall with realistic shadows, correct perspective and believable scale for the wall size.
        - Compose an intentional, balanced arrangement (one anchor piece, supporting pieces and small accents). Avoid a messy or crowded look.
        - Use premium framing: charcoal metal, walnut wood, ivory mats.
        - Do not add text, watermarks, people, or extra furniture.

        Design brief:
        \(brief.promptDescription)

        Return the edited photograph as an image.
        """
    }
}

// MARK: - Wire types

private struct ImageGenRequest: Encodable {
    var contents: [ImageGenContent]
    var generationConfig = ImageGenConfig()
}

private struct ImageGenConfig: Encodable {
    var responseModalities = ["IMAGE"]
}

private struct ImageGenContent: Codable {
    var parts: [ImageGenPart]
}

private struct ImageGenPart: Codable {
    var text: String?
    var inlineData: ImageGenInlineData?

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
}

private struct ImageGenInlineData: Codable {
    var mimeType: String
    var data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

private struct ImageGenResponse: Decodable {
    var candidates: [ImageGenCandidate]
}

private struct ImageGenCandidate: Decodable {
    var content: ImageGenContent
}

// MARK: - Image helpers

extension UIImage {
    /// Returns a copy scaled so its largest side is at most `maxDimension`.
    func resizedForUpload(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
