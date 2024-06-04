# el8-py312-dnf-wheels
This repo contains some proof of concept work to build wheels for rpm/dnf and related dependencies

## usage

1. `docker build -t el8-py312-dnf-wheels .`
1. `mkdir wheels`
1. `docker run -v $PWD/wheels:/root/wheels el8-py312-dnf-wheels`
1. Do something with the wheels in `wheels`
