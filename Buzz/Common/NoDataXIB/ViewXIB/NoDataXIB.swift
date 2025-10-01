//
//  NoDataXIB.swift
//  Zupet
//
//  Created by Pankaj Rawat on 04/09/25.
//

import UIKit

class NoDataXIB: UIView {

    @IBOutlet weak var imgNoData: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            lblTitle.font = .manropeBold(24)
            lblTitle.textColor = .textBlack
        }
    }
    @IBOutlet weak var lblSubtitle: UILabel!{
        didSet{
            lblSubtitle.font = .manropeRegular(16)
            lblSubtitle.textColor = .appDarkGray
        }
    }
    
    // MARK: - Load from XIB
    static func loadFromNib() -> NoDataXIB {
        let nib = UINib(nibName: "NoDataXIB", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? NoDataXIB else {
            fatalError("NoDataXIB.xib not found or misconfigured")
        }
        view.frame = UIScreen.main.bounds // optional: set default frame
        return view
    }

        
        // MARK: - Configure
        func configure(title: String, subtitle: String? = nil, image: UIImage? = nil) {
            lblTitle.text = title
            lblSubtitle.text = subtitle
            imgNoData.image = image
        }

}
