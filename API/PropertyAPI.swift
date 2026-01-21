import Foundation

// MARK: - Modello base conforme al JSON del backend
struct Property: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let address: String
    let price: Double
}

struct PropertyAPI {
    
    static func createProperty(title: String,
                               description: String,
                               category: String,
                               address: String,
                               price: Double,
                               completion: @escaping (Result<Int, Error>) -> Void) {
        
        let url = APIConfig.propertiesURL

        let bodyDict: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "address": address,
            "price": price
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(.failure(NSError(domain: "PropertyAPI", code: -2, 
                                       userInfo: [NSLocalizedDescriptionKey: "Errore serializzazione"])))
            return
        }

        APIClient.authorizedRequest(url: url, method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let propertyID = json["id"] as? Int,
                       propertyID > 0 {
                        completion(.success(propertyID))
                    } else {
                        completion(.failure(NSError(domain: "PropertyAPI",
                                                    code: -3,
                                                    userInfo: [NSLocalizedDescriptionKey: "ID mancante o non valido nella risposta"])))
                    }
                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func getImages(for propertyID: Int,
                          completion: @escaping (Result<[URL], Error>) -> Void) {

        guard let url = APIConfig.propertyImagesURL(id: propertyID) else {
            completion(.failure(NSError(domain: "PropertyAPI", code: -1, 
                                       userInfo: [NSLocalizedDescriptionKey: "URL non valida"])))
            return
        }

        APIClient.authorizedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        let urls: [URL] = jsonArray.compactMap { dict in
                            if let path = dict["image_url"] as? String {
                                return APIConfig.fullURL(from: path)
                            }
                            return nil
                        }
                        completion(.success(urls))
                    } else {
                        completion(.failure(NSError(domain: "PropertyAPI", code: -3, 
                                                   userInfo: [NSLocalizedDescriptionKey: "Formato JSON non valido"])))
                    }
                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func getProperties(completion: @escaping (Result<[Property], Error>) -> Void) {
        let url = APIConfig.propertiesURL
        
        APIClient.authorizedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let properties = try JSONDecoder().decode([Property].self, from: data)
                    completion(.success(properties))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func getPropertyDetails(id: Int,
                                   completion: @escaping (Result<Property, Error>) -> Void) {
        guard let url = APIConfig.propertyDetailURL(id: id) else {
            completion(.failure(NSError(domain: "PropertyAPI", code: -1, 
                                       userInfo: [NSLocalizedDescriptionKey: "URL non valida"])))
            return
        }
        
        APIClient.authorizedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let property = try JSONDecoder().decode(Property.self, from: data)
                    completion(.success(property))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}








