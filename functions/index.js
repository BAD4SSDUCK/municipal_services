const {onObjectFinalized} = require("firebase-functions/v2");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sharp = require("sharp");
const {Storage} = require("@google-cloud/storage");
const path = require("path");

admin.initializeApp();
const storage = new Storage();

// Existing compress image function
exports.compressImage = onObjectFinalized(async (event) => {
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

exports.organizeInvoiceUpload = onObjectFinalized(async (event) => {
  const object = event.data;
  const filePath = object.name; // e.g., "pdfs/inbox/October/123456789.pdf"

  if (!filePath.includes("inbox")) {
    functions.logger.log("File is already in the final location, skipping.");
    return;
  }

  const fileName = path.basename(filePath); // Extract "123456789.pdf"
  const accountNumber = fileName.split(".")[0]; // Extract "123456789"

  functions.logger.log(`Processing file for account number: ${accountNumber}`);

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

