//
//  UIDatePicker.swift
//  Broker Portal
//
//  Created by Pankaj on 28/05/25.
//

import UIKit
import ObjectiveC

final class DatePickerManager {
    
    static let shared = DatePickerManager()
    private init() {}
    
    // Use static constant addresses for associated keys — safe & warning-free
    private static let overlayKey = UnsafeRawPointer(bitPattern: "overlayKey".hashValue)!
    private static let containerKey = UnsafeRawPointer(bitPattern: "containerKey".hashValue)!
    private static let pickerKey = UnsafeRawPointer(bitPattern: "pickerKey".hashValue)!
    private static let callbackKey = UnsafeRawPointer(bitPattern: "callbackKey".hashValue)!
    private static let formatKey = UnsafeRawPointer(bitPattern: "formatKey".hashValue)!
    
    func showDatePicker(
        from view: UIView,
        mode: UIDatePicker.Mode = .date,
        dateFormat: DateFormatType = .yyyyMMdd,
        initialDate: Date? = nil,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        onDateSelected: @escaping (String, Date) -> Void
    ) {
        guard let viewController = view.findViewController() else { return }
        
        let overlay = UIView(frame: viewController.view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.isUserInteractionEnabled = true
        
        let alreadyHasTap = overlay.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false

        if !alreadyHasTap {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
            overlay.addGestureRecognizer(tapGesture)
        }

        
        let containerHeight: CGFloat = 300
        let container = UIView(frame: CGRect(x: 0, y: viewController.view.bounds.height, width: viewController.view.bounds.width, height: containerHeight))
        container.backgroundColor = .systemBackground
        
        let picker = UIDatePicker()
        picker.datePickerMode = mode
        picker.preferredDatePickerStyle = .wheels
        picker.date = initialDate ?? Date()
        picker.minimumDate = minimumDate
        picker.maximumDate = maximumDate
        picker.translatesAutoresizingMaskIntoConstraints = false
        
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([cancel, spacer, done], animated: false)
        
        container.addSubview(toolbar)
        container.addSubview(picker)
        viewController.view.addSubview(overlay)
        viewController.view.addSubview(container)
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44), // ✅ reduced toolbar height,
            
            picker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Animate appearance
        UIView.animate(withDuration: 0.3, animations: {
            overlay.alpha = 1
            container.transform = CGAffineTransform(translationX: 0, y: -containerHeight)
        })
        
        // Set associated objects
        objc_setAssociatedObject(self, Self.overlayKey, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, Self.containerKey, container, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, Self.pickerKey, picker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, Self.callbackKey, onDateSelected, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, Self.formatKey, dateFormat.rawValue as String, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    @objc private func cancelTapped() {
        dismissPicker()
    }
    
    @objc private func doneTapped() {
        guard
            let picker = objc_getAssociatedObject(self, Self.pickerKey) as? UIDatePicker,
            let callback = objc_getAssociatedObject(self, Self.callbackKey) as? (String, Date) -> Void,
            let format = objc_getAssociatedObject(self, Self.formatKey) as? NSString
        else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = format as String
        let result = formatter.string(from: picker.date)
        
        callback(result, picker.date)
        dismissPicker()
    }
    
    private func dismissPicker() {
        if let container = objc_getAssociatedObject(self, Self.containerKey) as? UIView,
           let overlay = objc_getAssociatedObject(self, Self.overlayKey) as? UIView {
            UIView.animate(withDuration: 0.3, animations: {
                container.transform = .identity
                overlay.alpha = 0
            }) { _ in
                self.cleanup()
            }
        } else {
            cleanup()
        }
    }
    
    
    private func cleanup() {
        (objc_getAssociatedObject(self, Self.overlayKey) as? UIView)?.removeFromSuperview()
        (objc_getAssociatedObject(self, Self.containerKey) as? UIView)?.removeFromSuperview()
        objc_removeAssociatedObjects(self)
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let vc = responder as? UIViewController {
                return vc
            }
            nextResponder = responder.next
        }
        return nil
    }
}


import UIKit

// MARK: - Month Year Picker
final class MonthYearPicker: UIPickerView {
    
    private let months: [String] = Calendar.current.monthSymbols
    private var years: [Int]
    
    private var selectedMonth: Int
    private var selectedYear: Int
    
    override init(frame: CGRect) {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Future years (up to +50 years)
        self.years = Array(currentYear...currentYear+50)
        
        self.selectedMonth = currentMonth
        self.selectedYear = currentYear
        
        super.init(frame: frame)
        
        self.delegate = self
        self.dataSource = self
        
        // Set default selection
        selectRow(selectedMonth - 1, inComponent: 0, animated: false)
        if let yearIndex = years.firstIndex(of: selectedYear) {
            selectRow(yearIndex, inComponent: 1, animated: false)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Call when pressing Done button
    func getSelectedMonthYear() -> (month: Int, year: Int) {
        let month = selectedRow(inComponent: 0) + 1
        let year = years[selectedRow(inComponent: 1)]
        return (month, year)
    }
}

// MARK: - UIPickerView Delegate & DataSource
extension MonthYearPicker: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? months.count : years.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? months[row] : "\(years[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedMonth = selectedRow(inComponent: 0) + 1
        let selectedYear = years[selectedRow(inComponent: 1)]
        
        // Restrict past months in current year
        let now = Date()
        let currentYear = Calendar.current.component(.year, from: now)
        let currentMonth = Calendar.current.component(.month, from: now)
        
        if selectedYear == currentYear && selectedMonth < currentMonth {
            // Reset to current month
            selectRow(currentMonth - 1, inComponent: 0, animated: true)
        }
    }
}
