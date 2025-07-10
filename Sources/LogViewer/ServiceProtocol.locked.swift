//
//  ServiceProtocol.swift
//  Remote
//
//  Created by Philip Loden on 4/2/25.
//

/*
public protocol ServiceProtocol {
    associatedtype ServiceModel
    typealias ServiceContinuation = AsyncStream<ServiceState<ServiceModel>>

    var currentServiceState: ServiceState<ServiceModel> { get }
    var mostRecentLoadedServiceState: ServiceState<ServiceModel>? { get }
    var continuations: [ServiceContinuation.Continuation] { get set }

    func load()
}

public extension ServiceProtocol {
    mutating func subscribe() -> ServiceContinuation {
        let stream = AsyncStream(ServiceState<ServiceModel>.self) { continuation in
            continuations.append(continuation)
        }

        return stream
    }

    func updateSubscribers() {
        for continuation in continuations {
            let currentServiceState = self.currentServiceState
            continuation.yield(currentServiceState)
        }
    }
}
*/
