import Foundation
import CoreData
import CryptoKit

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    private init(inMemory: Bool = false) {
        // Имя модели ДОЛЖНО совпадать с именем .xcdatamodeld (без .xcdatamodeld)
        persistentContainer = NSPersistentContainer(name: "coredb")
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            if let description = persistentContainer.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        
        // Диагностика: проверить, что сущность присутствует
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        assert(entityNames.contains("AccountEntity"), "AccountEntity is missing in loaded model. Check coredb.xcdatamodeld name, Codegen=Manual/None, Module, and current version.")
        
        // Строгая политика мерджа — ошибки при конфликтах уникальности
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.error
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func saveContext() throws {
        let ctx = context
        guard ctx.hasChanges else { return }
        try ctx.save()
    }
}

final class AccountManager {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    @discardableResult
    func addAccount(username: String, email: String, password: String) throws -> AccountEntity {
        // Явная проверка уникальности email
        if try getAccount(byEmail: email) != nil {
            throw AccountError.emailAlreadyExists
        }
        // Если username тоже должен быть уникален — раскомментируйте
        // if try getAccount(byUsername: username) != nil {
        //     throw AccountError.usernameAlreadyExists
        // }
        
        let account = AccountEntity(context: context)
        account.id = UUID()
        account.username = username
        account.email = email
        account.passwordHash = password.sha256()
        account.createdAt = Date()
        do {
            try context.save()
        } catch let nsError as NSError {
            // Попытка уточнить, что именно конфликтует
            if (try? getAccount(byEmail: email)) != nil {
                throw AccountError.emailAlreadyExists
            }
            if (try? getAccount(byUsername: username)) != nil {
                throw AccountError.usernameAlreadyExists
            }
            throw nsError
        }
        return account
    }
    
    func getAccount(byUsername username: String) throws -> AccountEntity? {
        let request: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "username ==[c] %@", username)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func getAccount(byEmail email: String) throws -> AccountEntity? {
        let request: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func getAllAccounts() -> [AccountEntity] {
        let request: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func authenticateByEmail(email: String, password: String) throws -> AccountEntity {
        guard let account = try getAccount(byEmail: email) else {
            throw AccountError.invalidEmail
        }
        guard account.passwordHash == password.sha256() else {
            throw AccountError.wrongPassword
        }
        return account
    }
    
    func authenticateByUsername(username: String, password: String) throws -> AccountEntity {
        guard let account = try getAccount(byUsername: username) else {
            throw AccountError.invalidUsername
        }
        guard account.passwordHash == password.sha256() else {
            throw AccountError.wrongPassword
        }
        return account
    }
}

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
