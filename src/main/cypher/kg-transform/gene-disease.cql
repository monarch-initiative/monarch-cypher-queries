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
  UNWIND edges.sources as sources
  UNWIND edges.evidence as evidence
  RETURN subject, object, COLLECT(DISTINCT sources) as sources, 
         COLLECT(DISTINCT evidence) as evidence
  ",
  "
  MERGE (subject)-[edge:`http://purl.obolibrary.org/obo/RO_0002326`]->(object)
  ON CREATE SET edge = {qualifer: 'inferred', lbl: 'contributes_to'}
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
