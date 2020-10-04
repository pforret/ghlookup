# ghlookup

Lookup Github info via API in bash

## Usage

	Program: ghlookup 0.0.1 by peter@forret.com
	Updated: Oct  4 21:32:52 2020
	Usage: ghlookup [-h] [-q] [-v] [-f] [-l <log_dir>] [-t <tmp_dir>] <id> <field>
	Flags, options and parameters:
	    -h|--help      : [flag] show usage [default: off]
	    -q|--quiet     : [flag] no output [default: off]
	    -v|--verbose   : [flag] output more [default: off]
	    -f|--force     : [flag] do not ask for confirmation (always yes) [default: off]
	    -l|--log_dir <val>: [optn] folder for log files   [default: log]
	    -t|--tmp_dir <val>: [optn] folder for temp files  [default: .tmp]
	    <action>  : [parameter] user/repo/repos
	    <path>    : [parameter] <user> or <user/repo>
	    <field>   : [parameter] field to retrieve:  name

## Examples

	> ghlookup user cli .
	{
	  "login": "cli",
	  "id": 59704711,
		(...)
	  "created_at": "2020-01-09T18:03:11Z",
	  "updated_at": "2020-09-24T15:31:55Z"
	}     

	> ghlookup repo cli/cli .
	{
	  "id": 212613049,
	  "node_id": "MDEwOlJlcG9zaXRvcnkyMTI2MTMwNDk=",
	  "name": "cli",
	  "full_name": "cli/cli",
		(...)
	  "network_count": 1219,
	  "subscribers_count": 460
	}

	> ghlookup repo cli/cli .license
	{
	  key: mit
	  name: MIT License
	  spdx_id: MIT
	  url: https://api.github.com/licenses/mit
	  node_id: MDc6TGljZW5zZTEz
	}   

	> ghlookup repo cli/cli .description
	GitHub’s official command line tool

	> ghlookup repos cli ".[].name"
	cli
	scoop-gh
	shurcooL-graphql


## authenticated or not

* works without Github API authentication (max 60 calls/hour)
* optionally works with Github personal tokens via .env file (max 5000 calls/hour)

## Created with [bashew](https://github.com/pforret/bashew)

in 1 hour



&copy; 2020 Peter Forret - MIT License
