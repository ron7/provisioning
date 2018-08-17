# provisioning

`bash <(curl -f -L -sS https://raw.githubusercontent.com/ron7/provisioning/master/builder)`

One liner for installing docker-ce

`apt-get update -qq && apt-get install apt-transport-https ca-certificates curl software-properties-common -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && apt-get install docker-ce -y`
