//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "8ffbdffcf51f26889670743cc533c307"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        //static let requestPath = "/authentication/token/new"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case getFavorites
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                completion(nil, error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
               
                    DispatchQueue.main.async {
                        completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
    }

    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, body: RequestType, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                print("data failed")
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                print("decoding failed in Login")
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        
     
        return task
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGETRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { response, error in
            if let response = response {
                    completion(response.results, nil)
            } else {
                    completion([], error)
            }
        }
    }
    
    class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) {
    
        taskForGETRequest(url: Endpoints.getFavorites.url, responseType: MovieResults.self) { response, error in
            if let response = response {
                    completion(response.results, nil)
            } else {
                    completion([], error)
            }
        }
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) {  response, error in
            if let response = response {
                Auth.requestToken = response.requestToken
                print(Auth.requestToken)
                    completion(true,nil)
            } else {
                print("decoding failed in getRequestToken")
                print(error)
                    completion(false, error)
            }
        }
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        taskForPOSTRequest(url: Endpoints.login.url, body: LoginRequest(username: username, password: password, requestToken: Auth.requestToken), responseType: RequestTokenResponse.self) { response, error in
                
            if let response = response {
                Auth.requestToken = response.requestToken
                print(Auth.requestToken)
                    completion(true, nil)
            } else {
                print("decoding failed in Login")
                print(error)
                    completion(false, error)
            }
        }
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?) -> Void) {
        taskForPOSTRequest(url: Endpoints.createSessionId.url, body: PostSession(requestToken: Auth.requestToken), responseType: SessionResponse.self) { response, error in
        
            if let response = response {
                Auth.sessionId = response.sessionId
                print(Auth.sessionId)
                    completion(true, nil)
            } else {
                print("decoding failed in Creating Session ID")
                print(error)
                    completion(false, error)
            }
        }
    }
    
    class func logout(completion: @escaping () -> Void) {
        var request = URLRequest(url: Endpoints.logout.url)
              
        request.httpMethod = "DELETE"
        let body = LogoutRequest(sessionId: Auth.sessionId)
        request.httpBody = try! JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
              
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            Auth.sessionId = ""
            Auth.requestToken = ""
            Auth.accountId = 0
            completion()
        }
        task.resume()
    }
    
    
}
