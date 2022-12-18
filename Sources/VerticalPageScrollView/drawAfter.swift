//
//  drawAfter.swift
//  
//
//  Created by Darren on 18/12/2022.
//

import SwiftUI

private struct DrawAfterDelayModifier: ViewModifier {
    
    var delay: Double = 0.5
    
    @State private var boolHidden = true;
    
    func body(content: Content) -> some View {
        modify(content)
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + delay){
                    withAnimation{
                        boolHidden = false
                    }
                }
            }
    }
    
    @ViewBuilder private func modify(_ content: Content) -> some View {
        if boolHidden {
            content.hidden()
        } else {
            content
        }
    }
    
}

public extension View {
    func drawAfter(delay: Double) -> some View{
        modifier(DrawAfterDelayModifier(delay: delay))
    }
}
