MATCH (node)
WHERE (((node:`sequence feature` AND (NOT node:gene AND NOT node:phenotypic_marker)) OR node:`variant locus`) AND NOT node:anonymous) OR node:`reagent targeted gene`
SET node:variant, node.category =
   CASE 
     WHEN node.category + "" = node.category
       THEN [node.category, "variant"]
     ELSE node.category + variant
   END;
