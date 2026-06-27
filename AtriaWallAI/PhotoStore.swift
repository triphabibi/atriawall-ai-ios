import Foundation
import UIKit

enum PhotoStore {
    static func saveImageData(_ data: Data, for id: UUID) throws -> String {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.88) else {
            throw PhotoStoreError.invalidImage
        }

        let filename = "\(id.uuidString).jpg"
        let url = try imageDirectory().appendingPathComponent(filename)
        try jpeg.write(to: url, options: [.atomic])
        return filename
    }

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
        "The selected file could not be converted into a gallery wall image."
    }
}
