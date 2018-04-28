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
SET predicate.frequency_iri = frequency.iri, predicate.frequency_label= frequency.label;

// Phenotype age of onset (in reference to a disease)
MATCH (subject:disease)-[predicate]->(object:phenotype)
WITH subject, predicate, object
MATCH (assoc:association)-[:`http://purl.org/oban/association_has_subject`]->(subject),
      (assoc)-[:`http://purl.org/oban/association_has_object`]->(object),
      (assoc)-[:`http://purl.org/oban/association_has_predicate`]->(edge)
WHERE edge.iri = predicate.iri
WITH predicate, assoc
MATCH (assoc)-[:`https://monarchinitiative.org/onset`]->(onset)
SET predicate.onset_iri = onset.iri, predicate.onset_label= onset.label;
