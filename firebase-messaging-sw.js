// firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-messaging.js');

const firebaseConfig = {
  apiKey: "AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY",
  authDomain: "municipal-tracker-msunduzi.firebaseapp.com",
  projectId: "municipal-tracker-msunduzi",
  storageBucket: "municipal-tracker-msunduzi.appspot.com",
  messagingSenderId: "183405317738",
  appId: "1:183405317738:web:bcbd50b2a791564f790413",
  measurementId: "G-PJ8BZFZZ8D"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Add your VAPID key here
messaging.getToken({ vapidKey: 'BKIRt7npcxun4bLzG-F_HXEHLu49TVVqBAHSx_V6KPwv8tIrIl2PIHvsoJdh_vGWhuM-V6byFLZVAqnk53LM6KM' }).then((currentToken) => {
  if (currentToken) {
    console.log('Token retrieved:', currentToken);
  } else {
    console.log('No registration token available. Request permission to generate one.');
  }
}).catch((err) => {
  console.error('An error occurred while retrieving token. ', err);
});
