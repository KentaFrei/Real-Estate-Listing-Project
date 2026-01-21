import UIKit

final class DashboardViewController: UIViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Dashboard"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let addPropertyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Aggiungi Immobile", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let propertiesCard = DashboardCard(title: "Immobili Pubblicati", value: "-")
    private let inquiriesCard  = DashboardCard(title: "Richieste",           value: "-")
    private let viewsCard      = DashboardCard(title: "Visualizzazioni",     value: "-")
    
    private let loginPromptView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 14
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let loginPromptLabel: UILabel = {
        let label = UILabel()
        label.text = "Accedi per vedere le tue statistiche e pubblicare immobili"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginPromptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accedi", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        addPropertyButton.addTarget(self, action: #selector(openAddProperty), for: .touchUpInside)
        loginPromptButton.addTarget(self, action: #selector(openLogin), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForAuthState()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(addPropertyButton)
        view.addSubview(propertiesCard)
        view.addSubview(inquiriesCard)
        view.addSubview(viewsCard)
        view.addSubview(loginPromptView)
        
        loginPromptView.addSubview(loginPromptLabel)
        loginPromptView.addSubview(loginPromptButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addPropertyButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            addPropertyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addPropertyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addPropertyButton.heightAnchor.constraint(equalToConstant: 52),

            propertiesCard.topAnchor.constraint(equalTo: addPropertyButton.bottomAnchor, constant: 28),
            propertiesCard.leadingAnchor.constraint(equalTo: addPropertyButton.leadingAnchor),
            propertiesCard.trailingAnchor.constraint(equalTo: addPropertyButton.trailingAnchor),
            propertiesCard.heightAnchor.constraint(equalToConstant: 84),

            inquiriesCard.topAnchor.constraint(equalTo: propertiesCard.bottomAnchor, constant: 16),
            inquiriesCard.leadingAnchor.constraint(equalTo: propertiesCard.leadingAnchor),
            inquiriesCard.trailingAnchor.constraint(equalTo: propertiesCard.trailingAnchor),
            inquiriesCard.heightAnchor.constraint(equalTo: propertiesCard.heightAnchor),

            viewsCard.topAnchor.constraint(equalTo: inquiriesCard.bottomAnchor, constant: 16),
            viewsCard.leadingAnchor.constraint(equalTo: inquiriesCard.leadingAnchor),
            viewsCard.trailingAnchor.constraint(equalTo: inquiriesCard.trailingAnchor),
            viewsCard.heightAnchor.constraint(equalTo: propertiesCard.heightAnchor),
            
            // Login prompt
            loginPromptView.topAnchor.constraint(equalTo: addPropertyButton.bottomAnchor, constant: 28),
            loginPromptView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginPromptView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            loginPromptLabel.topAnchor.constraint(equalTo: loginPromptView.topAnchor, constant: 20),
            loginPromptLabel.leadingAnchor.constraint(equalTo: loginPromptView.leadingAnchor, constant: 16),
            loginPromptLabel.trailingAnchor.constraint(equalTo: loginPromptView.trailingAnchor, constant: -16),
            
            loginPromptButton.topAnchor.constraint(equalTo: loginPromptLabel.bottomAnchor, constant: 12),
            loginPromptButton.centerXAnchor.constraint(equalTo: loginPromptView.centerXAnchor),
            loginPromptButton.bottomAnchor.constraint(equalTo: loginPromptView.bottomAnchor, constant: -16)
        ])
    }
    
    private func updateUIForAuthState() {
        let isLoggedIn = UserDefaults.standard.string(forKey: "authToken") != nil
        
        propertiesCard.isHidden = !isLoggedIn
        inquiriesCard.isHidden = !isLoggedIn
        viewsCard.isHidden = !isLoggedIn
        loginPromptView.isHidden = isLoggedIn
        
        if isLoggedIn {
            // TODO: Caricare statistiche reali dal backend
            // Per ora mostriamo placeholder
        }
    }

    // ✅ NUOVO: Controlla se l'utente è loggato prima di permettere la pubblicazione
    @objc private func openAddProperty() {
        if UserDefaults.standard.string(forKey: "authToken") != nil {
            // ✅ Utente loggato → procedi con la creazione
            let newPropertyVC = NewPropertyViewController()
            navigationController?.pushViewController(newPropertyVC, animated: true)
        } else {
            // ❌ Utente non loggato → chiedi login
            showLoginRequired()
        }
    }
    
    private func showLoginRequired() {
        let alert = UIAlertController(
            title: "Login Richiesto",
            message: "Devi accedere per pubblicare un immobile.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Accedi", style: .default) { [weak self] _ in
            self?.presentLoginForPublishing()
        })
        
        alert.addAction(UIAlertAction(title: "Registrati", style: .default) { [weak self] _ in
            self?.presentRegisterForPublishing()
        })
        
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentLoginForPublishing() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .pageSheet
        
        loginVC.onLoginSuccess = { [weak self] in
            let newPropertyVC = NewPropertyViewController()
            self?.navigationController?.pushViewController(newPropertyVC, animated: true)
        }
        
        present(loginVC, animated: true)
    }
    
    private func presentRegisterForPublishing() {
        let registerVC = RegisterViewController()
        registerVC.modalPresentationStyle = .pageSheet
        
        registerVC.onRegisterSuccess = { [weak self] in
            let newPropertyVC = NewPropertyViewController()
            self?.navigationController?.pushViewController(newPropertyVC, animated: true)
        }
        
        present(registerVC, animated: true)
    }
    
    @objc private func openLogin() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .pageSheet
        
        loginVC.onLoginSuccess = { [weak self] in
            self?.updateUIForAuthState()
        }
        
        present(loginVC, animated: true)
    }
}

// MARK: - Reusable Card
final class DashboardCard: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
