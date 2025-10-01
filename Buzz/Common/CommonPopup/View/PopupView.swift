//
//  PopupView.swift
//  Broker Portal
//
//  Created by Pankaj on 06/05/25.
//

import UIKit

final class PopupView: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var btnOk: UIButton!
    @IBOutlet private weak var btnCancel: UIButton!
    @IBOutlet private weak var lblSubtitle: UILabel!
    @IBOutlet private weak var lblTitle: UILabel!

    // MARK: - Properties
    var mainTitle: String?
    var subTitle: String?
    var btnOkTitle: String?
    var btnCancelTitle: String?
    
    var onOkPressed: (() -> Void)?
    var onCancelPressed: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPopup()
    }
    
    // MARK: - Setup
    private func setupPopup() {
        lblTitle.text = mainTitle
        lblSubtitle.text = subTitle
        btnOk.setTitle(btnOkTitle ?? "OK", for: .normal)
        btnCancel.setTitle(btnCancelTitle ?? "Cancel", for: .normal)
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnCancel.addInnerShadow(cornerRadius: btnCancel.layer.cornerRadius)
        btnOk.addInnerShadow(cornerRadius: btnOk.layer.cornerRadius)
    }



    // MARK: - Actions
    @IBAction private func okButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            self?.onOkPressed?()
        }
    }

    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            self?.onCancelPressed?()
        }
    }
}
