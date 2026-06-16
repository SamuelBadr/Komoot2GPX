import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.tintColor = UIColor.systemGreen
        view.image = UIImage(systemName: "arrow.down.circle.fill")
        view.accessibilityLabel = "Download progress"
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Downloading..."
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.accessibilityTraits = .header
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Fetching tour"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 2
        label.accessibilityTraits = .updatesFrequently
        return label
    }()
    
    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progress = 0
        view.trackTintColor = UIColor.systemGray4
        view.progressTintColor = UIColor.systemGreen
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = UIColor.systemGreen
        view.hidesWhenStopped = true
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task { await handleSharedContent() }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(progressView)
        stackView.addArrangedSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            
            activityIndicator.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        activityIndicator.startAnimating()
        animateIcon()
    }
    
    private func animateIcon() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.08, 1.0]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        iconView.layer.add(animation, forKey: "pulse")
    }
    
    // MARK: - Content Handling
    
    private func handleSharedContent() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            await MainActor.run { showError("No content shared") }
            return
        }
        
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                await handleURL(attachment)
                return
            }
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                await handleText(attachment)
                return
            }
        }
        
        await MainActor.run { showError("No URL found") }
    }
    
    private func handleURL(_ attachment: NSItemProvider) async {
        do {
            let item = try await attachment.loadItem(forTypeIdentifier: UTType.url.identifier)
            if let url = item as? URL {
                await downloadGPX(from: url.absoluteString)
                return
            }
        } catch {}
        await MainActor.run { showError("Could not read URL") }
    }
    
    private func handleText(_ attachment: NSItemProvider) async {
        do {
            let item = try await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier)
            if let text = item as? String {
                await downloadGPX(from: text)
                return
            }
        } catch {}
        await MainActor.run { showError("Could not read text") }
    }
    
    // MARK: - Download
    
    private func downloadGPX(from urlString: String) async {
        guard urlString.contains("komoot.com") else {
            await MainActor.run { showError("Not a Komoot URL") }
            return
        }
        
        guard let cleanURL = KomootURLNormalizer.normalize(urlString) else {
            await MainActor.run { showError("Invalid Komoot URL") }
            return
        }
        
        await updateStatus("Fetching tour...", progress: 0.2)
        
        do {
            let tour = try await KomootDownloader.downloadTour(from: cleanURL)
            
            await updateStatus("Building GPX...", progress: 0.5)
            let gpx = GPXBuilder.buildGPX(name: tour.name, coordinates: tour.coordinates)
            
            await updateStatus("Saving...", progress: 0.8)
            
            let fileManager = FileManager.default
            let sanitizedName = tour.name
                .replacingOccurrences(of: "/", with: "-")
                .components(separatedBy: CharacterSet(charactersIn: "<>:\"\\|?*"))
                .joined(separator: "_")
                .trimmingCharacters(in: .whitespaces)
            
            let tourID = KomootURLNormalizer.extractTourID(from: cleanURL) ?? UUID().uuidString
            let filename = "\(tourID)_\(sanitizedName).gpx"
            
            var saved = false
            
            if let sharedURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.komoot2gpx.app") {
                let fileURL = sharedURL.appendingPathComponent(filename)
                try? gpx.write(to: fileURL, atomically: true, encoding: .utf8)
                if fileManager.fileExists(atPath: fileURL.path) {
                    saved = true
                }
            }
            
            if !saved, let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docsURL.appendingPathComponent(filename)
                try? gpx.write(to: fileURL, atomically: true, encoding: .utf8)
                if fileManager.fileExists(atPath: fileURL.path) {
                    saved = true
                }
            }
            
            if saved {
                await showSuccess(tour.name)
                try await Task.sleep(nanoseconds: 1_200_000_000)
            } else {
                await updateStatus("Save failed", progress: 0)
                try await Task.sleep(nanoseconds: 1_500_000_000)
            }
            
            await MainActor.run {
                extensionContext?.completeRequest(returningItems: nil)
            }
            
        } catch let error as KomootError {
            await MainActor.run { showError(error.localizedDescription) }
        } catch {
            await MainActor.run { showError(error.localizedDescription) }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateStatus(_ message: String, progress: Float) async {
        await MainActor.run {
            withAnimation {
                self.statusLabel.text = message
                self.progressView.setProgress(progress, animated: true)
            }
        }
    }
    
    private func showSuccess(_ tourName: String) async {
        await MainActor.run {
            activityIndicator.stopAnimating()
            progressView.isHidden = true
            statusLabel.isHidden = true
            
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = UIColor.systemGreen
            
            titleLabel.text = "Saved!"
            
            iconView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8) {
                self.iconView.transform = .identity
            }
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func showError(_ message: String) {
        activityIndicator.stopAnimating()
        progressView.isHidden = true
        
        iconView.image = UIImage(systemName: "exclamationmark.circle.fill")
        iconView.tintColor = UIColor.systemRed
        
        titleLabel.text = "Failed"
        titleLabel.textColor = UIColor.systemRed
        statusLabel.text = message
        statusLabel.textColor = UIColor.systemRed
        statusLabel.isHidden = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}

// MARK: - Animation Helper

extension ShareViewController {
    private func withAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            animations()
        }
    }
}
