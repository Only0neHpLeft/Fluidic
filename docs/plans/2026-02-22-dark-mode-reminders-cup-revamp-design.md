# Design: Dark Mode, Reminder Intervals, Water Cup Revamp

## 1. Dark Mode Support

Replace hardcoded colors in `FluidicTheme` with `UIColor { traitCollection }` dynamic colors. App follows system appearance by default.

Dark palette: navy backgrounds (#0D1117/#161B22), dark card surfaces (#1C2128), softer blues (#58A6FF), muted text (#C9D1D9/#8B949E). Gradients also adaptive.

No view changes needed — all views reference `FluidicTheme.*`.

## 2. Notification Reminders — Smart vs Fixed Toggle

New `UserSettings` fields: `reminderMode` (smart/fixed), `reminderIntervalHours` (0.5-4.0, default 1.5).

NotificationManager gets `scheduleFixedReminders()` using repeating `UNCalendarNotificationTrigger`.

SettingsView adds segmented picker (Smart | Fixed) and interval stepper.

## 3. Water Cup Revamp

New tumbler shape with visible rim/lip. Glass wall thickness via inner+outer paths. Water fill stays below rim at 100%. Dual-wave surface. Glass refraction highlights (vertical strip, bottom arc). Rich water gradient.

## Implementation Order

1. Dark mode (FluidicTheme.swift only)
2. UserSettings + NotificationManager changes
3. SettingsView reminder UI
4. WaterCupShape + WaterCupView revamp
5. Screenshot verification
