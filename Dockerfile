name: Build and Export Multi-Arch Docker Images

on:
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]

jobs:
  build-and-export:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image for x86_64
        run: |
          IMAGE_NAME=fakesip
          TAG=$(date +%s)
          echo "Building Docker image: $IMAGE_NAME:x86_64-$TAG"
          docker buildx build \
            --platform linux/amd64 \
            --load \
            --file Dockerfile \
            --build-arg ARCH=x86_64 \
            --build-arg VERSION=0.9.1 \
            --tag $IMAGE_NAME:x86_64-$TAG \
            .

          docker save -o fakesip-x86_64.tar $IMAGE_NAME:x86_64-$TAG

      - name: Build Docker image for arm64
        run: |
          IMAGE_NAME=fakesip
          TAG=$(date +%s)
          echo "Building Docker image: $IMAGE_NAME:arm64-$TAG"
          docker buildx build \
            --platform linux/arm64 \
            --load \
            --file Dockerfile \
            --build-arg ARCH=arm64 \
            --build-arg VERSION=0.9.1 \
            --tag $IMAGE_NAME:arm64-$TAG \
            .

          docker save -o fakesip-arm64.tar $IMAGE_NAME:arm64-$TAG

      - name: Upload x86_64 Docker image tar to GitHub
        uses: actions/upload-artifact@v3
        with:
          name: fakesip-x86_64
          path: fakesip-x86_64.tar

      - name: Upload arm64 Docker image tar to GitHub
        uses: actions/upload-artifact@v3
        with:
          name: fakesip-arm64
          path: fakesip-arm64.tar
