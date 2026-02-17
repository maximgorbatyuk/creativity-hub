import os
import UIKit

/// Entry point for the CreativityHub Share Extension.
/// Receives shared content from other apps and allows saving it as an idea or note.
class ShareViewController: UIViewController {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ShareExtension")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        logger.info("ShareExtension launched")
        setupPlaceholderUI()
    }

    private func setupPlaceholderUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "CreativityHub"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label

        let subtitle = UILabel()
        subtitle.text = "Share extension coming soon"
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(doneButton)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func didTapDone() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
