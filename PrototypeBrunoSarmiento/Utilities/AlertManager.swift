//
//  AlertManager.swift
//  PrototypeBrunoSarmiento
//
//  Created by Bruno Sarmiento on 3/21/18.
//  Copyright © 2018 Akurey. All rights reserved.
//

import Foundation
import UIKit

struct AlertManager {
    static func showAlert(from viewController: UIViewController,
                          withTitle title: String?,
                          andMessage message: String?,
                          alertActions: [UIAlertAction]) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alertActions.forEach { alert.addAction($0) }
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func okAction() -> UIAlertAction {
        return UIAlertAction(title: "OK",
                             style: .default,
                             handler: nil)
    }
    
    static func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: "Cancel",
                             style: .default,
                             handler: nil)
    }
}
