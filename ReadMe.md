# <img src="https://cdn.jsdelivr.net/gh/brogers5/chocolatey-package-xsplit-broadcaster@e68e6db6b26c789efde0af0d5cb368a9212770e0/xsplit-broadcaster.png" width="48" height="48"/> Chocolatey Package: [XSplit Broadcaster](https://community.chocolatey.org/packages/xsplit-broadcaster/)
[![Chocolatey package version](https://img.shields.io/chocolatey/v/xsplit-broadcaster.svg)](https://community.chocolatey.org/packages/xsplit-broadcaster/)
[![Chocolatey package download count](https://img.shields.io/chocolatey/dt/xsplit-broadcaster.svg)](https://community.chocolatey.org/packages/xsplit-broadcaster/)

## Install
[Install Chocolatey](https://chocolatey.org/install), and run the following command to install the latest approved version on the Chocolatey Community Repository:
```shell
choco install xsplit-broadcaster
```

Alternatively, the packages as published on the Chocolatey Community Repository will also be mirrored on this repository's [Releases page](https://github.com/brogers5/chocolatey-package-xsplit-broadcaster/releases). The `nupkg` can be installed from the current directory as follows:

```shell
choco install xsplit-broadcaster -s .
```

## Build
[Install Chocolatey](https://chocolatey.org/install), clone this repository, and run the following command in the cloned repository:
```shell
choco pack
```

A successful build will create `xsplit-broadcaster.w.x.y.z.nupkg`, where `w.x.y.z` should be the Nuspec's `version` value at build time.

Note that Chocolatey package builds are non-deterministic. Consequently, an independently built package will fail a checksum validation against officially published packages.

## Update
This package should be automatically updated by the [Chocolatey Automatic Package Updater Module](https://github.com/majkinetor/au). If it is outdated by more than a few days, please [open an issue](https://github.com/brogers5/chocolatey-package-xsplit-broadcaster/issues).

AU expects the parent directory that contains this repository to share a name with the Nuspec (`xsplit-broadcaster`). Your local repository should therefore be cloned accordingly:
```shell
git clone git@github.com:brogers5/chocolatey-package-xsplit-broadcaster.git xsplit-broadcaster
```

Alternatively, a junction point can be created that points to the local repository (preferably within a repository adopting the [AU packages template](https://github.com/majkinetor/au-packages-template)):
```shell
mklink /J xsplit-broadcaster ..\chocolatey-package-xsplit-broadcaster
```

Once created, simply run `update.ps1` from within the created directory/junction point. Assuming all goes well, all relevant files should change to reflect the latest version available. This will also build a new package version using the modified files.

Before submitting a pull request, please [test the package](https://docs.chocolatey.org/en-us/community-repository/moderation/package-verifier#steps-for-each-package) with a 64-bit Windows 10 v1607+ environment similar to the [Chocolatey Testing Environment](https://github.com/chocolatey-community/chocolatey-test-environment) first.