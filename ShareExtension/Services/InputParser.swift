import Foundation
import os
import UniformTypeIdentifiers

/// Parses NSExtensionItem attachments into a normalized SharedInput model.
final class InputParser {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "InputParser"
    )

    /// Parse extension input items into a SharedInput.
    /// Returns nil if no supported content was found.
    func parse(inputItems: [NSExtensionItem]) async -> SharedInput? {
        var extractedURL: URL?
        var extractedText: String?
        var extractedImageURL: URL?
        var extractedTitle: String?
        var extractedFilename: String?

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            if let attributedText = item.attributedContentText {
                extractedTitle = attributedText.string
            }

            for provider in attachments {
                // 1. Try image first (most specific)
                if let imageURL = await extractImage(from: provider) {
                    extractedImageURL = imageURL
                    extractedFilename = imageURL.lastPathComponent
                    continue
                }

                // 2. Try URL
                if let url = await extractURL(from: provider) {
                    extractedURL = url
                    continue
                }

                // 3. Try plain text
                if let text = await extractText(from: provider) {
                    extractedText = text
                }
            }
        }

        // Build SharedInput based on what was extracted, in priority order
        if let imageURL = extractedImageURL {
            return SharedInput(
                kind: .image,
                imageFileURL: imageURL,
                suggestedTitle: extractedFilename.map { filenameWithoutExtension($0) },
                originalFilename: extractedFilename
            )
        }

        if let url = extractedURL {
            let title = extractedTitle ?? url.host
            let snippet = extractedText != url.absoluteString ? extractedText : nil
            return SharedInput(
                kind: .link,
                url: url,
                text: extractedText,
                suggestedTitle: title,
                suggestedSnippet: snippet
            )
        }

        if let text = extractedText, !text.isEmpty {
            // Check if the text itself is a URL
            if let detectedURL = detectURL(in: text) {
                return SharedInput(
                    kind: .link,
                    url: detectedURL,
                    text: text,
                    suggestedTitle: detectedURL.host,
                    suggestedSnippet: text
                )
            }

            return SharedInput(
                kind: .text,
                text: text,
                suggestedTitle: extractFirstLine(from: text),
                suggestedSnippet: text
            )
        }

        logger.warning("No supported content found in shared items")
        return nil
    }

    // MARK: - Extraction Helpers

    private func extractURL(from provider: NSItemProvider) async -> URL? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: item as? URL)
            }
        }
    }

    private func extractText(from provider: NSItemProvider) async -> String? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: item as? String)
            }
        }
    }

    private func extractImage(from provider: NSItemProvider) async -> URL? {
        let imageTypes = [
            UTType.jpeg.identifier,
            UTType.png.identifier,
            UTType.heic.identifier,
            UTType.image.identifier,
        ]

        for typeIdentifier in imageTypes {
            guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
                continue
            }

            let result: URL? = await withCheckedContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                    guard let url, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        continuation.resume(returning: tempURL)
                    } catch {
                        continuation.resume(returning: nil)
                    }
                }
            }

            if result != nil {
                return result
            }
        }

        return nil
    }

    // MARK: - Utilities

    private func detectURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = detector.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text)
        else {
            return nil
        }

        return URL(string: String(text[matchRange]))
    }

    private func extractFirstLine(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }

    private func filenameWithoutExtension(_ filename: String) -> String {
        let url = URL(fileURLWithPath: filename)
        return url.deletingPathExtension().lastPathComponent
    }
}
