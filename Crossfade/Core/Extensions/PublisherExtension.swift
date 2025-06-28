//
//  PublisherExtension.swift
//  Crossfade
//
//  Created by Giulio Pimenoff Verdolin on 28/06/25.
//

import Combine

extension Publisher {
    
    /**
     Awaits a single value from this publisher.
     
     If the publisher finishes with an error, then this error will be thrown
     from this method. If the publisher finishes normally without producing any
     elements, then returns `nil`.
     */
    func awaitSingleValue() async throws -> Output? {
        return try await withCheckedThrowingContinuation { continuation in
            var didSendValue = false
            var cancellable: AnyCancellable? = nil

            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        if didSendValue {
                            return
                        }

                        switch completion {
                            case .finished:
                                continuation.resume(returning: nil)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        // prevent any more values from being received
                        cancellable?.cancel()
                        
                        if !didSendValue {
                            didSendValue = true
                            continuation.resume(returning: value)
                        }
                    }
                )
        }
    }
    
    /**
     Returns an AsyncThrowingStream for asynchronously iterating through
     the values produced by this publisher.
     */
    func awaitValues() -> AsyncThrowingStream<Output, Error> {
        return AsyncThrowingStream { continuation in
            
            let cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                continuation.finish()
                            case .failure(let error):
                                continuation.finish(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        continuation.yield(value)
                    }
                )
            
            continuation.onTermination = { @Sendable termination in
                cancellable.cancel()
            }
        }
    }
}
