# Publiccode.yml to ADMS-AP knowledge graph generation
This tool tracks publiccode.yml repositories, and generates an ADMS-AP complient knowledge graph from them.

# Process
The publiccode.yml federation process has muliple steps:

## Catalogue identification
First, potential catalogues must be identified. The only thing a catalogue must supply, is the list of repostories (and as such reusable solutions) that it is compose of.
The only public catalogue identified today is the one provided by 'Team digitale'.

## Tracking the repositories
Each of the repositories identified gets 'tracked', meaning that the URL of the repository is registered.

## Each repository: from publiccode.yml to RDF
The following operations are executed for each repository. The steps are executed in order for each repository. 

### Fetching the repositories
The git repositories are then fetched:
- New repositories are cloned
- Existing repositories are updated

Only the commit history is downloaded at this point, as the actual repository content is not needed: it would slow the process down, and take up unneeded disk space.

### Extracting
From the git repostory, the puliccode.yml file is requested. As no blob objects are downloaded while cloning or updating, this might require git to fetch the file from the upstream repository.

### YAML to JSON
YAML isn't supported by the RDFMapper that executes the data transformation, so the publiccode.yml file is converted to publiccode.json.
This operation is a one on one convertion, similar to saving a file from excel to csv.

### Validation
The YAML file is checked for conformance to publiccode.yml standard. Non-conformant repositories are reported and excluded from further processing.

### JSON preprocessing
The data structure of the JSON file is challenging to transform directly, hence some preprocessing is done:
- Add the repository URL to all objects in the file (all levels).
- Flatten the structure of language codes of the 'description' field of publiccode.

### Transformation
The data transformation is performed by the execution of the RML mapper script. The transformation rules are defined in publiccode-to-adms.ttl
The transformation results in an RDF file (one for each repository).

## Aggregation
All the individual transformed repositories are now brought togheter in one big file (graph).

## Upload to Joinup
The resulting ADMS-AP file can now be uploaded to Joinup for import into a Joinup collection.

# Install
The following tools are required on the system.

 -  GNU make (part of the `build-essential` package for UNIX)
 -  [jq](https://stedolan.github.io/jq/download/) (dependency of yq, a tool to manipulate JSON files)
 -  [yq](https://github.com/mikefarah/yq) (to transform YAML to JSON) - version > 4.25.0 required
 -  Java JRE (to run RML Mapper)
 -  wget
 -  RML Mapper. Install by running `make dependencies` after you have installed the above packages.
 Please, note that this will install RML and Apache Jena in `tools` directory.
 Deleting the contents of the `tools` directory will result in having to
 re-install the dependencies.

# Harvesting the 'developers Italia' catalogue
First, update the list of tracked repositories with the state of the upstream catalogue.
```
make create-catalogue-it-data
```

Then continue with 'building the graph'.

# Building the graph
Run `make update` on a regular basis to keep the ADMS-AP catalogue file up-to-date.
By default the repositories will only be fetched once a day (see expire target).

As `make` builds a dependency tree of targets, the process can be speed up by running multiple make jobs at once:
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

