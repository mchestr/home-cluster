# Cluster Bootstrap

The process should be mostly automated via the `task bootstrap:apps` command. If all goes well
the cluster should come up based on the last available snapshot taken by volsync, which is run daily.

## MS-01 SecureBoot Setup

Enabling Secure boot on MS-01 can be difficult if its not something you have done before, heres how to do it.

1. Boot directly to the BIOS
2. Under `Security`->`Secure Boot` change to `custom`.
3. Go down to `Key Management`
4. Set `Factory Key Provision` to `disabled`.
4. Click `Reset To Setup Mode`.
    - IMPORTANT: click `cancel` when it says save without exiting.
5. Save and Reset.
6. Mount Talos image and reboot, click `Enroll secure boot keys: auto`.

If at any point you still see some errors on start about key violations it most likely means the factory default keys were not wiped (step 4 above). Make sure the changes are saved before rebooting.
