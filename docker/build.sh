#!/bin/bash

# todo: need $REPOSITORY_NAMESPACE and $REGISTRY env

# Migrate open source images to private repositories
images=("elasticsearch:8.16.1" "kibana:8.16.1" "bitnami/etcd:latest" "fluent/fluent-bit:3.2" "grafana/grafana:11.4.0" "bitnami/kafka:3.9.0"
      "minio/minio:latest" "mongo:latest" "mysql:latest" "prom/prometheus:latest" "redis:latest" "registry:latest" "apache/apisix:latest" "nginx:latest",
       "python:3.13-slim-bookworm")

function tag_images() {
  for image in "$@"; do
    if [[ $image == *":"* ]]; then
      local name=${image%%:*}
      local tag=${image##*:}
    else
      local name=$image
      local tag="latest"
    fi
    if [[ $name == *"/"* ]]; then
      local name=${name##*/}
    fi
    local repository="$REPOSITORY_NAMESPACE/${name}"
    local new_image="$REGISTRY/${repository}:${tag}"
    aws ecr describe-repositories --repository-names $repository --region $AWS_REGION >/dev/null 2>&1 || (echo "Creating ECR repository: $repository" && aws ecr create-repository --repository-name $repository --region $AWS_REGION) && echo "ECR repository already exists: $repository"
    echo $repository
    echo $new_image
    #docker pull ${image} && docker tag ${image} $new_image && docker push $new_image
    # docker buildx imagetools create --tag 867344450900.dkr.ecr.us-west-2.amazonaws.com/aws300/redis:latest redis:latest
  done
}


# Compile the Dockerfile of all subdirectories of the current directory
function build_images() {
  for dir in */; do
    cd $dir
    local name=${dir%/}
    local repository="$REPOSITORY_NAMESPACE/${name}"
    local new_image="$REGISTRY/${repository}:latest"
    # docker buildx create --driver docker-container --use --name multi-platform-builder
    aws ecr describe-repositories --repository-names $repository --region $AWS_REGION >/dev/null 2>&1 || (echo "Creating ECR repository: $repository" && aws ecr create-repository --repository-name $repository --region $AWS_REGION) && echo "ECR repository already exists: $repository"
    docker buildx build --platform linux/amd64,linux/arm64 -t $new_image --push .
    cd ..
  done
}

tag_images "${images[@]}"

BUILDX_EXPERIMENTAL=1
docker buildx create --use

build_images
