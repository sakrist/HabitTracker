//
//  UndoRedoAction.swift
//  HabitTracker
//
//  Created by Volodymyr Boichentsov on 14/05/2025.
//
import SwiftUI

extension View {
    public func withUndoRedo(perform action: @escaping () -> Void = {}) -> some View {
        modifier(UndoRedoAwareModifier(action: action))
    }
}

struct UndoRedoAwareModifier: ViewModifier {
    let action: () -> Void
    @State private var showUndoAlert = false

    func body(content: Content) -> some View {
        content
            .onShake {
                if ModelData.undoManager.canUndo {
                    showUndoAlert = true
                }
            }
            .alert("Undo Action", isPresented: $showUndoAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Undo", role: .destructive) {
                    ModelData.undoManager.undo()
                    action()
                    ModelData.shared.saveContext()
                }
            } message: {
                Text("Would you like to undo your last action?")
            }
    }
}
