# arkiver

A bespoke utility wrapper to list and extract archives in a user consistent
manner with multiple archival tools from tarballs, zip, 7zip, rar, and more.


## reason

I wanted a tool that could extract pretty much any archive format and list the
contents in a consistent format without having to fiddle with options every
single time, while `atool` exists and handles the usecase it unfortunately does
NOT support password protected archives and i do not know perl so here we are...


## requirements

|program|archive|
|-------|-------|
|tar|tarballs|
|xz utils|xz and lzma|
|bzip2|bz2|
|unrar|unzip|
|gzip|gz|
|7z|7zip and zip|
|uncompress|Z archives|
|zstd|zst|
|ar|deb|
|cabextract|cab and exe|
|unar|old mac and amiga formats|
|lsar|listing of files for gz, zip, bz2, 7z, rar and more|


## installation

```sh
make clean install
```

This will make the arkiver program available along the action specific symlinks
ext and arls
