#REPO=$(wildcard 'tracked-repos/*.git')
tracked = $(wildcard tracked-repos/*.git)
publiccode := $(subst tracked-repos, workspace/publiccode, $(tracked))
publiccode-rdf := $(subst .git,/publiccode.rdf,$(publiccode))

update: expire workspace/graph.rdf

workspace/graph.rdf: $(publiccode-rdf)
	 find workspace/*/* -type f -name '*.rdf' -exec cat {} \; > workspace/graph.rdf

workspace/cloned-repos/%.git: tracked-repos/%.git
	./bin/clone-update.sh $(@F)

workspace/publiccode/%/publiccode.yml: workspace/cloned-repos/%.git
	mkdir -p workspace/publiccode/$(*F)
	-git -C $^ cat-file blob HEAD:publiccode.yml > $@

workspace/publiccode/%/publiccode.json: workspace/publiccode/%/publiccode.yml
	-./bin/convert-yaml-to-json.sh $^ > $@

workspace/publiccode/%/publiccode.rdf: workspace/publiccode/%/publiccode.json publiccode-to-adms.ttl
	./bin/transform.sh $@ > $@

expire:
	# Mark all tracked repo files older than a day for processing.
	find tracked-repos/* -mmin +1440 -exec touch {}  \;

# Creates an environment with some publiccode.yml repositories.
provision-testdata:
	cat test/list-of-repos.txt | xargs -n 1 ./bin/repo-add.sh	

dependencies:
	wget https://github.com/RMLio/rmlmapper-java/releases/download/v4.13.0/rmlmapper-4.13.0-r359-all.jar -O tools/rmlmapper.jar
	# Note: Other dependencies are required, such as wget, java-jre, jq and yq.

clean:
	rm workspace/*/* -rf

.PHONY: update expire fetch dependencies provision-testdata clean

# Keep intermediate files for performance.
.PRECIOUS: workspace/cloned-repos/%.git workspace/publiccode/%/publiccode.yml workspace/publiccode/%/publiccode.json

# For performance, no need to process old suffix rules.
.SUFFIXES:  
