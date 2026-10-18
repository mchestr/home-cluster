---
name: add-app
description: Add a new app to the cluster. Create its Flux Kustomization and HelmRelease, and an ExternalSecret if necessary, build and validate them, then open a pull request. Use it when the owner asks you to add, deploy or install an app.
---

`docs/src/notes/application-deployment.md` has a full example of each file.

## Prepare

1. Get the app name, the namespace and the container image from the owner.
2. Read the files of the reference app in `kubernetes/apps/media/tautulli`.
3. Select the gateway.
4. Select the components and their variables.
5. If the app needs a secret, ask the owner to add the 1Password item (see `docs/src/notes/secrets-management.md`).
6. Create a branch from the latest main: `git fetch origin main && git switch --create <branch> origin/main`.

## Create the files

7. Create `kubernetes/apps/<namespace>/<app>/ks.yaml`: a `Kustomization` in the namespace of the app, with these fields:
   - `targetNamespace`, and `path` set to `./app`.
   - `dependsOn`: `onepassword-store` for an ExternalSecret, `rook-ceph-cluster` for a PVC, `cloudnative-pg-cluster` for a database.
   - `components`.
   - `postBuild.substitute` variables. Always set `APP`.
8. Create `kubernetes/apps/<namespace>/<app>/app/helmrelease.yaml`. The HelmRelease needs these values:
   - Probes on a real health endpoint.
   - A CPU request and a memory limit.
   - `runAsNonRoot` at pod level. `drop: [ALL]` and `readOnlyRootFilesystem` on the container, unless the app needs a device.
   - `reloader.stakater.com/auto: "true"` when the app reads a Secret or a ConfigMap without a name hash.
   - `route` with `sectionName: https`.
9. If the app needs a secret, create `kubernetes/apps/<namespace>/<app>/app/externalsecret.yaml`.
10. Create `kubernetes/apps/<namespace>/<app>/app/kustomization.yaml`. List each manifest of the `app/` directory under `resources`.
11. If the namespace is new, copy `kustomization.yaml` from another namespace directory. Set `namespace`, and remove the other apps from `resources`. Flux finds new namespace directories automatically. There is no top-level `kubernetes/apps/kustomization.yaml`.
12. Add `./<app>/ks.yaml` to `resources` in `kubernetes/apps/<namespace>/kustomization.yaml`.

## Build and validate

13. Build the app with its components and `postBuild` variables, as Flux does:

    ```sh
    flux build kustomization <app> --namespace <namespace> \
      --path ./kubernetes/apps/<namespace>/<app>/app \
      --kustomization-file ./kubernetes/apps/<namespace>/<app>/ks.yaml --dry-run
    ```

14. Make sure that the output has all the resources that you expect. In a dry run, the `cluster-secrets` variables stay as `${...}`.
15. Run `kustomize build kubernetes/apps/<namespace>`. Make sure that the output has the new Kustomization.
16. If `flux-local` is installed, run the CI test: `flux-local test --enable-helm --all-namespaces --path kubernetes/flux/cluster --sources flux-system`.
17. Fix each error, then do steps 13 to 16 again.

## Open the pull request

18. Commit the files: `git add kubernetes/apps/<namespace> && git commit -m "feat(<app>): add <app>"`.
19. Push the branch: `git push -u origin <branch>`.
20. Write the pull request body with the headings of `.github/PULL_REQUEST_TEMPLATE.md`.
21. Open the pull request: `gh pr create --base main --title "feat(<app>): add <app>" --body-file <file>`.
22. Run `gh pr checks <number>`. Fix each failed check, then push again.

CI runs Flux Local and Flux Diff on the pull request. The risk assessment runs only when the pull request is not a draft.
