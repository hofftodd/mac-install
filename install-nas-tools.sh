#!/usr/bin/env bash
set -euo pipefail

# macOS ships built-in SMB (mount_smbfs / smbutil) and NFS (mount_nfs / showmount)
# clients, so the only thing worth installing here is samba's smbclient for
# scriptable share listing and ad-hoc tests.
brew install samba

echo "NAS tools installed."
echo "  Browse SMB shares:  smbclient -L //<host> -N    (or -U <user>)"
echo "                      smbutil view //<user>@<host>   (built-in alternative)"
echo "  List NFS exports:   showmount -e <host>             (built-in)"
