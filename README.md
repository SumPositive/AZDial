# AZDial

A SwiftUI scroll-wheel dial control for iOS, macOS, and visionOS.

Originally created as an Objective-C component in 2012. Rewritten in SwiftUI in 2025.

![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20visionOS%201-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- 8 built-in visual styles + custom image tile support
- Adjustable dial width (80–220 pt)
- Optional stepper buttons with decimal label
- Smooth drag gesture with haptic feedback (iOS)
- VoiceOver / Accessibility support
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
    .package(url: "https://github.com/SumPositive/AZDial", from: "2.4.0")
]
```

## Usage

```swift
import AZDial

struct ContentView: View {
    @State private var weight = 600  // 60.0 kg (stored ×10)

    var body: some View {
        AZDialView(
            value: $weight,
            min: 300,         // 30.0 kg
            max: 2000,        // 200.0 kg
            step: 1,
            stepperStep: 10,
            decimals: 1,
            style: .regacy,
            dialWidth: 220
        )
    }
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Binding<Int>` | — | Current value |
| `min` | `Int` | — | Minimum value |
| `max` | `Int` | — | Maximum value |
| `step` | `Int` | — | Value increment per drag step |
| `stepperStep` | `Int` | — | Stepper button increment (`0` = hidden) |
| `decimals` | `Int` | `0` | Decimal places shown on stepper label |
| `style` | `DialStyle` | `.regacy` | Visual style |
| `dialWidth` | `CGFloat` | `220` | Dial width in points (clamped to 80–220) |

---

## DialStyle

### Built-in styles

| Style | Description |
|---|---|
| `.regacy` | Classic AZDial knurling — original Objective-C design |
| `.midnight` | Dark gunmetal with high-contrast silver highlights |
| `.brass` | Warm brass with champagne gold highlights |
| `.ocean` | Blue anodized aluminum with ice-blue highlights |
| `.varnia` | Narrow machined knurling |
| `.chrome` | Polished chrome with high contrast |
| `.hairline` | Ultra-fine hairline engraving |
| `.rubber` | Wide matte rubber grip |

```swift
AZDialView(value: $value, min: 0, max: 100, step: 1, stepperStep: 10,
           style: .midnight)
```

### Custom image tile

Supply your own PDF or PNG image from `Assets.xcassets`:

```swift
AZDialView(
    value: $value,
    min: 0, max: 100,
    step: 1, stepperStep: 10,
    style: .tile(
        light: "MyDialTile",
        dark: "MyDialTile_Dark",  // optional
        tileWidth: 20             // must match image width in points
    )
)
```

For assets in your own Swift Package, pass `bundle: .module`:

```swift
style: .tile(light: "MyDialTile", tileWidth: 20, bundle: .module)
```

### Persistence

Use `DialStyle.id` (a `String`) to store the selected style in UserDefaults or iCloud KVS, and restore it with `DialStyle.builtin(id:)`:

```swift
// Save
UserDefaults.standard.set(style.id, forKey: "dialStyle")

// Restore
let id = UserDefaults.standard.string(forKey: "dialStyle") ?? ""
let style = DialStyle.builtin(id: id) ?? .regacy
```

---

## AZDialBack

Use `AZDialBack` if you need only the scrolling ridge background — for example, in a settings UI preview:

```swift
AZDialBack(offset: 0, tickGap: 10, style: .brass)
    .frame(height: 44)
    .clipShape(RoundedRectangle(cornerRadius: 8))
```

---

## Development

Open `AZDial.xcworkspace` (not the package directly) to work on both the library and the demo app together.

```
AZDial/
├── AZDial.xcworkspace          ← open this
├── Package.swift
├── Sources/AZDial/
│   ├── AZDialView.swift
│   └── Resources/Assets.xcassets/
├── Tests/AZDialTests/
└── Examples/AZDialDemo/
```

## License

MIT License. See [LICENSE](LICENSE) for details.
