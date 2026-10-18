---
name: volsync-restore
description: Restore the PVC of an app from a VolSync snapshot with the task volsync commands, then check that the app has its data. Use it when app data is lost or corrupted, or when the owner asks for a restore.
---

The `volsync` component backs up the PVC of an app to Cloudflare R2 with Restic once a day. It keeps 7 daily, 4 weekly and 3 monthly snapshots. The tasks are in `.taskfiles/volsync/Taskfile.yml`, and `docs/src/notes/disaster-recovery.md` describes them.

## Check before you start

1. Make sure that the app agrees with the four assumptions of the tasks:
   - The Kustomization, HelmRelease, PVC and ReplicationSource have the same name.
   - The ReplicationSource uses Restic.
   - The app is a Deployment or a StatefulSet.
   - The app has only one PVC.
2. Run `kubectl --namespace <namespace> get replicationsource <app>`. If it does not exist, stop.
3. Run `kubectl --namespace volsync-system get deployment volsync`. If it has 0 replicas, ask the owner to run `task volsync:state-resume`.
4. Run `which flux kubectl minijinja-cli`. If one is missing, stop and tell the owner.
5. If `KUBECONFIG` is not set and `kubernetes/kubeconfig` does not exist, put `KUBECONFIG=$HOME/.kube/config` in front of each `task` command.

`task` sets `KUBECONFIG` to `kubernetes/kubeconfig` only when `KUBECONFIG` is not set.

## Select the snapshot

WARNING: Do not run `task volsync:snapshot` before the restore. A new snapshot changes the `PREVIOUS` count. The retention keeps one snapshot for each day, so it can remove a good snapshot from the same day.

6. Run `task volsync:list APP=<app> NS=<namespace>`.
7. Find the snapshot to restore. The list shows the oldest snapshot first and the latest snapshot last.
8. Count `PREVIOUS` back from the last line. `PREVIOUS=0` is the latest snapshot, and `PREVIOUS=1` is the snapshot before it.
9. Tell the owner the time of the snapshot and the `PREVIOUS` value. Continue only when the owner agrees.

## Restore

WARNING: The restore replaces the data on the PVC. It deletes the files that are not in the snapshot.

10. Run `task volsync:restore APP=<app> NS=<namespace> PREVIOUS=<n>` as a background command.

    The task suspends the Flux Kustomization and HelmRelease of the app and scales the app to 0. It restores the snapshot, resumes Flux and waits for the pods. It waits up to 2 hours for the restore.
11. If the task fails, stop and tell the owner. The app can stay suspended with 0 replicas.
12. Run `kubectl --namespace <namespace> get replicationdestination,job,pod` to find the restore Job.
13. Read the events and the logs of the restore Job to find the cause.

To start the app again after a failed restore, do steps 14 to 16.

WARNING: Do not start the app while a restore Job still writes to the PVC.

14. Run `flux resume ks -n <namespace> <app>`.
15. Run `flux resume hr -n <namespace> <app>`.
16. Run `flux reconcile hr -n <namespace> <app> --force`. The task uses this command to scale the app up again.

## Check that the app has its data

17. Run `flux get ks -n <namespace> <app>` and `flux get hr -n <namespace> <app>`. Make sure that both are ready and not suspended.
18. Run `kubectl get pods -n <namespace> -l app.kubernetes.io/name=<app>`. Make sure that the pods are ready.
19. Run `kubectl logs -n <namespace> -l app.kubernetes.io/name=<app> --tail=200`. Look for errors, and for messages that the app starts with no data.
20. Find the mount path of the PVC under `persistence` in `kubernetes/apps/<namespace>/<app>/app/helmrelease.yaml`.
21. Run `kubectl --namespace <namespace> exec <pod> -- ls -la <path>`. Make sure that the files of the app are there.
22. Ask the owner to open the app and confirm that the data from the time of the snapshot is there.
