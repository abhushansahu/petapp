# Tamagotchi macOS App

A cute Tamagotchi-style virtual pet for macOS that lives on your desktop, interacts with your workspace, and provides gentle reminders throughout your day.

## Features

- **Virtual Pet**: Ages throughout the day, resets at midnight
- **Multi-Screen Support**: Automatically moves across multiple screens when exploring. Detects screen edges and smoothly transitions between displays
- **Window Interaction**: Detects active applications and can sit on windows when you're focusing on work. Responds to workspace changes
- **Music Detection**: Dances to music playing on your system with beat-synchronized animations and music note accessories
- **Video Watching**: Observes videos you're watching. Detects video apps and browser-based video content, positioning itself to watch alongside you
- **Focus Mode**: Sits quietly when you're focusing on work, respecting your productivity
- **Reminders**: Time-based, custom, and health reminders with pet notifications
- **Random Activities**: Explores, plays, and observes throughout the day with personality-driven behavior
- **Mouse Interaction**: Playful interactions with your cursor - follows, chases, or avoids based on mood
- **Adorable Expressions**: Rich emotes and props including:
  - Hearts when happy or eating
  - Sparkles during play and curiosity
  - Hats and accessories when sitting
  - Music notes while dancing
  - Sleep accessories (blankets, Zzz bubbles)
  - Speed lines when running
  - Dizzy stars when dropped
  - And many more contextual expressions!
- **Performance**: Extremely lightweight and resource-efficient

## Requirements

- macOS 11.0 or later
- Screen Recording permission (for audio capture)
- Notification permissions (for reminders)

## Building

1. Open the project in Xcode
2. Build and run (⌘R)

## Permissions

The app requires:
- **Screen Recording**: For system audio capture to detect music
- **Notifications**: For reminder alerts

These permissions will be requested on first launch.

## Architecture

Built with Swift + AppKit for maximum performance and control:
- Core Animation for smooth vector animations
- AVAudioEngine for audio analysis
- NSWorkspace for application monitoring
- UserNotifications for reminders

## License

Copyright © 2025
