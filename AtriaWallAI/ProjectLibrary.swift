import Foundation
import Combine

@MainActor
final class ProjectLibrary: ObservableObject {
    @Published var projects: [WallProject] {
        didSet { save() }
    }

    @Published var selectedProjectID: WallProject.ID? {
        didSet { saveSelectedProjectID() }
    }

    private let projectsKey = "atriawall.projects.v1"
    private let selectedKey = "atriawall.selectedProjectID.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder.appDecoder.decode([WallProject].self, from: data),
           !decoded.isEmpty {
            projects = decoded
        } else {
            projects = WallProject.sampleProjects
        }

        if let idString = UserDefaults.standard.string(forKey: selectedKey),
           let id = UUID(uuidString: idString),
           projects.contains(where: { $0.id == id }) {
            selectedProjectID = id
        } else {
            selectedProjectID = projects.first?.id
        }
    }

    var selectedProject: WallProject? {
        guard let selectedProjectID else { return projects.first }
        return projects.first(where: { $0.id == selectedProjectID }) ?? projects.first
    }

    func createProject() {
        let project = WallProject(
            name: "New Gallery Wall",
            room: "Living Room",
            style: "Warm modern",
            wallWidth: 144,
            wallHeight: 96,
            frames: []
        )
        projects.insert(project, at: 0)
        selectedProjectID = project.id
    }

    func duplicateSelectedProject() {
        guard var project = selectedProject else { return }
        project.id = UUID()
        project.name += " Copy"
        project.frames = project.frames.map { frame in
            var copy = frame
            copy.id = UUID()
            return copy
        }
        project.touch()
        projects.insert(project, at: 0)
        selectedProjectID = project.id
    }

    func delete(_ project: WallProject) {
        guard projects.count > 1 else { return }
        projects.removeAll { $0.id == project.id }
        if selectedProjectID == project.id {
            selectedProjectID = projects.first?.id
        }
    }

    private func save() {
        guard let data = try? JSONEncoder.appEncoder.encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: projectsKey)
    }

    private func saveSelectedProjectID() {
        UserDefaults.standard.set(selectedProjectID?.uuidString, forKey: selectedKey)
    }
}

extension JSONEncoder {
    static var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
