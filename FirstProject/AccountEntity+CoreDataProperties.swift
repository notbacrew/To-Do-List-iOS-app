//
//  AccountEntity+CoreDataProperties.swift
//  FirstProject
//
//  Created by maksimchernukha on 22.09.2025.
//
//

import Foundation
import CoreData

extension AccountEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountEntity> {
        return NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var passwordHash: String?
    @NSManaged public var createdAt: Date?
}

extension AccountEntity: Identifiable { }
