# Project: Cherry'View - Social Restaurant Review App

## App Description:

Discover and share your food experiences with an app designed for food lovers. Post pictures, rate restaurants and dishes from 1–5 stars, and connect with other food enthusiasts. Upload multiple photos, leave comments, follow users, and like posts to explore and recommend the best food spots around. Perfect for anyone looking to review and discover new dining experiences.

### Purpose:
The app’s purpose is to allow users to review and discover new restaurants and dishes by sharing photos, ratings, and comments.

### Target Audience:
Food lovers and foodies who want to share their dining experiences and find recommendations from others with similar interests.

### Main Function:
Users can upload multiple photos from their dining experiences, give ratings (1–5 stars), comment, follow other users, and like posts.

### Key Features:

- Upload multiple photos per post
- Rate dishes with a 1–5 star system
- Comment on posts and review images
- Follow other users and view their posts
- Like and interact with reviews

## **Grade Ambition**
My goal is to achieve  a **5** by implementing and documenting sufficient point-earning features as per the project requirements. I aim to collect at least **17 points** through a combination of technical and entrepreneurial criterias.

---

## **Fulfilled Requirements**

### **Core Requirements**
These features are fundamental to the app's functionality and have been implemented according to the specifications:

- **Modular Code Following Design Patterns (2 points):**  
  The app is structured with a modular architecture, where components are separated into services and widgets to follow the "Single Responsibility Principle." Examples: `ReviewService` handles reviews, and `NearbyRestaurantsService` handles location data. This follows MVVM design guidelines.

- **Self-contained Widgets (1 point):**  
  All widgets manage their own state independently, e.g., `UserPage` and `PostView` retrieve data directly from Firestore without global dependencies.

- **Firebase Authentication (1 point):**  
  Google Sign-In is implemented via Firebase in the `LoginPage`.

- **Account Management (1 point):**  
  User data, such as followers, followed accounts, and reviews, is managed through Firestore.

- **Real-Time Updates (1 point):**  
  Reviews and comments are updated in real-time using Firestore streams (`UserPage`, `PostView`).

---

### **Technical Requirements**

- **Sensor Integration (1 point):**  
  GPS is used in the `NearbyRestaurantsService` to find restaurants near the user's location.

- **Forms and Input Validation (2 points):**  
  The `UsernameSetupPage` validates user input and ensures usernames are unique.

- **Third-Party Authentication (1 point):**  
  Google Sign-In is implemented using Firebase.

---

### **Entrepreneurial Requirements**
- **Using Firestore as a Database (2 points):**  
  All user profiles, reviews, and comments are managed and stored in Firestore.

- **Google Maps for Restaurant Discovery (2 points):**  
  Google Maps API is used in `NearbyRestaurantsService` and `DiscoverPage` to locate restaurants near the user's current or selected location.

---

## **Proposal for Custom Entrepreneurial Aspect**

### **Location-Based Social Interaction with Real-Time Reviews**

I propose the following innovation to be considered as a custom entrepreneurial aspect:

1. **Location-Based Filtering and Reviews:**  
   Users can find reviews and restaurants near their current or selected location using Google Maps API and GPS. This is implemented in `DiscoverPage` and `NearbyRestaurantsService`.

2. **Real-Time Updates for Social Interaction:**  
   Reviews, likes, and comments update in real-time via Firestore, enabling users to interact with content immediately.

3. **Social Network of User Profiles:**  
   Users can follow others and build a personalized network of recommendations and reviews. This is implemented in `UserPage`.

**Why This Is Entrepreneurial:**  
This solution combines location-based services, real-time updates, and social interaction to create an engaging and local user experience. It is a unique integration that adds value beyond traditional review apps.

---

**Request for Points:**  
I hope these aspects can be considered as additional entrepreneurial innovations and be awrded **1 point** each under the "Custom Entrepreneurial Aspect" criteria.

#### Link to halftime - screencast

https://www.youtube.com/watch?v=P6xEgPZ-ufk

#### Link to finished demo - screencast
https://www.youtube.com/watch?v=zy-FOiO47pA