import SwiftUI
import PDFKit

struct DocumentPreviewView: View {
    let document: Document
    let projectId: UUID
    let onDelete: (Document) -> Void
    let onRename: (Document, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showRenameAlert = false
    @State private var newName = ""

    private let analytics = AnalyticsService.shared

    private var documentURL: URL {
        DocumentService.shared.getDocumentURL(fileName: document.fileName, projectId: projectId)
    }

    var body: some View {
        NavigationStack {
            Group {
                if document.isPDF {
                    PDFViewerView(url: documentURL)
                } else if document.isImage {
                    ImageViewerView(url: documentURL)
                } else {
                    unsupportedView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(document.displayName)
                            .font(.headline)
                            .lineLimit(1)

                        if document.name != nil, !document.name!.isEmpty {
                            Text(document.fileName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.close")) { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label(L("document.action.share"), systemImage: "square.and.arrow.up")
                        }

                        Button {
                            newName = document.name ?? ""
                            showRenameAlert = true
                        } label: {
                            Label(L("document.action.rename"), systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("document_preview")
            }
            .sheet(isPresented: $showShareSheet) {
                DocumentShareSheet(activityItems: [documentURL])
            }
            .alert(L("document.delete.title"), isPresented: $showDeleteConfirmation) {
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("button.delete"), role: .destructive) {
                    onDelete(document)
                    dismiss()
                }
            } message: {
                Text(L("document.delete.message"))
            }
            .alert(L("document.rename.title"), isPresented: $showRenameAlert) {
                TextField(L("document.rename.placeholder"), text: $newName)
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("button.save")) {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onRename(document, trimmed.isEmpty ? nil : trimmed)
                }
            } message: {
                Text(L("document.rename.message"))
            }
        }
    }

    // MARK: - Unsupported

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(L("document.preview.unsupported"))
                .font(.headline)
                .foregroundColor(.secondary)

            Button {
                showShareSheet = true
            } label: {
                Label(L("document.action.open_in"), systemImage: "arrow.up.forward.app")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - PDF Viewer

struct PDFViewerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Image Viewer

struct ImageViewerView: View {
    let url: URL

    @State private var uiImage: UIImage?
    @State private var isImageLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation { scale = 1.0 }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else if isImageLoading {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L("document.preview.image_error"))
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color.black)
        .task(id: url) {
            isImageLoading = true
            if let data = await loadImageData() {
                uiImage = UIImage(data: data)
            } else {
                uiImage = nil
            }
            isImageLoading = false
        }
    }

    private func loadImageData() async -> Data? {
        await Task.detached(priority: .userInitiated) {
            try? Data(contentsOf: url)
        }.value
    }
}

// MARK: - Share Sheet

struct DocumentShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
