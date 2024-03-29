#REPO=$(wildcard 'tracked-repos/*.git')
tracked = $(wildcard tracked-repos/*.git)
publiccode := $(subst tracked-repos, workspace/publiccode, $(tracked))
publiccode-rdf := $(subst .git,/publiccode.rdf,$(publiccode))

update: expire workspace/graph.ttl

workspace/graph.ttl: workspace/inferred-contact-email.ttl workspace/inferred-missing-contacts.ttl workspace/inferred-publisher.ttl workspace/inferred-en-description.ttl
	./tools/apache-jena/bin/ntriples --formatted=turtle namespaces.ttl workspace/inferred-contact-email.ttl workspace/inferred-missing-contacts.ttl workspace/inferred-publisher.ttl workspace/inferred-en-description.ttl > workspace/graph.ttl

# Warning: output contains input graph + inferred triples.
workspace/inferred-contact-email.ttl: workspace/graph.nt mappings/infer-contact-email.rq
	./tools/apache-jena/bin/sparql --data=workspace/graph.nt --query=mappings/infer-contact-email.rq > workspace/inferred-contact-email.ttl

# Warning: output contains inferred triples only.
workspace/inferred-missing-contacts.ttl: workspace/graph.nt mappings/infer-missing-contact.rq
	./tools/apache-jena/bin/sparql --data=workspace/graph.nt --query=mappings/infer-missing-contact.rq > workspace/inferred-missing-contacts.ttl

# Warning: output contains inferred triples only.
workspace/inferred-publisher.ttl: workspace/graph.nt mappings/infer-publisher.rq
	./tools/apache-jena/bin/sparql --data=workspace/graph.nt --query=mappings/infer-publisher.rq > workspace/inferred-publisher.ttl

workspace/inferred-en-description.ttl: workspace/graph.nt mappings/infer-english-description.rq
	./tools/apache-jena/bin/sparql --data=workspace/graph.nt --query=mappings/infer-english-description.rq > workspace/inferred-en-description.ttl

workspace/graph.nt: $(publiccode-rdf)
	cat $(publiccode-rdf) > workspace/graph.nt

workspace/cloned-repos/%.git: tracked-repos/%.git
	./bin/clone-update.sh $(@F)

workspace/publiccode/%/publiccode.yml: workspace/cloned-repos/%.git
	mkdir -p workspace/publiccode/$(*F)
	-git -C $^ cat-file blob HEAD:publiccode.yml > $@
#	If the publiccode.yml file isn't valid, blank it out to avoid downstream issues.
	@docker run -i italia/publiccode-parser-go /dev/stdin < $@ > /dev/null 2>&1 || (echo "" > $@ && echo "\033[0;31mWARNING: File not conformant to publiccode.yml $@\033[0m (skipping)")

workspace/publiccode/%/publiccode.json: workspace/publiccode/%/publiccode.yml
	-./bin/convert-yaml-to-json.sh $^ > $@

workspace/publiccode/%/publiccode.rdf: workspace/publiccode/%/publiccode.json publiccode-to-adms.ttl
	./bin/transform.sh $@ > $@

expire:
# 	Mark all tracked repo files older than a day for processing.
	find tracked-repos/* -mmin +1440 -exec touch {}  \;

# Creates an environment with some publiccode.yml repositories.
create-catalogue-testdata: remove-tracked-repos
	cat test/list-of-repos.txt | xargs -n 1 ./bin/add-repository.sh

# Tracks the Italian catalogue (Developers Italia)
create-catalogue-it-data: remove-tracked-repos
	curl https://crawler.developers.italia.it/softwares.yml | yq e -o=j | jq -r .[].publiccode.url | xargs -n 1 ./bin/add-repository.sh

remove-tracked-repos:
	rm -f tracked-repos/*

dependencies: tools/rmlmapper.jar tools/apache-jena tools/apache-jena/lib/sparql-shell-1.0-SNAPSHOT.jar

tools/rmlmapper.jar:
	# wget https://github.com/RMLio/rmlmapper-java/releases/download/v4.13.0/rmlmapper-4.13.0-r359-all.jar -O tools/rmlmapper.jar
	wget https://github.com/RMLio/rmlmapper-java/releases/download/v6.0.0/rmlmapper-6.0.0-r363-all.jar -O tools/rmlmapper.jar
	# Note: Other dependencies are required, such as wget, java-jre, jq and yq.

tools/apache-jena:
	rm -f tools/apache-jena
	wget https://dlcdn.apache.org/jena/binaries/apache-jena-4.5.0.zip -O tools/apache-jena.zip
	unzip tools/apache-jena.zip -d tools
	rm tools/apache-jena.zip
	cd tools; ln -s apache-jena-4.5.0 apache-jena

tools/apache-jena/lib/sparql-shell-1.0-SNAPSHOT.jar: tools/apache-jena
	wget https://github.com/sandervd/SPARQL-shell/releases/download/1.0/sparql-shell-1.0-SNAPSHOT.jar -O tools/apache-jena/lib/sparql-shell-1.0-SNAPSHOT.jar

clean:
	rm workspace/*/* -rf
	rm workspace/graph.*

.PHONY: update expire fetch dependencies create-catalogue-testdata create-catalogue-it-data remove-tracked-repos clean

# Keep intermediate files for performance.
.PRECIOUS: workspace/cloned-repos/%.git workspace/publiccode/%/publiccode.yml workspace/publiccode/%/publiccode.json

# For performance, no need to process old suffix rules.
.SUFFIXES:  
