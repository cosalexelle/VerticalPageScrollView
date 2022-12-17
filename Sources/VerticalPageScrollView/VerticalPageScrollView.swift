//
//  VerticalPageScrollView.swift
//  VerticalPageScrollView
//
//  Created by cosalexelle on 15/12/2022.
//

import SwiftUI

struct VerticalPageScrollView<Content:View>: View {
    
    @State private var previousDragAmount: Double = 0.0
    @State private var scrollYOffset: Double = 0.0
    @State private var scrollGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
    @State private var parentGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
    
    @State private var intSelected: Int = 0
    @State private var intPageCount: Int = 0
    
    private class VerticalPageScrollViewConfig: ObservableObject {
        @Published var boolPreventOverscroll: Bool = false
        @Published var showIndicators: PageIndicators = .never
        @Published var viewSpacing: Double = 20.0
        
    }
    
    @ObservedObject private var view_config: VerticalPageScrollViewConfig = VerticalPageScrollViewConfig()
    
    @ViewBuilder var content: Content
    
    private func _calculateScrollGeo(withParentGeo parent_geo: GeometryProxy) -> some View {
        GeometryReader { geometry in
            
            // _calculateScrollGeo also runs at every view draw
            // which when scrolling is like 100 times per second
            // let's not waste resources calculating all of this at each draw
            // however, it can be useful as when the view rotates, we can re-calculate
            // the offsets and set scrollYOffset again
            
            // dont run this if the view is being scrolled
            
            if !boolIsScrolling {
                let scrollRect = geometry.frame(in: .global)
                
                DispatchQueue.main.async {
                    withAnimation(.easeInOut){
                        scrollGeo = scrollRect
                        parentGeo = parent_geo.frame(in: .global)
                        
                        // i dont know why this works, but it does
                        intPageCount = Int(((scrollGeo.height + view_config.viewSpacing) / (parentGeo.height + view_config.viewSpacing)))
                        
                        // potential race condition if scrollYOffset is updated by elsewhere in the model
                        // so this probably should be disabled, but useful for updating scroll position
                        // on draw update, for on update device orientation
                        // let currentView_top = Double(intSelected) * ( parentGeo.height + view_config.viewSpacing)
                        // scrollYOffset = -currentView_top
                    }
                }
            }
            
            
            return Color.clear
        }
    }
    
    @State private var boolIsScrolling: Bool = false
    
    private func _drag_onChange(_ value: DragGesture.Value){
        withAnimation(.easeInOut(duration: 0.4)){
            boolIsScrolling = true
            let delta = value.translation.height - previousDragAmount
            if !view_config.boolPreventOverscroll ||
                (scrollYOffset + delta < 0 &&
                 scrollYOffset + delta > -scrollGeo.height + parentGeo.height) {
                scrollYOffset = scrollYOffset + delta
            }
            previousDragAmount = value.translation.height
        }
    }
    
    private func _drag_onEnded(_ value: DragGesture.Value){
        withAnimation(.easeInOut(duration: 0.4)){
            
            previousDragAmount = 0.0
            boolIsScrolling = false
            
            let velocity = value.predictedEndLocation.y - value.location.y
            
            let currentView_top = Double(intSelected) * ( parentGeo.height + view_config.viewSpacing)
            
            let nextView_top: Double;
            
            let gesture_up = velocity < 0
            
            if abs(velocity) > 200 {
                
                nextView_top = Double(intSelected + (gesture_up ? 1 : -1)) * ( parentGeo.height + view_config.viewSpacing)
                
                if nextView_top < scrollGeo.height + view_config.viewSpacing && nextView_top >= 0 {
                    scrollYOffset = -nextView_top
                    intSelected = intSelected + (gesture_up ? 1 : -1)
                } else {
                    scrollYOffset = -currentView_top
                }
                
            } else {
                
                // Nearest view top
                
                let nearestView_top = round(scrollYOffset / ( parentGeo.height + view_config.viewSpacing) ) * ( parentGeo.height + view_config.viewSpacing)
                
                if nearestView_top > -(scrollGeo.height + view_config.viewSpacing) && nearestView_top <= 0 {
                    scrollYOffset = nearestView_top
                    intSelected = Int(abs(scrollYOffset) / (parentGeo.height + view_config.viewSpacing))
                } else {
                    scrollYOffset = -currentView_top
                }

            }
               
        }
    }
    
    func preventOverscroll(_ value: Bool = true) -> Self {
        self.view_config.boolPreventOverscroll = value
        return self
    }
    
    enum PageIndicators: Int {
        case never = 0, automatic = 1, always = 2
    }
    func showIndicators(_ value: PageIndicators = .automatic) -> Self {
        self.view_config.showIndicators = value
        return self
    }
    
    enum PageSpacing: Double {
        case none = 0.0, small = 20.0, large = 40.0, overlap = -40
    }
    
    func pageSpacing(_ value: PageSpacing = .small) -> Self {
        self.view_config.viewSpacing = value.rawValue;
        return self
    }
    
    var body: some View {
        GeometryReader{ parent_geo in
            
            ZStack(alignment: .top){
                
                VStack(spacing: view_config.viewSpacing){
                    
                    Group{
                        self.content
                    }
                    .frame(width: parent_geo.size.width, height: parent_geo.size.height)
                    .contentShape(Rectangle())
                    .offset(y: round(scrollYOffset))
                    
                }
                .containerShape(Rectangle())
                .background(_calculateScrollGeo(withParentGeo: parent_geo))
                .gesture(DragGesture()
                    .onChanged { value in _drag_onChange(value)}
                    .onEnded{ value in _drag_onEnded(value)})
                
                if view_config.showIndicators != .never && intPageCount > 1{
                    VStack {
                        VStack(spacing: 0.0) {
                            ForEach(0..<intPageCount, id: \.self){ i in
                                
                                Button(action: {
                                    let distance_to_item = abs(i - intSelected )
                                    withAnimation(.easeInOut(duration: distance_to_item >= 6 ? 1.5 : distance_to_item >= 3 ? 1.0 : 0.4)){
                                        let nextView_top = Double(i) * ( parent_geo.size.height + view_config.viewSpacing)
                                        scrollYOffset = -nextView_top
                                        intSelected = i
                                    }
                                }){
                                    Image(systemName: "circle.fill")
                                        .scaleEffect(intSelected == i ? 0.7 : 0.4)
                                        .opacity(intSelected == i ? 0.7 : 0.4)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.trailing, 8)
                    }
                    .frame(width: parent_geo.size.width, height: parent_geo.size.height, alignment: .trailing)
                }
                
            }
            .background(.black)
        }

    }
}

struct VerticalPageScrollView_Previews: PreviewProvider {
    static var previews: some View {
        VerticalPageScrollView(){
            Color.red
            Color.green
            Color.blue
        }
        .showIndicators()
        .preventOverscroll()
        .foregroundColor(.white)
        .ignoresSafeArea()
        
    }
}
