//
//  UIImageExtension.swift
//  PrototypeBrunoSarmiento
//
//  Created by Bruno Sarmiento on 3/20/18.
//  Copyright © 2018 Akurey. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    var png: Data? {
        guard let flattened = flattened else { return nil }
        return UIImagePNGRepresentation(flattened)
    }
    var flattened: UIImage? {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    class func imageWithLabel(label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
