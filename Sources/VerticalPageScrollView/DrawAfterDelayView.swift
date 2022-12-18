//
//  DrawAfterDelay.swift
//  
//
//  Created by cosalexelle on 18/12/2022.
//

import SwiftUI

struct DrawAfterDelayView<Content:View>: View {
    
    var delay: Double = 0.5
    
    var animation: Animation = .easeOut
    
    @ViewBuilder var content: Content
    
    @State private var boolIsHidden: Bool = true
    
    var body: some View {
        Group {
            if boolIsHidden {
                Color.clear
            } else {
                content
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(animation){
                    self.boolIsHidden = false
                }
            }
        }
    }
}

struct DrawAfterDelayView_Previews: PreviewProvider {
    static var previews: some View {
        DrawAfterDelayView(delay: 1.0){
            Text("hello")
        }
    }
}
