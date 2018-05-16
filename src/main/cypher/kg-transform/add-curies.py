import csv
import json
import gzip
from prefixcommons import contract_uri
from prefixcommons.curie_util import NoPrefix



def add_curie_to_node(node):
    try:
        node['properties']['id'] = contract_uri(node['properties']['iri'], strict=True)[0]
    except NoPrefix:
        node['properties']['id'] = node['properties']['iri']
    new_clique = []
    for iri in node['properties']['clique']:
        if iri.startswith('_'):
            continue
        try:
            new_clique.append(contract_uri(iri, strict=True)[0])
        except NoPrefix:
            pass
    node['properties']['clique'] = new_clique


# Main
infile = gzip.open('/path/to/data/export-kg.csv.gz', 'rt')
outfile = open('/path/to/data/export-kg-edit.csv', 'w')

reader = csv.reader(infile, quotechar='"')
writer = csv.writer(outfile, quotechar='"', quoting=csv.QUOTE_ALL)

writer.writerow(next(reader)) # header
for row in reader:
    subject = json.loads(row[0])
    object = json.loads(row[2])
    add_curie_to_node(subject)
    add_curie_to_node(object)
    writer.writerow([json.dumps(subject), row[1], json.dumps(object)])