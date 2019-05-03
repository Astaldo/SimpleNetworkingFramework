//
//  SimpleNetworkingFrameworkTests.swift
//  SimpleNetworkingFrameworkTests
//
//  Created by Anton Tikhonov on 2019-04-29.
//  Copyright © 2019 Anton Tikhonov. All rights reserved.
//

import XCTest
@testable import SimpleNetworkingFramework

class NetworkTests: XCTestCase {

    struct JsonData: Equatable, Codable {
        struct Address: Equatable, Codable {
            let city: String
            let street: String
            let houseNo: Int
            let zip: String
        }

        let firstName: String
        let lastName: String
        let age: Int
        let address: Address
        let likes: [String]
    }
    static let jsonData = JsonData(
        firstName: "John",
        lastName: "Doe",
        age: 20,
        address: NetworkTests.JsonData.Address(
            city: "Stockholm",
            street: "Upplandsgatan",
            houseNo: 7,
            zip: "17788"),
        likes: ["pizza", "coffee"])

    static let rawData = "Raw data string".data(using: .utf8).require()

    static let textData = "Test text data"

    func testGetRequestWithNoAuthentication() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: false)

        let exp = expectation(description: "get no authentication")

        testable.request(endpoint: TestEndpoint.getNoAuthentication) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/get-no-authentication")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertNil(authHeader)

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)
    }

    func testGetRequestWithAuthentication() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "get with basic authentication")

        testable.request(endpoint: TestEndpoint.getWithAuthentication) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/get-with-authentication")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)
    }

    func testGetRequestWithQueryItems() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "get with query items")

        testable.request(endpoint: TestEndpoint.getWithQueryItems) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url?.contains("https://test.example.com:8888/get-with-query-items"), true)

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)

        let query = transport.request?.url?.query?
            .split(separator: "&")
            .sorted()
        XCTAssertEqual(query, ["flag=true", "novalue", "number=100", "string=test"])
    }

    func testPostRequestWithNoAuthentication() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: false)

        let exp = expectation(description: "post no authentication")

        testable.request(endpoint: TestEndpoint.postNoAuthentication) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/post-no-authentication")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertNil(authHeader)

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)
    }

    func testPostRequestWithAuthentication() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with basic authentication")

        testable.request(endpoint: TestEndpoint.postWithAuthentication) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/post-with-authentication")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)
    }

    func testPostRequestWithQueryItems() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with query items")

        testable.request(endpoint: TestEndpoint.postWithQueryItems) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url?.contains("https://test.example.com:8888/post-with-query-items"), true)

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)

        let query = transport.request?.url?.query?
            .split(separator: "&")
            .sorted()
        XCTAssertEqual(query, ["flag=true", "novalue", "number=100", "string=test"])
    }

    func testPostRequestJsonData() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with json data")

        testable.request(endpoint: TestEndpoint.postWithJsonData) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/post-with-json-data")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertEqual(contentType, "application/json")

        let body: JsonData? = transport.request?.httpBody.flatMap { try? $0.fromJSON() }
        XCTAssertEqual(body, NetworkTests.jsonData)
    }

    func testPostRequestQueryItemsAndJsonData() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with query items and json data")

        testable.request(endpoint: TestEndpoint.postWithQueryItemsAndJsonData) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url?.contains("https://test.example.com:8888/post-with-query-items-and-json-data"), true)

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertEqual(contentType, "application/json")

        let body: JsonData? = transport.request?.httpBody.flatMap { try? $0.fromJSON() }
        XCTAssertEqual(body, NetworkTests.jsonData)

        let query = transport.request?.url?.query?
            .split(separator: "&")
            .sorted()
        XCTAssertEqual(query, ["flag=true", "novalue", "number=100", "string=test"])
    }

    func testPostRequestRawData() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with raw data")

        testable.request(endpoint: TestEndpoint.postWithRawData) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/post-with-raw-data")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertEqual(contentType, "application/octet-stream")

        let body: String? = transport.request?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body, "Raw data string")
    }

    func testPostRequestQueryItemsAndRawData() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post with query items and raw data")

        testable.request(endpoint: TestEndpoint.postWithQueryItemsAndRawData) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url?.contains("https://test.example.com:8888/post-with-query-items-and-raw-data"), true)

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertEqual(contentType, "application/octet-stream")

        let body: String? = transport.request?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body, "Raw data string")

        let query = transport.request?.url?.query?
            .split(separator: "&")
            .sorted()
        XCTAssertEqual(query, ["flag=true", "novalue", "number=100", "string=test"])
    }

    func testPostPlainText() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200, headers: [:])

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "post plain text")

        testable.request(endpoint: TestEndpoint.postPlainText) { response in
            XCTAssertTrue(response.succeeded)

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/post-plain-text")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertEqual(contentType, "text/plain")

        let body: String? = transport.request?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body, NetworkTests.textData)
    }

    func testJsonResponse() {
        let transport = MockHttpTransport()
        transport.response = mockResponse(status: 200,
                                          headers: ["Content-Type": "application/json"])
        transport.responseData = try? NetworkTests.jsonData.toJSONData()

        let testable = mockSession(transport: transport,
                                   authenticate: true)

        let exp = expectation(description: "json response")

        testable.request(endpoint: TestEndpoint.getWithAuthentication) { response in
            let jsonResponse: JsonData? = response.map()
            XCTAssertEqual(jsonResponse, NetworkTests.jsonData)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        let url = transport.request?.url?.absoluteString
        XCTAssertEqual(url, "https://test.example.com:8888/get-with-authentication")

        let authHeader = transport.request?.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Basic dGVzdDoxMjM0")

        let contentType = transport.request?.allHTTPHeaderFields?["Content-Type"]
        XCTAssertNil(contentType)
    }
}

enum TestEndpoint {
    case getNoAuthentication
    case getWithAuthentication
    case getWithQueryItems
    case postNoAuthentication
    case postWithAuthentication
    case postWithQueryItems
    case postWithJsonData
    case postWithQueryItemsAndJsonData
    case postWithRawData
    case postWithQueryItemsAndRawData
    case postPlainText
}

extension TestEndpoint: HttpEndpoint {
    var path: String {
        switch self {
        case .getNoAuthentication: return "/get-no-authentication"
        case .getWithAuthentication: return "/get-with-authentication"
        case .getWithQueryItems: return "/get-with-query-items"
        case .postNoAuthentication: return "/post-no-authentication"
        case .postWithAuthentication: return "/post-with-authentication"
        case .postWithQueryItems: return "/post-with-query-items"
        case .postWithJsonData: return "/post-with-json-data"
        case .postWithQueryItemsAndJsonData: return "/post-with-query-items-and-json-data"
        case .postWithRawData: return "/post-with-raw-data"
        case .postWithQueryItemsAndRawData: return "/post-with-query-items-and-raw-data"
        case .postPlainText: return "/post-plain-text"
        }
    }

    var method: HttpMethod {
        switch self {
        case .getNoAuthentication,
             .getWithAuthentication,
             .getWithQueryItems:
            return .get
        case .postNoAuthentication,
             .postWithAuthentication,
             .postWithQueryItems,
             .postWithJsonData,
             .postWithQueryItemsAndJsonData,
             .postWithRawData,
             .postWithQueryItemsAndRawData,
             .postPlainText:
            return .post
        }
    }

    var params: HttpRequestParameters {
        switch self {
        case .getNoAuthentication,
             .getWithAuthentication,
             .postNoAuthentication,
             .postWithAuthentication,
             .postWithRawData,
             .postWithJsonData,
             .postPlainText:
            return .none
        case .getWithQueryItems,
             .postWithQueryItems,
             .postWithQueryItemsAndJsonData,
             .postWithQueryItemsAndRawData:
            return .queryItems([
                "string": "test",
                "number": 100,
                "flag": true,
                "novalue": nil
            ])
        }
    }

    var headerFields: [String : CustomStringConvertible] {
        return [
            "custom-header-one": "one",
            "custom-header-two": 200
        ]
    }

    var requestData: HttpRequestData {
        switch self {
        case .getNoAuthentication,
             .getWithAuthentication,
             .getWithQueryItems,
             .postWithQueryItems,
             .postNoAuthentication,
             .postWithAuthentication:
            return .none
        case .postWithJsonData,
             .postWithQueryItemsAndJsonData:
            return .json(NetworkTests.jsonData)
        case .postWithRawData,
             .postWithQueryItemsAndRawData:
            return .data(NetworkTests.rawData)
        case .postPlainText:
            return .text(NetworkTests.textData)
        }
    }
}

private func mockSession(transport: HttpTransport, authenticate: Bool) -> HttpSession {
    return DefaultHttpSession(
        config: URLSessionConfiguration.default,
        scheme: .https,
        host: "test.example.com",
        port: 8888,
        authentication: authenticate
            ? .basic(username: "test", password: "1234")
            : .none,
        transport: transport)
}

private func mockResponse(status: Int, headers: [String: String]?) -> HTTPURLResponse {
    return HTTPURLResponse(
        url: URL(string: "test.example.com").require(),
        statusCode: status,
        httpVersion: "1.1",
        headerFields: headers).require()
}

private class MockTask: URLSessionTask {
    var onResume: (() -> Void)?
    var onCancel: (() -> Void)?

    override func resume() {
        onResume?()
    }

    override func cancel() {
        onCancel?()
    }
}

private final class MockHttpTransport: HttpTransport {
    var response: HTTPURLResponse?
    var responseData: Data?
    var responseError: Error?
    var delay = TimeInterval(0)

    var request: URLRequest?
    var session: URLSession?

    func performRequest(
        session: URLSession,
        request: URLRequest,
        then completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask
    {
        self.request = request
        self.session = session

        let task = MockTask()
        task.onResume = {
            DispatchQueue.global().asyncAfter(deadline: .now() + self.delay) {
                completion(self.responseData, self.response, self.responseError)
            }
        }

        return task
    }
}
