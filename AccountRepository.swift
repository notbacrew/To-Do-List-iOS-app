//
//  AccountRepository.swift
//  FirstProject
//
//  CRUD для AccountEntity (через CoreDataManager)
//

import Foundation
import CoreData
import CryptoKit

struct AccountDTO {
    let id: UUID
    let username: String
    let email: String
    let createdAt: Date
}

final class AccountRepository {
    private let context: NSManagedObjectContext

    // Переведено на CoreDataManager, чтобы в проекте был один стек Core Data
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }

    // MARK: - Helpers

    private func sha256(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Create

    func register(email: String, username: String, password: String) throws -> AccountDTO {
        // Проверяем, что такого email ещё нет
        if try findByEmail(email) != nil {
            throw NSError(domain: "AccountRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Email already exists"])
        }
        let entity = AccountEntity(context: context)
        entity.id = UUID()
        entity.email = email
        entity.username = username
        entity.passwordHash = sha256(password)
        entity.createdAt = Date()

        try context.save()

        return AccountDTO(
            id: entity.id ?? UUID(),
            username: entity.username ?? "",
            email: entity.email ?? "",
            createdAt: entity.createdAt ?? Date()
        )
    }

    // MARK: - Read

    func findByEmail(_ email: String) throws -> AccountEntity? {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "email ==[c] %@", email)
        let result = try context.fetch(req)
        return result.first
    }

    func findByUsername(_ username: String) throws -> AccountEntity? {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "username ==[c] %@", username)
        let result = try context.fetch(req)
        return result.first
    }

    func findById(_ id: UUID) throws -> AccountEntity? {
        let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let result = try context.fetch(req)
        return result.first
    }

    func login(email: String, password: String) throws -> AccountDTO? {
        guard let entity = try findByEmail(email) else { return nil }
        let hash = sha256(password)
        guard entity.passwordHash == hash else { return nil }
        return AccountDTO(
            id: entity.id ?? UUID(),
            username: entity.username ?? "",
            email: entity.email ?? "",
            createdAt: entity.createdAt ?? Date()
        )
    }

    // MARK: - Update

    func updateUsername(for id: UUID, newUsername: String) throws {
        guard let entity = try findById(id) else { return }
        entity.username = newUsername
        try context.save()
    }

    func updatePassword(for id: UUID, newPassword: String) throws {
        guard let entity = try findById(id) else { return }
        entity.passwordHash = sha256(newPassword)
        try context.save()
    }

    // MARK: - Delete

    func deleteAccount(id: UUID) throws {
        guard let entity = try findById(id) else { return }
        context.delete(entity)
        try context.save()
    }
}
