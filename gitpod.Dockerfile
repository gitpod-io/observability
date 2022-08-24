# Copyright (c) 2020 Gitpod GmbH. All rights reserved.
# Licensed under the GNU Affero General Public License (AGPL).
# See License-AGPL.txt in the project root for license information.

FROM gitpod/workspace-full:2022-08-04-13-40-17

ENV TRIGGER_REBUILD 20

USER root

RUN sudo curl -Lo /usr/bin/yq https://github.com/mikefarah/yq/releases/download/v4.27.2/yq_linux_amd64 && sudo chmod +x /usr/bin/yq

RUN sudo apt update && sudo apt-get install shellcheck apt-transport-https ca-certificates -y && sudo update-ca-certificates

USER gitpod

# Install pre-commit https://pre-commit.com/#install
RUN sudo install-packages shellcheck \
    && sudo python3 -m pip install pre-commit
sadsa
