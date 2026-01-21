import UIKit

final class NewPropertyViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleField = NewPropertyViewController.makeTextField(placeholder: "Titolo proprietà")
    private let descriptionField: UITextView = {
        let view = UITextView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 8
        view.font = .systemFont(ofSize: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let categoryLabel = NewPropertyViewController.makeLabel("Categoria")
    private let categorySegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Appartamento", "Casa", "Ufficio"])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private let addressField = NewPropertyViewController.makeTextField(placeholder: "Indirizzo")
    private let priceField: UITextField = {
        let field = NewPropertyViewController.makeTextField(placeholder: "Prezzo")
        field.keyboardType = .decimalPad
        return field
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scatta Foto 360°", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.color = .white
        return spinner
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Nuova Proprietà"
        
        setupLayout()
        setupKeyboardDismiss()
        continueButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    // MARK: - Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // ✅ FIX #47: Constraint corretti per lo scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Titolo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Titolo"))
        contentStack.addArrangedSubview(titleField)
        
        // Descrizione
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Descrizione"))
        contentStack.addArrangedSubview(descriptionField)
        descriptionField.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        // Categoria
        contentStack.addArrangedSubview(categoryLabel)
        contentStack.addArrangedSubview(categorySegment)
        
        // Indirizzo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Indirizzo"))
        contentStack.addArrangedSubview(addressField)
        
        // Prezzo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Prezzo"))
        contentStack.addArrangedSubview(priceField)
        
        // Spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(spacer)
        
        // Bottone
        contentStack.addArrangedSubview(continueButton)
        continueButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @objc private func handleSave() {
        dismissKeyboard()
        
        guard let title = titleField.text, !title.isEmpty,
              let description = descriptionField.text, !description.isEmpty,
              let address = addressField.text, !address.isEmpty,
              let priceText = priceField.text, let price = Double(priceText) else {
            showAlert(title: "Errore", message: "Completa tutti i campi.")
            return
        }
        
        let category = categorySegment.titleForSegment(at: categorySegment.selectedSegmentIndex) ?? "Altro"
        
        // Mostra stato loading
        setLoadingState(true)
        
        PropertyAPI.createProperty(title: title,
                                   description: description,
                                   category: category,
                                   address: address,
                                   price: price) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoadingState(false)
                
                switch result {
                case .success(let propertyID):
                    print("✅ Proprietà salvata con ID: \(propertyID)")
                    let guidedVC = GuidedCaptureViewController(propertyID: propertyID)
                    self?.navigationController?.pushViewController(guidedVC, animated: true)
                    
                case .failure(let error):
                    self?.showAlert(title: "Errore", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func setLoadingState(_ loading: Bool) {
        continueButton.isEnabled = !loading
        
        if loading {
            continueButton.setTitle("", for: .normal)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            continueButton.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor)
            ])
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            continueButton.setTitle("Scatta Foto 360°", for: .normal)
        }
    }
    
    // MARK: - Helpers
    private static func makeTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }
    
    private static func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
    }
}




