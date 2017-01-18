get an URI list for all models:
```Bash
  curl -X GET --header 'Accept: text/uri-list' -H 'accept:text/uri-list' 'https://enm.in-silico.ch/model' 
```

retrieve an JSON representation of a model:
```Bash
  curl -X GET -H 'Accept: application/json' -H 'accept: application/json' 'https://enm.in-silico.ch/model/<MODELID>'
```

predict a nano-particle:
```Bash
  curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:text/html' -d 'identifier= \ https://enm.in-silico.ch/nanoparticle/<NANOPARTICLEID>' 'https://enm.in-silico.ch/model/<MODELID>'
```