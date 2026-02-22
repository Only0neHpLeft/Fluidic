# Fluidic - Water Intake Tracker Design

## Overview

Fluidic is an iPhone water intake tracking app with a modern SaaS-inspired UI, smart adaptive notifications, and HealthKit integration. Users tap an animated water cup to log intake and receive intelligent reminders when falling behind their daily goal.

## Color Palette

- **Background gradient:** #E8F4FD (top) to #F0F8FF (bottom) - soft sky blue
- **Primary blue:** #42A5F5 - water fill color, primary actions
- **Secondary blue:** #90CAF9 - progress rings, secondary elements
- **Accent:** #1E88E5 - buttons, links, active states
- **Card background:** #FFFFFF with subtle shadow
- **Text primary:** #1A1A2E - dark navy for readability
- **Text secondary:** #6B7B8D - muted descriptions
- **Success green:** #66BB6A - goal achieved celebration

## Architecture

- **Pattern:** SwiftUI with @Observable view models (MVVM-light)
- **Persistence:** SwiftData for intake logs, settings, and streak data
- **Health:** HealthKit integration for syncing water intake samples
- **Notifications:** UNUserNotificationCenter with smart adaptive scheduling
- **Animations:** SwiftUI native animations + custom Shape paths for water cup

## Data Models

### WaterIntake (SwiftData)
- `id: UUID`
- `amount: Double` (milliliters)
- `timestamp: Date`

### UserSettings (SwiftData)
- `dailyGoalML: Double` (default: 2500)
- `cupSizeML: Double` (default: 250)
- `activeHoursStart: Int` (default: 8, meaning 8am)
- `activeHoursEnd: Int` (default: 22, meaning 10pm)
- `notificationsEnabled: Bool`
- `healthKitEnabled: Bool`

## Screen Design

### Tab 1: Home (Main Screen)

**Layout (top to bottom):**
1. Greeting header: "Good morning!" with date
2. Large water cup/glass in center (~60% of screen)
   - Custom SwiftUI Shape drawn with `Path` - rounded glass silhouette
   - Water fill level animates proportionally to intake/goal ratio
   - Subtle sine-wave animation on the water surface
   - Tap anywhere on the cup to add `cupSize` ml
   - Haptic feedback (medium impact) on each tap
3. Progress text below cup: "1,250 ml / 2,500 ml"
4. Circular progress ring around or below the cup showing percentage
5. Quick-add row: preset buttons (+100ml, +250ml, +500ml, Custom)
6. When goal is reached: confetti/particle celebration animation

### Tab 2: History

**Layout:**
1. Week selector (swipeable)
2. Bar chart showing daily intake for the week (SwiftUI Charts)
3. Current streak counter with flame icon
4. Monthly calendar view with color-coded dots (green = met goal, light blue = partial, gray = no data)

### Tab 3: Settings

**Layout (grouped list):**
1. **Daily Goal** - stepper or slider, displays in liters
2. **Cup Size** - how much each tap adds (100ml, 200ml, 250ml, 330ml, 500ml)
3. **Notifications** - toggle + active hours picker
4. **HealthKit** - toggle to sync with Apple Health
5. **Reset Today** - clear today's data

## Water Cup Shape

The cup is built with SwiftUI `Path`:
- Slightly wider at the top than bottom (tapered glass shape)
- Rounded corners at the bottom
- The "water" inside is a clipped fill that rises from 0% to 100%
- A sine wave at the water surface oscillates using a repeating animation
- Fill color uses a vertical gradient from #42A5F5 (top) to #1E88E5 (bottom)

## Smart Adaptive Notifications

**Algorithm:**
1. Calculate `remaining = dailyGoal - todayIntake`
2. Calculate `hoursLeft = activeHoursEnd - currentHour`
3. Calculate `paceNeeded = remaining / hoursLeft` (ml per hour)
4. If user hasn't logged in the last `interval` hours AND `remaining > 0`:
   - Send notification: "You need about X ml per hour to hit your goal. Tap to log!"
5. Notifications are rescheduled every time the user logs intake
6. No notifications sent after `activeHoursEnd` or before `activeHoursStart`
7. When goal is met, send a single congratulation notification

**Implementation:** Use `UNUserNotificationCenter` with scheduled local notifications. Recalculate and reschedule on each intake log.

## HealthKit Integration

- Request authorization for `HKQuantityType.dietaryWater`
- On each intake log, also save an `HKQuantitySample` to HealthKit
- Read existing samples on app launch to reconcile (in case user logged via another app)

## Frameworks Used

- SwiftUI (all UI)
- SwiftData (persistence)
- Charts (bar chart in history)
- HealthKit (health sync)
- UserNotifications (smart reminders)
