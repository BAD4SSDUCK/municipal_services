// functions/runBackfill.js
const {getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");

module.exports = async function runBackfill() {
  const db = getFirestore();
  const auth = getAuth();
  /**
 * Backfill users under a collection path into usersByUid mirrors.
 *
 * @param {string} path Firestore path to the /users collection.
 * @param {boolean} isDistrict True if path belongs to a district muni.
 * @return {Promise<void>} Resolves when the backfill completes.
 */
  async function backfillCollection(path, isDistrict) {
    const snap = await db.collection(path).get();
    for (const doc of snap.docs) {
      const data = doc.data();

      let uid = data.uid || data.authUid;
      if (!uid && data.email) {
        try {
          const u = await auth.getUserByEmail(data.email);
          uid = u.uid;
          await doc.ref.set({uid}, {merge: true});
        } catch (e) {
          console.warn(
              `No Auth user for ${data.email} at ${doc.ref.path}`,
          );
          continue;
        }
      }
      if (!uid) continue;

      const parts = doc.ref.path.split("/");
      let mirrorPath;
      if (isDistrict) {
        mirrorPath = "districts/" + parts[1] + "/municipalities/" +
             parts[3] + "/usersByUid/" + uid;
      } else {
        mirrorPath = "localMunicipalities/" + parts[1] + "/usersByUid/" + uid;
      }

      const mirrorData = {
        email: data.email || null,
        role: data.userRole || data.role || null,
        official: data.official === true,
        deptName: data.deptName || null,
        updatedAt: Date.now(),
      };

      await db.doc(mirrorPath).set(mirrorData, {merge: true});
      console.log(`✔ Wrote mirror: ${mirrorPath}`);
    }
  }

  // districts
  const distSnap = await db.collection("districts").get();
  for (const d of distSnap.docs) {
    const muniSnap = await db
        .collection(`districts/${d.id}/municipalities`)
        .get();
    for (const m of muniSnap.docs) {
      await backfillCollection(
          `districts/${d.id}/municipalities/${m.id}/users`,
          true,
      );
    }
  }

  // locals
  const localSnap = await db.collection("localMunicipalities").get();
  for (const m of localSnap.docs) {
    await backfillCollection(`localMunicipalities/${m.id}/users`, false);
  }
};
