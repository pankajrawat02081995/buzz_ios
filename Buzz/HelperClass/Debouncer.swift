//
//  Debouncer.swift
//  Broker Portal
//
//  Created by Pankaj on 28/04/25.
//

import Foundation

final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func run(action: @escaping () -> Void) {
        // Cancel any existing work item
        workItem?.cancel()

        // Create a new work item
        let newItem = DispatchWorkItem(block: action)
        workItem = newItem

        // Schedule it on the queue
        queue.asyncAfter(deadline: .now() + delay, execute: newItem)
    }

    deinit {
        workItem?.cancel() // Cancel on deallocation for safety
    }
}
