# GlennVerse Admin Panel

A basic admin panel for managing books and audiobooks in the GlennVerse app.

## Features

### ✅ Completed Features
- **Admin Login** - Simple authentication with demo credentials
- **Dashboard** - Overview with statistics and quick actions
- **Add Books** - Form to add new books with all required fields
- **Manage Books** - List, search, filter, and delete books
- **Firebase Integration** - Firestore database for content storage

### 📋 Admin Panel Structure
```
lib/admin_panel/
├── models/
│   └── book_model.dart          # Book data model
├── services/
│   └── firebase_service.dart    # Firebase operations
├── screens/
│   ├── admin_login_screen.dart  # Login page
│   ├── admin_dashboard_screen.dart # Main dashboard
│   ├── add_book_screen.dart      # Add new book form
│   └── manage_books_screen.dart # Book management
├── admin_main.dart              # Admin app entry point
└── README.md                    # This file
```

## How to Use

### 1. Access Admin Panel
```dart
// In your main app, add a way to access admin panel
// For example, add a hidden button or gesture
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMain(),
      ),
    );
  },
  child: Text('Admin Panel'),
)
```

### 2. Demo Credentials
- **Email**: admin@glennverse.com
- **Password**: admin123

### 3. Admin Features

#### Dashboard
- View total books count
- See published vs draft books
- Quick action buttons
- Statistics overview

#### Add Books
- **Basic Info**: Title, Author, Description, Category
- **Media Files**: Cover image URL, Audio file URL
- **Content**: Book text content
- **Timing**: Read time and listen time in minutes
- **Publishing**: Save as draft or publish immediately

#### Manage Books
- **View All Books**: List of all books with cover previews
- **Search**: Search by title or author
- **Filter**: Filter by All/Published/Draft
- **Actions**: Edit and delete books
- **Status**: Visual indicators for published/draft status

## Firebase Setup

### 1. Firestore Collections
The admin panel uses a `books` collection in Firestore with the following structure:

```json
{
  "id": "unique_book_id",
  "title": "Book Title",
  "author": "Author Name",
  "description": "Book description",
  "coverImageUrl": "https://example.com/cover.jpg",
  "content": "Book text content",
  "audioFileUrl": "https://example.com/audio.mp3",
  "category": "Fiction",
  "readTime": 15,
  "listenTime": 12,
  "isPublished": true,
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

### 2. Security Rules
Make sure to set up proper Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /books/{document} {
      allow read: if true; // Allow public read for main app
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```

## Integration with Main App

### 1. Update Main App to Use Dynamic Content
Replace the hardcoded book lists in your main app screens with Firebase data:

```dart
// In home_screen.dart, library_screen.dart, etc.
// Replace static lists with:
final books = await FirebaseService.getAllBooks();
```

### 2. Add Admin Access
Add a way to access the admin panel from your main app (hidden gesture, settings menu, etc.)

## Future Enhancements

- **User Authentication**: Replace demo login with real Firebase Auth
- **File Upload**: Add image and audio file upload functionality
- **Content Editor**: Rich text editor for book content
- **Analytics**: Track book views and user engagement
- **Bulk Operations**: Import/export multiple books
- **Content Validation**: Validate book content before publishing
- **User Management**: Manage admin users and permissions

## Dependencies Added

- `cloud_firestore: ^5.4.4` - For Firestore database operations

## Usage Notes

- This is a basic admin panel with essential features only
- No file upload functionality (uses URLs for images/audio)
- Demo authentication (replace with real auth for production)
- All content is stored in Firestore
- Designed to be simple and functional
