#!/bin/bash -e
pip wheel --no-deps --wheel-dir "$1" "$2==$3"
pip install --target="$1"/tmp "$1"/*.whl

cat > "$1"/BUILD << EOF
load('@//build_tools:pypi.bzl', 'pypi_library')

pypi_library(
   name='$2',
   src='$(basename "$1"/*.whl)',
   outs=[
       $(awk 'BEGIN { FS = "," } {print "\047" $1 "\047,"}' "$1"/tmp/*dist-info/RECORD)
   ],
   visibility=['//visibility:public'],
)
EOF

rm -rf "$1"/tmp
