import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

let credential;
const serviceAccountPath = path.resolve(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  credential = admin.credential.cert(require(serviceAccountPath));
} else {
  throw new Error("Missing credentials");
}
admin.initializeApp({ credential });

const token = "dJq45NH_TuyoFwmjPFRwKO:APA91bGn4PBsL-0gBKAFw9oMXgpTla3JR_opbgz5qabu-7K_z1jSfojPFCdELi0U2NdhK81EjpVM2_yTdf6cTQYpxdYIPAWMXZcDFDzq5GifrKC5tKF-pHE";

async function send() {
  try {
    const res = await admin.messaging().send({
      token,
      notification: { title: "Test Notification", body: "Checking if push works" }
    });
    console.log("Success:", res);
  } catch (e) {
    console.error("Error:", e);
  }
}

send();
