START htax=node:node_auto_index(iri='http://purl.obolibrary.org/obo/NCBITaxon_9606')

MATCH (humangene:gene)-[:`http://purl.obolibrary.org/obo/RO_0002162`]-(htax)
//WHERE humangene.iri =~ '.*ncbi.*' 
WHERE 'cliqueLeader' in labels(humangene)
WITH htax, humangene

MATCH (humangene)<-[:`http://purl.obolibrary.org/obo/GENO_0000610`|`http://purl.obolibrary.org/obo/GENO_0000444`|`http://purl.obolibrary.org/obo/GENO_0000410`|`http://purl.obolibrary.org/obo/GENO_0000443`|`http://purl.obolibrary.org/obo/GENO_0000641`|`http://purl.obolibrary.org/obo/GENO_0000442`|`http://purl.obolibrary.org/obo/GENO_0000408`|`http://purl.obolibrary.org/obo/GENO_0000418`*0..1]-(feature)-[:`http://purl.obolibrary.org/obo/RO_0002610`|`http://purl.obolibrary.org/obo/RO_0002326`|`http://purl.obolibrary.org/obo/RO_0002452`|`http://purl.obolibrary.org/obo/RO_0002200`|`http://purl.obolibrary.org/obo/RO_0002607`|type*1..3]->(phenotype:Phenotype)         
RETURN DISTINCT humangene.iri as humangene_iri, humangene.label as humangene_label, humangene.iri as othergene_iri, humangene.label as othergene_label, htax.iri as othertaxon_iri, htax.label as othertaxon_label, phenotype.iri as phenotype_iri, phenotype.label as phenotype_label ;
