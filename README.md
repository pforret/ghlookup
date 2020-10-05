![Shellcheck CI](https://github.com/pforret/ghlookup/workflows/Shellcheck%20CI/badge.svg)
![Bash CI](https://github.com/pforret/ghlookup/workflows/Bash%20CI/badge.svg)
[![basher install](https://img.shields.io/badge/basher-install-white?logo=gnu-bash&style=flat)](https://basher.gitparade.com/package/)

# ghlookup

Lookup Github info via API in bash

## Usage

    Program: ghlookup 1.1.0 by peter@forret.com
    Updated: Oct  4 21:32:52 2020
    Usage: ghlookup [-h] [-q] [-v] [-f] [-l <log_dir>] [-t <tmp_dir>] [-a <accept>] <action> <ident> <field>
    Flags, options and parameters:
        -h|--help      : [flag] show usage [default: off]
        -q|--quiet     : [flag] no output [default: off]
        -v|--verbose   : [flag] output more [default: off]
        -f|--force     : [flag] do not ask for confirmation (always yes) [default: off]
        -l|--log_dir <val>: [optn] folder for log files   [default: log]
        -t|--tmp_dir <val>: [optn] folder for temp files  [default: .tmp]
        -a|--accept <val>: [optn] accept header (e.g. application/vnd.github.mercy-preview+json)
        <action>  : [parameter] user/repo/repos/tags/langs/topics
        <ident>   : [parameter] <user> or <user/repo>
        <field>   : [parameter] field to retrieve: field to retrieve: . / .field / .[].name / @ 
    
## Installation

	basher install pforret/ghlookup
	
or
    
    git clone https://github.com/pforret/ghlookup.git
    cd ghlookup
    ./ghlookup.sh user pforret .
    
## Examples

```bash
> ghlookup user cli .
{
  "login": "cli",
  "id": 59704711,
    (...)
  "created_at": "2020-01-09T18:03:11Z",
  "updated_at": "2020-09-24T15:31:55Z"
}     

> ghlookup user cli @ 
GitHub CLI                         

> ghlookup repo laravel/laravel .        
  {
    "id": 1863329,
    "node_id": "MDEwOlJlcG9zaXRvcnkxODYzMzI5",
    "name": "laravel",
    "full_name": "laravel/laravel",
    (...)
    "network_count": 19510,
    "subscribers_count": 4752
} 

> ghlookup repo laravel/laravel .watchers
  61821                              

> ghlookup repos cli @
cli/cli
cli/scoop-gh
cli/shurcooL-graphql

> ghlookup topics alebcay/awesome-shell @
awesome-list
awesome
list
zsh
fish
bash
cli
shell  

> ghlookup tags laravel/laravel @ | head -1
v8.0.3

> ghlookup langs laravel/laravel @
Blade
PHP
Shell

> ghlookup files pforret/ghlookup @         
.env.example
.github
.gitignore
CHANGELOG.md
LICENSE
README.md
VERSION.md
ghlookup
ghlookup.sh
tests
```

## authenticated or not

* works without Github API authentication (max 60 calls/hour)
* optionally works with Github personal tokens via .env file (max 5000 calls/hour)

_Created with [bashew](https://github.com/pforret/bashew)_

&copy; 2020 Peter Forret - MIT License
