//
//  ActivityView.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 16/05/2025.
//
import SwiftUI

#if os(iOS)
import UIKit

class SheetPresentationDelegate: NSObject, UISheetPresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentationController.presentedViewController.dismiss(animated: true)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    private let presentationDelegate = SheetPresentationDelegate()
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.modalPresentationStyle = .pageSheet
        
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 15
            sheet.delegate = presentationDelegate as? UISheetPresentationControllerDelegate
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
