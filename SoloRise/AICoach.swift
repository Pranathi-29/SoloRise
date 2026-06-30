import Foundation
import Security

// Provider-agnostic coaching interface. Swap GeminiCoach → a ClaudeCoach later
// without touching the rest of the app.
protocol AICoach {
    func weeklyCoaching(context: String) async throws -> String
}

enum AICoachError: LocalizedError {
    case missingKey
    case badResponse
    case empty
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "No API key set. Add your Gemini key in Settings → AI Coach."
        case .badResponse: return "Couldn't reach the coach. Check your connection and key."
        case .empty:       return "The coach returned no response. Try again."
        case .server(let m): return m
        }
    }
}

// MARK: - Gemini (free tier)
struct GeminiCoach: AICoach {
    // Free, fast model. Google renames these periodically — confirm the current free
    // model name in Google AI Studio and update here if the request 404s.
    static let model = "gemini-2.0-flash"

    let apiKey: String

    func weeklyCoaching(context: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AICoachError.missingKey }
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { throw AICoachError.badResponse }

        let system = """
        You are a warm, practical habit coach inside a Solo Leveling–themed self-improvement app. \
        The user is on a year-long journey to rank up (E→S) by completing five daily quests: \
        Physical Training, Nutrition, Career Growth, Mind Training, and Recovery. Read their week's \
        data and reflections below, then reply with a short encouraging summary (120–180 words) \
        followed by 2–3 concrete, specific suggestions as bullet points. Reference their actual \
        patterns, reasons, and goals. Be supportive and human, never preachy. Plain text only.
        """

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": system]]],
            "contents": [["parts": [["text": context]]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 600]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AICoachError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = obj["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw AICoachError.server(msg)
            }
            throw AICoachError.badResponse
        }

        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = obj["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AICoachError.empty
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Keychain (securely stores the API key)
enum KeychainHelper {
    private static let service = "com.solorise.ai"
    private static let account = "gemini_api_key"

    static func saveKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = Data(trimmed.utf8)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }
        return key
    }

    static func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
