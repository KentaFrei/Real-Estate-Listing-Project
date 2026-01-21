import UIKit

final class PanoramaReviewViewController: UIViewController {
    
    // MARK: - Properties
    private let propertyID: Int
    private let panorama: UIImage
    
    private var viewerVC: PanoramaViewerViewController?
    private var tempPanoramaURL: URL?
    
    private let publishButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✅ Pubblica", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemGreen
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("🔄 Rifai", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - Init
    init(propertyID: Int, panorama: UIImage) {
        self.propertyID = propertyID
        self.panorama = panorama
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) non implementato") 
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViewer()
        setupButtons()
    }
    
    deinit {
        cleanupTempFile()
    }
    
    // MARK: - Setup Viewer
    private func setupViewer() {
        let viewer = PanoramaViewerViewController()
        viewer.showCloseButton = false  
        
        let uniqueFilename = "panorama_\(UUID().uuidString).jpg"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            guard let data = panorama.jpegData(compressionQuality: 0.9) else {
                print("❌ Errore: impossibile convertire panorama in JPEG")
                showErrorAndDismiss("Impossibile elaborare il panorama.")
                return
            }
            try data.write(to: tmpURL)
            viewer.panoramaImageURL = tmpURL
            self.tempPanoramaURL = tmpURL
        } catch {
            print("❌ Errore salvataggio panorama temporaneo: \(error)")
            showErrorAndDismiss("Impossibile salvare il panorama temporaneo.")
            return
        }
        
        addChild(viewer)
        view.addSubview(viewer.view)
        viewer.view.frame = view.bounds
        viewer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewer.didMove(toParent: self)
        
        self.viewerVC = viewer
    }
    
    // MARK: - Setup Buttons
    private func setupButtons() {
        let stack = UIStackView(arrangedSubviews: [publishButton, retryButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            publishButton.heightAnchor.constraint(equalToConstant: 52),
            retryButton.heightAnchor.constraint(equalToConstant: 52),
            
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        publishButton.addTarget(self, action: #selector(handlePublish), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handlePublish() {
        // Disabilita i pulsanti durante l'upload
        publishButton.isEnabled = false
        retryButton.isEnabled = false
        
        let alert = UIAlertController(title: nil, message: "Pubblicazione in corso…", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            alert.view.heightAnchor.constraint(equalToConstant: 95),
            spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
        ])
        
        present(alert, animated: true)
        
        ImageUploader.upload(image: panorama, to: propertyID) { [weak self] result in
            guard let self = self else { return }
            
            alert.dismiss(animated: true) {
                switch result {
                case .success(_):
                    let done = UIAlertController(
                        title: "Pubblicato ✅",
                        message: "Il tour è stato caricato correttamente.",
                        preferredStyle: .alert
                    )
                    done.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(done, animated: true)
                    
                case .failure(let error):
                    self.publishButton.isEnabled = true
                    self.retryButton.isEnabled = true
                    
                    let fail = UIAlertController(
                        title: "Errore",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    fail.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(fail, animated: true)
                }
            }
        }
    }
    
    @objc private func handleRetry() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers
    private func cleanupTempFile() {
        if let url = tempPanoramaURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func showErrorAndDismiss(_ message: String) {
        let alert = UIAlertController(
            title: "Errore",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

