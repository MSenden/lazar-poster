Get an URI list for all models:
\footnotesize

```Bash
  curl -X GET --header 'Accept: text/uri-list' -H 'accept:text/uri-list' 'https://enm.in-silico.ch/model' 
```
\normalsize
Retrieve an JSON representation of a model:
\footnotesize

```Bash
  curl -X GET -H 'Accept: application/json' -H 'accept: application/json' 'https://enm.in-silico.ch/model/<MODELID>'
```
\normalsize
Predict a nano-particle:
\footnotesize

```Bash
  curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:text/html' -d 'identifier= https://enm.in-silico.ch/nanoparticle/<NANOPARTICLEID>' 'https://enm.in-silico.ch/model/<MODELID>'
```