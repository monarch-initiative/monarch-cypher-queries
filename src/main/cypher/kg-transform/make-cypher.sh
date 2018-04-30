#!/bin/sh

cat add-node-properties.cql dereification.cql > transform-graph.cql

# Hack until https://github.com/neo4j-contrib/neo4j-apoc-procedures/issues/163
sed -e '/AGGREGATE_EVIDENCE_SOURCE_PROPS/ r aggregate-evidence.txt' -e s/AGGREGATE_EVIDENCE_SOURCE_PROPS//  gene-disease.cql >> transform-graph.cql
sed -e '/AGGREGATE_EVIDENCE_SOURCE_PROPS/ r aggregate-evidence.txt' -e s/AGGREGATE_EVIDENCE_SOURCE_PROPS//  gene-phenotype.cql >> transform-graph.cql

cat remove-edges.cql >> transform-graph.cql
