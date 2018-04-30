// Human gene to phenotype inference, we join a gene-variant-disease, and disease-phenotype relations
// Leverages the prejoin of gene to disease through a variant from gene-disease.cql

// The merge statement is not very DRY, but I can't find a way to
// make this a templated query, maybe https://github.com/neo4j-contrib/neo4j-apoc-procedures/issues/163
// Or a user defined procedure, or inject them into these text files (similar to how we build curie maps)

CALL apoc.periodic.iterate(
  "MATCH path=(subject:gene)-[contributes_to:`http://purl.obolibrary.org/obo/RO_0002326`]->(disease:disease),
         (disease)-[predicate:`http://purl.obolibrary.org/obo/RO_0002200`]->(object:phenotype)
  WHERE NOT EXISTS(predicate.frequency) OR predicate.frequency <> 'http://purl.obolibrary.org/obo/HP_0040284'
  UNWIND relationships(path) as edges
  UNWIND edges.sources as sources
  UNWIND edges.evidence as evidence
  RETURN subject, object, COLLECT(DISTINCT sources) as sources, 
       COLLECT(DISTINCT evidence) as evidence",
  "
  MERGE (subject)-[edge:`http://purl.obolibrary.org/obo/RO_0002200`]->(object)
  ON CREATE SET edge = {qualifer: 'inferred', lbl: 'has_phenotype'}
  ON CREATE SET edge.sources = 
     CASE
       WHEN NOT (sources IS NULL)
         THEN sources
     END
  ON CREATE SET edge.evidence = 
     CASE
       WHEN NOT (evidence IS NULL)
         THEN evidence
     END
  ON MATCH SET edge.sources = 
      CASE
        WHEN (EXISTS (edge.sources) AND NOT (sources IS NULL))
          THEN edge.sources + FILTER(src in sources WHERE NOT src IN edge.sources)
        WHEN (NOT EXISTS (edge.sources) AND NOT (sources IS NULL))
          THEN sources
        WHEN (EXISTS (edge.sources))
          THEN edge.sources
      END
  ON MATCH SET edge.evidence = 
      CASE
        WHEN (EXISTS (edge.evidence) AND NOT (evidence IS NULL))
          THEN edge.evidence + FILTER(ev in evidence WHERE NOT ev IN edge.evidence)
        WHEN (NOT EXISTS (edge.evidence) AND NOT (evidence IS NULL))
          THEN evidence
        WHEN (EXISTS (edge.evidence))
          THEN edge.evidence
      END
  ",
    {batchSize:1000, parallel:false, iterateList:true}
);
