// A series of apoc.procedures that add node IRIs connected via
// specific edges as node properties
// This current covers the use cases of
// 1. Creating a clique list (a list of equivalent IRIs) on the clique leader
// 2. Adding isDefinedBy relationships as node properties
// 3. Adding disease inheritance and modifiers as node properties

// Note that without properly setting dbms.tx_log.rotation.retention_policy
// the neo4j store size increases by >10g while running these
// from the neostore.transaction.db.* files
// See https://neo4j.com/docs/operations-manual/current/configuration/transaction-logs/


// Create a new node property for storing a list of iri's in a clique
CALL apoc.periodic.iterate(
  "MATCH (node:cliqueLeader) RETURN node",
  "SET node.clique = [node.iri]",
  {batchSize:1000, parallel:true, iterateList:true}
);

// Add name property (copy from label)
CALL apoc.periodic.iterate(
  "MATCH (node:cliqueLeader) RETURN node",
  "SET node.name = node.label",
  {batchSize:1000, parallel:true, iterateList:true}
);

// Add non-leader iris to the clique property
CALL apoc.periodic.iterate(
  "MATCH (node:cliqueLeader)-[r:equivalentClass|sameAs]-(eqNode)
   RETURN node, eqNode",
  "SET node.clique =
      CASE
        WHEN NOT (eqNode.iri IN node.clique)
          THEN node.clique + eqNode.iri
        ELSE node.clique
      END",
  {batchSize:1000, parallel:false, iterateList:false}
);

// Remove the eq edges
// Note setting parallel:true causes deadlock exceptions
CALL apoc.periodic.iterate(
  "MATCH (node:cliqueLeader)-[r:equivalentClass|sameAs]-(eqNode)
   WHERE NOT eqNode:cliqueLeader
   RETURN DISTINCT eqNode",
  "DETACH DELETE eqNode",
  {batchSize:1000, parallel:false, iterateList:true}
);

// Add inheritance as node properties
CALL apoc.periodic.iterate(
  "MATCH (disease:disease)-[:`http://purl.obolibrary.org/obo/RO_0000091`]->(inheritance:inheritance)
   RETURN DISTINCT disease, inheritance",
  "SET disease.inheritance =
      CASE
        WHEN (EXISTS (disease.inheritance) AND NOT inheritance.label IN disease.inheritance)
          THEN disease.inheritance + inheritance.label
        WHEN NOT (EXISTS (disease.inheritance))
          THEN [inheritance.label]
        ELSE disease.inheritance
      END",
  {batchSize:1000, parallel:false, iterateList:true}
);


// Make isDefinedBy a node property
// Currently commenting this out as it is not very useful
// For example, things are summed to monarch.owl rather than their source
// ontology.  isDefindedBy on edges is more meaningful, which is done
// when loading scigraph

//CALL apoc.periodic.iterate(
//   "MATCH (n:cliqueLeader)-[:isDefinedBy]->(ontology:Ontology)
//    RETURN n, ontology",
//    "SET n.isDefinedBy = 
//      CASE
//        WHEN (EXISTS (n.isDefinedBy) AND NOT ontology.iri IN n.isDefinedBy)
//          THEN n.isDefinedBy + ontology.iri
//        WHEN NOT (EXISTS (n.isDefinedBy))
//          THEN [ontology.iri]
//        ELSE n.isDefinedBy          
//      END",
//    {batchSize:1000, parallel:false, iterateList:false}
//);


// Add clinical course as node properties
// Untested
//CALL apoc.periodic.iterate(
//   "MATCH (n:disease)-[:`http://purl.obolibrary.org/obo/RO_0000091`]->(course:clinical_course)
//    RETURN n, course",
//   "SET n.clinical_course = 
//      CASE
//        WHEN (EXISTS (n.clinical_course) AND NOT course.label IN n.clinical_course)
//          THEN n.clinical_course + course.label
//        WHEN NOT (EXISTS (n.clinical_course) )
//          THEN [course.label]
//        ELSE n.clinical_course
//      END",
//    {batchSize:1000, parallel:false, , iterateList:false}
//);

