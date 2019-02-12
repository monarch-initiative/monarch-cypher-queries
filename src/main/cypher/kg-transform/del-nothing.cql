MATCH ()-[r]-(nothing:Node{iri:'http://www.w3.org/2002/07/owl#Nothing'}) DELETE r;

MATCH (nothing:Node{iri:'http://www.w3.org/2002/07/owl#Nothing'}) DELETE nothing;
