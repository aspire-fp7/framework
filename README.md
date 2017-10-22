# How to use the ASPIRE framework in a Docker container
In this manual, we will explain how to set up the ASPIRE tools and how to use
them to protect a simple application.

The set up of the open sourced version ASPIRE tools is simple thanks to the use
of the [Docker virtualization framework](https://www.docker.com/).
The rest of this manual describes how to set up a Docker container
with the ASPIRE tools in it. It will also explain how to apply different ASPIRE protections
with the ASPIRE Compiler Tool Chain (ACTC).


## Setting up the Docker container
We assume that you have already Docker installed on your machine. If not,
you can follow the instructions from the [Docker website](https://www.docker.com/).

To set up an ASPIRE Docker container, you just have to clone this repository which contains the base Docker file. As
all the actual tools (and Docker support files) are linked into this repository with git submodules, you'll also
have to initialize the git submodules in addition to cloning this repository. We use a separate script for this, which
will also query you to (optionally) install additional support for anti_debugging.

    # git clone https://github.com/aspire-fp7/framework/
    # cd framework
    # ./setup.sh

This repository contains the Dockerfile and docker-compose.yml files. To build the ASPIRE docker service, at least version 1.13 of
docker-compose is required. When the right version of docker-compose is installed, you just run the following command in this directory:

    # docker-compose build aspire

When building the Docker container, most ASPIRE projects are built from scratch
inside the container.
This allows you to immediately start developing and extending any existing
tools, without having to worry about how to build the projects and how to
overwrite the pre-built files. The only down side is that setting up the initial
container will take some time. The build process takes about 4 minutes on
a decently modern machine.

The only files that are not built inside the container are:

* The patched binary tool chains. These can be rebuilt from source by cloning
Diablo's toolchains repository located at [https://github.com/diablo-rewriter/toolchains](https://github.com/diablo-rewriter/toolchains)
and following the instructions in the `README.MD` file.
* Versions of the OpenSSL, libwebsockets and libcurl libraries that have
been built with Diablo-compatible tool chains. These can be rebuilt
from source by cloning the [https://github.com/aspire-fp7/3rd_party/](https://github.com/aspire-fp7/3rd_party/) repository
and following the instructions in the `README.MD` file.

## Starting the Docker
We have provided a script to start the Docker container with the correct parameters:

    # ./docker/run.sh
    root@33f36aef63c2:/projects# 

First, this script prepares a 'projects' directory which already has the actc-demos repository
checked out into it. It is one of the samples in that demos repository that we will
be using in the remainder of this manual.

Next, the script opens a bash shell in the *aspire* container in which we will
be executing all further commands. Furthermore, this script sets up the correct
ports on your Docker container for
the online protection techniques. Finally, it maps the `projects/`
directory into the container as `/projects/`.

## Running the ACTC without any protections
The `build.sh` sets up a repository with a demo project in 
`/projects/actc-demos/` We will be protecting the bzip2
compression utility in this demos repository. As an example, we have already
added some annotations to the `bzip2.c` source file.

First, we will use the ACTC to build an unprotected bzip2 binary for the 
ARM Linux platform. We have provided an ACTC configuration file for this purpose. You can view this file at `actc/bzip2_linux.json`.
This configuration file instructs the ACTC in such a way that the
ACTC will build the binary, but it will not apply any protections. To
run the ACTC with this configuration file, do the following:

    # cd actc-demos/bzip2-1.0.6/
    # /opt/ACTC/actc.py -d -f actc/bzip2_linux.json

This produces a final binary in `actc/build/bzip2_linux/BC05/bzip2`.
If you have an ARM development board, you can copy this file and run it as
you would do any other binary.

## Running the ACTC with only offline protections
The ACTC now has applied no protections at all to our binary. As a first step, we will 
apply some offline protection techniques. The annotations to instruct the protection
tools which code fragments need to be protected have already been added in the source
code (you can find these by looking for `_Pragma("ASPIRE begin` and
`_Pragma ("ASPIRE end")` in the source files). 
As you can see, we have added annotations for *call stack checks*, *binary obfuscations*,
and *code guards*.
We only need to
enable their application in the configuration file of the ACTC.

Annotations can be added and modified at will. Their syntax and semantics are
described in detail in the appendices of the
[ASPIRE Framework report](https://aspire-fp7.eu/sites/default/files/D5.11-ASPIRE-Framework-Report.pdf).

The configuration file is a JSON file that can be edited easily. The Docker container
has vim installed, but of course you can use any editor of your liking.

    # vim actc/bzip2_linux.json

Code guards is a technique that consists of a source-to-source transformation
and a binary transformation. First, we enable the source-to-source part.
We search for `"SLP08"`, which is the name of the source step responsible for
this. We see that the `"traverse"` is currently set to `true`,
which means that the action for this step simply copies the files from
the input directory to the output directory, rather than applying the action
in this step. Thus, set this action to `false`.

Next, we have to edit the configuration where the binary protection techniques
are described. Search for `"BLP04"`, which is the name of the final
binary protection step in the ACTC. In the configuration for this step,
we will now enable all the aforementioned protections: set `"obfuscations"` and
`"call_stack_check"` to `true` (the binary
part of the code guards protection is automatically enabled or disabled depending
on how we configured the `"SLP08"` step). We can now
run the ACTC as before:

    # /opt/ACTC/actc.py -d -f actc/bzip2_linux.json

This again produces the protected binary in `actc/build/bzip2_linux/BC05/bzip2`.
This time, you can check the log files in the `actc/build/bzip2_linux/BC05/` directory
to verify that the protections have indeed been applied. For example, the file
`bzip2.diablo.obfuscation.log` contains information of which binary
obfuscations have been applied to which code fragments.

## Running the ACTC with code mobility
Now that we have created a version of our binary with offline protections
applied, it is time to apply our first online protection called code mobility.
This will split off binary code fragments from the application, and replace them
with stubs that at run time ask for these code fragments to be downloaded
from a protection server. Only once they are downloaded at run time, are these
code fragments executed.

The first step is to enable this protection in the JSON configuration. There
are two steps needed to enable this: enabling the technique itself, and
configuring the server. To enable the technique, simply change the value of
`"code_mobility"` to `true` in the `"BLP04"`
section of the configuration file.

To configure the server in the JSON configuration file, go to the `"COMPILE_ACCL"`
section of the configuration, and modify the value of `"endpoint"` to
be the IP of the machine on which your Docker container is running.

Again, run the ACTC as before:

    # /opt/ACTC/actc.py -d -f actc/bzip2_linux.json

You can first verify that the code mobility protection was applied by
inspecting the log file called `bzip2.diablo.code_mobility.log`. Next, 
verify that mobile code blocks were indeed produced. If you look up at the output
of the ACTC, near the end it will write information to the terminal similar to:

    .  SERVER_P20
       code mobility       /projects/actc-demos/bzip2-1.0.6/actc/build/bzip2_linux/BC05/mobile_blocks

    /opt/code_mobility/deploy_application.sh -a D7846E47BB09D62A2824CA9CF5000AE8 -p 20 -i YOUR_IP_HERE /projects/actc-demos/bzip2-1.0.6/actc/build/bzip2_linux/BC05/mobile_blocks && touch /projects/actc-demos/bzip2-1.0.6/actc/build/bzip2_linux/BC05/mobile_blocks/.p20done

    APPLICATION ID  = D7846E47BB09D62A2824CA9CF5000AE8
    .  SERVER_RENEWABILITY_CREATE

This indicates that the ACTC is deploying the mobile blocks to the location
in which the code mobility server expects these blocks to be. This
location depends on the `APPLICATION ID` (AID) mentioned in the output of the ACTC:
they are located in `/opt/online_backends/<AID>/code_mobility/00000000/`:

    # ls  /opt/online_backends/D7846E47BB09D62A2824CA9CF5000AE8/code_mobility/00000000/
    mobile_dump_00000000  mobile_dump_00000001  mobile_dump_00000002  mobile_dump_00000003  mobile_dump_00000004  mobile_dump_00000005  mobile_dump_00000006  mobile_dump_00000007  mobile_dump_00000008  mobile_dump_00000009  mobile_dump_0000000a  source.txt
    
As you can see in the source code, the code mobility annotation was applied to the
`uncompress` function. So if you now copy the protected file to an ARM board and try to decompress a file,
the code mobility protection will be triggered. You can afterwards verify
the logs in the server to see which blocks were requested:

    # scp actc/build/bzip2_linux/BC05/bzip2 user@armboard:.
    # ssh user@armboard
    user@armboard:~$ dd if=/dev/zero of=./zeroes bs=1M count=10 ; bzip2 zeroes
    10+0 records in
    10+0 records out
    10485760 bytes (10 MB) copied, 0.080404 s, 130 MB/s
    user@armboard:~$ ./bzip2 -d zeroes.bz2 
    user@armboard:~$ logout
    # tail /opt/online_backends/code_mobility/mobility_server.log 
    Fri Nov 25 15:02:24 2016 [Code Mobility Server] Actual revision for app_id D7846E47BB09D62A2824CA9CF5000AE8 is 00000000
    
    Fri Nov 25 15:02:24 2016 [Code Mobility Server] BLOCK_ID 8 requested
    
    Fri Nov 25 15:02:24 2016 [Code Mobility Server] BLOCK_ID 8 (filename: /opt/online_backends/D7846E47BB09D62A2824CA9CF5000AE8/code_mobility/00000000/mobile_dump_00000008) is going to be served.
    
    Fri Nov 25 15:02:24 2016 [Code Mobility Server] BLOCK_ID 8 is 52 bytes long.
    
    Fri Nov 25 15:02:24 2016 [Code Mobility Server] BLOCK_ID 8 correctly sent to ASPIRE Portal.

**Warning:** the server ports of the ASPIRE servers should not be firewalled
on your Docker machine. Similarly, if your Docker is running inside a virtual machine,
your virtual machine monitor should forward these ports to the VM itself. The ports are
all ports between 8080 to 8099 (inclusive) and port 18001.

## Running the ACTC with remote attestation
Now that we have protected the application with code mobility, we will enable
another online protection technique called remote attestation. This technique
uses a server to verify the integrity of code fragments during the application execution.
The application connects to the server, which then instructs the application to send
attestations of certain code regions back to the server. The results of these
attestations can be linked to the code mobility protection technique to
stop serving code to applications that have been compromised.

First, we enable the remote attestation step in the ACTC configuration file.
The name of the step source-to-source part of the remote attestation protection
is named SLP07. So, to enable remote attestation, simply change the `"excluded"`
value in the `"SLP07"` section of the configuration file to `false`.
The binary part of this protection technique is again automatically enabled and disabled
based on the value in `"SLP07"`.

Again, to build the protected application with the ACTC, just run as before:

    # /opt/ACTC/actc.py -d -f actc/bzip2_linux.json

The output of the ACTC immediately shows that the remote attestation was deployed:

    Add attestator in the DB (nr: 00000000000000000000, name: remote_ra_region, f: 10)
    Generating inital 100 prepared data for current attestator (launching extractor)
    Attestator inserted with ID: 5
    Inserting startup areas in the DB, found 1 areas
    Startup area: 0
    
    **** RA application components deployed on server successfully ****

To verify that the binary itself indeed connects to the protection server
of the remote attestation technique, and that this server indeed receives
valid attestations, we can again copy the protected binary to a development board,
run it to compress and decompress the file we created earlier
to demonstrate code mobility, and check the attestation logs on the server:

    # scp actc/build/bzip2_linux/BC05/bzip2 user@armboard:.
    # ssh user@armboard
    user@armboard:~$ ./bzip2 zeroes ; ./bzip2 -d zeroes.bz2
    [1927760:9055] NOTICE: Initial logging level 7
    <... some additional logging information about the connection is displayed ...>
    user@armboard:~$ logout
    # tail /opt/online_backends/remote_attestation/verifier.log  
    03E2A03010E28DBB00E3922A020A02D3
    75E190009DE39330F8E3FE305CE19F00
    00E5933078EB014D9AE1FE2C45E39CCA
    38EB00FFD40A5330AFEB02490AE19220
    9DE30300BCE39CCA06E2A03027E1900A
    03E24F3848E2911A00E58D1010E30D20
    03E2900A0EE3A0DB
    (Verifier) Response verification result: SUCCESS
    (Verifier) Response verified in = 0.001435 s
    (Verifier) Execution finished at: Fri Nov 25 15:55:07 2016

This shows that the protected application indeed connected to the server, and
that the server sent an annotation request back to this client, and that
this client successfully responded to that request.

## Doing development with this Docker container

When you're playing with the Docker container and want to edit the sources of one of
the tools, it can be handy to have changes made in your host immediately propagate
to the Docker, and vice versa. To make this easier, we have provided the option of
running the container in development mode. This can be enabled by setting the
`DEVELOPER_MODE` variable before running the docker, like so:

    # export DEVELOPER_MODE=yes

When starting the container with the `run.sh` script this sets up Docker volumes in
`/opt/development` that refer to the directories of all the tools on your host.
`/opt/framework` is then updated to be a symlink to `/opt/development`, and Diablo is
built from (development) source. This build happens on a named volume (located at /build
in the Docker) so that it has to happen only once, and incremental builds are easy.

## Further reading

These are some documents describing parts of the framework and its components in more detail:

* [Reference architecture](https://aspire-fp7.eu/sites/default/files/D1.04-ASPIRE-Reference-Architecture-v2.1.pdf) Describes the architectural design of the ASPIRE protections and the communication logic for the client and server components of the protections.
* [ASPIRE Framework report](https://aspire-fp7.eu/sites/default/files/D5.11-ASPIRE-Framework-Report.pdf) Documents the ASPIRE tool chain and decision support components in exhaustive detail. This document furthermore documents the supported protection annotations.
* [ASPIRE Open Source Manual](https://aspire-fp7.eu/sites/default/files/D5.13-ASPIRE-Open-Source-Manual.pdf) Contains manuals for the framework (which is an older version of this README), and documentation of the ADSS Full.
