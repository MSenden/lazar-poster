Data confidentiality, authentication and authorization (AA) is a common requirement for many resources. 
Within the OpenTox\cite{hardy2010collaborative} project, in-silico toxicology gmbh has implemented a single-sign-on method with an OpenLDAP backend for user management
and OpenAM for authentication and authorization. 
This system was updated and revised for eNanoMapper and provides access control for the current services. 
Conforming to the OpenTox web service architecture principles\cite{hardy2010collaborative}, eNanoMapper services can be decoupled from AA. 
This provides the opportunity to deploy a service without A&A, if required (e.g. for local installations). 