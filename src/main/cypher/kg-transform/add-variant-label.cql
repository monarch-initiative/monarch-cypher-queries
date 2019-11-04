MATCH (node)
WHERE (((node:`sequence feature` AND (NOT node:gene OR NOT node:phenotypic_marker)) OR node:`variant locus`) AND NOT node:anonymous) OR node:`reagent targeted gene`
SET node:variant, node.category = node.category + "variant";
