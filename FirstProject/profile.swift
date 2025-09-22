import SwiftUI
import PhotosUI
import Combine
import AuthenticationServices
import CoreData

final class UserProfile: ObservableObject {
    private let ud = UserDefaults.standard
    private let keyCurrentUserID = "user.currentUserID"

    private var cancellables = Set<AnyCancellable>()
    // Заменяем репозиторий на AccountManager с явными ошибками
    private let accountManager = AccountManager()

    @Published var isLoggedIn: Bool
    @Published var email: String?
    @Published var username: String
    @Published var avatar: UIImage?
    @Published var totalXP: Int
    @Published var completedTasks: Int
    @Published var completedToday: Int

    // Текущий идентификатор пользователя (кэшируем для удобства)
    private var currentUserID: UUID? {
        didSet {
            // При смене пользователя обновляем подписки на сохранение и подгружаем его данные
            configurePersistenceBindings()
        }
    }

    // MARK: - Авторизация/регистрация (через Core Data, с ошибками)
    @discardableResult
    func login(email: String, password: String) -> Bool {
        switch loginByEmail(email: email, password: password) {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    func loginByEmail(email: String, password: String) -> Result<Void, AccountError> {
        do {
            let account = try accountManager.authenticateByEmail(email: email, password: password)
            self.email = account.email
            self.username = account.username ?? "User"
            self.isLoggedIn = true

            let id = try ensureAccountID(account)
            self.currentUserID = id
            ud.set(id.uuidString, forKey: keyCurrentUserID)

            // Подгружаем персональные данные пользователя
            loadPerUserData(for: id)

            return .success(())
        } catch let err as AccountError {
            return .failure(err)
        } catch {
            return .failure(.unknown)
        }
    }

    // Вариант входа по username
    func login(username: String, password: String) -> Result<Void, AccountError> {
        do {
            let account = try accountManager.authenticateByUsername(username: username, password: password)
            self.email = account.email
            self.username = account.username ?? "User"
            self.isLoggedIn = true

            let id = try ensureAccountID(account)
            self.currentUserID = id
            ud.set(id.uuidString, forKey: keyCurrentUserID)

            loadPerUserData(for: id)

            return .success(())
        } catch let err as AccountError {
            return .failure(err)
        } catch {
            return .failure(.unknown)
        }
    }

    // Регистрация всегда создаёт НОВЫЙ аккаунт (если email свободен).
    func register(email: String, password: String) -> Result<Void, AccountError> {
        let baseName = email // можешь заменить на вводимое имя
        do {
            let account = try accountManager.addAccount(username: baseName, email: email, password: password)
            self.email = account.email
            self.username = account.username ?? "User"
            self.isLoggedIn = true

            let id = try ensureAccountID(account)
            self.currentUserID = id
            ud.set(id.uuidString, forKey: keyCurrentUserID)

            // Новый аккаунт — стартуем с дефолтной статистики (0) и пустого аватара,
            // но если уже были какие-то данные под этим id (маловероятно) — загрузим их.
            loadPerUserData(for: id, useDefaultsIfMissing: true)

            return .success(())
        } catch let err as AccountError {
            return .failure(err)
        } catch {
            return .failure(.unknown)
        }
    }

    func logout() {
        self.isLoggedIn = false
        ud.removeObject(forKey: keyCurrentUserID)
        self.currentUserID = nil

        // Сбрасываем сессионные данные в модели (UI увидит "чистое" состояние)
        self.email = nil
        self.username = "User"
        self.avatar = nil
        self.totalXP = 0
        self.completedTasks = 0
        self.completedToday = 0
    }

    // MARK: - Инициализация
    init() {
        // Базовые дефолты, пока не восстановим пользователя
        self.isLoggedIn = false
        self.email = nil
        self.username = "User"
        self.totalXP = 0
        self.completedTasks = 0
        self.completedToday = 0
        self.avatar = nil

        // Восстанавливаем текущего пользователя по сохранённому UUID
        if let idString = ud.string(forKey: keyCurrentUserID), let uuid = UUID(uuidString: idString) {
            do {
                let ctx = CoreDataManager.shared.context
                let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                req.fetchLimit = 1
                req.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                if let entity = try ctx.fetch(req).first {
                    self.isLoggedIn = true
                    self.email = entity.email
                    self.username = entity.username ?? "User"
                    self.currentUserID = uuid

                    // Подгружаем пер-пользовательские данные
                    loadPerUserData(for: uuid)
                } else {
                    // Не нашли пользователя — чистим состояние
                    self.isLoggedIn = false
                    self.email = nil
                    self.username = "User"
                    self.currentUserID = nil
                }
            } catch {
                self.isLoggedIn = false
                self.email = nil
                self.username = "User"
                self.currentUserID = nil
            }
        }

        // Настраиваем подписки на сохранение (привязанные к текущему пользователю)
        configurePersistenceBindings()

        NotificationCenter.default.addObserver(forName: .resetStatisticsRequested, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.completedTasks = 0
            self.completedToday = 0
        }
    }

    // MARK: - Аватар
    func persistAvatar() {
        guard let userID = currentUserID else {
            // Нет текущего пользователя — не сохраняем в глобальные ключи
            return
        }
        let key = Self.keyAvatarData(for: userID)
        if let data = avatar?.pngData() {
            ud.set(data, forKey: key)
        } else {
            ud.removeObject(forKey: key)
        }
    }

    // MARK: - Leveling (без изменений)
    var level: Int {
        var currentLevel = 1
        var remainingXP = totalXP
        var neededForNext = 20
        while remainingXP >= neededForNext {
            remainingXP -= neededForNext
            currentLevel += 1
            neededForNext += 10
        }
        return max(1, currentLevel)
    }

    var xpForNextLevel: Int {
        let baseForLevel2 = 20
        let increment = 10
        var threshold = baseForLevel2
        var accumulated = 0
        while accumulated + threshold <= totalXP {
            accumulated += threshold
            threshold += increment
        }
        return threshold
    }

    var currentLevelProgressXP: Int {
        var threshold = 20
        var accumulated = 0
        while accumulated + threshold <= totalXP {
            accumulated += threshold
            threshold += 10
        }
        return totalXP - accumulated
    }

    var progressToNextLevel: Double {
        let req = Double(xpForNextLevel)
        if req <= 0 { return 0 }
        return min(1.0, Double(currentLevelProgressXP) / req)
    }

    // MARK: - Helpers
    private func ensureAccountID(_ account: AccountEntity) throws -> UUID {
        if let id = account.id { return id }
        // Если по какой-то причине id пуст — создадим и сохраним
        let newID = UUID()
        account.id = newID
        try CoreDataManager.shared.context.save()
        return newID
    }

    // Генерация пер-пользовательских ключей
    private static func keyTotalXP(for id: UUID) -> String { "user.\(id.uuidString).totalXP" }
    private static func keyCompletedTasks(for id: UUID) -> String { "user.\(id.uuidString).completedTasks" }
    private static func keyCompletedToday(for id: UUID) -> String { "user.\(id.uuidString).completedToday" }
    private static func keyAvatarData(for id: UUID) -> String { "user.\(id.uuidString).avatarData" }

    // Загрузка данных конкретного пользователя
    private func loadPerUserData(for id: UUID, useDefaultsIfMissing: Bool = false) {
        let totalXPKey = Self.keyTotalXP(for: id)
        let completedTasksKey = Self.keyCompletedTasks(for: id)
        let completedTodayKey = Self.keyCompletedToday(for: id)
        let avatarKey = Self.keyAvatarData(for: id)

        if useDefaultsIfMissing {
            self.totalXP = ud.object(forKey: totalXPKey) as? Int ?? 0
            self.completedTasks = ud.object(forKey: completedTasksKey) as? Int ?? 0
            self.completedToday = ud.object(forKey: completedTodayKey) as? Int ?? 0
        } else {
            // Тоже самое, но разделено для ясности
            self.totalXP = ud.integer(forKey: totalXPKey)
            self.completedTasks = ud.integer(forKey: completedTasksKey)
            self.completedToday = ud.integer(forKey: completedTodayKey)
        }

        if let data = ud.data(forKey: avatarKey) {
            self.avatar = UIImage(data: data)
        } else {
            self.avatar = nil
        }
    }

    // Подписки на сохранение значений — привязаны к текущему пользователю
    private func configurePersistenceBindings() {
        // Сбрасываем старые подписки
        cancellables.removeAll()

        // Обновление username в Core Data (как и было)
        $username
            .sink { [weak self] newValue in
                guard let self = self else { return }
                guard self.isLoggedIn,
                      let id = self.currentUserID else { return }
                do {
                    let ctx = CoreDataManager.shared.context
                    let req: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                    req.fetchLimit = 1
                    req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    if let entity = try ctx.fetch(req).first {
                        entity.username = newValue
                        try ctx.save()
                    }
                } catch {
                    print("Update username error: \(error)")
                }
            }
            .store(in: &cancellables)

        // Если нет текущего пользователя — не сохраняем статистику в UD
        guard let userID = currentUserID else { return }

        $totalXP
            .sink { [weak self] v in
                guard let self = self else { return }
                self.ud.set(v, forKey: Self.keyTotalXP(for: userID))
            }
            .store(in: &cancellables)

        $completedTasks
            .sink { [weak self] v in
                guard let self = self else { return }
                self.ud.set(v, forKey: Self.keyCompletedTasks(for: userID))
            }
            .store(in: &cancellables)

        $completedToday
            .sink { [weak self] v in
                guard let self = self else { return }
                self.ud.set(v, forKey: Self.keyCompletedToday(for: userID))
            }
            .store(in: &cancellables)
    }
}

