import Foundation

precedencegroup LeftAssociativity {
    associativity: left
}

protocol Semigroup {
    func operation(_ g: Self) -> Self
}

func <> <S: Semigroup> (lhs: S, rhs: S) -> S {
    return lhs.operation(rhs)
}

infix operator <> : LeftAssociativity
infix operator <*>: LeftAssociativity

extension Array : Semigroup {
    func operation(_ element: Array) -> Array {
        return self + element
    }
}

enum Result<T, E> {
    
    case success(T)
    case failure(E)
    
    func map<U>(_ transform: (T) -> U) -> Result<U, E> {
        return flatMap { .success(transform($0)) }
    }
    
    func flatMap<U>(_ transform: (T) -> Result<U, E>) -> Result<U, E> {
        switch self {
        case let .success(value): return transform(value)
        case let .failure(error): return .failure(error)
        }
    }
    
}

extension Result {
    
    
    
}

extension Result where E: Semigroup {
    
    func apply<U>(_ transform: Result<(T) -> U , E>) -> Result<U, E> {
        switch (transform, self) {
        case let (.success(f), _): return map(f)
        case let (.failure(e), .success): return .failure(e)
        case let (.failure(e1), .failure(e2)): return .failure(e1 <> e2)
        }
    }
    
    func or(_ default: Result) -> Result {
        switch (self, `default`) {
        case (.success, _): return self
        case (_, .success): return `default`
        case let (.failure(e1), .failure(e2)): return .failure(e1 <> e2)
        }
    }
    
    func and(_ result: Result) -> Result {
        switch (self, result)  {
        case (.success, .success): return result
        case (.failure, _): return self
        case (_, .failure): return result
        }
    }
    
    static func ||(_ lhs: Result, rhs: Result) -> Result {
        return lhs.or(rhs)
    }
    
    static func &&(_ lhs: Result, rhs: Result) -> Result {
        return lhs.and(rhs)
    }
    
    static func <*> <B>(lhs: Result<(T) -> B, E>, rhs: Result<T, E>) -> Result<B, E> {
        return rhs.apply(lhs)
    }
    
    
    
}

struct UnregisteredUser {
    let id: Int
    let email: String
    let age: Int
}

struct RegisteredUser {
    let id: Int
    let email: String
    let age: Int
    
    private init(id: Int, email: String, age: Int) {
        self.id = id
        self.email = email
        self.age = age
    }
    
    static func create(user: UnregisteredUser) -> Result<RegisteredUser, [String]> {
        let createRegisteredUser = { id in { email in { age in return RegisteredUser(id: id, email: email, age: age) } } }
        
        return Result.success(createRegisteredUser)
            <*> validId(user.id)
            <*> (validEmail(user.email) && validGmailEmail(user.email))
            <*> (validMillennial(user.age) || validGenX(user.age))
    }
}

func validId(_ id: Int) -> Result<Int, [String]> {
    return id > 0 ? .success(id) : .failure(["invalid id"])
}

func validEmail(_ email: String) -> Result<String, [String]> {
    return email.contains("@") ? .success(email) : .failure(["invalid email"])
}

func validGmailEmail(_ email: String) -> Result<String, [String]> {
    return email.range(of:"gmail") != .none ? .success(email) : .failure(["invalid gmail address"])
}

func validMillennial(_ age: Int) -> Result<Int, [String]> {
    return age >= 18 && age <= 34 ? .success(age) : .failure(["invalid millennial"])
}

func validGenX(_ age: Int) -> Result<Int, [String]> {
    return age >= 35 && age <= 50 ? .success(age) : .failure(["invalid gen x"])
}



let unregisteredUser = UnregisteredUser(id: 0, email: "test@test.com", age: 7)
let registeredUser = RegisteredUser.create(user: unregisteredUser)

dump(registeredUser)


//    ▿ __lldb_expr_263.Result<__lldb_expr_263.RegisteredUser, Swift.Array<Swift.String>>.failure
//    ▿ failure: 4 elements
//- "invalid id"
//- "invalid email"
//- "invalid millennial"
//- "invalid gen x"

