#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scan_bin=${GITLEAKS_BIN:-gitleaks}
scan_dir=$(mktemp -d)
trap 'rm -rf "$scan_dir"' EXIT
python3 - "$scan_dir" <<'PY'
from pathlib import Path
import shutil,subprocess,sys
out=Path(sys.argv[1])
files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z']).decode().split('\0')
for name in set(filter(None,files)):
 p=Path(name)
 if p.is_file():
  dest=out/p;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
PY
"$scan_bin" dir "$scan_dir" --no-banner --redact --max-archive-depth 2 "$@"
