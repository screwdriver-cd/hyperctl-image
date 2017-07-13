# hyperctl docker image
[![Build Status][status-image]][status-url] [![Open Issues][issues-image]][issues-url]

> This repo creates a minimal docker image containing hyperctl and k8s-vm scripts.

## Usage
# Build the hyperctl image on docker hub
Run it through the pipeline

# Build the hyperctl image locally
Run the command under the root of this repository:

```bash
docker run -v $(pwd):/tmp/src -ti centos /bin/bash -c "cd /tmp/src; bash -xe scripts/hyperctl-download.sh"
```
The above command will create a `hyperctl` binary under current directory.

Replace the `wget` line (downloading the hyperctl binary from github) in the `Dockerfile` with your local hyperctl binary.

```bash
docker build -t scredrivercd/hyperctl-image:tag .
```


## License

Code licensed under the BSD 3-Clause license. See LICENSE file for terms.


[issues-image]: https://img.shields.io/github/issues/screwdriver-cd/hyperctl-image.svg
[issues-url]: https://github.com/screwdriver-cd/hyperctl-image/issues
[status-image]: https://cd.screwdriver.cd/pipelines/254/badge
[status-url]: https://cd.screwdriver.cd/pipelines/254
