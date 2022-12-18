//
//  VerticalPageScrollView.swift
//  VerticalPageScrollView
//
//  Created by cosalexelle on 15/12/2022.
//

import SwiftUI

public struct VerticalPageScrollView<Content:View>: View {
    
    @ObservedObject private var view_model: VerticalPageScrollViewModel = VerticalPageScrollViewModel()
    
    @ViewBuilder public var content: Content
    
    public init(@ViewBuilder content: () -> Content){
        self.content = content()
    }
    
    public func preventOverscroll(_ value: Bool = true) -> Self {
        view_model.view_config.boolPreventOverscroll = value
        return self
    }
    
    public enum PageIndicators: Int {
        case never = 0, automatic = 1, always = 2
    }
    public func showIndicators(_ value: PageIndicators = .automatic) -> Self {
        view_model.view_config.showIndicators = value
        return self
    }
    
    public enum PageSpacing: Double {
        case none = 0.0, small = 20.0, large = 40.0, overlap = -40
    }
    
    public func pageSpacing(_ value: PageSpacing = .small) -> Self {
        view_model.view_config.viewSpacing = value.rawValue;
        return self
    }
    
    public var body: some View {
        GeometryReader{ parent_geo in
            
            ZStack(alignment: .top){
                
                VStack(spacing: view_model.view_config.viewSpacing){
                    
                    Group{
                        self.content
                    }
                    .frame(width: parent_geo.size.width, height: parent_geo.size.height)
                    .contentShape(Rectangle())
                    .offset(y: round(view_model.scrollYOffset))
                    
                }
                .containerShape(Rectangle())
                .background(view_model._calculateScrollGeo(withParentGeo: parent_geo))
                .gesture(DragGesture()
                    .onChanged { value in view_model._drag_onChange(value)}
                    .onEnded{ value in view_model._drag_onEnded(value)})
                
                DrawAfterDelayView(delay: 0.5, animation: .easeInOut(duration: 0.5)){
                    ProgressViewIndicators(view_model)
                }
                
            }
            .background(.black)
        }

    }
}

public struct VerticalPageScrollView_Previews: PreviewProvider {
    public static var previews: some View {
        VerticalPageScrollView{
            Color.red
            Color.green
            Color.blue
        }
        .showIndicators()
//        .preventOverscroll()
//        .pageSpacing(.overlap)
        .foregroundColor(.white)
        .ignoresSafeArea()
        
    }
}

private extension VerticalPageScrollView{
    private class VerticalPageScrollViewConfig: ObservableObject {
        @Published var boolPreventOverscroll: Bool = false
        @Published var showIndicators: PageIndicators = .never
        @Published var viewSpacing: Double = 20.0
    }
}

private extension VerticalPageScrollView {
    
    private class VerticalPageScrollViewModel: ObservableObject {
        
        var previousDragAmount: Double = 0.0
        @Published var scrollYOffset: Double = 0.0
        var scrollGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        var parentGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        @Published var intSelected: Int = 0
        var intPageCount: Int {
            scroll_height > 0 ? Int( scroll_height / page_height ) : 1
        }
        
        var view_config: VerticalPageScrollViewConfig = VerticalPageScrollViewConfig()
        
        var page_height: Double {
            parentGeo.height + view_config.viewSpacing
        }
        
        var scroll_height: Double {
            scrollGeo.height + view_config.viewSpacing
        }
        
        var boolIsScrolling: Bool {
            previousDragAmount != 0.0
        }
        
        var currentView_top: Double {
            Double(intSelected) * page_height
        }
        
        var nearestView_top: Double {
            round(-scrollYOffset / page_height) * page_height
        }
        
        var scrollProgress: Double {
            -scrollYOffset / scroll_height
        }
        
        public func updateSelected_fromDotsIndicator(index i: Int){
            let distance_to_item = abs( i - intSelected )
            withAnimation(.easeInOut(duration: distance_to_item >= 6 ? 1.5 : distance_to_item >= 3 ? 1.0 : 0.4)){
                let nextView_top = Double(i) * page_height
                scrollYOffset = -nextView_top
                intSelected = Int(abs(scrollYOffset) / page_height)
            }
        }
        
        public func _calculateScrollGeo(withParentGeo parent_geo: GeometryProxy) -> some View {
            GeometryReader { geometry in
                
                // _calculateScrollGeo also runs at every view draw
                // which when scrolling is like 100 times per second
                // let's not waste resources calculating all of this at each draw
                // however, it can be useful as when the view rotates, we can re-calculate
                // the offsets and set scrollYOffset again
                
                // dont run this if the view is being scrolled
                
                print("bg main", self.intPageCount)
                
                if !self.boolIsScrolling {
                    let scrollRect = geometry.frame(in: .global)
                    
                    withAnimation(.easeInOut){
                        self.scrollGeo = scrollRect
                        self.parentGeo = parent_geo.frame(in: .global)
                    }
                }
                
                return Color.clear
            }
        }
        
        public func _drag_onChange(_ value: DragGesture.Value){
            withAnimation(.easeInOut(duration: 0.4)){
                let delta = value.translation.height - previousDragAmount
                if !view_config.boolPreventOverscroll ||
                    (scrollYOffset + delta < 0 &&
                     scrollYOffset + delta > -scroll_height + page_height) {
                    scrollYOffset = scrollYOffset + delta
                }
                previousDragAmount = value.translation.height
            }
        }
        
        public func _drag_onEnded(_ value: DragGesture.Value){
            withAnimation(.easeInOut(duration: 0.4)){
                
                previousDragAmount = 0.0
                
                let velocity = value.predictedEndLocation.y - value.location.y
                
                let nextView_top = abs(velocity) > 200 ? Double(intSelected + (velocity < 0 ? 1 : -1)) * page_height : nearestView_top
                
                scrollYOffset = nextView_top < scroll_height && nextView_top >= 0 ? -nextView_top : -currentView_top
                
                intSelected = Int(abs(scrollYOffset) / page_height)
                   
            }
        }
        
    }
    
}

private extension VerticalPageScrollView {
    
    private struct ProgressViewIndicators: View {
        
        @ObservedObject private var view_model: VerticalPageScrollViewModel
        
        @State private var progressBar_height: Double = 300
        @State private var progressBar_width: Double = 16
        @State private var progressBar_padding_trailing: Double = 8
        @State private var progressBar_btn_opacity: Double = 0.4
        
        @State var previousDragAmount: Double = 0.0
        
        private var progressBar_offset: Double {
            view_model.scrollProgress * progressBar_height
        }
        
        init(_ view_model: VerticalPageScrollViewModel){
            self.view_model = view_model
        }
        
        var body: some View{
            VStack {
                VStack(spacing: 0.0) {
                    RoundedRectangle(cornerRadius: 16)
//                        .fill(.ultraThinMaterial)
                        .opacity(progressBar_btn_opacity)
                        .frame(height: progressBar_height / CGFloat(view_model.intPageCount))
                        .offset(y: progressBar_offset)
                    Spacer()
                }
                .frame(width: progressBar_width, height: progressBar_height)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.trailing, progressBar_padding_trailing)
                .onTapGesture { value in
                    withAnimation(.easeInOut(duration: 0.4)){
                        
                        let tap_offset = (progressBar_height / Double(view_model.intPageCount)) * 0.5
                        
                        var nextView_top = ( ( value.y - tap_offset) / progressBar_height ) * view_model.scroll_height
                        
                        nextView_top = round(nextView_top / view_model.page_height) * view_model.page_height
                        
                        view_model.scrollYOffset = nextView_top < view_model.scroll_height && nextView_top >= 0 ? -nextView_top : -view_model.currentView_top
                        
                        view_model.intSelected = Int(abs(view_model.scrollYOffset) / view_model.page_height)
                    }
                }
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.interpolatingSpring(mass: 0.1, stiffness: 30, damping: 1.4, initialVelocity: 5)) {
                            progressBar_width = 24
                            progressBar_height = 320
                            progressBar_btn_opacity = 0.7
                        }
                    }
                    .onEnded{ _ in
                        withAnimation(.interpolatingSpring(mass: 0.1, stiffness: 30, damping: 1.4, initialVelocity: 5)) {
                            progressBar_width = 16
                            progressBar_height = 300
                            progressBar_btn_opacity = 0.4
                        }
                    })
                .simultaneousGesture(DragGesture()
                    .onChanged { value in
                        withAnimation(.easeInOut(duration: 0.4)){
                            let delta = -(value.translation.height - previousDragAmount) / progressBar_height * view_model.scroll_height
                            if (view_model.scrollYOffset + delta < 0 &&
                                 view_model.scrollYOffset + delta > -view_model.scroll_height + view_model.page_height) {
                                view_model.scrollYOffset = view_model.scrollYOffset + delta
                            }
                            previousDragAmount = value.translation.height
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.4)){
                            previousDragAmount = 0.0
                            let nextView_top = view_model.nearestView_top
                            
                            view_model.scrollYOffset = nextView_top < view_model.scroll_height && nextView_top >= 0 ? -nextView_top : -view_model.currentView_top
                            
                            view_model.intSelected = Int(abs(view_model.scrollYOffset) / view_model.page_height)
                        }
                    })
                
            }.frame(width: view_model.parentGeo.width, height: view_model.parentGeo.height, alignment: .trailing)
        }
    }
    
}
