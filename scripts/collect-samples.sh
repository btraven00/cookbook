#!/usr/bin/env bash
# Pick the first file matching each stage's declared output pattern from a
# real `out/` tree and copy it into samples/<stage>/.
#
# Usage:  collect-samples.sh <out-dir> <samples-dir>
#
# Hacky on purpose. See ../samples/README.md.

set -euo pipefail

OUT="${1:?usage: $0 <out-dir> <samples-dir>}"
DST="${2:?usage: $0 <out-dir> <samples-dir>}"

# stage : output-glob (matched anywhere under out/, since omnibenchmark
# nests each stage's outputs inside the upstream stages' parameter dirs)
declare -A PATTERNS=(
  [one-data]='*.h5ad *.clusters_truth.tsv *.clusters_truth_num.txt'
  [two-filter]='*_cellids.txt.gz'
  [three-normalize]='*_normalized.h5'
  [four-select]='*_normalized_selected.h5'
  [five-pca]='*_pcas.tsv'
  [graph]='*_neighbors.h5'
  [cluster]='*_clusters.tsv'
)

for stage in "${!PATTERNS[@]}"; do
  mkdir -p "$DST/$stage"
  : > "$DST/$stage/PROVENANCE.txt"
  for pat in ${PATTERNS[$stage]}; do
    match=$(find "$OUT" -type f -name "$pat" \
              ! -path '*/.logs/*' ! -path '*/.modules/*' ! -path '*/.snakemake/*' \
              2>/dev/null | sort | head -n1 || true)
    if [[ -z "$match" ]]; then
      echo "WARN: no match for $stage / $pat" >&2
      continue
    fi
    cp -v "$match" "$DST/$stage/"
    echo "$pat <- $match" >> "$DST/$stage/PROVENANCE.txt"
  done
done
