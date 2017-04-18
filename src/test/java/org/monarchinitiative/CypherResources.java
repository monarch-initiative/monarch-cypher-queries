package org.monarchinitiative;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import javax.validation.Valid;

import com.fasterxml.jackson.annotation.JsonProperty;

import io.scigraph.services.swagger.beans.resource.Apis;

public class CypherResources {
  @Valid
  @JsonProperty(required = false)
  private List<Apis> cypherResources = Collections.emptyList();

  public Optional<String> getCypherResource(String path) {
    Optional<String> hit = Optional.empty();
    for (Apis api : cypherResources) {
      if (api.getPath().equals(path)) {
        hit = Optional.of(api.getQuery());
      }
    }
    return hit;
  }
}
