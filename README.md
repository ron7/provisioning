# provisioning

`bash <(curl -f -L -sS https://raw.githubusercontent.com/ron7/provisioning/master/builder)`

if you DO need the default webmail client:

`ADDMAIL=1 bash <(curl -f -L -sS https://raw.githubusercontent.com/ron7/provisioning/master/builder)`

if you DO need to force a PHP version:

`PHPVER=8.2 bash <(curl -f -L -sS https://raw.githubusercontent.com/ron7/provisioning/master/builder)`

or if you DO need the custom NGINX built with PageSpeed, use the default `nginx` package with:

`BUILD=1 bash <(curl -f -L -sS https://raw.githubusercontent.com/ron7/provisioning/master/builder)`

One liner for installing docker-ce

`apt-get update -qq && apt-get install apt-transport-https ca-certificates curl software-properties-common -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && apt-get install docker-ce docker-compose -y`
