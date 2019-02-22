//
//  BannerButton.swift
//  Stature
//
//  Created by Robert Manson on 2/21/19.
//

import Foundation

import UIKit

final class BannerButton: UIButton {
    enum Style {
        case `default`
        case destructive
    }
    var style = Style.default {
        didSet {
            refreshStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        refreshStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        refreshStyle()
    }
}

private extension BannerButton {
    func refreshStyle() {
        switch style {
        case .default:
            setBackgroundColor(.teal, for: .normal)
            setTitleColor(.white, for: .normal)
        case .destructive:
            setBackgroundColor(.alert, for: .normal)
            setTitleColor(.white, for: .normal)
        }

        setBackgroundColor(.lightGray, for: .disabled)
        setTitleColor(.moon, for: .disabled)

        titleLabel?.font = .systemFont(ofSize: 26, weight: .semibold)
    }

    func setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
        let backgroundImage = backgroundColor.map { UIImage.imageFromColor($0, size: CGSize(width: 1, height: 1)) }
        setBackgroundImage(backgroundImage, for: state)
    }
}

private extension UIImage {
    static func imageFromColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
