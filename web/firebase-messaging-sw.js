// Firebase Cloud Messaging Service Worker for SKA-DAN
// This handles background push notifications on web

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration (same as in firebase_options.dart)
firebase.initializeApp({
  apiKey: 'AIzaSyBFc9L4gHexaFoyrSKF9VXuttTKnaXZP88',
  appId: '1:413383556944:web:dc7c67305b223b5299f655',
  messagingSenderId: '413383556944',
  projectId: 'ska-dan-app',
  authDomain: 'ska-dan-app.firebaseapp.com',
  storageBucket: 'ska-dan-app.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'SKA-DAN';
  const notificationOptions = {
    body: payload.notification?.body || 'Du har en ny besked',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.sagId || 'ska-dan-notification',
    data: payload.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click:', event);
  event.notification.close();

  // Open the app when notification is clicked
  const sagId = event.notification.data?.sagId;
  const urlToOpen = sagId ? `/#/sager/${sagId}` : '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Check if there is already a window/tab open
      for (const client of windowClients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          if (sagId) {
            client.postMessage({ type: 'NAVIGATE', sagId: sagId });
          }
          return;
        }
      }
      // If no window is open, open a new one
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
