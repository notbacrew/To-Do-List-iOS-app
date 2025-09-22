import Foundation

public enum AccountError: Error, Equatable {
    // Поиск/вход
    case invalidEmail
    case invalidUsername
    case wrongPassword

    // Регистрация
    case emailAlreadyExists
    case usernameAlreadyExists

    // Прочее
    case unknown
}

extension AccountError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Email not found"
        case .invalidUsername:
            return "Username not found"
        case .wrongPassword:
            return "Wrong password"
        case .emailAlreadyExists:
            return "Email already exists"
        case .usernameAlreadyExists:
            return "Username already exists"
        case .unknown:
            return "Unknown error"
        }
    }
}
