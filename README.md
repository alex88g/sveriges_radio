# sveriges_radio 📻

## Overview

**Sveriges Radio App** The Flutter app in the code provided is a Swedish Radio Channels player. It is designed to fetch radio channels from an API, display them in a list, and allow users to tap on a channel to listen to it. 



Here's a summary of its components and functionality:



- **Channel Class**: Represents a radio channel with properties like id, name, imageUrl, color, and others. It includes a factory constructor to create instances from JSON data.



- **MyApp Widget**: The root of the application, setting up the theme and home screen of the app.



- **MyScreen Widget**: The main screen that displays a list of channels. It fetches channel data from an API and uses a `ListView.builder` to create a list.



- **_buildCard Method**: Creates a card for each radio channel with a subtle 3D effect, showing the channel's image and information. Tapping on it navigates to a new screen to play the channel.



- **RadioPlayerScreen Widget**: A screen that uses `AudioPlayer` to play the selected radio channel. It has play and pause functionality.



- **Network Operations**: The app uses the `http` package to perform network requests to fetch channel data and audio URLs.



- **Error Handling**: The app includes basic error handling for network requests.



The app is simple in terms of UI, relying on Material components, but it's functional, providing users with the ability to explore and listen to various Swedish radio channels.

## 🌟 Main Features

### 📡 Efficient Data Fetching
**Description:** Fetches and dynamically renders data from the specified SR API.

### 🎨 Sleek User Interface
**Description:** Card-based design with each showcasing an optional image (or a placeholder when absent) accompanied by related text.

### 🪄 3D Visualization
**Description:** Enhances user experience with subtle 3D effects on the cards.

### 🔒 Robust Error Handling
**Description:** Integrated error-handling mechanisms to tackle potential data-fetching issues.

## 🚀 Getting Started

### Prerequisites

Before diving in, ensure Flutter is set up on your machine. If not, refer to Flutter's official [Installation Guide](https://flutter.dev/docs/get-started/install).

### Installation Steps
**Clone the Repository:**

git clone 

### Setup and Dependencies:**
**Move into the project directory and fetch dependencies.**

cd sveriges_radio
flutter pub get

### Running the App:
**Start the app on your preferred device or emulator.**
flutter run

### Additional Information

### 📸 Screenshots
![Skärmbild_2023-11-09_143152-removebg-preview](https://github.com/alex88g/sveriges_radio/assets/113544188/ebcbc908-8b8e-4813-b24d-3e59218fe493)
![Skärmbild_2023-11-10_045446-removebg-preview](https://github.com/alex88g/sveriges_radio/assets/113544188/af2bc93b-1951-4c13-9844-64de91eec9ef)



### Figma 
https://www.figma.com/file/4m9fgkmcCFsXCYsNv0bgXU/sveriges_radio?type=design&node-id=0-1&mode=design&t=M8iF5hKHLhvs1LgB-0

### Summary
The app is a Swedish radio channel player. It displays a list of channels fetched via an API, where the user can select and listen to different stations. Each channel is presented with a card that contains an image and information, and can be played in a built-in media player.

### 📚 Acknowledgments
Appreciation to the Flutter team for their comprehensive documentation.
Special thanks to api.sr.se for providing the required data.

### 📜 License
This project is governed by the IT- Högskoaln license.
