# Begin build step.
FROM golang:alpine AS build

# Install Tailscale & Tailscaled.
RUN go get tailscale.com/cmd/tailscale@v1.8.1
RUN go get tailscale.com/cmd/tailscaled@v1.8.1

# Build the application.
ADD . /build
WORKDIR /build

# Begin run step.
FROM golang:alpine

# Install some dependencies.
RUN apk add --update sudo bash

# Tailscaled can't run as root user, cuz of an SO_MARK issue.
# See: https://github.com/tailscale/tailscale/issues/634.
ARG USER=default
ENV HOME /home/$USER
RUN adduser -D $USER \
  && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
  && chmod 0440 /etc/sudoers.d/$USER
USER $USER
WORKDIR $HOME

# Copy over the files.
COPY --from=build /build/entrypoint.sh $HOME/entrypoint.sh
COPY --from=build $GOPATH/bin/tailscale $HOME/tailscale
COPY --from=build $GOPATH/bin/tailscaled $HOME/tailscaled

# Fire up tailscaled, authenticate using a reusable key, and run.
ARG TAILSCALE_KEY
RUN mkdir -p $HOME/tailscale-storage
ENTRYPOINT bash $HOME/entrypoint.sh
