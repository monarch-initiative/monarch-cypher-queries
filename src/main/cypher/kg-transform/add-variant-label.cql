MATCH (node)
WHERE (((node:`sequence feature` AND NOT node:gene) OR node:`variant locus`) AND NOT node:anonymous) OR node:`reagent targeted gene`
SET node:variant
RETURN node.iri;
