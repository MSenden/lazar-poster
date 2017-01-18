Data confidentiality, authentication and authorization (AA) is a common requirement for many resources. 
Within the OpenTox\cite{hardy2010collaborative} project, in-silico toxicology gmbh has implemented a single-sign-on method with an OpenLDAP backend for user management
and OpenAM for authentication and authorization. The revised technic is also used in eNanoMapper services to provide access control.  
Conforming to the OpenTox web service architecture principles\cite{hardy2010collaborative}, eNanoMapper services will be decoupled from AAI. 
This provides the opportunity to deploy a service without A&A, if/when possible. 