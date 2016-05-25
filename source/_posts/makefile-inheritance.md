---
title: Makefile reuse and inheritance
date: 2016-05-25
categories:
- Technologies
- Make
tags:
- task-runner
---
## Reusable Makefile

Trends like microservices and technologies like AWS Lambda mean applications are changing how applications are built.  Before, a single application may have been contained within a single repository but now one product might be delivered by dozens or even hundreds of little application in individual repositories, each of which are responsible for a small number of tasks.

Why you might do this is a topic for another time, but this approach makes maintaining build automation tools across an applications architected makes it harder.

Front end build automation tools like gulp and grunt have are mature plugin framework.  That mean it's easy to share solutions to common problem.  You can create plugins that are downloaded at build time and can be shared across different repositories.

There is no package manager or registry for makefile.  But there's nothing to stop you putting Makefiles in npm (or bower, nuget, composer, etc) modules.  You could even use git submodules.

Once you have a shared bit of makefile you can then use `include`.

#### `include`

The `include [filenames…]` ‘directive’ of makefile reads in the contents of all the filenames into the parent makefile before continuing.

`filenames…` can also be shell patterns.

For example adding `include *.mk` will include all files in the same directory that end with `.mk`.

## The Financial Times' Makefile for front end applications

The pattern we adopted was to have [a single, centralised Makefile](https://github.com/Financial-Times/n-makefile) that got committed to each our applications in a file called `n.Makefile`.  That was then pulled into each repository's *actual* makefile by an `include n.Makefile` added at the top.  That centralised makefile contains a [simple update script](https://github.com/Financial-Times/n-makefile/blob/master/Makefile#L119L126) that allows each repository to be upgraded to the latest version by running `make update-tools`.

That centralised makefile contained standard patterns for installing dependencies, building assets, deployments and linting.

Part of the philosophy behind it was to ensure that it was easy to override any part of it.

For example, if a developer wanted their repository wanted to simply use the default task provided by the central makefile to install a repositories' dependencies (run by the developer by typing `make install`) they didn't need to do anything besides `include n.Makefile`.  It would be provided by default.

However, if the developer wanted to write their own install task all they need to do is *implement* an `install` task in their Makefile.  They can even call `make install-super` anywhere in their `install` task to run the shared makefile's `install` task as well.

This might appear at first glance to be quite similar to inheritance except that make does not support inheritance.  So how did we achieve this?

We basically hacked inheritance into make by exploiting wildcards.  In our shared makefile instead of defining an `install` task, we define an `instal%` task.

This means that if there isn't a task called `install` running `make install` will run the steps defined in the `instal%` task and if an `install` task gets added that will run whenever a developer runs `make install` instead.

For example:-

**n.Makefile**

```
instal%:
	echo "shared install"
```

**Makefile**

```
include n.Makefile

install:
	echo "repo install"
	make install-super
```

Will do this:-

```
$ make install
echo "repo install"
repo install
echo "shared install"
shared install
```

We use `-super` as a suffix by convention but the way we've achieved inheritance actually means `install-super` could be swapped with any string that matches `instal%` and isn't equal to `install`.