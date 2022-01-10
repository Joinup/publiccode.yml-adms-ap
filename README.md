# Publiccode.yml to ADMS-AP knowledge graph generation
This tool tracks publiccode.yml repositories, and (aims to) generates an ADMS-AP complient knowledge graph from them.

# Install
The following tools are required on the system.

 -  GNU make
 -  jq (depedency of yq, a tool to manipulate JSON files)
 -  yq (to transform YAML to JSON)
 -  JAVA JRE (to run RML Mapper)
 -  wget
 -  RML Mapper (Install by running `make dependencies`)

# Tracking new repositories
From the root of the project, run:
```
./bin/add-repository.sh https://github.com/UniversitaDellaCalabria/unicms-template-unical.git
```

# Building the graph
Run `make update` on a regular basis to keep the knowledge file up-to-date.
The latest publiccode.yml file is pulled from each tracked repository on a daily basis, transformed into ADMS-AP, and merged into a graph.
The graph is available under workspace/graph.rdf

The RML mapping script can be altered by updating publiccode-to-adms.ttl
Documentation on RML: https://rml.io/docs/rml/tutorials/json/

# Provisioning with test data.
It should suffice to run `make provision-testdata` to have a set of 100 repositories to work with.
If more data is needed, this can get you started on building a list of publiccode.yml repositories:
```
curl -H "Authorization: token YOUR_PERSONAL_GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/search/code?q=publiccodeYmlVersion+filename:publiccode.yml+path:/&per_page=100" > test/list-of-repos.json
cat test/list-of-repos.json | jq '.items[].repository.html_url' -r | sed 's/$/.git/' > test/list-of-repos.txt
cat test/list-of-repos.txt | xargs -n 1 ./repo-add.sh
```
