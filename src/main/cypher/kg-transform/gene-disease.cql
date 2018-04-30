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
  AGGREGATE_EVIDENCE_SOURCE_PROPS
  ",
    {batchSize:1000, parallel:false, iterateList:true}
);
