#!/bin/sh
# Build the playground and upload www/ to the web server with rsync.
#
#   ./deploy.sh              # deploy to the default destination
#   ./deploy.sh --dry-run    # show what would change, without uploading
#
# By default this publishes to
#   https://www.fos.kuis.kyoto-u.ac.jp/~murase/metaocaml-playground/
# via the "io" host from ~/.ssh/config (murase@io.kuis.kyoto-u.ac.jp).
# Set DEPLOY_DEST to upload somewhere else, e.g.
#   DEPLOY_DEST=user@host:public_html/metaocaml-playground/ ./deploy.sh
#
# The destination directory is made to mirror www/: files there that are
# not in www/ are deleted, so DEPLOY_DEST must be a directory used only
# for the playground.
set -e

DEPLOY_DEST=${DEPLOY_DEST:-io:public_html/metaocaml-playground/}
case "$DEPLOY_DEST" in
  */) ;;
  *) DEPLOY_DEST="$DEPLOY_DEST/" ;;
esac

cd "$(dirname "$0")"
dune build

# www/dune is a build rule, not part of the site.
# --chmod makes everything world-readable, as a web server needs.
rsync -rtvz --delete \
  --exclude dune \
  --chmod=D755,F644 \
  "$@" \
  www/ "$DEPLOY_DEST"

case " $* " in
  *" --dry-run "* | *" -n "*) echo "Dry run: nothing was uploaded" ;;
  *) echo "Deployed to $DEPLOY_DEST" ;;
esac
