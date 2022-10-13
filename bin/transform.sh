#!/bin/bash -e
directory=${1%/*}
cd $directory

# --verbose: Additional debug information.
# --strict: Fail if there is a missing mapping.
# --duplicates: Removes duplicates in the resulting file.
# --mappingfile: The file to use in order to construct the new RDF file.
# --base-iri: The IRI to use in the JSON properties.
java -jar ../../../tools/rmlmapper.jar --verbose --strict --duplicates --mappingfile ../../../publiccode-to-adms.ttl --base-iri http://example.com/
