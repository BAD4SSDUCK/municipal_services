// ✅ Fix: Ensure correct imports for Firebase Service Worker
importScripts("https://www.gstatic.com/firebasejs/10.11.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.0/firebase-messaging-compat.js");

// ✅ Fix: Initialize Firebase inside Service Worker
firebase.initializeApp({
    apiKey: "AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY",
    projectId: "municipal-tracker-msunduzi",
    storageBucket: "municipal-tracker-msunduzi.appspot.com",
    messagingSenderId: "183405317738",
    appId: "1:183405317738:web:bcbd50b2a791564f790413",
    measurementId: "G-PJ8BZFZZ8D"
});

// ✅ Fix: Initialize Firebase Messaging
const messaging = firebase.messaging();

// ✅ Fix: Background message handler
messaging.onBackgroundMessage(function(payload) {
    console.log("📩 Received background message: ", payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: "/firebase-logo.png"
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
