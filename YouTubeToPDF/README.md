# YouTubeToPDF iOS App

This iOS app allows users to convert YouTube videos into downloadable PDFs. The app handles submitting a job to a remote server, polling for the job status, and notifying the user once the conversion is finished. The app uses **push notifications** to inform users when their job is complete, and it also provides a **local popup** for downloading the resulting PDF file.

## Features
- **Job Submission**: Submits a remote job to convert YouTube videos into PDFs.
- **Polling**: Periodically checks the status of the job via a remote URL.
- **Push Notifications**: Notifies the user when the job has finished and the PDF is ready.
- **Download Popup**: Displays a download popup once the job is finished, allowing users to download the generated PDF.

## App Flow
1. **Submit a Job**: The app sends a request to a remote server to start a video-to-PDF conversion.
2. **Polling**: The app continuously checks the status of the job by polling a remote URL.
3. **Push Notification**: Once the job is completed, the app sends a **push notification** to the user (even if the app is in the background).
4. **Popup Notification**: After the user taps on the notification or when the app is in the foreground, the app displays a **download popup** showing a **presigned URL** for the user to download the generated PDF.

## How It Works

### App Delegate (AppDelegate.swift)
- The `AppDelegate` manages the push notification registration, background task handling, and manages when notifications are tapped.
- Upon receiving a push notification, the `AppDelegate` attempts to present a **download popup** by communicating with the appropriate view controller in the app.
- When the app enters the foreground, the `AppDelegate` checks if there is any new information to display (e.g., a completed download URL).

### View Controller (ViewController.swift)
- The `ViewController` listens for a custom notification (`didFinishDownloading`), which is posted by the `AppDelegate` once the job completes and the presigned URL is available.
- Once the URL is received, it displays a popup using an `UIAlertController` to allow the user to download the PDF.

### Background Polling and Remote Job Status
- The app continually polls the server for job status updates to ensure it reflects the latest conversion state.
- When the job is completed and the presigned URL is available, the app presents a notification to inform the user.

---

t’s a more decoupled and event-driven approach where view controllers communicate via notifications instead of calling each other directly, which can lead to better separation of concerns.

Key Points:
Decoupling: The AppDelegate and the ViewController no longer directly call methods on each other. Instead, they communicate via the NotificationCenter.
Custom Notification: By posting a custom notification (didFinishDownloading), we can inform the ViewController that it should update the UI.
State Management: The download URL is stored in UserDefaults or AppState for persistence, and the notification sends this URL when it's ready.

### Decoupling

Sending a Notification when a background task finishes or a notification is tapped, and having the Main ViewController listen to this notification to update the UI.
Using NotificationCenter to decouple the components and avoid directly calling methods on the ViewController.

Instead of calling methods directly on the ViewController from the AppDelegate (which tightly couples them), you can send a notification from the AppDelegate or the background task to notify the ViewController.
This allows the ViewController to respond to the notification when the app is active and handle UI updates appropriately.

### Custom Notification
The main view controller listens for notifications (e.g., UIApplicationWillEnterForegroundNotification or a custom notification like DownloadFinishedNotification).
When a push notification's data arrives or the background fetch is complete, a local notification or a custom notification is sent to the main view controller, prompting it to update the UI accordingly.

### State Management
The data, like the download URL, is saved in UserDefaults or another state manager (like AppState), which simplifies persisting data that needs to be accessed later.


---


## Prerequisites

To run this app, you will need:

- **Xcode** (version 12.0 or later)
- **iOS 14.0+**
- A valid **Apple Developer Account** to configure push notifications and deploy to a device.

---

## Instructions for Running

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/YouTubeToPDF.git
cd YouTubeToPDF
