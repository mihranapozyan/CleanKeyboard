//
//  SessionView.swift
//  CleanKeyboard
//
//  Created by Mihran on 19.11.26.
//

import SwiftUI

/// The window's root: the screen for the current phase above a status bar.
struct SessionView: View {
    let viewModel: CleanSessionViewModel
    @State private var showingHelp = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch viewModel.phase {
                case .ready: ReadyView(viewModel: viewModel)
                case .countdown: CountdownView(viewModel: viewModel)
                case .cleaning: CleaningView(viewModel: viewModel)
                case .completed: CompletedView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            StatusBar(viewModel: viewModel, showingHelp: $showingHelp)
        }
        .frame(width: Theme.windowSize.width, height: Theme.windowSize.height)
        .background(Theme.panelBackground)
        .animation(.easeOut(duration: 0.18), value: viewModel.phase)
        .sheet(isPresented: $showingHelp) { HelpSheet(viewModel: viewModel) }
        .onExitCommand { if viewModel.phase == .countdown { viewModel.finish() } }
    }
}
