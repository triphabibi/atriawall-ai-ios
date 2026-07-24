import SwiftUI

#if canImport(ARKit)
import ARKit
import SceneKit
#endif

struct ARPreviewView: View {
    var project: WallProject

    var body: some View {
        ZStack {
            arSurface

            VStack {
                overlayHeader
                Spacer()
                ARLayoutOverlay(project: project)
                    .frame(height: 190)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
    }

    @ViewBuilder
    private var arSurface: some View {
        #if canImport(ARKit)
        if ARWorldTrackingConfiguration.isSupported {
            ARWallCameraView()
                .ignoresSafeArea()
        } else {
            unsupportedSurface
        }
        #else
        unsupportedSurface
        #endif
    }

    private var unsupportedSurface: some View {
        LinearGradient(
            colors: [Color.atriaInk, Color.atriaBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var overlayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AR Wall Preview")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Point at a vertical wall and align the overlay before hanging.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
            }
            Spacer()
            Image(systemName: "arkit")
                .font(.title2)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.62), .black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct ARLayoutOverlay: View {
    var project: WallProject

    var body: some View {
        GeometryReader { geometry in
            let layout = AROverlayLayout.layout(for: project, in: geometry.size)
            AROverlayCanvas(project: project, layout: layout)
        }
        .padding(12)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topLeading) {
            Label("Scale overlay", systemImage: "viewfinder")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(10)
        }
    }
}

private struct AROverlayCanvas: View {
    var project: WallProject
    var layout: AROverlayLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.54), lineWidth: 1)
                )

            ForEach(project.frames) { frame in
                ARFramePreview(frame: frame, layout: layout)
            }
        }
        .frame(width: layout.wallSize.width, height: layout.wallSize.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ARFramePreview: View {
    var frame: FrameItem
    var layout: AROverlayLayout

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color(hex: frame.frameColorHex).opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(hex: frame.artColorHex).opacity(0.9))
                    .padding(5)
            )
            .frame(width: CGFloat(frame.width * layout.scale), height: CGFloat(frame.height * layout.scale))
            .position(
                x: CGFloat((frame.x + frame.width / 2) * layout.scale),
                y: CGFloat((frame.y + frame.height / 2) * layout.scale)
            )
            .rotationEffect(.degrees(frame.rotation))
    }
}

struct AROverlayLayout {
    let scale: Double
    let wallSize: CGSize

    static func layout(for project: WallProject, in size: CGSize) -> AROverlayLayout {
        let widthScale = max(24, size.width - 32) / CGFloat(project.wallWidth)
        let heightScale = max(24, size.height - 28) / CGFloat(project.wallHeight)
        let scale = min(Double(widthScale), Double(heightScale))
        let wallSize = CGSize(width: CGFloat(project.wallWidth * scale), height: CGFloat(project.wallHeight * scale))
        return AROverlayLayout(scale: scale, wallSize: wallSize)
    }
}

#if canImport(ARKit)
private struct ARWallCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.scene = SCNScene()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        view.session.run(configuration)
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
#endif
