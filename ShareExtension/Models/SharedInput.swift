import Foundation

/// The kind of content shared to the extension.
enum SharedInputKind: String {
    case link
    case text
    case image
}

/// Normalized input model parsed from NSExtensionItem attachments.
struct SharedInput {
    let kind: SharedInputKind

    /// The shared URL (for .link kind)
    var url: URL?

    /// The shared text content (for .text kind, or page title for .link)
    var text: String?

    /// The shared image file URL in temp directory (for .image kind)
    var imageFileURL: URL?

    /// Prefill candidate for the name/title field
    var suggestedTitle: String?

    /// Prefill candidate for the notes/description field
    var suggestedSnippet: String?

    /// The original filename for images
    var originalFilename: String?
}
