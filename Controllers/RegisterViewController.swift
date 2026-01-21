isterviewcontroller · SWIFT
Copia

import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    var onRegisterSuccess: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Registrati"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Crea un account per pubblicare immobili"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.keyboardType = .emailAddress
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let usernameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Password"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Crea account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Hai già un account? Accedi", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.color = .white
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupFieldListeners()
        
        registerButton.addTarget(self, action: #selector(registerUser), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(openLogin), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailField)
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        view.addSubview(registerButton)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Email
            emailField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailField.heightAnchor.constraint(equalToConstant: 50),
            
            // Username
            usernameField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            usernameField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            usernameField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            usernameField.heightAnchor.constraint(equalToConstant: 50),

            // Password
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 50),

            // Register button
            registerButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 30),
            registerButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            registerButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            registerButton.heightAnchor.constraint(equalToConstant: 50),

            // Login button
            loginButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 16),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupFieldListeners() {
        [emailField, usernameField, passwordField].forEach {
            $0.addTarget(self, action: #selector(validateFields), for: .editingChanged)
        }
    }

    @objc private func validateFields() {
        let isValid = !(emailField.text?.isEmpty ?? true) &&
                      !(usernameField.text?.isEmpty ?? true) &&
                      !(passwordField.text?.isEmpty ?? true)

        registerButton.isEnabled = isValid
        registerButton.alpha = isValid ? 1.0 : 0.5
    }

    @objc private func registerUser() {
        view.endEditing(true)
        
        guard let email = emailField.text, !email.isEmpty,
              let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert("Compila tutti i campi")
            return
        }
        
        setLoadingState(true)

        let params = [
            "email": email,
            "username": username,
            "password": password
        ]

        let url = APIConfig.registerURL

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            setLoadingState(false)
            showAlert("Errore nella richiesta")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.setLoadingState(false)
                    self.showAlert("Errore: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.setLoadingState(false)
                    self.showAlert("Nessuna risposta dal server")
                    return
                }

                if httpResponse.statusCode == 201 {
                    self.handleSuccessfulRegistration(username: username, password: password)
                } else {
                    self.setLoadingState(false)
                    self.showAlert("Registrazione fallita. Codice: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    private func setLoadingState(_ loading: Bool) {
        registerButton.isEnabled = !loading
        loginButton.isEnabled = !loading
        emailField.isEnabled = !loading
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading
        
        if loading {
            registerButton.setTitle("", for: .normal)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            registerButton.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: registerButton.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: registerButton.centerYAnchor)
            ])
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            registerButton.setTitle("Crea account", for: .normal)
            validateFields()
        }
    }
    
    private func handleSuccessfulRegistration(username: String, password: String) {
        AuthAPI.login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setLoadingState(false)
                
                switch result {
                case .success(let token):
                    UserDefaults.standard.set(token, forKey: "authToken")
                    
                    // ✅ NUOVA LOGICA: Controlla se c'è un callback
                    if let callback = self.onRegisterSuccess {
                        // Chiudi tutte le modali e esegui callback
                        self.dismiss(animated: true) {
                            // Se c'è un altro VC presentante (LoginVC), chiudi anche quello
                            if let presentingVC = self.presentingViewController {
                                presentingVC.dismiss(animated: false) {
                                    callback()
                                }
                            } else {
                                callback()
                            }
                        }
                    } else {
                        // Mostra welcome e vai alla home
                        self.showWelcomeAndDismiss()
                    }

                case .failure(let loginError):
                    self.showAlert("Registrato ma login fallito: \(loginError.localizedDescription)")
                }
            }
        }
    }
    
    private func showWelcomeAndDismiss() {
        let alert = UIAlertController(title: "Benvenuto! 🎉", message: "Account creato con successo.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func handleClose() {
        dismiss(animated: true)
    }
    
    @objc private func openLogin() {
        // Torna al login
        dismiss(animated: true)
    }

    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

