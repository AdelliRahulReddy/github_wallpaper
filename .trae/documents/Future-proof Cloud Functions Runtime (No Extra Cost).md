## What “Future Proof, No Extra Cost” Means
- You can keep the **same schedule (every 60 minutes)** and the same behavior.
- The goal is to avoid the **Node 20 end-of-support** event so you won’t get blocked from deploying later.
- Runtime upgrades themselves don’t add a new subscription, but **2nd gen has some default resource differences**, so we’ll explicitly configure it to avoid idle cost (no always-on instances). Firebase notes cost behavior differences between 1st gen and 2nd gen. citehttps://firebase.google.com/docs/functions/manage-functions

## Recommended Approach (Safest + Most Future-Proof)
### Migrate this scheduled function to **Cloud Functions for Firebase (2nd gen)**
- Reason: Node 22 can be used via Firebase runtime settings (Firebase docs show runtime can be `nodejs20` or `nodejs22`). citehttps://firebase.google.com/docs/functions/manage-functions
- Reason: 1st gen may not accept `nodejs22` in some cases; 2nd gen is the forward path and officially supported for migration. citehttps://firebase.google.com/docs/functions/2nd-gen-upgrade

## Cost-Control Rules (To Keep Cost Flat)
- Ensure **minInstances is NOT set** (or explicitly 0). This prevents paying for idle instances.
- Keep the job frequency at **60 minutes** (already done).
- Enable/keep an **Artifact Registry cleanup policy** so old deploy images don’t slowly add storage cost (Firebase CLI supports this). citehttps://firebase.google.com/docs/functions/manage-functions

## Exact Implementation Plan (What I Will Do After You Confirm)
1. **Update functions runtime/deps**
   - Update [functions/package.json](file:///c:/Users/adell/Desktop/github_wallpaper/functions/package.json) to a supported future runtime (target **Node 22** where supported) and upgrade `firebase-functions` to latest recommended.
2. **Add a 2nd-gen scheduled function alongside the current one**
   - In [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js), add a new export like `triggerDailyUpdateV2` using `firebase-functions/v2/scheduler` (`onSchedule`).
   - Keep the same message payload and topic.
3. **Deploy only the new v2 function**
   - `firebase deploy --only functions:triggerDailyUpdateV2`
4. **Verify schedule + logs**
   - Check Cloud Scheduler shows the new job runs every 60 minutes.
   - Confirm logs show message sends.
5. **Disable old gen1 function to avoid double-triggers**
   - Delete the old `triggerDailyUpdate` gen1 function (so you don’t send twice per hour).
6. **Set Artifact Registry cleanup policy** (optional but recommended for “no extra cost” long-term)
   - Configure cleanup so old deployment images auto-delete.

## End Result
- Future-safe runtime (no Node 20 decommission blocker).
- Same 60-minute behavior.
- No idle-instance costs introduced.
- No long-term Artifact Registry storage creep.
