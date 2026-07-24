import Foundation
import UIKit

/// Stores images (frame artwork, captured wall photos, and AI renders) in the
/// app's Documents directory and hands back stable filenames to persist.
enum PhotoStore {

    // MARK: Frame artwork (kept for backward compatibility)

    static func saveImageData(_ data: Data, for id: UUID) throws -> String {
        guard let image = UIImage(data: data) else {
            throw PhotoStoreError.invalidImage
        }
        return try save(image, filename: "\(id.uuidString).jpg")
    }

    // MARK: General image saving

    /// Persist a UIImage and return the generated filename.
    @discardableResult
    static func save(_ image: UIImage, filename: String = "\(UUID().uuidString).jpg", quality: CGFloat = 0.9) throws -> String {
        guard let jpeg = image.jpegData(compressionQuality: quality) else {
            throw PhotoStoreError.invalidImage
        }
        let url = try imageDirectory().appendingPathComponent(filename)
        try jpeg.write(to: url, options: [.atomic])
        return filename
    }

    /// Persist raw image data (e.g. from the camera or an AI response).
    @discardableResult
    static func saveData(_ data: Data, filename: String = "\(UUID().uuidString).jpg") throws -> String {
        guard let image = UIImage(data: data) else {
            throw PhotoStoreError.invalidImage
        }
        return try save(image, filename: filename)
    }

    // MARK: Reading

    static func image(named filename: String?) -> UIImage? {
        guard let filename else { return nil }
        do {
            let url = try imageDirectory().appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return UIImage(contentsOfFile: url.path)
        } catch {
            return nil
        }
    }

    static func data(named filename: String?) -> Data? {
        guard let filename else { return nil }
        do {
            let url = try imageDirectory().appendingPathComponent(filename)
            return try? Data(contentsOf: url)
        }
    }

    // MARK: Deleting

    static func delete(_ filename: String?) {
        guard let filename else { return }
        if let url = try? imageDirectory().appendingPathComponent(filename) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: Location

    private static func imageDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("FrameImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

enum PhotoStoreError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "The selected file could not be converted into an image."
    }
}
