**`lazar`** \cite{helma_2017}\cite{helma_christoph_2016_215483}

  - Mirrors eNanoMapper data for read-across models
  - Creates read-across predictions for the `nano-lazar` webinterface
  - Responds to requests from the `lazar-rest` interface (e.g. nanoparticle predictions, model creation and validation, descriptor calculation)

**RDF store**

  - Mirrors eNanoMapper data and ontologies
  - Responds to SPARQL queries from the ontology viewer and the SPARQL interface

**`nano-lazar` GUI** \cite{gebele_denis_2017_250818}

  - Obtains nanoparticle toxicity predictions from the `lazar` library
  - Uses ontologies (eNanoMapper, BioPortal, UniProt) to explain domain specific terms in the user interface
  - Uses ontologies and eNanoMapper data as supporting information for read-across predictions

**eNM `ontology viewer`**

  - Sends SPARQL queries to the RDF store
  - Visualises RDF response from the RDF store

**`nano-lazar` REST interface** \cite{rautenberg_micha_2016_187328}

  - Interacts with the `lazar` library (e.g. for toxicity predictions, model creation and validation, descriptor calculation)
  - Will be maintained and developed in the FP7 OpenRiskNet project

**eNM SPARQL interface**

  - Sends SPARQL queries to the RDF store
  - Receives SPARQL query results in different formats


