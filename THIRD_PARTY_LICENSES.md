# Third-Party Licenses

`fronttier.tar.xz` is an aggregate distribution of independent
third-party components. Each component is licensed separately;
no single license applies to the entire tarball.

| Component  | Version | License | Source |
|------------|---------|---------|--------|
| linux      | 6.18.10 | GPL-2.0-only | https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz |
| bash       | 5.3     | GPL-3.0-or-later | https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz |
| systemd    | 259.1   | LGPL-2.1-or-later | https://github.com/systemd/systemd/releases/tag/v259 |
| glibc      | 2.x     | LGPL-2.1-or-later | https://ftp.gnu.org/gnu/glibc/ |
| util-linux | 2.41.3  | GPL-2.0-or-later | https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/ |
| busybox    | 1.36    | GPL-2.0-only | https://busybox.net/downloads/ |

## Linux kernel

The compiled kernel (`bzImage`) is distributed as a GPL-2.0
derivative work. No source modifications were made.

- Kernel build config: `configs/kernel-6.18.10-fronttier.config`
- Kernel source: https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz

## Full license texts

Each package installs its license under `/usr/share/doc/<pkg>/`
in the installed system. The complete GPL and LGPL texts are
available at:

- GPL-2.0: https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
- GPL-3.0: https://www.gnu.org/licenses/gpl-3.0.txt
- LGPL-2.1: https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt
