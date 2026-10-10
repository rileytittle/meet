# meet

A simple iPhone app for staying in touch with people.

- **Add people from Contacts.** Tap **+** to pick one or more contacts. The system picker is used, so no Contacts permission is needed.
- **Meeting reminders.** Each person gets a reminder interval (every week, 2 weeks, month, or 3 months, or off). A local notification fires at 9 AM when it's time to meet again. Tap **We met today** to reset the clock. The list is sorted so whoever is due soonest is at the top.
- **Prayer requests.** Tap a person to see their prayer requests, newest first. Tap **+** to add one, tap a request to edit it, and swipe to delete.

## Requirements

- Xcode 16 or later
- iOS 17 or later (uses SwiftUI and SwiftData)

## Running

1. Open `Meet.xcodeproj` in Xcode.
2. Select the **Meet** target, then **Signing & Capabilities**, and choose your Team. If `com.rileytittle.meet` is already taken, change the bundle identifier.
3. Pick a simulator or your iPhone and press **Run**.

## Project layout

```
Meet/
  MeetApp.swift                 App entry point and SwiftData container
  Models/
    Person.swift                A person, their reminder interval, and when you last met
    PrayerRequest.swift         A dated note attached to a person
  Services/
    ReminderScheduler.swift     Local notification scheduling
  Views/
    PeopleListView.swift        Main list and adding from Contacts
    PersonDetailView.swift      Prayer requests and reminder settings for a person
    PrayerRequestEditor.swift   Add/edit sheet
    ContactPicker.swift         Wrapper around the system contact picker
```
