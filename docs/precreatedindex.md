---
layout: default
title: Reducing opening time
simple_header: true
no_description: true
mermaid: true
---

# Problem Statement
Every time DigViewer opens a specified folder, it recursively scans all images within the folder's hierarchy. While this process doesn't take much time when the image repository is located on built-in storage of Mac or fast external storage, it can become time-consuming if you are building a repository with a large number of photos on a NAS. In such cases, it might take an unbearable amount of time for the scan to complete.<br>
This is due in part to the low throughput of storage access, including network-based access. However, the impact of overhead from network file sharing protocols such as CIFS and AFP is even more significant. Access through these protocols, particularly when it involves referencing and updating the file system's namespace, imposes substantial overhead.

# Solution
If DigViewer finds a file named ```.Pathfinder.pflist``` in the specified folder, it assumes that this file contains the pathname of all files within the specified folder. DigViewer reads this file to reconstruct the namespace, instead of querying the namespace to file system.<br>
In ```.Pathfinder.pflist```, file paths are recorded with prefixes ```D ``` for directories and ```F``` for regular files, as showns below.

```text
D trip
D trip/2014-06-09 USA San Jose
D trip/2018-02-10 Taiwan-K30
D trip/2013-10-14 USA
D trip/2013-10-14 USA/data
     .
     .
    snip
     .
     .
F trip/2013-10-14 USA/data/IMGP8135.DNG
F trip/2013-10-14 USA/data/IMGP8769.DNG
F trip/2013-10-14 USA/data/IMGP8934.DNG
F trip/2013-10-14 USA/data/IMGP7869.DNG
```

You can create the ```.Pathfinder.pflist``` by executing the following shell script with the path to the folder where the image repository exists as an argument.

```sh
#!/bin/sh
if [ $# != 1 ];then
    echo "usage: `basename $0` TARGET-PATH" >&2
    exit 1
fi

DIR=`dirname $1`
BASE=`basename $1`
(
    cd "${DIR}"
    find "${BASE}" -type d | awk '{print "D " $0}'
    find "${BASE}" -type f | awk '{print "F " $0}'
) | grep -v \\.AppleDouble > "${DIR}/${BASE}/.Pathfinder.pflist"
```

By regularly executing this script on your NAS or running it when you upload a large number of photos, you can significantly reduce the time it takes to open an image repository on your NAS using DigViewer.

Please note that it's important to execute this script on the NAS's operating system rather than on a Mac with the NAS mounted. 
While the script will create the files correctly in either case,
executing the script on a Mac can take an excessively long time due to the same reasons mentioned in the "Problem Statement" section,<br>
Many NAS systems offer SSH access and the ability to run user-defined scripts, so consider using these features for script execution.
