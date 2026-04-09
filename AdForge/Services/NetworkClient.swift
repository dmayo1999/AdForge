// NetworkClient.swift
// AdForge
//
// Actor-based HTTP client. All network calls pass through here.

import Foundation

// MARK: - NetworkError

enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int, body: String)
    case decodingFailed(underlying: String)
    case encodingFailed
    case noData
    case serverError(message: String)
    case unauthorized
    case rateLimited
    case timeout
    case unknown(underlying: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse(let code, let body):
            return "Server returned \(code): \(body)"
        case .decodingFailed(let desc):
            return "Failed to decode response: \(desc)"
        case .encodingFailed:
            return "Failed to encode request body."
        case .noData:
            return "The server returned an empty response."
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .unauthorized:
            return "Unauthorized. Please sign in again."
        case .rateLimited:
            return "You're making requests too quickly. Please wait a moment."
        case .timeout:
            return "The request timed out. Check your connection and try again."
        case .unknown(let desc):
            return "An unexpected error occurred: \(desc)"
        }
    }
}

// MARK: - NetworkClient

actor NetworkClient {
    // MARK: Shared instance
    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        // Backend uses camelCase (imageURL, videoURL) — no snake_case conversion needed

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        // Send camelCase to match backend expectations
    }

    // MARK: - GET

    /// Fetches and decodes a Decodable response from a GET endpoint.
    func get<Response: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) async throws -> Response {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyDefaultHeaders(&request)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await perform(request: request)
    }

    // MARK: - POST

    /// Encodes `body` as JSON and decodes a Decodable response from a POST endpoint.
    func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        path: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyDefaultHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.encodingFailed
        }

        return try await perform(request: request)
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: API.baseURL + path) else {
            throw NetworkError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }

    private func applyDefaultHeaders(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AdForge-iOS/1.0", forHTTPHeaderField: "User-Agent")
    }

    private func perform<Response: Decodable & Sendable>(request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.unknown(underlying: urlError.localizedDescription)
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            let body = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.serverError(message: body)
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }

        if data.isEmpty {
            throw NetworkError.noData
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error.localizedDescription)
        }
    }
}
