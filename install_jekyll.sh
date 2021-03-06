#!/usr/bin/env sh

set -o errexit
set -o nounset

# Some links that were useful in getting 'gem install' to work:
#
#   - https://jekyllrb.com/docs/installation/
#   - https://github.com/ffi/ffi/issues/485
#
apk update
apk add gcc g++ libffi-dev musl-dev make ruby ruby-dev
gem install --no-document bundler jekyll

# Other dependencies for gems
apk add nodejs

# Required for the static file generator
apk add rsync

# Required for the pygments gem.  This has to be Python 2, not Python 3:
# https://github.com/tmm1/pygments.rb/issues/45
apk add py2-pip
pip install pygments

# Fixes an issue where bundler complains about running as root.
# In Docker, that doesn't matter!
# https://github.com/docker-library/rails/issues/10
bundle config --global silence_root_warning 1

bundle install

apk del --purge build-base
rm -rf /var/cache/apk/*
