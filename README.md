# SwiftToasts Library

## Overview
SwiftToasts is a lightweight, interactive toast notification library for SwiftUI that provides an elegant way to display temporary messages in iOS applications.

## Key Components

### `Toast` Struct
Represents an individual toast notification with the following properties:
- `id`: Unique identifier for each toast
- `content`: The view content of the toast
- `offsetX`: Horizontal offset for swipe interactions
- `isDeleting`: Flag indicating deletion state

#### Creation Methods
1. **Simple Toast**
```swift
Toast.simple("Notification Text", systemImage: "checkmark.circle")
```

2. **Custom Toast**
```swift
Toast { id in
    // Custom toast content
}
```

### Usage Example
Check [Demo.swift](./Sources/SwiftToasts/Demo.swift)

## Features
- Swipe-to-dismiss gesture
- Expandable toast view
- Stacked notification layout
- Smooth animations
- iOS 17+ visual effects support

## Interaction Modes
- Compact mode: Stacked, overlapping toasts
- Expanded mode: Full list of toasts

## Gesture Interactions
- Horizontal swipe left to dismiss
- Tap to expand/collapse toast stack

## Compatibility
- Supports iOS 16+
- Optimized for iOS 17 with additional visual effects

## Installation
Add the Swift file to your project or integrate via Swift Package Manager.
