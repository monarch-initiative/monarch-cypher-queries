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
