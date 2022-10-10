# Harvesting publiccode.yml catalogues
Catalogues like Joinup facilitate the discoverability of reusable interoperability solutions.
Often, similar initiatives exists at the memberstate level, which leads to the possibility of federating those catalogues at the european level.

Two datastandards are currently in use for building such catalogues, each with its specificities.

## ADMS-AP
This specification covers the full domain of asset catalogues, including the description of the catalogue itself.
Its model is based on linked data (RDF), which makes offers advantages when combining data from multiple sources.
It's most important traits are:
- Relatively difficult to implement
- Describes: Interoperability solutions (open source software, standards & specifications, methodologies,...)
- Technical serialisation: Linked data (RDF)
- Description: External to the system. The act of cataloguing is considered external to the development of the solution.
- Governance: Change control managed by working groups with member state representatives organised by SEMIC action of the Digital Europe Programme.
- Identifiers: URIs are minted by the source catalogue.
- Model coverage: Catalogue, Solution, Release, Distribution (and auxiliary classes)

## Publiccode.yml
This specification is focused on Open Source Software. A YAML file in the repository is all that is needed, which can improve the timeliness of the metadata updates, and lead to a better data quality.
- Relatively easy to implement
- Describes: Open source software (definition of a catalogue is not covered, as such methodology of harvesting a catalogue is not defined)
- Technical serialisation: YAML file
- Description: Self descriptive, the description is maintained in the source code repository of the software
- Governance: Change control managed by the 'Foundation for Public Code'.
- Identifiers: Not really considered (moving a repo can cause issues)
- Model coverage: Software solution

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

# Run through docker
After cloning the repository, cd into the directory and run
```bash
docker build . -t publiccode -f .
```
You can swap the `publiccode` with any keyword but remember that this is the tag name.

Then, you can start the container using:
```bash
docker run -v "workspace:/app/workspace" -it publiccode
```

and then `cd` into the `/app` directory.
All data will be generated in the workspace directory locally which is mapped to the corresponding workspace directory in the container.

# Install locally
The following tools are required on the system.

 -  GNU make (part of the `build-essential` package for UNIX)
 -  [jq](https://stedolan.github.io/jq/download/) (dependency of yq, a tool to manipulate JSON files)
 -  [yq](https://github.com/mikefarah/yq) (to transform YAML to JSON) - version > 4.25.0 required
 -  Java JRE (to run RML Mapper)
 -  wget
 -  git
 -  Pearl URI module - Installed with CPAN (`cpan install URI`)
 -  RML Mapper. Install by running `make dependencies` after you have installed the above packages.
 Please, note that this will install RML and Apache Jena in `tools` directory.
 Deleting the contents of the `tools` directory will result in having to
 re-install the dependencies. -  Golang-go
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
