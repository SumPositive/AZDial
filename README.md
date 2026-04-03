# AZDial

A SwiftUI scroll-wheel dial control for iOS, macOS, and visionOS.

Originally created as an Objective-C component in 2012. Rewritten in SwiftUI in 2025.

![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20visionOS%201-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- 8 visual styles: Soft, Machined, Chrome, Fine, Hairline, Rubber, Gold, Vintage
- Smooth drag gesture with pixel-level precision
- Optional stepper buttons
- VoiceOver / Accessibility support
- Haptic feedback on iOS
- Dark mode support
- Pure SwiftUI — no UIKit wrappers

## Requirements

- iOS 16.0+ / macOS 13.0+ / visionOS 1.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**

```
https://github.com/SumPositive/AZDial
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SumPositive/AZDial", from: "1.0.0")
]
```

## Usage

```swift
import AZDial

struct ContentView: View {
    @State private var weight = 600  // 60.0 kg (×10 internally)

    var body: some View {
        AZDialView(
            value: $weight,
            min: 300,    // 30.0 kg
            max: 2000,   // 200.0 kg
            step: 1,
            stepperStep: 10,
            decimals: 1,
            style: .machined
        )
    }
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `value` | `Binding<Int>` | Current value |
| `min` | `Int` | Minimum value |
| `max` | `Int` | Maximum value |
| `step` | `Int` | Value increment per drag step |
| `stepperStep` | `Int` | Stepper button increment (0 = hidden) |
| `decimals` | `Int` | Decimal places shown on stepper label (default: 0) |
| `style` | `DialStyle` | Visual style (default: `.machined`) |

### DialStyle

```swift
public enum DialStyle: Int, CaseIterable {
    case soft
    case machined
    case chrome
    case fine
    case hairline
    case rubber
    case gold
    case vintage
}
```

### AZDialBack (background only)

If you need just the scrolling ridge background:

```swift
AZDialBack(offset: scrollOffset, tickGap: 16, style: .chrome)
```

## License

MIT License. See [LICENSE](LICENSE) for details.
