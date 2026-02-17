import os
import SwiftUI
import UIKit

/// Entry point for the CreativityHub Share Extension.
/// Parses shared content and presents the share form.
class ShareViewController: UIViewController {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "ShareExtension"
    )
    private let inputParser = InputParser()
    private var viewModel: ShareFormViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        logger.info("ShareExtension launched")
        parseAndPresent()
    }

    private func parseAndPresent() {
        guard let extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem],
              !inputItems.isEmpty
        else {
            dismiss(error: L("share.error.unsupported"))
            return
        }

        Task { [weak self] in
            guard let self else { return }

            guard let input = await inputParser.parse(inputItems: inputItems) else {
                await MainActor.run {
                    self.dismiss(error: L("share.error.unsupported"))
                }
                return
            }

            let projects = DatabaseManager.shared.projectRepository?.fetchAll() ?? []

            await MainActor.run {
                let vm = ShareFormViewModel()
                vm.configure(input: input, projects: projects)
                vm.onComplete = { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil)
                }
                vm.onCancel = { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: NSError(
                        domain: "ShareExtension",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: L("share.error.cancelled")]
                    ))
                }

                self.viewModel = vm
                self.presentForm(viewModel: vm)
            }
        }
    }

    private func presentForm(viewModel: ShareFormViewModel) {
        let formView = ShareFormView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: formView)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        hostingController.didMove(toParent: self)
    }

    private func dismiss(error message: String) {
        logger.warning("ShareExtension dismissed: \(message)")
        extensionContext?.cancelRequest(withError: NSError(
            domain: "ShareExtension",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        ))
    }
}
