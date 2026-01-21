import UIKit
import SceneKit

class PanoramaViewerViewController: UIViewController {
    
    // MARK: - Properties
    private var sceneView: SCNView!
    private var cameraNode = SCNNode()
    
    var panoramaImageURL: URL?
    
    var showCloseButton: Bool = true
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private var closeButton: UIButton?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScene()
        setupCamera()
        setupLoadingIndicator()
        
        if showCloseButton {
            addCloseButton()
        }
        
        loadPanoramaFromURL()
    }
    
    // MARK: - Setup
    private func setupScene() {
        sceneView = SCNView(frame: view.bounds)
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        view.addSubview(sceneView)
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 80
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
    }
    
    private func loadPanoramaFromURL() {
        guard let url = panoramaImageURL else {
            loadingIndicator.stopAnimating()
            showError("Nessun URL panorama specificato.")
            return
        }
        
        // Determina se è un file locale o remoto
        if url.isFileURL {
            loadLocalFile(url: url)
        } else {
            loadRemoteFile(url: url)
        }
    }
    
    private func loadLocalFile(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self?.loadingIndicator.stopAnimating()
                        self?.showError("Impossibile decodificare l'immagine.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.applyPanoramaTexture(image: image)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.showError("Errore nel caricamento: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadRemoteFile(url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.showError("Errore di rete: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.showError("Errore nel caricamento immagine.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.applyPanoramaTexture(image: image)
            }
        }
        task.resume()
    }
    
    private func applyPanoramaTexture(image: UIImage) {
        let sphere = SCNSphere(radius: 10)
        sphere.segmentCount = 96
        sphere.firstMaterial?.diffuse.contents = image
        sphere.firstMaterial?.isDoubleSided = true
        sphere.firstMaterial?.diffuse.wrapS = .repeat
        sphere.firstMaterial?.diffuse.wrapT = .clamp
        sphere.firstMaterial?.cullMode = .front
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.scale = SCNVector3(-1, 1, 1)
        sceneView.scene?.rootNode.addChildNode(sphereNode)
    }
    
    private func addCloseButton() {
        let buttonSize: CGFloat = 40
        let button = UIButton(type: .system)
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let closeImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(closeImage, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = buttonSize / 2
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(closeViewer), for: .touchUpInside)
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        self.closeButton = button
    }
    
    @objc private func closeViewer() {
        // Se presentato modalmente, dismetti
        if presentingViewController != nil {
            dismiss(animated: true)
        } else if let nav = navigationController {
            // Se in navigation stack, pop
            nav.popViewController(animated: true)
        } else if let parent = parent {
            // Se child VC, rimuovi
            willMove(toParent: nil)
            view.removeFromSuperview()
            removeFromParent()
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Errore",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.closeViewer()
        })
        present(alert, animated: true)
    }
}



