// this will get all nodes in the NCBITaxonomy that are not
// neo4j-labeled as "organism", currently defined as subclasses of 
// NCBITaxon:131567 (cellular organisms)
// we do this by limiting the taxon to be related to anything
// by the "in_taxon" relationship, because we only care about 
//those nodes that are actually related to something in our system.
MATCH ()-[:`http://purl.obolibrary.org/obo/RO_0002162`]-(taxon)
WHERE taxon.iri =~ ".*NCBITaxon_.*"
AND not 'organism' in labels(taxon)
RETURN DISTINCT taxon.iri, taxon.label ;

