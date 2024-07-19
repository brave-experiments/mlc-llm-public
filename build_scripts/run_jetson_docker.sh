#!/bin/bash

sudo docker run --runtime nvidia -it --network=host --name jetson_docker_mlc -v /media/jetson/ssd/melt/:/tmp/melt dustynv/mlc:dev-r36.2.0