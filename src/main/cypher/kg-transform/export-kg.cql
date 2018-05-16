// exports given nodes and relationships incl. indexes as cypher statements to the provided file
// requires apoc.export.file.enabled=true in the conf
MATCH (p1:cliqueLeader)-[r{qualifier:'direct'}]->(p2:cliqueLeader)
WITH collect(p1)+collect(p2) as export_nodes, collect(r) as export_rels
CALL apoc.export.cypher.data(export_nodes,export_rels,"export.cypher",{})
YIELD file, source, format, nodes, relationships, properties, time
RETURN nodes, relationships, time;


// Export as csv
CALL apoc.export.csv.query("MATCH (p1:cliqueLeader)-[r{qualifier:'direct'}]->(p2:cliqueLeader) RETURN p1,r,p2" ,"export-kg.csv",{});






