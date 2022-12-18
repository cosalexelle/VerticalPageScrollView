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
    
    public enum PageIndicatorsStyle: Int {
        case dots = 1, progressbar = 2
    }
    public func indicatorsStyle(_ value: PageIndicatorsStyle = .dots) -> Self {
        view_model.view_config.indicatorsStyle = value
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
                
                if view_model.view_config.showIndicators != .never && view_model.intPageCount > 1{
                    
                    if view_model.view_config.indicatorsStyle == .dots {
                        
                        DotsIndicators(view_model)
                        
                    } else if view_model.view_config.indicatorsStyle == .progressbar {
                        
                        
                        
                    }
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
//        .indicatorsStyle(.progressbar)
        .foregroundColor(.white)
        .ignoresSafeArea()
        
    }
}

private extension VerticalPageScrollView{
    private class VerticalPageScrollViewConfig: ObservableObject {
        @Published var boolPreventOverscroll: Bool = false
        @Published var showIndicators: PageIndicators = .never
        @Published var indicatorsStyle: PageIndicatorsStyle = .dots
        @Published var viewSpacing: Double = 20.0
    }
}

private extension VerticalPageScrollView {
    
    private class VerticalPageScrollViewModel: ObservableObject {
        
        @Published var previousDragAmount: Double = 0.0
        @Published var scrollYOffset: Double = 0.0
        @Published var scrollGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        @Published var parentGeo: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        @Published var intSelected: Int = 0
        @Published var intPageCount: Int = 0
        
        @Published var view_config: VerticalPageScrollViewConfig = VerticalPageScrollViewConfig()
        
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
                
                if !self.boolIsScrolling {
                    let scrollRect = geometry.frame(in: .global)
                    
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut){
                            self.scrollGeo = scrollRect
                            self.parentGeo = parent_geo.frame(in: .global)

                            self.intPageCount = Int(self.scroll_height / self.page_height)

                        }
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
    
    private struct DotsIndicators: View {
        
        @ObservedObject private var view_model: VerticalPageScrollViewModel
        
        init(_ view_model: VerticalPageScrollViewModel){
            self.view_model = view_model
        }
        
        var body: some View{
            VStack {
                VStack(spacing: 0.0) {
                    ForEach(0..<view_model.intPageCount, id: \.self){ i in
                        
                        Button(action: {
                            view_model.updateSelected_fromDotsIndicator(index: i)
                        }){
                            Image(systemName: "circle.fill")
                                .scaleEffect(view_model.intSelected == i ? 0.7 : 0.4)
                                .opacity(view_model.intSelected == i ? 0.7 : 0.4)
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
            }.frame(width: view_model.parentGeo.width, height: view_model.parentGeo.height, alignment: .trailing)
        }
    }
    
}
