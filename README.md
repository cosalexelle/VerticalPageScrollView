# VerticalPageScrollView

An imperfect, pure Swift UI implementation of a vertically-scrolling page view, with indicators of the current selected page.

**WARNING:** This is very unoptimised code, it may have issues and is provided without warranty. 

## Example Usage

```swift
import SwiftUI

struct ContentView: View {
    
    @State private var colors: [Color] = [
        .orange,
        .purple,
        .cyan,
        .indigo
    ]
    
    var body: some View {
        VerticalPageScrollView{
            ForEach(colors, id: \.self){ color in
                ZStack{
                    Rectangle()
                        .fill(color.gradient)
                    Text("\(color.description)")
                        .font(.title.weight(.bold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .showIndicators()
        .pageSpacing(.large)
        .ignoresSafeArea()
    }
}
```

## Bugs
(to be listed shortly)
1. Using spacing of .none (0.0) between views causes some flickering at the bottom / top of view. Hence the default option adds spacing between each view.

## TODO:
Basically everything...

## License
The Unlicense
