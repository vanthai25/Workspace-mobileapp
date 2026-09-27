importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"
);

importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyCF0cTTVMPcx27OXCK5yv5P2vu6zC9wooM",
  authDomain: "hrm-hung-vuong.firebaseapp.com",
  projectId: "hrm-hung-vuong",
  storageBucket: "hrm-hung-vuong.firebasestorage.app",
  messagingSenderId: "413550551562",
  appId: "1:413550551562:web:4ff3969e3f6bfc4cd8f5f3"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message:",
    payload
  );
});