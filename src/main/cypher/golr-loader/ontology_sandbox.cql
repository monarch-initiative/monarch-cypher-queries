// A list of common queries over an ontology graph

//Search for a class with the exact label Coloboma from HPO
START hp = node:node_auto_index(label='Coloboma')
MATCH (hp)-[:isDefinedBy]->(ontology{iri:'http://purl.obolibrary.org/obo/hp.owl'})
RETURN hp.iri, hp.category,hp.label;

//Or with a regex
START hp = node:node_auto_index(label='Coloboma') 
MATCH (hp)-[:isDefinedBy]->(ontology)
WHERE ontology.iri =~ '(?i).*hp.owl'
RETURN hp.iri, hp.category,hp.label;

// Get entity and quality statements for Splenomegaly/enlarged spleen, HP:0001744
// Uses scigraph query expansion
START hp = node:node_auto_index(iri='http://purl.obolibrary.org/obo/HP_0001744')
MATCH (hp)-[:BFO:0000051]->(eq_bnode)
OPTIONAL MATCH (eq_bnode)-[:RO:0002573|operand]->(quality)
OPTIONAL MATCH (eq_bnode)-[:RO:0002502!]->(entity)
RETURN DISTINCT hp.iri, hp.category,hp.label, quality.label, entity.label;

//Same as above without scigraph expansion
START hp = node:node_auto_index(iri='http://purl.obolibrary.org/obo/HP_0001744')
MATCH (hp)-[:`http://purl.obolibrary.org/obo/BFO_0000051`]->(eq_bnode)
OPTIONAL MATCH (eq_bnode)-[:`http://purl.obolibrary.org/obo/RO_0002573`|operand]->(quality)
OPTIONAL MATCH (eq_bnode)-[:`http://purl.obolibrary.org/obo/RO_0002314`|`http://purl.obolibrary.org/obo/RO_0000079`|`http://purl.obolibrary.org/obo/RO_0000052`|`http://purl.obolibrary.org/obo/RO_0002502`|`http://purl.obolibrary.org/obo/RO_0000092`|`http://purl.obolibrary.org/obo/RO_0002503`|`http://purl.obolibrary.org/obo/RO_0000081`|`http://purl.obolibrary.org/obo/RO_0000080`]->(entity)
RETURN DISTINCT hp.iri, hp.category,hp.label, quality.label, entity.label;

// Find paths between two classes in HPO
MATCH path=shortestPath((macular_degeneration{iri:'http://purl.obolibrary.org/obo/HP_0007754'})-[rel:subClassOf*]->(cardio{iri:'http://purl.obolibrary.org/obo/HP_0001626'}))
WHERE ALL (relation in rel where relation.isDefinedBy='http://purl.obolibrary.org/obo/hp.owl')
RETURN path

// Find paths between two HPO classes via namespace (allows edges from upheno)
MATCH path=(macular_degeneration{iri:'http://purl.obolibrary.org/obo/HP_0007754'})-[rel:subClassOf*]->(cardio{iri:'http://purl.obolibrary.org/obo/HP_0001626'})
WHERE ALL (node IN nodes(path) WHERE node.`http://www.geneontology.org/formats/oboInOwl#hasOBONamespace`='human_phenotype')
RETURN path

// Find paths between two classes with no filter
MATCH path=(macular_degeneration{iri:'http://purl.obolibrary.org/obo/HP_0007754'})-[rel:subClassOf*]->(cardio{iri:'http://purl.obolibrary.org/obo/HP_0001626'})
RETURN path
