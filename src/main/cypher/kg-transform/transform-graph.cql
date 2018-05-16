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

// Add proteins to gene clique
CALL apoc.periodic.iterate(
  "MATCH (node:gene)-[r:`http://purl.obolibrary.org/obo/RO_0002205`]-(protein:protein)
   RETURN node, protein",
  "SET node.clique =
      CASE
        WHEN NOT (protein.iri IN node.clique)
          THEN node.clique + protein.iri
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

// A series of cypher statements and apoc.procedures that
// move nodes linked to associations to edges as edge properties
// For example, here we move all evidence codes and pub IDs to the 
// the edges they support

// Phenotype frequency (in reference to a disease)
MATCH (subject:disease)-[predicate]->(object:phenotype)
WITH subject, predicate, object
MATCH (assoc:association)-[:`http://purl.org/oban/association_has_subject`]->(subject),
      (assoc)-[:`http://purl.org/oban/association_has_object`]->(object),
      (assoc)-[:`http://purl.org/oban/association_has_predicate`]->(edge)
WHERE edge.iri = predicate.iri
WITH predicate, assoc
MATCH (assoc)-[:`https://monarchinitiative.org/frequencyOfPhenotype`]->(frequency)
SET predicate.frequency = frequency.iri, predicate.frequency_label= frequency.label;

// Phenotype age of onset (in reference to a disease)
MATCH (subject:disease)-[predicate]->(object:phenotype)
WITH subject, predicate, object
MATCH (assoc:association)-[:`http://purl.org/oban/association_has_subject`]->(subject),
      (assoc)-[:`http://purl.org/oban/association_has_object`]->(object),
      (assoc)-[:`http://purl.org/oban/association_has_predicate`]->(edge)
WHERE edge.iri = predicate.iri
WITH predicate, assoc
MATCH (assoc)-[:`https://monarchinitiative.org/onset`]->(onset)
SET predicate.onset = onset.iri, predicate.onset_label= onset.label;


// Add publications as edge properties
CALL apoc.periodic.iterate(
  "MATCH (subject:cliqueLeader)-[predicate]->(object:cliqueLeader)
   WITH subject, predicate, object
   MATCH (assoc:association)-[:`http://purl.org/oban/association_has_subject`]->(subject),
         (assoc)-[:`http://purl.org/oban/association_has_object`]->(object),
         (assoc)-[:`http://purl.org/oban/association_has_predicate`]->(edge)
   WHERE edge.iri = predicate.iri
   WITH predicate, assoc
   MATCH (assoc)-[:`http://purl.org/dc/elements/1.1/source`]->(publication)
   RETURN predicate, publication",
  "SET predicate.publications =
      CASE
        WHEN (EXISTS (predicate.publications) AND NOT publication.iri IN predicate.publications)
          THEN predicate.publications + publication.iri
        WHEN NOT (EXISTS (predicate.publications))
          THEN [publication.iri]
        ELSE predicate.publications
      END",
  {batchSize:1000, parallel:false, iterateList:true}
);

// Add ECO codes as edge properties
CALL apoc.periodic.iterate(
  "MATCH (subject:cliqueLeader)-[predicate]->(object:cliqueLeader)
   WITH subject, predicate, object
   MATCH (assoc:association)-[:`http://purl.org/oban/association_has_subject`]->(subject),
         (assoc)-[:`http://purl.org/oban/association_has_object`]->(object),
         (assoc)-[:`http://purl.org/oban/association_has_predicate`]->(edge)
   WHERE edge.iri = predicate.iri
   WITH predicate, assoc
   MATCH (assoc)-[:`http://purl.obolibrary.org/obo/RO_0002558`]->(evidence:evidence)
   RETURN predicate, evidence",
  "SET predicate.evidence =
      CASE
        WHEN (EXISTS (predicate.evidence) AND NOT evidence.iri IN predicate.evidence)
          THEN predicate.evidence + evidence.iri
        WHEN NOT (EXISTS (predicate.evidence))
          THEN [evidence.iri]
        ELSE predicate.evidence
      END",
  {batchSize:1000, parallel:false, iterateList:true}
);


// Make isDefinedBy an array, change name to sources
// This takes a really long time, will think of a different
// strategy
//CALL apoc.periodic.iterate(
//  "MATCH (subject:cliqueLeader)-[predicate]->(object:cliqueLeader)
//   WHERE EXISTS(predicate.isDefinedBy)
//   RETURN predicate",
//  "SET predicate.sources = [predicate.isDefinedBy]
//   REMOVE predicate.isDefinedBy",
//  {batchSize:1000, parallel:true, iterateList:true}
//);

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
  
ON CREATE SET edge.provided_by = sources
ON CREATE SET edge.evidence = evidence
ON CREATE SET edge.publications = publications
ON MATCH SET edge.provided_by =
  CASE
    WHEN (EXISTS (edge.provided_by))
      THEN edge.provided_by + FILTER(src in sources WHERE NOT src IN edge.provided_by)
      ELSE sources
  END
ON MATCH SET edge.evidence =
  CASE
    WHEN (EXISTS (edge.evidence))
      THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
      ELSE evidence
  END
ON MATCH SET edge.publications =
  CASE
    WHEN (EXISTS (edge.publications))
      THEN edge.publications + FILTER(pub in publications WHERE NOT pub IN edge.publications)
      ELSE publications
  END
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
// Human gene to phenotype inference, we join a gene-variant-disease, and disease-phenotype relations
// Leverages the prejoin of gene to disease through a variant from gene-disease.cql

CALL apoc.periodic.iterate(
  "MATCH path=(subject:gene)-[r:contributes_to*0..1]->(disease)-[predicate:`http://purl.obolibrary.org/obo/RO_0002200`]->(object:phenotype)
  WHERE NOT EXISTS(predicate.frequency) OR predicate.frequency <> 'http://purl.obolibrary.org/obo/HP_0040284'
  UNWIND relationships(path) as edges
  UNWIND (CASE edges.evidence WHEN NULL THEN [NULL] ELSE edges.evidence END) as evidence
  UNWIND (CASE edges.publications WHEN NULL THEN [NULL] ELSE edges.publications END) as publications
  RETURN subject, object, COLLECT(DISTINCT edges.isDefinedBy) as sources,
         COLLECT(DISTINCT evidence) as evidence,
         COLLECT(DISTINCT publications) as publications",
  "
  MERGE (subject)-[edge:has_phenotype]->(object)
  ON CREATE SET edge = {
     qualifier: 'direct',
     relation: 'RO:0002200',
     is_defined_by: 'Monarch'
  }
  
ON CREATE SET edge.provided_by = sources
ON CREATE SET edge.evidence = evidence
ON CREATE SET edge.publications = publications
ON MATCH SET edge.provided_by =
  CASE
    WHEN (EXISTS (edge.provided_by))
      THEN edge.provided_by + FILTER(src in sources WHERE NOT src IN edge.provided_by)
      ELSE sources
  END
ON MATCH SET edge.evidence =
  CASE
    WHEN (EXISTS (edge.evidence))
      THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
      ELSE evidence
  END
ON MATCH SET edge.publications =
  CASE
    WHEN (EXISTS (edge.publications))
      THEN edge.publications + FILTER(pub in publications WHERE NOT pub IN edge.publications)
      ELSE publications
  END
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
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
  
ON CREATE SET edge.provided_by = sources
ON CREATE SET edge.evidence = evidence
ON CREATE SET edge.publications = publications
ON MATCH SET edge.provided_by =
  CASE
    WHEN (EXISTS (edge.provided_by))
      THEN edge.provided_by + FILTER(src in sources WHERE NOT src IN edge.provided_by)
      ELSE sources
  END
ON MATCH SET edge.evidence =
  CASE
    WHEN (EXISTS (edge.evidence))
      THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
      ELSE evidence
  END
ON MATCH SET edge.publications =
  CASE
    WHEN (EXISTS (edge.publications))
      THEN edge.publications + FILTER(pub in publications WHERE NOT pub IN edge.publications)
      ELSE publications
  END
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
  
ON CREATE SET edge.provided_by = sources
ON CREATE SET edge.evidence = evidence
ON CREATE SET edge.publications = publications
ON MATCH SET edge.provided_by =
  CASE
    WHEN (EXISTS (edge.provided_by))
      THEN edge.provided_by + FILTER(src in sources WHERE NOT src IN edge.provided_by)
      ELSE sources
  END
ON MATCH SET edge.evidence =
  CASE
    WHEN (EXISTS (edge.evidence))
      THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
      ELSE evidence
  END
ON MATCH SET edge.publications =
  CASE
    WHEN (EXISTS (edge.publications))
      THEN edge.publications + FILTER(pub in publications WHERE NOT pub IN edge.publications)
      ELSE publications
  END
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
  
ON CREATE SET edge.provided_by = sources
ON CREATE SET edge.evidence = evidence
ON CREATE SET edge.publications = publications
ON MATCH SET edge.provided_by =
  CASE
    WHEN (EXISTS (edge.provided_by))
      THEN edge.provided_by + FILTER(src in sources WHERE NOT src IN edge.provided_by)
      ELSE sources
  END
ON MATCH SET edge.evidence =
  CASE
    WHEN (EXISTS (edge.evidence))
      THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
      ELSE evidence
  END
ON MATCH SET edge.publications =
  CASE
    WHEN (EXISTS (edge.publications))
      THEN edge.publications + FILTER(pub in publications WHERE NOT pub IN edge.publications)
      ELSE publications
  END
  ",
  {batchSize:1000, parallel:false, iterateList:true}
);
// A series of delete statements for annotation properties
// Note that this should be the last cypher file to execute
// in case we have moved some IRIs to linked nodes as node properties

// Delete inSubset
MATCH ()-[r:`http://www.geneontology.org/formats/oboInOwl#inSubset`]-() DELETE r;

// Delete hasDbXref
MATCH ()-[r:`http://www.geneontology.org/formats/oboInOwl#hasDbXref`]-() DELETE r;

// Delete imported from
MATCH ()-[r:`http://purl.obolibrary.org/obo/IAO_0000412`]-() DELETE r;

// Delete isDefinedBy
MATCH ()-[r:isDefinedBy]->() DELETE r;

// Delete versionIRI
MATCH ()-[r:versionIRI]->() DELETE r;

// Delete OBAN edges
// MATCH ()-[r:`http://purl.org/oban/association_has_object`]-() DELETE r;
// MATCH ()-[r:`http://purl.org/oban/association_has_subject`]-() DELETE r;
// MATCH ()-[r:`http://purl.org/oban/association_has_predicate`]-() DELETE r;
