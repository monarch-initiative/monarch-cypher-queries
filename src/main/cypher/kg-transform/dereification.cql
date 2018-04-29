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
   MATCH (assoc)-[:`http://purl.org/dc/elements/1.1/source`]->(source)
   RETURN predicate, source",
  "SET predicate.sources =
      CASE
        WHEN (EXISTS (predicate.sources) AND NOT source.iri IN predicate.sources)
          THEN predicate.sources + source.iri
        WHEN NOT (EXISTS (predicate.sources))
          THEN [source.iri]
        ELSE predicate.sources
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

