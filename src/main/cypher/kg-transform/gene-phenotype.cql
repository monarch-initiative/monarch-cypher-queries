// Human gene to phenotype inference, we join a gene-variant-disease, and disease-phenotype relations
// Leverages the prejoin of gene to disease through a variant from gene-disease.cql

CALL apoc.periodic.iterate(
  "MATCH path=(subject:gene)-[r:contributes_to*0..1]->(disease)-[predicate:`http://purl.obolibrary.org/obo/RO_0002200`]->(object:phenotype)
  WHERE NOT EXISTS(predicate.frequency) OR predicate.frequency <> 'http://purl.obolibrary.org/obo/HP_0040284'
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.isDefinedBy WHEN NULL THEN [NULL] ELSE edges.isDefinedBy END) as sources
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject,
         object,
         COLLECT(DISTINCT sources) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:has_phenotype]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'RO:0002200',
     is_defined_by: 'Monarch'
  }
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
