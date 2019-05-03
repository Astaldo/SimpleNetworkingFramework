//
//  Common.swift
//  SimpleNetworkingFramework
//
//  Created by Anton Tikhonov on 2019-05-02.
//  Copyright © 2019 Anton Tikhonov. All rights reserved.
//

import Foundation

enum Common {
    enum Result<T> {
        case success(T)
        case error(String?)

        var succeeded: Bool {
            switch self {
            case .success: return true
            default: return false
            }
        }

        var failed: Bool {
            switch self {
            case .error: return true
            default: return false
            }
        }

        var errorMessage: String? {
            switch self {
            case .success: return nil
            case .error(let message): return message
            }
        }

        func onFailedWithMessage(_ f: (String) -> Void) {
            errorMessage.map { f($0) }
        }

        func asError<D>() -> Result<D> {
            return Result<D>.error(self.errorMessage)
        }
    }

    // Simplifies/standardizes calling completion handlers.
    // Ensures that the completion handler:
    // - gets called on the main thread
    // - gets called exactly once
    //
    // Example:
    //
    // func asyncFunction(then: (Common.Result<Data>) -> Void) {
    //    let completion = Common.Completion(then)
    //    ...
    //    guard succeeded else {
    //      completion.complete(with: .error)
    //      return
    //    }
    //    ...
    //    completion.complete(with: .success(data))
    // }
    class Completion<R> {
        typealias Completion = (R) -> Void
        private let completion: Completion
        private var completionCalled = false

        private func onMainThread(async: Bool, _ block: @escaping () -> Void) {
            if !async && Thread.isMainThread {
                // No-op in Release builds.
                assert(!completionCalled, "completion has already been called")
                self.completionCalled = true

                block()
            } else {
                DispatchQueue.main.async {
                    // No-op in Release builds.
                    assert(!self.completionCalled, "completion has already been called")
                    self.completionCalled = true

                    block()
                }
            }
        }

        func complete(with result: R, alwaysAsync: Bool = false) {
            onMainThread(async: alwaysAsync) {
                self.completion(result)
            }
        }

        init(_ completion: @escaping Completion) {
            self.completion = completion
        }

        deinit {
            // no-op in Release builds
            assert(completionCalled, "completion leaked")
        }
    }
}

// Syntactic sugar that allows writing .success instead of .success(())
// when no success value needs to be passed.
extension Common.Result where T == Void {
    static var success: Common.Result<Void> {
        return .success(())
    }
}

// Syntactic sugar to allow writing .error instead of .error(nil)
extension Common.Result {
    static var error: Common.Result<T> {
        return .error(nil)
    }
}

extension Common.Result: Equatable where T: Equatable {
    static func == (left: Common.Result<T>, right: Common.Result<T>) -> Bool {
        switch (left, right) {
        case let (.error(leftErrorMessage), .error(rightErrorMessage)):
            return leftErrorMessage == rightErrorMessage
        case let (.success(leftPayload), .success(rightPayload)):
            return leftPayload == rightPayload
        default:
            return false
        }
    }
}

// Syntactic sugar for () -> Void completion handlers.
extension Common.Completion where R == Void {
    func complete(alwaysAsync: Bool = false) {
        onMainThread(async: alwaysAsync) {
            self.completion(())
        }
    }
}

extension Dictionary {
    func keyValueMap<K, V>(_ transform: (Element) -> (K, V)) -> [K: V] {
        var dictionary: [K: V] = [:]
        forEach {
            let transformed = transform($0)
            dictionary[transformed.0] = transformed.1
        }
        return dictionary
    }

    func keyValueCompactMap<K, V>(_ transform: (Element) -> (K?, V?)) -> [K: V] {
        var dictionary: [K: V] = [:]
        forEach {
            let transformed = transform($0)
            if let key = transformed.0,
                let value = transformed.1 {
                dictionary[key] = value
            }
        }
        return dictionary
    }
}

// An extension that helps getting rid of annoying "forced unwrapping" warning/error.
extension Optional {
    // Require an optional to be non-nil.
    // Returns the value the optional contains or crashes with fatalError.
    func require(error: @autoclosure () -> String? = nil,
                 file: StaticString = #file,
                 line: Int = #line) -> Wrapped {
        guard let unwrapped = self else {
            let msg: String = {
                if let msg = error() { return ": \(msg)" }
                return ""
            }()
            fatalError("Required reference is nil in file \(file) at line: \(line)\(msg)")
        }
        return unwrapped
    }

    // Same as above but casts return value to a type different than the one the optional wraps.
    // Crashes with fatalError if type cast fails.
    func requireAs<T>(error: @autoclosure () -> String? = nil,
                      file: StaticString = #file,
                      line: Int = #line) -> T {
        guard let t = require(error: error(), file: file, line: line) as? T else {
            let msg: String = {
                if let msg = error() { return ": \(msg)" }
                return ""
            }()
            fatalError("Required reference is nil or can't be casted to desired " +
                "type in file \(file) at line \(line)\(msg)")
        }
        return t
    }
}

extension Encodable {
    func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

extension Data {
    func fromJSON<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
}
