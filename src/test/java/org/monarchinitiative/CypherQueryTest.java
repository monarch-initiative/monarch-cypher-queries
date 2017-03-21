package org.monarchinitiative;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.is;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.junit.After;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.ClassRule;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.neo4j.graphdb.Direction;
import org.neo4j.graphdb.GraphDatabaseService;
import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.Path;
import org.neo4j.graphdb.Relationship;
import org.neo4j.graphdb.Result;
import org.neo4j.graphdb.Transaction;
import org.prefixcommons.CurieUtil;

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.google.common.base.Charsets;
import com.google.common.base.Optional;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.google.common.io.Resources;
import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;

import io.scigraph.frames.CommonProperties;
import io.scigraph.frames.Concept;
import io.scigraph.internal.CypherUtil;
import io.scigraph.neo4j.Graph;
import io.scigraph.neo4j.GraphTransactionalImpl;
import io.scigraph.neo4j.Neo4jModule;
import io.scigraph.owlapi.OwlRelationships;
import io.scigraph.owlapi.loader.BatchOwlLoader;
import io.scigraph.owlapi.loader.OwlLoadConfiguration;

public class CypherQueryTest {

  @ClassRule
  public static TemporaryFolder graphDir = new TemporaryFolder();

  public static final String CONSTANT_LOCATION = "target/graph-test/";

  static ObjectMapper MAPPER = new ObjectMapper(new YAMLFactory());

  static CypherUtil cypherUtil;
  static GraphDatabaseService graphDb;
  static CurieUtil curieUtil;
  static Graph graph;

  Multimap<String, Object> params = HashMultimap.create();

  Transaction tx;

  @BeforeClass
  public static void loadGraph() throws Exception {
    File graphLoc = new File(CONSTANT_LOCATION);

    OwlLoadConfiguration config = MAPPER.readValue(Resources.getResource("final-test-config.yaml"), OwlLoadConfiguration.class);
    // config.getGraphConfiguration().setLocation(graphDir.getRoot().getAbsolutePath());
    config.getGraphConfiguration().setLocation(CONSTANT_LOCATION);
    if (!graphLoc.exists()) {
      BatchOwlLoader.load(config);
    }
    Injector i = Guice.createInjector(new Neo4jModule(config.getGraphConfiguration()), new AbstractModule() {
      @Override
      protected void configure() {
        bind(Graph.class).to(GraphTransactionalImpl.class);
      }
    });
    cypherUtil = i.getInstance(CypherUtil.class);
    curieUtil = i.getInstance(CurieUtil.class);
    graphDb = i.getInstance(GraphDatabaseService.class);
    graph = i.getInstance(Graph.class);
  }

  @Before
  public void clearParams() {
    params.clear();
  }

  @Before
  public void startTx() {
    tx = graphDb.beginTx();
  }

  @After
  public void endTx() {
    tx.failure();
    tx.close();
  }

  Optional<String> getCurie(Node node) {
    return curieUtil.getCurie((String) node.getProperty(Concept.IRI));
  }

  String getQuery(String methodName) throws IOException {
    methodName = methodName.substring(0, methodName.indexOf('_'));
    URL url = Resources.getResource("queries/" + methodName + ".txt");
    return Resources.toString(url, Charsets.UTF_8);
  }

  Node getParent(Node child) {
    for (Relationship r : child.getRelationships(Direction.OUTGOING, OwlRelationships.RDFS_SUBCLASS_OF)) {
      return r.getOtherNode(child);
    }
    return null;
  }

  List<String> getParents(Node child) {
    List<String> parents = new ArrayList<>();
    for (Path path : graphDb.traversalDescription().depthFirst().relationships(OwlRelationships.RDFS_SUBCLASS_OF, Direction.OUTGOING).traverse(child)) {
      if (path.length() > 1) {
        parents.add((String) path.endNode().getProperty(CommonProperties.IRI));
        /*
         * Optional<String> curie = getCurie(path.endNode()); if (curie.isPresent()) {
         * parents.add(curie.get()); }
         */
      }
    }
    return parents;
  }


  /**
   * Example of a test
   * */
  @Test
  @Ignore
  public void diseaseFromPhenotype_test() throws Exception {
    String query = getQueryFromTemplate("/dynamic/evidence/{subject_id}/{object_id}");
    long id = graph.getNode(curieUtil.getIri("HP:0100543").get()).get();
    params.put("phenotype_id", graph.getNodeProperty(id, CommonProperties.IRI, String.class).get());
    Result result = cypherUtil.execute(query, params);
    Set<String> diseases = new HashSet<>();
    while (result.hasNext()) {
      Node gene = (Node) result.next().get("disease");
      diseases.add(getCurie(gene).get());
    }
    assertThat(
        "Diseases are returned.",
        diseases,
        containsInAnyOrder("OMIM:100100", "OMIM:102150", "DECIPHER:1", "OMIM:607822", "OMIM:610168", "DECIPHER:14", "OMIM:158900", "OMIM:168600",
            "OMIM:194072"));
  }

  
  public String getQueryFromTemplate(String queryPath) throws JsonParseException, JsonMappingException, IOException {
    ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
    CypherResources cypherResources = mapper.readValue(Resources.getResource("queries_monarch.yaml"), CypherResources.class);

    String resourcePath = "queryPath";
    Optional<String> queryOption = cypherResources.getCypherResource(resourcePath);
    assertThat("Can't find query for path " + resourcePath, queryOption.isPresent(), is(true));
    return queryOption.get();
  }


}
