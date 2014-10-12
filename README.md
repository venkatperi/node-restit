
*Command Line Interface for RESTful APIs*

## Overview

[restit](https://github.com/venkatperi/node-restit) is a [command line tool (CLI)](http://en.wikipedia.org/wiki/Command-line_interface) for talking to RESTful APIs. It's intended to reduce some of the repetition and verbosity that comes with using general purpose CLI tools such as [curl](http://en.wikipedia.org/wiki/CURL) with RESTful APIs.

`restit` requires `npm`, the [node package manager](http://npmjs.org).

## Example

    restit get statuses/user_timeline -q 'screen_name:"twitterapi"'
    
In curl:

    curl --get -H "Authentication: Bearer TOKEN" "https://api.twitter.com/1.1/statuses/user_timeline.json" -d "screen_name=twitterapi"

## Features

- **API Profiles** Stores common API data such as the base url (e.g. `https://api.twitter.com/1.1`) and headers (e.g. `Authorization: ...`) in a config file.
- **CSON Objects** Uses CoffeeScript Object Notation  ([CSON](https://github.com/bevry/cson)), so you don't have to quote everything. 
- **JSONPath** Transforms the JSON response with XPath like selectors.
- **Pretty JSON** Cleaner output and *colors*. 
- **Timing** Reports round trip time.

## Install

    [sudo] npm install restit -g

## Usage

    Usage: restit <command>

where command is either a http method or a config command.

## Configuration
`restyle` stores configuration information in the user's home directory at `$HOME/.restitconf`.

### Edit Configuration

    restit set-config <api> [options]

    api     name of the API

    Options:
       -u, --url       base url of the API
       -e, --header    add/remove request headers (leave value empty to remove)
       -d, --default   make this the default API

To an entry for Twitter's [REST API](https://dev.twitter.com/rest/public), add a OAUTH app/bearer token for authentication and mark it as the default.

    set-config twitter11 --url https://api.twitter.com/1.1 --header "Authentication: Bearer TOKEN" --header "Accept-Encoding: gzip" --default
    
Subsequent calls to Twitter's API need not specify the base url or auth token. e.g.

    restit get statuses/user_timeline -q 'screen_name:"twitterapi"'
    
### Show Configuration
Use the `show-config` command to dump the current configuration.

    restit show-config

e.g.

    twitter:
        url: https://api.twitter.com
    twitter11:
        url: https://api.twitter.com/1.1
    default:   twitter11

## Sending REST Requests

    coffee app.coffee get <resource> [options]

    resource     resource part of the URL (baseurl/resource). required.

    Options:
       -a, --api       the API (from config). if missing, default api is used.
       -d, --data      request body
       -q, --query     query parameters
       -e, --header    request header(s). can be used more than once. empty value deletes header.
       --nopretty      don't run output through prettyjson
       -v, --verbose   verbose output
       --nojson        don't encode body as 'application/json'. uses 'application/x-www-form-urlencoded'
       --nosend        construct the request but don't send it
       --noinfo        no informational output
       --jpath         json path selector (transform JSON response)
     
## More Examples
### Froyo APIs

    #setup
    restit set-config --api froyo --url "http://api.froyo.io" --header "Accept: application/vnd.collection.doc+json"

    #invoke
    ./bin/restit get -a froyo pwd --query "length:30" --jpath "$..password" --noinfo
    
    #result
    pecroveswutrurisidecopigijupit

*** &copy; Copyright 2014, Venkat Peri. All Rights Reserved. ***