# Publiccode.yml to ADMS-AP knowledge graph generation
This tool tracks publiccode.yml repositories, and (aims to) generates an ADMS-AP complient knowledge graph from them.

# Run through docker
After cloning the repository, cd into the directory and run
```bash
docker build . -t publiccode -f .
```
You can swap the `publiccode` with any keyword but remember that this is the tag name.

Then, you can start the container using:
```bash
docker run -v "workspace:/build/workspace" -it publiccode
```

and then `cd` into the `/build` directory.
All data will be generated in the workspace directory locally which is mapped to the corresponding workspace directory in the container.

# Install locally
The following tools are required on the system.

 -  GNU make
 -  jq (dependency of yq, a tool to manipulate JSON files)
 -  yq (to transform YAML to JSON)
 -  Java JRE (to run RML Mapper)
 -  wget
 -  git
 -  Pearl URI module - Installed with CPAN (`cpan install URI`)
 -  RML Mapper (install by running `make dependencies`)
 -  Golang-go
 -  [pcvalidate package](https://github.com/italia/publiccode-parser-go)

# Harvesting the 'developers Italia' catalogue
First, update the list of tracked repositories with the state of the upstream catalogue.
```
make create-catalogue-it-data
```

Then continue with 'building the graph'.

# Building the graph
Run `make update` on a regular basis to keep the ADMS-AP catalogue file up-to-date.
By default the repositories will only be fetched once a day (see expire target).

As make builds a dependency tree of targets, the process can be speed up by running multiple make jobs at once:
`make update -j8`
The latest publiccode.yml file is pulled from each tracked repository on a daily basis, transformed into ADMS-AP, and merged into a graph.
The graph is made available under workspace/graph.rdf

The RML mapping script can be altered by updating publiccode-to-adms.ttl
Documentation on RML: https://rml.io/docs/rml/tutorials/json/

# Manual tracking new repositories
From the root of the project, run:
```
./bin/add-repository.sh https://github.com/UniversitaDellaCalabria/unicms-template-unical.git
```

# Provisioning with test data.
It should suffice to run `make create-catalogue-testdata` to have a set of 100 repositories to work with.
If more data is needed, the following procedure can help building a list of publiccode.yml repositories:
```
curl -H "Authorization: token YOUR_PERSONAL_GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/search/code?q=publiccodeYmlVersion+filename:publiccode.yml+path:/&per_page=100" > test/list-of-repos.json
cat test/list-of-repos.json | jq '.items[].repository.html_url' -r | sed 's/$/.git/' > test/list-of-repos.txt
cat test/list-of-repos.txt | xargs -n 1 ./repo-add.sh
```

