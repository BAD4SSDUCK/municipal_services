const {onObjectFinalized} = require("firebase-functions/v2/storage");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sharp = require("sharp");
const {Storage} = require("@google-cloud/storage");
const path = require("path");
const nodemailer = require("nodemailer");

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
      region: "europe-west1", // Match this to your bucket's region
    },
    async (event) => {
      const object = event.data;
      const filePath = object.name; // e.g., "pdfs/inbox/October/123456789.pdf"

      if (!filePath.includes("inbox")) {
        functions.logger.log("File is already in the final location,skipping.");
        return;
      }

      const fileName = path.basename(filePath); // Extract "123456789.pdf"
      const accountNumber = fileName.split(".")[0];
      functions.logger.log(`Processing file for account number:
       ${accountNumber}`);

      const month = extractMonthFromUploadPath(filePath);

      if (!month) {
        functions.logger.error("No valid month found in the file path.");
        return;
      }
      // Fetch user data from Firestore using accountNumber
      const propertiesRef = admin.firestore()
          .collectionGroup("properties")
          .where("accountNumber", "==", accountNumber);
      const snapshot = await propertiesRef.get();

      if (snapshot.empty) {
        functions.logger.log(
            `No matching property found for account number: ${accountNumber}`);
        return;
      }
      const propertyData = snapshot.docs[0].data();
      const cellNumber = propertyData.cellNumber;
      const propertyAddress = propertyData.address;


      const destinationPath = `pdfs/${month}/${cellNumber}/` +
      `${propertyAddress}/${accountNumber}.pdf`;

      try {
        const bucket = storage.bucket(object.bucket);
        await moveFileWithRetry(bucket, filePath, destinationPath);
      } catch (error) {
        functions.logger.error(`Error moving file: ${error}`);
      }
    },
);

// ✅ Configure Nodemailer with your service email
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "dxander25@gmail.com",
    pass: "nwxe uofz mjrl bhgf",
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


  const municipalityId = event.params.municipalityId;
  const isLocal = event.params.isLocal === true;
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

  // 🔍 Build user collection path
  const basePath = isLocal ?
   "localMunicipalities" :
   `districts/${event.params.districtId}/municipalities`;


  const usersRef = admin.firestore()
      .collection(basePath)
      .doc(municipalityId)
      .collection("users");

  let employeeEmail = "";
  let managerEmail = "";
  let adminEmail = "";

  try {
    if (assignedEmployee) {
      const empSnapshot = await usersRef
          .where("userName", "==", assignedEmployee)
          .limit(1)
          .get();

      if (!empSnapshot.empty) {
        employeeEmail = empSnapshot.docs[0].data().email;
        console.log(`📧 Employee Email: ${employeeEmail}`);
      }
    }

    if (assignedManager) {
      const managerSnapshot = await usersRef
          .where("userName", "==", assignedManager)
          .limit(1)
          .get();

      if (!managerSnapshot.empty) {
        managerEmail = managerSnapshot.docs[0].data().email;
        console.log(`📧 Manager Email: ${managerEmail}`);
      }
    }

    if (assignedAdmin) {
      const adminSnapshot = await usersRef
          .where("userName", "==", assignedAdmin)
          .limit(1)
          .get();

      if (!adminSnapshot.empty) {
        adminEmail = adminSnapshot.docs[0].data().email;
        console.log(`📧 Admin Email: ${adminEmail}`);
      }
    }
  } catch (error) {
    console.error("🔥 Error fetching emails:", error);
    return;
  }


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
        "<p><strong>Reference Number:</strong> " +
        `${referenceNumber}</p>` +
        "<p>Please log into the Municipal Services App to view details.</p>" +
        "<p>Thank you for your service.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";
      break;

    case 3:
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
        "<p>The fault <strong>" +
        `${referenceNumber}</strong> is now under review.</p>` +
        "<p>Please verify and confirm the status.</p>" +
        "<p>Regards,<br/>Municipal Services App</p>";
      break;

    case 5:
      subject = `🎉 Fault Resolved: ${referenceNumber}`;
      recipientEmail = adminEmail;
      emailBody =
        "<p>Dear Admin,</p>" +
        "<p>The fault <strong>" +
        `${referenceNumber}</strong> has been resolved.</p>` +
        "<p>Please confirm and archive if no further action is required.</p>" +
        "<p>Thank you for using the Municipal Services App.</p>";
      break;

    default:
      console.log("⚠️ No email required for this stage.");
      return;
  }
  // ✉️ Send email
  if (recipientEmail) {
    const mailOptions = {
      from: "Municipal Services App <dxander25@gmail.com>",
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

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getAuth} = require("firebase-admin/auth");
/**
 * creation of Firebase Auth users for both district and local municipalities.
 * @param {object} event - Firestore event containing the new user document.
 * @param {string} userType -Either 'district' or 'local' for municipality type.
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
