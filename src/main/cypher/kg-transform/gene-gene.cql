// Gene-gene interactions
CALL apoc.periodic.iterate(
  "MATCH path=(subject:gene)-[predicate:`http://purl.obolibrary.org/obo/RO_0002434`|`http://purl.obolibrary.org/obo/RO_0002435`|`http://purl.obolibrary.org/obo/RO_0002325`]->(object:gene)
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
  MERGE (subject)-[edge:interacts_with]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'RO:0002434',
     is_defined_by: 'Monarch'
  }
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
