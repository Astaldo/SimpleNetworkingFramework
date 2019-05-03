//
//  Endpoint.swift
//  SimpleNetworkingFramework
//
//  Created by Anton Tikhonov on 2019-04-29.
//  Copyright © 2019 Anton Tikhonov. All rights reserved.
//

import Foundation

enum MyService {
    case login(name: String, password: String)
    case logout
    case loadProfile
    case loadUserProfile(userId: Int)
    case loadData(offset: Int, length: Int)
}

extension MyService: HttpEndpoint {
    var path: String {
        switch self {
        case .login:
            return "/login"
        case .logout:
            return "/logout"
        case .loadProfile:
            return "/loadProfile"
        case .loadUserProfile(let userId):
            return "/loadProfile/\(userId)"
        case .loadData:
            return "/loadData"
        }
    }

    var method: HttpMethod {
        switch self {
        case .login,
             .logout:
            return .post
        case .loadProfile,
             .loadUserProfile,
             .loadData:
            return .get
        }
    }

    var params: HttpRequestParameters {
        switch self {
        case .loadUserProfile(let userId):
            return .queryItems(["userid": userId])
        case let .loadData(offset, length):
            return .queryItems([
                "offset": offset,
                "length": length
            ])
        case .login,
             .logout,
             .loadProfile:
            return .none
        }
    }

    var headerFields: [String: CustomStringConvertible] {
        return [:]
    }

    var requestData: HttpRequestData {
        switch self {
        case let .login(name, password):
            return .json([
                "username": name,
                "userpassword": password
            ])
        case .logout,
             .loadProfile,
             .loadUserProfile,
             .loadData:
            return .none
        }
    }
}

struct LoginDO: Decodable {
    let accessToken: String?
    let error: String?
}

struct LogoutDO: Decodable {
    let success: Bool?
    let error: String?
}
