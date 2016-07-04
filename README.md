Sinatra app that searches commits 
=========================

### overview

Sinatra app that searches commits by user/organization and pushed_at date.
Search can also be limited to commits in a single repository since a specified date.

### configure

create `configs` folder in the root directory, with a yaml file following this template:

```
user:		    your_github_user
password: 	    your_pass
base_url:           https://api.github.com
```

### requires

`github_inator` source is in [github_inator repo](https://github.com/nmusaelian-rally/github_inator)

```
require 'sinatra'
require 'shotgun'
require 'github_inator'
require 'time'
```

### run

`shotgun app.rb`

### License

AppTemplate is released under the MIT license.  See the file [LICENSE](./LICENSE) for the full text.



