#!/usr/bin/env bash
set -euo pipefail

SRC="$1"
TARGET="$2"
SUBTARGET="$3"
PROFILE="$4"
DEV_DIR="$5"

# 复制 files 下的最终文件到 source
if [[ -d "$DEV_DIR/files" ]]; then
  (cd "$DEV_DIR/files" && tar cf - .) | (cd "$SRC" && tar xf -)
  echo "copied files/"
fi

# 合并 fragments 到对应 mk 文件
MK="$SRC/target/linux/$TARGET/image/$SUBTARGET.mk"
APPEND="$DEV_DIR/fragments/$SUBTARGET.mk.append"
if [[ -f "$APPEND" ]] && ! grep -q "$PROFILE" "$MK"; then
  printf '\n# backport %s\n' "$PROFILE" >> "$MK"
  cat "$APPEND" >> "$MK"
  echo "merged $SUBTARGET.mk"
fi

# 应用 patches
if [[ -d "$DEV_DIR/patches" ]]; then
  for patch_file in "$DEV_DIR/patches"/*.patch; do
    [[ -f "$patch_file" ]] || continue
    echo "applying $patch_file"
    patch -p1 --forward -d "$SRC" < "$patch_file" || true
  done
fi

echo "backport $PROFILE applied"
