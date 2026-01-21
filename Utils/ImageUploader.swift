import UIKit

enum APIConfig {
    static let baseURL = "https://realestate360-backend-vv8d.onrender.com"
    
    static func uploadURL(for propertyID: Int) -> URL? {
        return URL(string: "\(baseURL)/api/properties/\(propertyID)/upload_image/")
    }
}

struct ImageUploader {
    
    enum ImageUploaderError: LocalizedError {
        case invalidPropertyID
        case invalidURL
        case imageConversionFailed
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidPropertyID:
                return "ID proprietà non valido."
            case .invalidURL:
                return "URL non valido."
            case .imageConversionFailed:
                return "Impossibile convertire l'immagine."
            case .invalidResponse:
                return "Risposta del server non valida."
            }
        }
    }
    
    static func upload(image: UIImage,
                       to propertyID: Int,
                       completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard propertyID > 0 else {
            completion(.failure(ImageUploaderError.invalidPropertyID))
            return
        }
        
        guard let url = APIConfig.uploadURL(for: propertyID) else {
            completion(.failure(ImageUploaderError.invalidURL))
            return
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageUploaderError.imageConversionFailed))
            return
        }

        // 🔧 Crea multipart form-data
        let boundary = UUID().uuidString
        var data = Data()

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"panorama.jpg\"\r\n")
        data.appendString("Content-Type: image/jpeg\r\n\r\n")
        data.append(jpegData)
        data.appendString("\r\n")
        data.appendString("--\(boundary)--\r\n")

        APIClient.authorizedRequest(
            url: url,
            method: "POST",
            body: data,
            contentType: "multipart/form-data; boundary=\(boundary)"
        ) { result in
            switch result {
            case .success(let responseData):
                guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                      let path = json["image_url"] as? String,
                      let imageURL = URL(string: APIConfig.baseURL + path) else {
                    completion(.failure(ImageUploaderError.invalidResponse))
                    return
                }
                completion(.success(imageURL))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}







