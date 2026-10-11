# Gather

A simple iPhone app for staying in touch with people: meeting with them, praying for them, and studying together.

The app has three tabs:

**Meet**
- **Add people from Contacts.** Tap **+** to search your contacts and pick one or more. Their contact photos show in the list. The app asks for Contacts access the first time.
- **Meeting reminders.** Set any frequency for each person (every N days, weeks, or months, or off) and an optional start date for the first reminder. A local notification fires at 9 AM when it's time to meet again. Tap **We met today** to reset the clock. The list is sorted so whoever is due soonest is at the top.
- **Prayer requests per person.** Tap a person to see their prayer requests, newest first. Tap **+** to add one, tap a request to edit it, and swipe to delete.

**Prayer**
- Every prayer as a card: general prayers you add here plus each person's prayer requests (with the person's name in the bottom-left corner).
- Swipe right to mark a prayer as prayed for. It moves to the bottom, then works its way back up as you pray for others. Swipe left to delete. Tap a card to edit it.

**Studies**
- Add a book you're studying, the contact you're studying with (searchable, with their photo), and how many chapters it has.
- Each time you meet, tap **We met and finished a chapter** to move the progress bar forward. Use the stepper to correct the count.

## Requirements

- Xcode 16 or later
- iOS 17 or later (uses SwiftUI and SwiftData)

## Running

1. Open `Gather.xcodeproj` in Xcode.
2. Select the **Gather** target, then **Signing & Capabilities**, and choose your Team. If `com.colemeetapp.meet` is already taken, change the bundle identifier.
3. Pick a simulator or your iPhone and press **Run**.

## Project layout

```
Gather/
  GatherApp.swift               App entry point and SwiftData container
  Models/
    Person.swift                A person, their reminder interval, and when you last met
    PrayerRequest.swift         A dated prayer, for a person or general
    Study.swift                 A book study and its chapter progress
  Services/
    ReminderScheduler.swift     Local notification scheduling
    ContactsService.swift       Reading contacts and their photos
  Views/
    ContentView.swift           The Meet / Prayer / Studies tabs
    PeopleListView.swift        Meet tab: people list and adding from Contacts
    PersonDetailView.swift      Prayer requests and reminder settings for a person
    PrayerRequestEditor.swift   Add/edit sheet for prayers
    PrayerListView.swift        Prayer tab cards and swipe actions
    StudiesListView.swift       Studies tab list
    NewStudyView.swift          Add-a-study sheet
    StudyDetailView.swift       Study progress and details
    ContactsPickerView.swift    Searchable contact picker with photos
    ContactAvatar.swift         Round contact photo or initials
```
