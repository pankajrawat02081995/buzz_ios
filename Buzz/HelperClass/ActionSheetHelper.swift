//
//  ActionSheetHelper.swift
//  Broker Portal
//
//  Created by Pankaj on 05/05/25.
//

import UIKit

enum ActionSheetActionType {
    case `default`
    case destructive
    case cancel
}

struct ActionSheetAction {
    let title: String
    let type: ActionSheetActionType
    let handler: (() -> Void)?
}

final class ActionSheetHelper {
    
    static func showActionSheet(
        on viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [ActionSheetAction],
        sourceView: UIView? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for action in actions {
            let style: UIAlertAction.Style
            switch action.type {
            case .default: style = .default
            case .destructive: style = .destructive
            case .cancel: style = .cancel
            }
            
            let alertAction = UIAlertAction(title: action.title, style: style) { _ in
                action.handler?()
            }
            alertController.addAction(alertAction)
        }
        
        // For iPad support
        if let popover = alertController.popoverPresentationController, let source = sourceView {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        
        viewController.present(alertController, animated: true, completion: nil)
    }
}
