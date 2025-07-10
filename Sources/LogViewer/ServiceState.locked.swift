//
//  ServiceState.swift
//  Remote
//
//  Created by Philip Loden on 4/2/25.
//

/*
public enum ServiceState<T: Any> {
    case stopped
    case loading
    case loaded(T)
    case error(Error)    
}

extension ServiceState: Equatable {
    public static func == (lhs: ServiceState, rhs: ServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.loaded(let lhsData), .loaded(let rhsData)):
            //return lhsData == rhsData
            return true
        case (.loading, .loading):
            return true
        case (.stopped, .stopped):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
*/
