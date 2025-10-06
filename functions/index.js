const {onObjectFinalized} = require("firebase-functions/v2/storage");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sharp = require("sharp");
const {Storage} = require("@google-cloud/storage");
const path = require("path");
const nodemailer = require("nodemailer");
const {getFirestore} = require("firebase-admin/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const runBackfill = require("./runBackfill");

setGlobalOptions({region: "europe-west1"});
admin.initializeApp();
const storage = new Storage();

exports.compressImage = onObjectFinalized(
    {
      region: "europe-west1", // Change this to match your bucket's region
    },
    async (event) => {
      const object = event.data;
      if (!object.contentType || !object.contentType.startsWith("image/")) {
        functions.logger.log("No content type specified or not an image.");
        return;
      }
      const bucket = storage.bucket(object.bucket);
      const filePath = object.name;
      const pathSegments = filePath.split("/");
      const chatType = pathSegments[0];
      const fileName = pathSegments.pop();

      const metadataKey = `compressed_${chatType}`;
      if (object.metadata && object.metadata[metadataKey] === "true") {
        functions.logger.log("Already processed image for this chat type.");
        return;
      }

      const tempFilePath = `/tmp/${fileName}`;
      const tempCompressedPath = `/tmp/compressed_${fileName}`;

      try {
        await bucket.file(filePath).download({
          destination: tempFilePath,
        });

        await sharp(tempFilePath)
            .resize(1024)
            .jpeg({quality: 50})
            .toFile(tempCompressedPath);

        await bucket.upload(tempCompressedPath, {
          destination: filePath,
          metadata: {
            metadata: {
              [metadataKey]: "true",
            },
          },
        });

        functions.logger.log(
            `Document compressed and uploaded successfully for ${chatType}.`,
        );

        try {
          const [metadata] = await bucket.file(filePath).getMetadata();
          if (!metadata.metadata || metadata.metadata[metadataKey] !== "true") {
            await bucket.file(filePath).delete();
            functions.logger.log(`Original file deleted: ${filePath}`);
          }
        } catch (error) {
          functions.logger.error(
              `Failed to delete the original file: ${filePath}`,
              error,
          );
        }
      } catch (error) {
        functions.logger.error(`Error during processing: ${error}`, error);
      }
    });

/**
 * Helper function to introduce a delay in milliseconds.
 * @param {number} ms - The time to delay in milliseconds.
 * @return {Promise} A promise that resolves after the delay.
 */
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Function to move a file in the Google Cloud Storage bucket with retry logic.
 * @param {Object} bucket - The storage bucket object.
 * @param {string} filePath - The source file path in the bucket.
 * @param {string} destinationPath - The destination path for the file.
 * @param {number} retries - Number of retries allowed.
 * @param {number} delayMs - Initial delay between retries in milliseconds.
 */
async function moveFileWithRetry(
    bucket, filePath, destinationPath, retries = 5, delayMs = 2000,
) {
  try {
    await bucket.file(filePath).move(destinationPath);
    functions.logger.log(`File moved to: ${destinationPath}`);
  } catch (error) {
    if (error.code === 429 && retries > 0) {
      functions.logger.warn(`Rate limit hit, retrying in ${delayMs}ms...`);
      await delay(delayMs); // Wait before retrying
      await moveFileWithRetry(bucket, filePath, destinationPath,
          retries - 1, delayMs * 2); // Exponential backoff
    } else {
      functions.logger.error(`Error moving file after retries: ${error}`);
    }
  }
}

/**
 * Helper function to extract the month from the upload path.
 * This assumes the month is part of the 'inbox' folder in the path.
 * @param {string} filePath - The full path of the uploaded file.
 * @return {string|null} The extracted month if found, otherwise null.
 */
function extractMonthFromUploadPath(filePath) {
  const pathSegments = filePath.split("/");
  // The 'inbox' folder should be at index 1 and the month at index 2
  if (pathSegments.length >= 3 && pathSegments[1] === "inbox") {
    return pathSegments[2]; // Extract the month (e.g., "October")
  }
  return null; // Return null if the expected structure is not found
}

exports.organizeInvoiceUpload = onObjectFinalized(
    {
      region: "europe-west1",
    },
    async (event) => {
      const object = event.data;
      const filePath = object.name; // e.g., "pdfs/inbox/July/123456789.pdf"

      if (!filePath.includes("inbox")) {
        functions.logger.log("📦 File is already in final location. Skipping.");
        return;
      }

      const fileName = path.basename(filePath); // "123456789.pdf"
      const rawAccountNumber = fileName.split(".")[0];

      const month = extractMonthFromUploadPath(filePath);
      if (!month) {
        functions.logger.error("❌ No valid month found in file path.");
        return;
      }

      let isElectricity = false;
      let snapshot;

      // 🔍 First try matching electricity account number
      snapshot = await admin.firestore()
          .collectionGroup("properties")
          .where("electricityAccountNumber", "==", rawAccountNumber)
          .get();

      if (snapshot.empty) {
        // ⚠️ Not electricity, try water account number
        snapshot = await admin.firestore()
            .collectionGroup("properties")
            .where("accountNumber", "==", rawAccountNumber)
            .get();
      } else {
        isElectricity = true;
      }

      if (snapshot.empty) {
        functions.logger.log(
            "❌ No property found for account: " + rawAccountNumber,
        );
        return;
      }

      const propertyData = snapshot.docs[0].data();
      const cellNumber = propertyData.cellNumber;
      const propertyAddress = propertyData.address;

      // ✅ File name stays the same
      const destinationFileName = `${rawAccountNumber}.pdf`;

      const destinationPath =
        `pdfs/${month}/${cellNumber}/${propertyAddress}/${destinationFileName}`;

      functions.logger.log(
          "📁 Organizing invoice for account " +
             rawAccountNumber +
          " (" + (isElectricity ? "Electricity" : "Water") + ") → " +
       destinationPath,
      );

      try {
        const bucket = storage.bucket(object.bucket);
        await moveFileWithRetry(bucket, filePath, destinationPath);
        functions.logger.log("✅ File moved successfully.");
      } catch (error) {
        functions.logger.error(`❌ Error moving file: ${error}`);
      }
    },
);

// ✅ Configure Nodemailer with your service email
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "cyberfoxitsa@gmail.com",
    pass: "bwwo amjd azes fncb",
  },
});


/**
 * Handles sending an email when a fault's stage changes.
 * Supports both district and local municipalities.
 * @param {functions.Event} event - The Firestore update event
 */
async function handleFaultEmail(event) {
  console.log("⚡ Function triggered");

  // Log full event to inspect structure
  console.log("📦 Raw event:", JSON.stringify(event, null, 2));

  // Check that after exists
  if (!event.data || !event.data.after || !event.data.after.data) {
    console.error("🔥 Firestore event missing 'after.data'");
    return;
  }

  const after = event.data.after.data();
  if (!after) {
    console.error("🔥 'after.data()' is null or empty");
    return;
  }

  const faultStage = after.faultStage || null;
  const referenceNumber = after.ref || "No Ref";
  const assignedEmployee = after.attendeeAllocated || null;
  const assignedManager = after.managerAllocated || null;
  const assignedAdmin = after.adminAllocated || null;

  console.log(`🛠️ Fault Updated: ${referenceNumber}, Stage: ${faultStage}`);
  console.log(
      `👤 Assigned:
     Employee=${assignedEmployee},
     Manager=${assignedManager},
     Admin=${assignedAdmin}`,
  );

  if (!assignedEmployee && !assignedManager && !assignedAdmin) {
    console.log("⚠️ No assigned users found. Skipping email.");
    return;
  }

  let employeeEmail = "";
  let managerEmail = "";
  let adminEmail = "";

  // 🎯 Use directly written emails from the fault document
  employeeEmail = after.employeeEmail || "";
  managerEmail = after.managerEmail || "";
  adminEmail = after.adminEmail || "";

  console.log(`📧 Employee Email: ${employeeEmail}`);
  console.log(`📧 Manager Email: ${managerEmail}`);
  console.log(`📧 Admin Email: ${adminEmail}`);

  // 📨 Determine who to notify
  let recipientEmail = "";
  let subject = "";
  let emailBody = "";

  switch (faultStage) {
    case 1:
      subject = `🚨 Fault Reported: ${referenceNumber}`;
      recipientEmail = adminEmail;
      emailBody =
        "<p>Dear Admin,</p>" +
        "<p>A new fault has been reported with reference number " +
        `<strong>${referenceNumber}</strong>.</p>` +
        "<p>Please review and assign it to the appropriate personnel.</p>" +
        "<p>Thank you,<br/>Municipal Services App</p>";
      break;

    case 2:
      subject = `✅ Fault Assigned: ${referenceNumber}`;
      recipientEmail = employeeEmail;
      emailBody =
        `<p>Dear ${assignedEmployee},</p>` +
        "<p>You have been assigned a new fault to attend to.</p>" +
          "<p>Below are the details:</p>" +
        `<ul>
          <li><strong>Reference Number:</strong> ${referenceNumber}</li>
          <li><strong>Address:</strong> ${after.address}</li>
          <li><strong>Department:</strong> ${after.depAllocated}</li>
          <li><strong>Reported On:</strong> ${after.dateReported}</li>
          <li><strong>Description:</strong> ${after.faultDescription}</li>
        </ul>` +
        "<p>Please log into the Municipal Services App to respond.</p>" +
        "<p>Thank you for your service.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";
      break;

    case 3:
      subject = `↩️ Fault Returned: ${referenceNumber}`;
      emailBody =
        "<p>The fault <strong>" + referenceNumber +
        "</strong> has been returned for further " +
        "action.</p>" +
        "<p>Please check the app for additional instructions.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";

      // Check if fault was returned from Stage 4 (admin review)
      if (event.data.before.data().faultStage === 4) {
        const recipients = [employeeEmail, managerEmail].filter(Boolean);

        await Promise.all(recipients.map(async (email) => {
          const mailOptions = {
            from: "Municipal Services App <cyberfoxitsa@gmail.com>",
            to: email,
            subject,
            html: "<p>Dear User,</p>" + emailBody,
          };
          try {
            await transporter.sendMail(mailOptions);
            console.log(`📨 Email sent to: ${email}`);
          } catch (error) {
            console.error(`❌ Failed to send email to ${email}:`, error);
          }
        }));
        return; // prevent sending the default admin-only email
      }

      // Normal case: employee marks fault as in progress
      subject = `⚙️ Work In Progress: ${referenceNumber}`;
      recipientEmail = adminEmail;
      emailBody =
        "<p>Dear Admin,</p>" +
        "<p>The employee has marked fault " +
        `<strong>${referenceNumber}</strong> as 'Work In Progress'.</p>` +
        "<p>Please monitor the progress.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";
      break;

    case 4:
      subject = `🔍 Fault Review: ${referenceNumber}`;
      recipientEmail = adminEmail;
      emailBody =
        "<p>Dear Admin,</p>" +
        "<p>The fault <strong>" + referenceNumber +
        "</strong> is now under review.</p>" +
        "<p><strong>Department:</strong><br/>" +
          (after.depAllocated || "") + "</p>" +
        "<p><strong>Address:</strong> " + (after.address || "") + "</p>" +
        "<p><strong>Description:</strong> " + (after.faultDescription || "") +
        "</p>" +
        "<p>Please verify and confirm the status.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";
      break;

    case 5: {
      subject = `🎉 Fault Resolved: ${referenceNumber}`;
      emailBody =
        "<p>Dear Team,</p>" +
        "<p>The fault <strong>" + referenceNumber +
        "</strong> has been resolved.</p>" +
        "<p><strong>Department:</strong><br/>" +
          (after.depAllocated || "") + "</p>" +
        "<p><strong>Address:</strong> " + (after.address || "") + "</p>" +
        "<p><strong>Description:</strong> " + (after.faultDescription || "") +
        "</p>" +
        "<p>Marked as resolved by the administrator.</p>" +
        "<p>Thank you for your contributions.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";

      const recipients = [employeeEmail, managerEmail].filter(Boolean);
      if (recipients.length === 0) {
        console.log("⚠️ No manager or employee email found. Skipping email.");
        return;
      }

      const mailOptions = {
        from: "Municipal Services App <cyberfoxitsa@gmail.com>",
        to: recipients.join(","),
        subject,
        html: emailBody,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log(`📨 Email sent to: ${recipients.join(", ")}`);
      } catch (error) {
        console.error("❌ Failed to send email:", error);
      }
      break;
    }

    default:
      console.log("⚠️ No email required for this stage.");
      return;
  }
  // ✉️ Send email
  if (recipientEmail) {
    const mailOptions = {
      from: "Municipal Services App <cyberfoxitsa@gmail.com>",
      to: recipientEmail,
      subject,
      html: emailBody,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`📨 Email sent to: ${recipientEmail}`);
    } catch (error) {
      console.error("❌ Failed to send email:", error);
    }
  } else {
    console.log("⚠️ No recipient email found. Email not sent.");
  }
}
/**
 * Trigger for fault stage updates in district municipalities.
 * Sends email alerts to assigned users.
 */
// ✅ Trigger for District Municipalities
exports.sendFaultUpdateEmail = functions
    .region("europe-west1")
    .firestore
    .document(
        "districts/{districtId}/municipalities/{municipalityId}/" +
        "faultReporting/{faultId}",
    )
    .onUpdate(async (change, context) => {
      console.log("🔥 Gen 1 Firestore trigger activated");

      const before = change.before.data();
      const after = change.after.data();

      if (!before || !after) {
        console.error("❌ Missing before or after data");
        return;
      }

      const event = {
        data: {
          before: change.before,
          after: change.after,
        },
        params: context.params,
      };
      event.params.isLocal = false;

      return await handleFaultEmail(event);
    });
/**
 * Trigger for fault stage updates in local municipalities.
 * Sends email alerts to assigned users.
 */
// ✅ Trigger for Local Municipalities
exports.sendFaultUpdateEmailLocal = functions
    .region("europe-west1")
    .firestore
    .document(
        "localMunicipalities/{municipalityId}/faultReporting/{faultId}",
    )
    .onUpdate(async (change, context) => {
      console.log("🔥 Gen 1 Firestore trigger (local) activated");

      const before = change.before.data();
      const after = change.after.data();

      if (!before || !after) {
        console.error("❌ Missing before or after data");
        return;
      }

      const event = {
        data: {
          before: change.before,
          after: change.after,
        },
        params: context.params,
      };
      event.params.isLocal = true; // ✅ Local flag

      return await handleFaultEmail(event);
    });

const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const {getAuth} = require("firebase-admin/auth");
/**
 * Create or resolve an Auth user for this municipal user doc,
 * then write back the uid so userUpdated_* can upsert usersByUid/{uid}.
 *
 * @param {*} event Firestore onDocumentCreated event.
 * @param {"district"|"local"} userType Municipality type.
 * @return {Promise<void>}
 */
async function handleUserCreation(event, userType) {
  if (!event.data || !event.data.data) {
    functions.logger.error("❌ Missing Firestore data in event.");
    return;
  }
  const data = event.data.data();


  if (!data) {
    console.error(`❌ No user data found in the ${userType} user document.`);
    return;
  }

  const {email, password, firstName, lastName} = data;

  if (!email || !password) {
    console.error(`❌ Missing email or password for ${userType} user.`);
    return;
  }

  try {
    await getAuth().createUser({
      email,
      password,
      displayName: `${firstName || ""} ${lastName || ""}`.trim(),
    });
    console.log(`✅ Firebase Auth user created for ${email} (${userType})`);
  } catch (error) {
    console.error(`Error creating Firebase Auth for ${userType}:`, error);
  }
}

// ✅ For district-based municipalities
exports.createAuthUserForDistrict = onDocumentCreated(
    {
      region: "europe-west1",
      document:
        "districts/{districtId}/municipalities/{municipalityId}/" +
        "users/{userId}",
    },
    async (event) => {
      await handleUserCreation(event, "district");
    },
);

// ✅ For local municipalities
exports.createAuthUserForLocal = onDocumentCreated(
    {
      region: "europe-west1",
      document: "localMunicipalities/{municipalityId}/users/{userId}",
    },
    async (event) => {
      await handleUserCreation(event, "local");
    },
);

/**
 * Throws if the caller is not a superadmin.
 * @param {functions.https.CallableContext} context Callable context.
 * @throws {functions.https.HttpsError} Permission error when not allowed.
 */
function assertSuperadmin(context) {
  const hasAuth = !!context.auth;
  const isSuper = hasAuth && context.auth.token.superadmin === true;
  if (!isSuper) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Not authorized (superadmin required).",
    );
  }
}

/**
 * Callable: set developer custom claims on a user.
 * data = {
 *   uid: string,
 *   scope?: {
 *     all?: boolean,
 *     districts?: { [districtId: string]: true },
 *     municipalities?: { [municipalityId: string]: true }
 *   }
 * }
 * @param {Object} data Payload with uid and scope.
 * @param {functions.https.CallableContext} context Callable context.
 * @return {Promise<Object>} Result object with ok, uid, devScope.
 */
exports.setDeveloperClaims = functions
    .region("europe-west1")
    .https.onCall(async (data, context) => {
      assertSuperadmin(context);

      const uid = data && data.uid;
      if (!uid) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing uid.",
        );
      }

      // Minimal validation to keep the token small & safe
      const scope = (data && data.scope) || {};
      const devScope = {
        all: !!scope.all,
        districts:
             (scope.districts &&
               typeof scope.districts === "object" &&
               scope.districts) ||
             {},
        municipalities:
             (scope.municipalities &&
               typeof scope.municipalities === "object" &&
               scope.municipalities) ||
             {},
      };


      await admin.auth().setCustomUserClaims(uid, {
        developer: true,
        devScope: devScope,
      });

      // Force token refresh next time user calls getIdToken(true)
      return {ok: true, uid: uid, devScope: devScope};
    });

/**
 * Callable: clear ALL custom claims for a user.
 * (If you store other flags, adapt to preserve them.)
 * data = { uid: string }
 * @param {Object} data Payload with uid.
 * @param {functions.https.CallableContext} context Callable context.
 * @return {Promise<Object>} Result object with ok and uid.
 */
exports.clearDeveloperClaims = functions
    .region("europe-west1")
    .https.onCall(async (data, context) => {
      assertSuperadmin(context);
      const uid = data && data.uid;
      if (!uid) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing uid.",
        );
      }

      // Remove developer flags but preserve other claims if needed.
      // For simplicity we wipe all claims here; adjust if you store more flags.
      await admin.auth().setCustomUserClaims(uid, null);
      return {ok: true, uid};
    });

/**
 * Callable: return caller's current auth claims.
 * Useful for debugging from the client.
 * @param {Object} _data Unused.
 * @param {functions.https.CallableContext} context Callable context.
 * @return {Promise<Object>} Caller identity and claims.
 */
exports.whoAmI = functions
    .region("europe-west1")
    .https.onCall(async (_data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be signed in.",
        );
      }
      return {
        uid: context.auth.uid,
        email: context.auth.token.email || null,
        claims: context.auth.token,
      };
    });

const db = getFirestore();
const auth = getAuth();

/**
 * @typedef {Object} MirrorPathInfo
 * @property {boolean} isLocal
 * @property {(string|null)} dId
 * @property {string} mId
 * @property {string} mirrorPath
 */

/**
 * Extract context (dId, mId) and build a usersByUid mirror path.
 *
 * @param {string} refPath Absolute path to the source user doc.
 * @param {string} uid Firebase Auth UID to key the mirror with.
 * @return {MirrorPathInfo} Parsed flags and mirror path.
 */
function buildMirrorPathFromRef(refPath, uid) {
  const parts = refPath.split("/");

  if (parts[0] === "districts") {
    const dId = parts[1];
    const mId = parts[3];
    return {
      isLocal: false,
      dId,
      mId,
      mirrorPath:
              `districts/${dId}/municipalities/` +
              `${mId}/usersByUid/${uid}`,
    };
  }

  if (parts[0] === "localMunicipalities") {
    const mId = parts[1];
    return {
      isLocal: true,
      dId: null,
      mId,
      mirrorPath: `localMunicipalities/${mId}/usersByUid/${uid}`,
    };
  }

  throw new Error(`Unexpected user path: ${refPath}`);
}

/**
 * Resolve the Auth UID for a municipal user document.
 * Prefers data.uid, then data.authUid, then email lookup.
 *
 * @param {Object.<string, *>} userDoc The user document data.
 * @return {Promise<(string|null)>} Resolved UID or null.
 */
async function resolveUid(userDoc) {
  if (userDoc.uid) return userDoc.uid;
  if (userDoc.authUid) return userDoc.authUid;

  if (userDoc.email) {
    try {
      const u = await auth.getUserByEmail(userDoc.email);
      return u.uid;
    } catch (e) {
      console.warn(
          `No Auth user for email ${userDoc.email}: ${e.message}`,
      );
    }
  }
  return null;
}

/**
 * Create or update the mirror document keyed by UID.
 *
 * @param {*} originalSnap Snapshot of the original user doc.
 * @return {Promise<void>} Resolves when the mirror is written.
 */
async function upsertMirror(originalSnap) {
  const data = originalSnap.data();
  if (!data) return;

  const uid = await resolveUid(data);
  if (!uid) {
    console.warn(
        "Skipping mirror upsert — missing uid for",
        originalSnap.ref.path,
    );
    return;
  }

  const {mirrorPath} = buildMirrorPathFromRef(
      originalSnap.ref.path,
      uid,
  );

  const mirrorData = {
    email: data.email || null,
    role: data.userRole || data.role || null,
    official: data.official === true,
    deptName: data.deptName || null,
    updatedAt: Date.now(),
  };

  await db.doc(mirrorPath).set(mirrorData, {merge: true});
  console.log(`Mirror upserted: ${mirrorPath}`);
}

/**
 * Delete the mirror document keyed by UID.
 *
 * @param {*} originalSnap Snapshot of the original user doc.
 * @return {Promise<void>} Resolves when the mirror is deleted.
 */
async function deleteMirror(originalSnap) {
  const data = originalSnap.data() || {};
  const uid = await resolveUid(data);
  if (!uid) {
    console.warn(
        "Skipping mirror delete — missing uid for",
        originalSnap.ref.path,
    );
    return;
  }
  const {mirrorPath} = buildMirrorPathFromRef(
      originalSnap.ref.path,
      uid,
  );
  await db.doc(mirrorPath).delete().catch(() => {});
  console.log(`Mirror deleted: ${mirrorPath}`);
}

/** Triggers for DISTRICT municipal users */
exports.userCreated_district = onDocumentCreated(
    "districts/{dId}/municipalities/{mId}/users/{autoId}",
    async (event) => upsertMirror(event.data),
);

exports.userUpdated_district = onDocumentUpdated(
    "districts/{dId}/municipalities/{mId}/users/{autoId}",
    async (event) => {
      const before = event.data.before.data() || {};
      const after = event.data.after.data() || {};
      const changed = [
        "email",
        "userRole",
        "role",
        "official",
        "deptName",
        "uid",
        "authUid",
      ].some((k) => before[k] !== after[k]);
      if (changed) {
        await upsertMirror(event.data.after);
      }
    },
);

exports.userDeleted_district = onDocumentDeleted(
    "districts/{dId}/municipalities/{mId}/users/{autoId}",
    async (event) => deleteMirror(event.data),
);

/** Triggers for LOCAL municipal users */
exports.userCreated_local = onDocumentCreated(
    "localMunicipalities/{mId}/users/{autoId}",
    async (event) => upsertMirror(event.data),
);

exports.userUpdated_local = onDocumentUpdated(
    "localMunicipalities/{mId}/users/{autoId}",
    async (event) => {
      const before = event.data.before.data() || {};
      const after = event.data.after.data() || {};
      const changed = [
        "email",
        "userRole",
        "role",
        "official",
        "deptName",
        "uid",
        "authUid",
      ].some((k) => before[k] !== after[k]);
      if (changed) {
        await upsertMirror(event.data.after);
      }
    },
);

exports.userDeleted_local = onDocumentDeleted(
    "localMunicipalities/{mId}/users/{autoId}",
    async (event) => deleteMirror(event.data),
);

const BACKFILL_SECRET=defineSecret("BACKFILL_SECRET");

exports.backfillUsersByUid = onRequest(
    {
      region: "europe-west1",
      secrets: [BACKFILL_SECRET],
      timeoutSeconds: 540,
    },
    async (req, res) => {
      const provided = req.get("x-backfill-secret") || "";
      if (provided !== BACKFILL_SECRET.value()) {
        res.status(403).send("Forbidden");
        return;
      }
      try {
        await runBackfill();
        res.status(200).send("ok");
      } catch (err) {
        console.error("Backfill error:", err);
        res.status(500).send("error");
      }
    },
);

/**
 * POST with header:
 *   x-superadmin-secret: <your secret>
 * Body (JSON): one of { uid | email | phone } and optional { enable }
 * Examples:
 *   { "email": "admin@example.com", "enable": true }
 *   { "phone": "+27XXXXXXXXX", "enable": false }
 */
const SUPERADMIN_SECRET = defineSecret("SUPERADMIN_SECRET");

exports.setSuperadmin = onRequest(
    {region: "europe-west1", secrets: [SUPERADMIN_SECRET], timeoutSeconds: 60},
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Use POST");
        return;
      }

      const provided = req.get("x-superadmin-secret") || "";
      if (provided !== SUPERADMIN_SECRET.value()) {
        res.status(403).send("Forbidden");
        return;
      }

      try {
        const body = typeof req.body === "object" ? req.body : {};
        const {uid, email, phone, enable = true} = body;

        const admin = require("firebase-admin");
        if (!admin.apps.length) admin.initializeApp();

        let targetUid = uid;
        if (!targetUid) {
          const auth = admin.auth();
          if (email) {
            targetUid = (await auth.getUserByEmail(email)).uid;
          } else if (phone) {
            targetUid = (await auth.getUserByPhoneNumber(phone)).uid;
          }
        }
        if (!targetUid) {
          res.status(400).send("Missing uid/email/phone");
          return;
        }

        await admin
            .auth()
            .setCustomUserClaims(
                targetUid,
            enable ? {superadmin: true} : null,
            );
      } catch (e) {
        console.error(e);
        res.status(500).send("error");
      }
    },
);

const {HttpsError} = functions.https;
/**
 * Recursively deletes a document and all of its subcollections.
 * Used when the Admin SDK doesn't provide `firestore().recursiveDelete`.
 *
 * @param {FirebaseFirestore.DocumentReference} docRef
 *     Firestore document to delete (including all nested subcollections).
 * @return {Promise<void>} Resolves when deletion completes.
 */
async function deleteDocAndSubs(docRef) {
  // Delete all subcollections first
  const subcols = await docRef.listCollections();
  for (const col of subcols) {
    // Page through the collection in batches
    let snap = await col.limit(500).get();
    while (!snap.empty) {
      // Recurse into each doc
      await Promise.all(
          snap.docs.map((d) => deleteDocAndSubs(d.ref)),
      );
      // Next page (after deletions)
      snap = await col.limit(500).get();
    }
  }
  // Now delete the document itself
  await docRef.delete();
}

exports.deleteMunicipalityRecursive = functions
    .region("europe-west1")
    .runWith({timeoutSeconds: 540, memory: "1GB"})
    .https.onCall(async (data, context) => {
    // ---- Auth check (superadmin only) ----
      const isSuperadmin =
      context.auth &&
      context.auth.token &&
      context.auth.token.superadmin === true;

      if (!isSuperadmin) {
        throw new HttpsError(
            "permission-denied",
            "Superadmin only.",
        );
      }

      // ---- Validate args ----
      const basePath =
        (data && typeof data.basePath === "string") ?
        data.basePath.trim() :
        "";


      if (!basePath) {
        throw new HttpsError(
            "invalid-argument",
            "basePath is required.",
        );
      }

      // ---- Recursive delete ----
      const docRef = admin.firestore().doc(basePath);

      try {
        const fs = admin.firestore();
        const hasRecursive =
          typeof fs.recursiveDelete === "function";

        if (hasRecursive) {
          await fs.recursiveDelete(docRef);
        } else {
          await deleteDocAndSubs(docRef);
        }
        return {ok: true};
      } catch (err) {
        console.error(
            "Recursive delete failed for",
            basePath,
            err,
        );
        const msg =
          (err && err.message) ? err.message : "internal";
        throw new HttpsError("internal", msg);
      }
    });

exports.listActionLogAddresses = functions
    .region("europe-west1")
    .https.onCall(async (data, context) => {
      const {HttpsError} = functions.https;

      // Optional: require superadmin
      if (!context.auth || context.auth.token.superadmin !== true) {
        throw new HttpsError("permission-denied", "Superadmin only.");
      }

      const toStr = (v) => (typeof v === "string" ? v.trim() : "");
      const stripSlashes = (s) => s.replace(/^\/+|\/+$/g, "");

      const basePath = stripSlashes(toStr(data?.basePath));
      const uploader = stripSlashes(toStr(data?.uploader));

      if (!basePath || !uploader) {
        throw new HttpsError(
            "invalid-argument",
            "basePath and uploader are required.",
        );
      }

      // IMPORTANT: do not call this variable "path"
      const docPath = `${basePath}/actionLogs/${uploader}`;

      try {
        const docRef = admin.firestore().doc(docPath);
        const cols = await docRef.listCollections();
        const addresses = cols
            .map((c) => c.id)
            .sort((a, b) => a.localeCompare(b));

        return {addresses};
      } catch (err) {
        console.error(
            "listActionLogAddresses failed",
            {docPath, err: err.message},
        );
        throw new HttpsError("internal", err.message || "internal");
      }
    });

const MAPS_SERVER_KEY = defineSecret("MAPS_SERVER_KEY");
const ALLOWED_ORIGINS = new Set([
  "http://localhost:5173",
  "http://cyberfox.dedicated.co.za:83",
  "https://municipal-tracker-msunduzi.web.app",
]);

exports.geocodeAddress = onRequest(
    {region: "europe-west1", secrets: [MAPS_SERVER_KEY], timeoutSeconds: 30},
    async (req, res) => {
    // CORS
      const origin = req.get("origin") || "";
      const allow = ALLOWED_ORIGINS.has(origin);
      if (allow) {
        res.set("Access-Control-Allow-Origin", origin);
        res.set("Vary", "Origin");
      }
      res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      if (req.method === "OPTIONS") return res.status(204).send("");

      try {
        const address = (req.query.address || "").toString().trim();
        if (!address) return res.status(400).json({error: "address required"});

        const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
        url.searchParams.set("address", address);
        url.searchParams.set("region", "za"); // bias to South Africa (optional)
        url.searchParams.set("key", MAPS_SERVER_KEY.value());

        // Node 18 in Functions v2 has fetch built-in
        const r = await fetch(url.toString());
        const json = await r.json();

        // Pass through the Geocoding response (status/ results / error_message)
        res.status(r.ok ? 200 : 500).json(json);
      } catch (e) {
        console.error("geocodeAddress error:", e);
        res.status(500).json({error: e.message || "internal"});
      }
    },
);
