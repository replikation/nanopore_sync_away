# sync fast5 to server
===
![](https://img.shields.io/badge/bash-brightgreen)
![](https://img.shields.io/badge/licence-GPL--3.0-lightgrey.svg)

[![Twitter Follow](https://img.shields.io/twitter/follow/gcloudChris.svg?style=social)](https://twitter.com/gcloudChris) 



## What is this Repo?

* standardise the file upload of fast5 to another server via rsync

## configuration

```bash
# open sync_away.sh and modify
SYNOLOGY_FAST5_LOCATION="/volume1/Database_FAST5_raw_data"
# this is the storage location on the server
```


## USAGE

```bash
sync_away.sh folder_to_sync/
```