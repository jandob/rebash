#!/usr/bin/env bash

echo "export REBASH_HOME=/usr/lib/rebash" | tee /etc/.rebash
chmod 0755 /etc/.rebash
ln -s /usr/bin/rebash /usr/lib/rebash.sh
