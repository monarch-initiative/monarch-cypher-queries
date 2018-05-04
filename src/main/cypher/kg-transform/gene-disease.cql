// This is (likely) our most common gene to disease inference pattern,
// we infer from a variant to disease association
// (pathogenic, likely pathogenic, contributes to, has phenotype)

CALL apoc.periodic.iterate(
  "MATCH path=(subject:gene)<-[geno:`http://purl.obolibrary.org/obo/GENO_0000408`|
                                    `http://purl.obolibrary.org/obo/GENO_0000418`|
                                    `http://purl.obolibrary.org/obo/GENO_0000639`]-(feature)-[predicate:`http://purl.obolibrary.org/obo/RO_0002326`  |
                                                                                                        `http://purl.obolibrary.org/obo/RO_0002200`  |
                                                                                                        `http://purl.obolibrary.org/obo/GENO_0000840`|
                                                                                                        `http://purl.obolibrary.org/obo/GENO_0000841`]->(object:disease)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications
  ",
  "
  MERGE (subject)-[edge:contributes_to]->(object)
  ON CREATE SET edge = {
    qualifier: 'direct',
    relation: 'RO:0002326',
    is_defined_by: 'Monarch'
  }
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
