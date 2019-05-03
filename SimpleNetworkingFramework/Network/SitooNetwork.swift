//
//  SitooNetwork.swift
//  SimpleNetworkingFramework
//
//  Created by Anton Tikhonov on 2019-05-02.
//  Copyright © 2019 Anton Tikhonov. All rights reserved.
//

import Foundation

enum HttpMethod: Equatable {
    case get
    case post
    case delete
}

enum HttpRequestParameters {
    case none
    case queryItems([String: CustomStringConvertible?])
}

enum HttpRequestData {
    case none
    case json(Encodable)
    case text(String)
    case data(Data)
}

enum HttpResponseData: Equatable {
    case none
    case data(Data)
}

protocol HttpEndpoint {
    var path: String { get }
    var method: HttpMethod { get }
    var params: HttpRequestParameters { get }
    var headerFields: [String: CustomStringConvertible] { get }
    var requestData: HttpRequestData { get }
}

protocol Cancellable: AnyObject {
    func cancel()
}

enum HttpError: Error {
    case clientError(message: String?)
    case serverError(status: Int)
}

enum HttpResponse {
    case success(HttpResponseData)
    case error(HttpError)

    var succeeded: Bool {
        switch self {
        case .success: return true
        case .error: return false
        }
    }

    func map<T: Decodable>() -> T? {
        switch self {
        case .success(let data):
            switch data {
            case .data(let data):
                let decoder = JSONDecoder()
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("json decoding error: \(error)")
                    return nil
                }
            case .none:
                return nil // empty response
            }
        case .error:
            return nil
        }
    }
}

enum HttpAuthentication {
    case none
    case basic(username: String, password: String)
}

enum HttpScheme: String {
    case http
    case https
}

protocol HttpSession {
    @discardableResult
    func request(
        endpoint: HttpEndpoint,
        then: @escaping (HttpResponse) -> Void) -> Cancellable?
}

protocol HttpTransport {
    func performRequest(
        session: URLSession,
        request: URLRequest,
        then: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask
}

final class DefaultHttpSession: HttpSession {

    static var shared: HttpSession {
        return DefaultHttpSession(
            config: URLSessionConfiguration.default,
            scheme: .https,
            host: "localhost",
            port: 8082,
            authentication: .basic(username: "test", password: "test1234"),
            transport: DefaultHttpTransport())
    }

    private let config: URLSessionConfiguration
    private let scheme: HttpScheme
    private let host: String
    private let port: Int
    private let authentication: HttpAuthentication
    private let transport: HttpTransport

    private lazy var session = URLSession(configuration: config)

    init(config: URLSessionConfiguration,
         scheme: HttpScheme,
         host: String,
         port: Int,
         authentication: HttpAuthentication,
         transport: HttpTransport)
    {
        self.config = config
        self.scheme = scheme
        self.host = host
        self.port = port
        self.authentication = authentication
        self.transport = transport
    }

    @discardableResult
    func request(endpoint: HttpEndpoint, then: @escaping (HttpResponse) -> Void) -> Cancellable? {
        let completion = Common.Completion(then)

        guard
            let url = endpoint.url(
                scheme: scheme.rawValue,
                host: self.host,
                port: self.port)
        else {
            completion.complete(with:
                .error(.clientError(message: "wrong url")))
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod

        if let authHeaderField = authentication.authorizationHeaderValue {
            request.setValue(authHeaderField, forHTTPHeaderField: "Authorization")
        }
        if let contentType = endpoint.requestData.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        endpoint.headerFields.forEach { field, value in
            request.setValue(value.description, forHTTPHeaderField: field)
        }

        if let data = endpoint.requestData.data {
            request.httpBody = data
        }

        let task = transport.performRequest(session: session, request: request) { (data, response, error) in
            if let error = error {
                completion.complete(with:
                    .error(.clientError(message: error.localizedDescription)))
                return
            }

            guard
                let response = response as? HTTPURLResponse
            else {
                completion.complete(with:
                    .error(.clientError(message: "wrong response type")))
                return
            }

            guard
                case 200..<300 = response.statusCode
            else {
                completion.complete(with:
                    .error(.serverError(status: response.statusCode)))
                return
            }

            let responseData: HttpResponseData = data.map { .data($0) } ?? .none

            completion.complete(with: .success(responseData))
        }

        task.resume()

        return HttpRequestToken(for: task)
    }
}

private final class DefaultHttpTransport: HttpTransport {
    func performRequest(
        session: URLSession,
        request: URLRequest,
        then completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask
    {
        let task = session.dataTask(with: request, completionHandler: completion)
        return task
    }
}

private class HttpRequestToken: Cancellable {
    let task: URLSessionTask

    init(for task: URLSessionTask) {
        self.task = task
    }

    func cancel() {
        self.task.cancel()
    }
}

private extension HttpEndpoint {
    func url(scheme: String, host: String, port: Int?) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = self.path

        switch self.params {
        case .queryItems(let params):
            components.queryItems = params
                .map { key, value in
                    guard let value = value else { return URLQueryItem(name: key, value: nil) }
                    return URLQueryItem(name: key, value: value.description)
            }
        case .none:
            break
        }

        return components.url
    }

    var httpMethod: String {
        switch self.method {
        case .get: return "GET"
        case .post: return "POST"
        case .delete: return "DELETE"
        }
    }
}

private extension HttpRequestData {
    var data: Data? {
        switch self {
        case .none:
            return nil
        case .data(let rawData):
            return rawData
        case .text(let text):
            return text.data(using: .utf8)
        case .json(let json):
            do {
                return try json.toJSONData()
            } catch {
                print("json encoding error: \(error)")
                return nil
            }
        }
    }

    var contentType: String? {
        switch self {
        case .none:
            return nil
        case .json:
            return "application/json"
        case .text:
            return "text/plain"
        case .data:
            return "application/octet-stream"
        }
    }
}

private extension HttpAuthentication {
    var authorizationHeaderValue: String? {
        switch self {
        case .none:
            return nil
        case let .basic(username, password):
            guard
                let token = "\(username):\(password)"
                    .data(using: .utf8)?.base64EncodedString(options: [])
                else { return nil }

            return "Basic \(token)"
        }
    }
}
