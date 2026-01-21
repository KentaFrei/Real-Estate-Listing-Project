import Foundation
import UIKit

enum APIClient {
    
    // MARK: - Authorized Request
    static func authorizedRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        contentType: String? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Usa Content-Type custom se fornito, altrimenti default a JSON
        if let customContentType = contentType {
            request.setValue(customContentType, forHTTPHeaderField: "Content-Type")
        } else if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.httpBody = body

        // Se esiste un token, usalo
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        } else {
            #if DEBUG
            print("⚠️ Nessun token trovato → procedo senza Authorization (modalità test)")
            #endif
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Gestione 401 - Unauthorized
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    logoutAndReturnToLogin()
                    return
                }

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }

                completion(.success(data))
            }
        }.resume()
    }
    
    // MARK: - Error Types
    enum APIError: LocalizedError {
        case noData
        case unauthorized
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .noData:
                return "Nessun dato ricevuto dal server."
            case .unauthorized:
                return "Sessione scaduta. Effettua nuovamente l'accesso."
            case .serverError(let code):
                return "Errore del server (codice \(code))."
            }
        }
    }
    
    private static func logoutAndReturnToLogin() {
        UserDefaults.standard.removeObject(forKey: "authToken")

        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene.delegate as? SceneDelegate else { 
            return 
        }

        let loginVC = LoginViewController()

        sceneDelegate.window?.rootViewController = loginVC
        sceneDelegate.window?.makeKeyAndVisible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let alert = UIAlertController(
                title: "Sessione scaduta",
                message: "La sessione è terminata. Effettua di nuovo l'accesso.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            loginVC.present(alert, animated: true)
        }
    }
}







