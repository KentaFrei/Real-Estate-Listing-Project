import UIKit
import AVFoundation
import CoreMotion
import CoreImage

class GuidedCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?  
    private let motionManager = CMMotionManager()
    private var referenceYaw: Double?
    private let targetAngleStep = Double.pi / 12 // 15°
    private var nextTargetAngle: Double = 0
    private var isCapturing = false
    private var retryCount = 0

    private let progressCircle = CircularProgressView()
    private let ghostPreview = UIImageView()

    private var stitchedImages: [UIImage] = []
    private let propertyID: Int
    private let expectedShots = 24
    
    private let sharpnessThreshold: Double = 100.0

    // 🔄 Spinner per stitching
    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let shotCounterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let closeImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        btn.setImage(closeImage, for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Init
    init(propertyID: Int) {
        self.propertyID = propertyID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non implementato, usa init(propertyID:)")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLoadingIndicator()
        setupShotCounter()
        setupCancelButton()
        checkPermissionsAndSetup()
        updateShotCounter()

        print("📌 GuidedCaptureViewController avviato con propertyID =", propertyID)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSessionAndMotion()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            startMotionUpdates()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Setup
    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.setupCaptureSession() : self?.showPermissionDeniedAlert()
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }

    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            showCameraErrorAlert()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(preview, at: 0)
            self.previewLayer = preview

            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            startMotionUpdates()
        } catch {
            captureSession.commitConfiguration()
            showCameraErrorAlert()
        }
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        ghostPreview.contentMode = .scaleAspectFill
        ghostPreview.alpha = 0.25
        ghostPreview.isUserInteractionEnabled = false
        ghostPreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ghostPreview)
        
        NSLayoutConstraint.activate([
            ghostPreview.topAnchor.constraint(equalTo: view.topAnchor),
            ghostPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ghostPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ghostPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        progressCircle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressCircle)
        
        NSLayoutConstraint.activate([
            progressCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressCircle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressCircle.widthAnchor.constraint(equalToConstant: 100),
            progressCircle.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupShotCounter() {
        view.addSubview(shotCounterLabel)
        NSLayoutConstraint.activate([
            shotCounterLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            shotCounterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shotCounterLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            shotCounterLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupCancelButton() {
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 40),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    }
    
    @objc private func handleCancel() {
        let alert = UIAlertController(
            title: "Annullare la cattura?",
            message: "Le foto scattate andranno perse.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continua", style: .cancel))
        alert.addAction(UIAlertAction(title: "Annulla", style: .destructive) { [weak self] _ in
            self?.stopSessionAndMotion()
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func updateShotCounter() {
        shotCounterLabel.text = "  \(stitchedImages.count)/\(expectedShots)  "
    }

    // MARK: - Motion
    private func startMotionUpdates() {
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, _) in
            guard let self = self, let attitude = motion?.attitude else { return }

            if self.referenceYaw == nil {
                self.referenceYaw = attitude.yaw
                self.nextTargetAngle = self.normalizeAngle(attitude.yaw + self.targetAngleStep)
            }

            let delta = self.angleDifference(attitude.yaw, self.nextTargetAngle)
            let progress = min(1.0, max(0.0, 1.0 - abs(delta) / (self.targetAngleStep)))
            self.progressCircle.setProgress(CGFloat(progress))

            if abs(delta) < 0.05 && !self.isCapturing {
                self.isCapturing = true
                self.captureSinglePhoto()
            }
        }
    }

    // MARK: - Capture
    private func captureSinglePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        if photoOutput.supportedFlashModes.contains(.off) {
            settings.flashMode = .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("❌ Errore scatto: \(error.localizedDescription)")
            isCapturing = false
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            isCapturing = false
            return
        }

        if !IsImageSharp(image, sharpnessThreshold) {
            if retryCount < 2 {
                retryCount += 1
                print("⚠️ Foto sfocata, retry #\(retryCount)")
                captureSinglePhoto()
                return
            } else {
                print("❌ Foto troppo sfocata, scartata.")
                retryCount = 0
                isCapturing = false
                return
            }
        }

        retryCount = 0
        ghostPreview.image = image
        processImageForStitching(image)

        self.nextTargetAngle = self.normalizeAngle(self.nextTargetAngle + self.targetAngleStep)
        self.isCapturing = false
    }

    // MARK: - Stitching
    private func processImageForStitching(_ image: UIImage) {
        stitchedImages.append(image)
        updateShotCounter()

        if stitchedImages.count == expectedShots {
            
            motionManager.stopDeviceMotionUpdates()
            
            let imagesToStitch = self.stitchedImages
            self.stitchedImages.removeAll()
            
            let stitcher = ImageStitcher()
            stitcher.panoConfidenceThresh = 0.8
            stitcher.blendingStrength = 8
            stitcher.waveCorrection = true

            loadingIndicator.startAnimating()
            progressCircle.isHidden = true
            shotCounterLabel.isHidden = true

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let panorama = try stitcher.stitchImages(imagesToStitch)

                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        let reviewVC = PanoramaReviewViewController(propertyID: self.propertyID,
                                                                    panorama: panorama)
                        self.navigationController?.pushViewController(reviewVC, animated: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        self.progressCircle.isHidden = false
                        self.shotCounterLabel.isHidden = false
                        
                        let alert = UIAlertController(
                            title: "Errore",
                            message: "Impossibile creare il panorama: \(error.localizedDescription). Riprova.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.referenceYaw = nil
                            self.updateShotCounter()
                            self.startMotionUpdates()
                        })
                        self.present(alert, animated: true)
                        
                        print("❌ Errore stitching: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func stopSessionAndMotion() {
        captureSession.stopRunning()
        motionManager.stopDeviceMotionUpdates()
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permessi necessari",
            message: "Abilita la fotocamera nelle impostazioni.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        present(alert, animated: true)
    }

    private func showCameraErrorAlert() {
        let alert = UIAlertController(
            title: "Errore fotocamera",
            message: "Impossibile accedere alla fotocamera.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized < -Double.pi { normalized += 2 * Double.pi }
        while normalized > Double.pi { normalized -= 2 * Double.pi }
        return normalized
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        return normalizeAngle(b - a)
    }
}











