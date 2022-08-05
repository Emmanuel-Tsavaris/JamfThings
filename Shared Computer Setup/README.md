# Shared Computer Setup

This is folder includes Managed Settings and scripts used for our shared computer prototype, which essentialy deletes all user info from the computer once they log out.
The idea is that users authenticate through Jamf Connect to their IdP, which will then create them a local account.
Once the user logs out of the computer, all data local to their account will be deleted, which will keep the computer from needing local disk encryption in order for it to be HIPAA compliant.

This is intended to fix issues where:
  1. multiple computers are used by different staff at any given point, with password changes happening frequently, thus locking them out of a computer that they haven't used for a significant period of time
  2. bypassing the need for Bootstrap tokens and encryption, so that new users can log in even when the computer first boots up

This is simply a proof of concept, and does include various bugs including but not limited to:
  1. Getting stuck during user creation if all steps are explicitely skipped via config profile
  2. some other things that I need to go look into but forgot about (Just be on the lookout)
