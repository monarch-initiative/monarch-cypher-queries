// Link phenotypes to anatomical entities
CALL apoc.periodic.iterate(
  "MATCH path=(subject:phenotype)-[r:filler|`http://purl.obolibrary.org/obo/BFO_0000051`]->()-[predicate:`http://purl.obolibrary.org/obo/RO_0002314`|`http://purl.obolibrary.org/obo/RO_0000052`]->(object:`anatomical entity`)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:has_entity]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'has_entity',
     is_defined_by: 'Monarch'
  }
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// Link phenotypes to qualities
CALL apoc.periodic.iterate(
  "MATCH path=(subject:phenotype)-[r:filler]->()-[predicate:operand]->(object:quality)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:has_quality]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'has_quality',
     is_defined_by: 'Monarch'
  }
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// subclass of relationships
CALL apoc.periodic.iterate(
  "MATCH path=(subject:phenotype)-[r:subClassOf]->(object:phenotype)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:subclass_of]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'owl:subClassOf',
     is_defined_by: 'Monarch'
  }
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// subclass of relationships
CALL apoc.periodic.iterate(
  "MATCH path=(subject:disease)-[r:subClassOf]->(object:disease)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:subclass_of]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'owl:subClassOf',
     is_defined_by: 'Monarch'
  }
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// subclass of relationships
CALL apoc.periodic.iterate(
  "MATCH path=(subject:`anatomical entity`)-[r:subClassOf]->(object:`anatomical entity`)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:subclass_of]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'owl:subClassOf',
     is_defined_by: 'Monarch'
  }
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// subclass of relationships
CALL apoc.periodic.iterate(
  "MATCH path=(subject:quality)-[r:subClassOf]->(object:quality)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:subclass_of]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'owl:subClassOf',
     is_defined_by: 'Monarch'
  }
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);

// subclass of relationships
CALL apoc.periodic.iterate(
  "MATCH path=(subject:`anatomical entity`)-[r:`http://purl.obolibrary.org/obo/BFO_0000051`]->(object:`anatomical entity`)
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:part_of]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'BFO:0000051',
     is_defined_by: 'Monarch'
  }
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
